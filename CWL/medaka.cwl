cwlVersion: 'sbg:draft-2'
class: CommandLineTool
$namespaces:
  sbg: 'https://www.sevenbridges.com/'
id: medaka
label: medaka
baseCommand:
  - medaka_consensus
inputs:
  - type:
      - File
    inputBinding:
      position: 0
      prefix: '-i'
      separate: true
      secondaryFiles: []
    label: host filtered reads FASTQ.GZ
    id: '#input_host_filtered_reads'
  - type:
      - File
    inputBinding:
      position: 2
      prefix: '-d'
      separate: true
      secondaryFiles: []
    label: assembly FASTA
    id: '#input_assembly_fasta'
  - type:
      - 'null'
      - string
    inputBinding:
      position: 3
      prefix: '-o'
      separate: true
    label: output directory path
    id: '#output_dir_path'
outputs:
  - type:
      - File
    label: output consensus contigs
    outputBinding:
      glob: '*.fasta'
    id: '#output'
hints:
  - class: DockerRequirement
    dockerPull: 'docker.io/staphb/medaka:latest'
arguments:
  - position: 0
    prefix: '-t'
    separate: true
    valueFrom: '4'
