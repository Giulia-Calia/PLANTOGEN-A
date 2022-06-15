cwlVersion: 'sbg:draft-2'
class: CommandLineTool
$namespaces:
  sbg: 'https://www.sevenbridges.com/'
id: host_filter
label: host_filter
baseCommand:
  - python3
inputs:
  - type:
      - File
    inputBinding:
      position: 0
      secondaryFiles: []
    label: PYTHON SCRIPT
    id: '#input_filter_script'
  - type:
      - File
    inputBinding:
      position: 1
      separate: true
      secondaryFiles: []
    label: basecalled FASTQ reads
    id: '#input_basecalled_reads'
  - type:
      - string
    inputBinding:
      position: 2
      separate: true
    label: output filtered reads name
    id: '#output_file_name'
  - type:
      - 'null'
      - File
    inputBinding:
      position: 3
      prefix: '-r'
      separate: true
      secondaryFiles: []
    label: input filtered read ids
    id: '#input_filtered_read_ids'
outputs:
  - type:
      - 'null'
      - File
    label: host filtered reads
    'sbg:fileTypes': FASTQ.GZ
    outputBinding:
      glob: '*fastq.gz'
    id: '#output_host_filtered'
hints:
  - class: DockerRequirement
    dockerPull: 'docker.io/zavolab/python_htseq_biopython:3.6.5_0.10.0_1.71'
