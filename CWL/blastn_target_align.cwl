cwlVersion: 'sbg:draft-2'
class: CommandLineTool
$namespaces:
  sbg: 'https://www.sevenbridges.com/'
id: blastn_target_align
label: blastn_target_align
baseCommand:
  - blastn
inputs:
  - type:
      - File
    inputBinding:
      position: 0
      prefix: '-subject'
      separate: true
      secondaryFiles: []
    label: input symbiont reference genome FASTA
    id: '#input_symbiont_target_ref'
  - type:
      - File
    inputBinding:
      position: 1
      prefix: '-query'
      separate: true
      secondaryFiles: []
    label: consensus contigs from medaka FASTA
    id: '#input_consensus_contigs'
  - type:
      - string
    inputBinding:
      position: 2
      prefix: '-out'
      separate: true
    label: output aligned file
    id: '#out_file_name'
outputs:
  - type:
      - File
    label: BLASTN alignment output
    outputBinding:
      glob: '*.t*'
    id: '#output_blastn_alignment'
hints:
  - class: DockerRequirement
    dockerPull: 'docker.io/confurious/blastn:latest'
arguments:
  - position: 0
    prefix: '-outfmt'
    separate: true
    valueFrom: '"6 std qlen slen"'
