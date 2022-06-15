cwlVersion: 'sbg:draft-2'
class: CommandLineTool
$namespaces:
  sbg: 'https://www.sevenbridges.com/'
id: contig_selection
label: contig_selection
baseCommand:
  - python3
inputs:
  - type:
      - File
    inputBinding:
      position: 0
      secondaryFiles: []
    label: contig selection PYTHON script
    id: '#input_contig_sel_script'
  - type:
      - File
    inputBinding:
      position: 1
      prefix: '-c'
      separate: true
      secondaryFiles: []
    label: consensus contigs FASTA
    id: '#input_consensus_contigs'
  - type:
      - File
    inputBinding:
      position: 2
      prefix: '-t'
      separate: true
      secondaryFiles: []
    label: BLASTN alignment file
    id: '#input_blastn_aligned_file'
  - type:
      - string
    inputBinding:
      position: 3
      prefix: '-p'
      separate: true
    label: name for output file
    id: '#output_prefix_name'
  - type:
      - string
    inputBinding:
      position: 4
      prefix: '-o'
      separate: true
    label: output dir path
    id: '#output_dir_path'
outputs:
  - type:
      - 'null'
      - File
    label: selected contigs for symbiont FASTA
    'sbg:fileTypes': FASTA
    outputBinding:
      glob: '*.fasta'
    id: '#output_selected_contigs'
