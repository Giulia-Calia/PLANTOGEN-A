cwlVersion: 'sbg:draft-2'
class: CommandLineTool
$namespaces:
  sbg: 'https://www.sevenbridges.com/'
id: samtools_sam2bam
label: samtools_sam2bam
baseCommand:
  - samtools
  - sort
  - ''
inputs:
  - type:
      - string
    inputBinding:
      position: 0
      prefix: '-o'
      separate: true
    label: output BAM file name
    id: '#output_file_name'
  - type:
      - File
    inputBinding:
      position: 0
      separate: true
      secondaryFiles: []
    label: input SAM mapped file
    id: '#input_mapped_sam'
outputs:
  - type:
      - File
    label: output BAM file
    'sbg:fileTypes': BAM
    outputBinding:
      glob: '*.bam'
    id: '#output_mapped_bam'
hints:
  - class: DockerRequirement
    dockerPull: 'docker.io/staphb/samtools:latest'
arguments:
  - position: 0
    prefix: '-O'
    separate: true
    valueFrom: BAM
