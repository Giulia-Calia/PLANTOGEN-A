# PLANTOGEN-A

PLANTOGEN-A is an automated genome assembly pipeline designed to assemble symbiont microorganisms genome from Oxford Nanopore (ONT) data. A necessary condition for our pipeline is to have an available and well-known host genome to use as a reference for the host-reads cleaning step.

Almost every step of PLANTOGEN-A is associated with a logical step in the genome assembly workflow, from basecalled reads as input files, to corrected contigs, as output ones. Conceptually the workflow is composed as follows:
- reads mapping (Minimap2 v2.17)
- host filtering (host_reads_filter.py, mapping quality to filter = 21) 
- reads assembly (Flye v2.8) 
- contig consensus production (Medaka v1.2.0)
- contig selection (BLAST v2.5.0 + blastn_contig_selection.py) 
- contig correction (Pilon) 

# USAGE - Nextflow

Nextflow has to be installed or integrated in the HPC cluster in use. With Nextflow, all the workflow is optimized and, according to computational resources and process independence, steps are executed in parallel. Each automated step can have specific allocated resources defined in the configuration file that are automatically reserved to it when executed. PLANTOGEN-A is designed to work on an **HPC Cluster** and it automatically deals with the **SGE system for job submission**. In addition, it can be configured to use containerized software (**Singularity** or Docker). 

To specify parameters in the command line, use:

`nextflow run pipeline.nf -c nextflow.config --name prefix --host_ref /path/to/host_genome.fasta --basecalled /path/to/basecalled_reads.fastq.gz --symbiont_target_ref /path/to/symbiont_target.fasta --r1 /path/to/illumina_R1.fq.gz --r2 /path/to/illumina_R2.fq.gz -bg`

Otherwise, simply modify the `nextflow.config` file with the corrected path in the `params` section:
`params {
  name = "prefix_name_for_output_files"
  host_ref = "/path/to/the/host_reference_genome.fasta"
  ...
 }`
 
 And then simply run:
 `nextflow run pipeline.nf -c nextflow.config -bg` 
 
 > `-bg` parameter of Nextflow is important to execute the pipeline in background 

# USAGE - Snakemake 

Also Snakemake has to be installed or completely integrated into the Cluster. To use the pipeline with Snakemake run:

`snakemake --configfile config.yml --cores n` 

Snakemake expect that the Snakefile is in the directory where the snakemake environment is active. The config.yml contains all the paths that has to be modified/specified for the pipeline to works. 

# USAGE - CWL 
The entire workflow is stored in the plantogen-a.cwl file but each step is interpreted as a different tool in the pipeline and has its own definition `.cwl` file. For the pipeline to work you must have all the software installed locally or a docker image of them and you have to replace the path to the image in the right section of the `tool.cwl` file

> hints:
> 
  >> class: DockerRequirement
>
  >> dockerPull: 'docker.io/some_name/tool_name:version'
