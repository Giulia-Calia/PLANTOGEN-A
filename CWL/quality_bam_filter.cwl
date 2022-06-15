cwlVersion: 'sbg:draft-2'
class: CommandLineTool
$namespaces:
  sbg: 'https://www.sevenbridges.com/'
id: quality_bam_filter
label: quality_bam_filter
baseCommand:
  - samtools
  - view
inputs:
  - type:
      - string
    inputBinding:
      position: 0
      prefix: '-U'
      separate: true
    label: filename_tmp_filtered_reads
    id: '#tmp_file_name'
  - type:
      - File
    inputBinding:
      position: 1
      prefix: '-T'
      separate: true
      secondaryFiles: []
    label: input FASTA host genome
    id: '#input_host_reference_genome'
  - type:
      - File
    inputBinding:
      position: 2
      separate: true
      secondaryFiles: []
    label: input BAM mapped reads
    id: '#input_mapped_reads'
outputs:
  - type:
      - 'null'
      - File
    label: tmp_filtered_file
    outputBinding:
      glob: '*'
    id: '#output_tmp_fileterd_file'
hints:
  - class: DockerRequirement
    dockerPull: 'docker.io/staphb/samtools:latest'
arguments:
  - position: 0
    prefix: '-Sq'
    separate: true
    valueFrom: '21'
