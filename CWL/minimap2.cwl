cwlVersion: 'sbg:draft-2'
class: CommandLineTool
$namespaces:
  sbg: 'https://www.sevenbridges.com/'
id: minimap2
label: minimap2.cwl
baseCommand:
  - minimap2
inputs:
  - type:
      - string
    inputBinding:
      position: 0
      prefix: '-o'
      separate: true
    label: output SAM file name
    id: '#output_file_name'
  - type:
      - File
    inputBinding:
      position: 1
      separate: true
      secondaryFiles: []
    label: input FASTA host reference genome
    id: '#input_host_reference_genome'
  - type:
      - 'null'
      - File
    inputBinding:
      position: 2
      separate: true
      secondaryFiles: []
    label: input FASTQ basecalled reads
    id: '#input_basecalled_reads'
outputs:
  - type:
      - File
    label: Output SAM file
    'sbg:fileTypes': SAM
    outputBinding:
      glob: '*.sam'
    id: '#output'
hints:
  - class: DockerRequirement
    dockerPull: 'docker.io/staphb/minimap2:latest'
arguments:
  - position: 0
    prefix: '-ax'
    separate: true
    valueFrom: map-ont
