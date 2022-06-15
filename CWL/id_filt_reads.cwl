cwlVersion: 'sbg:draft-2'
class: CommandLineTool
$namespaces:
  sbg: 'https://www.sevenbridges.com/'
id: id_filt_reads
label: id_filt_reads
baseCommand:
  - cut
inputs:
  - type:
      - File
    inputBinding:
      position: 0
      secondaryFiles: []
    label: TMP filtered reads
    id: '#input_filt_reads'
  - type:
      - string
    inputBinding:
      position: 0
      prefix: '>'
      separate: true
    label: output file name
    id: '#output_file_name'
outputs:
  - type:
      - 'null'
      - File
    label: ID filtered reads
    outputBinding:
      glob: '*'
    id: '#output_id_filtered_reads'
hints:
  - class: DockerRequirement
    dockerPull: 'docker.io/library/ubuntu:latest'
arguments:
  - position: 0
    prefix: '-f'
    separate: true
    valueFrom: '1'
