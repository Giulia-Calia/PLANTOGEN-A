cwlVersion: 'sbg:draft-2'
class: CommandLineTool
$namespaces:
  sbg: 'https://www.sevenbridges.com/'
id: flye
label: flye
baseCommand:
  - flye
  - '--meta'
inputs:
  - type:
      - File
    inputBinding:
      position: 0
      prefix: '--nano-raw'
      separate: true
      secondaryFiles: []
    label: baecalled reads
    id: '#input_basecalled_reads'
  - type:
      - string
    inputBinding:
      position: 0
      prefix: '--out-dir'
      separate: true
    label: output directory
    id: '#output_dir'
outputs:
  - type:
      - 'null'
      - File
    label: assembly FASTA
    'sbg:fileTypes': FASTA
    outputBinding:
      glob: '*.fasta'
    id: '#output_assembly'
hints:
  - class: DockerRequirement
    dockerPull: 'docker.io/staphb/flye:latest'
arguments:
  - position: 0
    prefix: '-i'
    separate: true
    valueFrom: '5'
  - position: 0
    prefix: '--genome-size'
    separate: true
    valueFrom: 600k
  - position: 0
    prefix: '--threads'
    separate: true
    valueFrom: '4'
