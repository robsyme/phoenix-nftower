process SPADES {
    tag "$meta.id"
    label 'process_high_memory'
    container 'staphb/spades:3.15.5'

    input:
    tuple val(meta), path(reads), path(unpaired_reads), path(k2_bh_summary), \
    path(fastp_raw_qc), \
    path(fastp_total_qc), \
    path(kraken2_trimd_report), \
    path(krona_trimd), \
    path(full_outdir)

    output:
    tuple val(meta), path('*.scaffolds.fa.gz')    , optional:true, emit: scaffolds
    tuple val(meta), path('*.contigs.fa.gz')      ,                emit: contigs
    tuple val(meta), path('*.assembly.gfa.gz')    , optional:true, emit: gfa
    tuple val(meta), path('*.log')                ,                emit: log
    tuple val(meta), path('*_summaryline.tsv')    , optional:true, emit: line_summary
    tuple val(meta), path('*.synopsis')           , optional:true, emit: synopsis
    path  "versions.yml"                          ,                emit: versions
    tuple val(meta), path("*_spades_outcome.csv") ,                emit: spades_outcome

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def maxmem = task.memory.toGiga() // allow 4 less GB to provide enough space
    def input_reads = "-1 ${reads[0]} -2 ${reads[1]}"
    def single_reads = "-s $unpaired_reads"
    def phred_offset = params.phred
    """
    pipeline_stats_writer_trimd.sh -a ${fastp_raw_qc} -b ${fastp_total_qc} -c ${reads[0]} -d ${reads[1]} -e ${kraken2_trimd_report} -f ${k2_bh_summary} -g ${krona_trimd}
    beforeSpades.sh -k ${k2_bh_summary} -n ${prefix} -d ${full_outdir}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        spades: \$(spades.py --version 2>&1 | sed 's/^.*SPAdes genome assembler v//; s/ .*\$//')
    END_VERSIONS

    spades_complete=run_failure,no_scaffolds,no_contigs
    echo \$spades_complete | tr -d "\\n" > ${prefix}_spades_outcome.csv

    spades.py \\
        $args \\
        --threads $task.cpus \\
        --memory $maxmem \\
        $single_reads \\
        $input_reads \\
        --phred-offset $phred_offset\\
        -o ./

    mv spades.log ${prefix}.spades.log
    spades_complete=run_completed
    echo \$spades_complete | tr -d "\\n" > ${prefix}_spades_outcome.csv

    rm ${full_outdir}/${prefix}/${prefix}_summaryline_failure.tsv
    rm ${full_outdir}/${prefix}/${prefix}.synopsis
    afterSpades.sh
    """
}
