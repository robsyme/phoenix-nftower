process GATHER_SUMMARY_LINES {
    label 'process_low'
    afterScript "rm ${params.outdir}/*_summaryline.tsv"
    container 'quay.io/jvhagey/phoenix:base_v1.0.0'

    /*container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/python:3.8.3' :
        'quay.io/biocontainers/python:3.8.3' }"*/

    input:
    path(summary_line_files)
    val(busco_val)

    output:
    path 'Phoenix_Output_Report.tsv'  , emit: summary_report
    path "versions.yml"               , emit: versions

    script: // This script is bundled with the pipeline, in cdcgov/phoenix/bin/
    def busco_parameter = busco_val ? "--busco" : ""
    """
    if [ -f "empty_summaryline.tsv" ]; then
        rm empty_summaryline.tsv
        new_summary_line_files=\$(echo $summary_line_files | sed 's/empty_summaryline.tsv //')
        if [ -f "placeholder.txt" ]; then
            rm placeholder.txt
            new_summary_line_files=\$(echo \$new_summary_line_files | sed 's/placeholder.txt //')
        fi
        Create_phoenix_summary_tsv.py --out Phoenix_Output_Report.tsv $busco_parameter \$new_summary_line_files
    elif [ -f "placeholder.txt" ]; then
        rm placeholder.txt
        new_summary_line_files=\$(echo $summary_line_files | sed 's/placeholder.txt //')
        if [ -f "empty_summaryline.tsv" ]; then
            rm empty_summaryline.tsv
            new_summary_line_files=\$(echo \$new_summary_line_files | sed 's/empty_summaryline.tsv //')
        fi
        Create_phoenix_summary_tsv.py --out Phoenix_Output_Report.tsv $busco_parameter \$new_summary_line_files
    else
        Create_phoenix_summary_tsv.py \\
            --out Phoenix_Output_Report.tsv \\
            $busco_parameter \\
            $summary_line_files
    fi

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version | sed 's/Python //g')
    END_VERSIONS
    """
}
