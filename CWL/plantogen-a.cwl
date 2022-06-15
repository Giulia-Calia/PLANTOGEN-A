class: Workflow
cwlVersion: 'sbg:draft-2'
id: plantogen_a
label: PLANTOGEN-A
$namespaces:
  sbg: 'https://www.sevenbridges.com/'
inputs:
  - type:
      - File
    id: '#input_host_reference_genome'
    'sbg:includeInPorts': true
    'sbg:x': -654.5380859375
    'sbg:y': -303.49237060546875
  - type:
      - 'null'
      - File
    id: '#input_basecalled_reads'
    'sbg:includeInPorts': true
    'sbg:x': -663.9594116210938
    'sbg:y': -180.56344604492188
  - type:
      - File
    id: '#input_filter_script'
    'sbg:includeInPorts': true
    'sbg:x': 228.03045654296875
    'sbg:y': -198.28933715820312
  - type:
      - File
    id: '#input_symbiont_target_ref'
    'sbg:includeInPorts': true
    'sbg:x': 150.94923400878906
    'sbg:y': 153.21827697753906
  - type:
      - File
    id: '#input_contig_sel_script'
    'sbg:includeInPorts': true
    'sbg:x': 150.4467010498047
    'sbg:y': 366.1979675292969
  - type:
      - File
    id: '#input_sh_pilon_file'
    'sbg:x': 97.80203247070312
    'sbg:y': 559.7106323242188
    'sbg:includeInPorts': true
  - type:
      - File
    id: '#input_r2_illumina_reads'
    'sbg:x': 53.954315185546875
    'sbg:y': 654.6446533203125
    'sbg:includeInPorts': true
  - type:
      - File
    id: '#input_r1_illumina_reads'
    'sbg:x': 71.85279083251953
    'sbg:y': 792.7918701171875
    'sbg:includeInPorts': true
outputs: []
steps:
  - id: '#minimap2'
    inputs:
      - id: '#minimap2.input_host_reference_genome'
        source: '#input_host_reference_genome'
      - id: '#minimap2.input_basecalled_reads'
        source: '#input_basecalled_reads'
    outputs:
      - id: '#minimap2.output'
    run: ./minimap2.cwl
    label: minimap2.cwl
    'sbg:x': -467.4111633300781
    'sbg:y': -173.3045654296875
  - id: '#quality_bam_filter'
    inputs:
      - id: '#quality_bam_filter.input_host_reference_genome'
        source: '#input_host_reference_genome'
      - id: '#quality_bam_filter.input_mapped_reads'
        source: '#minimap2.output'
    outputs:
      - id: '#quality_bam_filter.output_tmp_fileterd_file'
    run: ./quality_bam_filter.cwl
    label: quality_bam_filter
    'sbg:x': -232.56344604492188
    'sbg:y': -199.23350524902344
  - id: '#id_filt_reads'
    inputs:
      - id: '#id_filt_reads.input_filt_reads'
        source: '#quality_bam_filter.output_tmp_fileterd_file'
    outputs:
      - id: '#id_filt_reads.output_id_filtered_reads'
    run: ./id_filt_reads.cwl
    label: id_filt_reads
    'sbg:x': -60.68020248413086
    'sbg:y': -199.53807067871094
  - id: '#id_filt_reads_unique'
    inputs:
      - id: '#id_filt_reads_unique.input_id_qfilt'
        source: '#id_filt_reads.output_id_filtered_reads'
    outputs:
      - id: '#id_filt_reads_unique.output_qfilt_reads_id'
    run: ./id_filt_reads_unique.cwl
    label: if_filt_reads_unique
    'sbg:x': 91.9289321899414
    'sbg:y': -196.3045654296875
  - id: '#host_filter'
    inputs:
      - id: '#host_filter.input_filter_script'
        source: '#input_filter_script'
      - id: '#host_filter.input_basecalled_reads'
        source: '#id_filt_reads_unique.output_qfilt_reads_id'
    outputs:
      - id: '#host_filter.output_host_filtered'
    run: ./host_filter.cwl
    label: host_filter
    'sbg:x': 211.97462463378906
    'sbg:y': -21.253807067871094
  - id: '#flye'
    inputs:
      - id: '#flye.input_basecalled_reads'
        source: '#host_filter.output_host_filtered'
    outputs:
      - id: '#flye.output_assembly'
    run: ./flye.cwl
    label: flye
    'sbg:x': 381.5482177734375
    'sbg:y': -22.406091690063477
  - id: '#medaka'
    inputs:
      - id: '#medaka.input_host_filtered_reads'
        source: '#host_filter.output_host_filtered'
      - id: '#medaka.input_assembly_fasta'
        source: '#flye.output_assembly'
    outputs:
      - id: '#medaka.output'
    run: ./medaka.cwl
    label: medaka
    'sbg:x': 331.51776123046875
    'sbg:y': 112.49238586425781
  - id: '#blastn_target_align'
    inputs:
      - id: '#blastn_target_align.input_symbiont_target_ref'
        source: '#input_symbiont_target_ref'
      - id: '#blastn_target_align.input_consensus_contigs'
        source: '#medaka.output'
    outputs:
      - id: '#blastn_target_align.output_blastn_alignment'
    run: ./blastn_target_align.cwl
    label: blastn_target_align
    'sbg:x': 327.4466857910156
    'sbg:y': 280.63958740234375
  - id: '#contig_selection'
    inputs:
      - id: '#contig_selection.input_contig_sel_script'
        source: '#input_contig_sel_script'
      - id: '#contig_selection.input_consensus_contigs'
        source: '#medaka.output'
      - id: '#contig_selection.input_blastn_aligned_file'
        source: '#blastn_target_align.output_blastn_alignment'
    outputs:
      - id: '#contig_selection.output_selected_contigs'
    run: ./contig_selection.cwl
    label: contig_selection
    'sbg:x': 327.7918701171875
    'sbg:y': 468.3147277832031
  - id: '#pilon'
    inputs:
      - id: '#pilon.input_sh_pilon_file'
        source: '#input_sh_pilon_file'
      - id: '#pilon.input_selected_contigs'
        source: '#contig_selection.output_selected_contigs'
      - id: '#pilon.input_r1_illumina_reads'
        source: '#input_r1_illumina_reads'
      - id: '#pilon.input_r2_illumina_reads'
        source: '#input_r2_illumina_reads'
    outputs:
      - id: '#pilon.outputs'
    run: ./pilon.cwl
    label: pilon
    'sbg:x': 325.0660095214844
    'sbg:y': 655.8729248046875
