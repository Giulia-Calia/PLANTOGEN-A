cwlVersion: 'sbg:draft-2'
class: CommandLineTool
$namespaces:
  sbg: 'https://www.sevenbridges.com/'
id: id_filt_reads_unique
label: if_filt_reads_unique
baseCommand:
  - sort
inputs:
  - type:
      - File
    inputBinding:
      position: 0
      prefix: '-u'
      separate: true
      secondaryFiles: []
    label: input qfiltered reads
    id: '#input_id_qfilt'
  - type:
      - string
    inputBinding:
      position: 0
      prefix: '>'
      separate: true
    label: output filtered ID reads name
    id: '#output_file_name'
outputs:
  - type:
      - 'null'
      - File
    label: output filtered reads IDs
    outputBinding:
      glob: '*'
    id: '#output_qfilt_reads_id'
hints:
  - class: DockerRequirement
    dockerPull: 'docker.io/library/ubuntu:latest'
