cwlVersion: 'sbg:draft-2'
class: CommandLineTool
$namespaces:
  sbg: 'https://www.sevenbridges.com/'
id: pilon
label: pilon
baseCommand:
  - bash
  - ''
inputs:
  - type:
      - File
    inputBinding:
      position: 0
      secondaryFiles: []
    label: SH script for pilon usage
    id: '#input_sh_pilon_file'
  - type:
      - File
    inputBinding:
      position: 1
      separate: true
      secondaryFiles: []
    label: contigs of symbiont assembled genome FASTA
    id: '#input_selected_contigs'
  - type:
      - File
    inputBinding:
      position: 2
      separate: true
      secondaryFiles: []
    label: r1 illumina reads for correction
    id: '#input_r1_illumina_reads'
  - type:
      - File
    inputBinding:
      position: 3
      separate: true
      secondaryFiles: []
    label: r2 illumina reads for correction
    id: '#input_r2_illumina_reads'
  - type:
      - 'null'
      - string
    inputBinding:
      position: 4
      separate: true
    label: prefix for output files
    id: '#input_prefix_name'
outputs:
  - type:
      - File
    label: all outputs from pilon iterations
    outputBinding:
      glob: '*.fasta'
    id: '#outputs'
hints:
  - class: DockerRequirement
    dockerPull: 'docker.io/staphb/bwa:latest'
