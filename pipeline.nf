#!/usr/bin/env nextflow

params.ref = "/nfs1/caliag/phytoplasmas/GDDH13_1-1_formatted.fasta"
params.basecalled = "/nfs1/caliag/phytoplasmas/PM/some_PM.fastq"
params.host_filt_py = "/nfs1/caliag/scripts/fasta_filter_mod_mic.py"
params.phytoplasm_ref = "/nfs1/caliag/phytoplasmas/NC_011047.1_capm_AT.fasta"
params.name = "PM"

ref = file(params.ref)
basecalled = file(params.basecalled)
filt_py = file(params.host_filt_py)
phytoplasm_ref = file(params.phytoplasm_ref)

ref_ch = Channel.fromPath(params.ref)
basecalled_ch = Channel.fromPath(params.basecalled)
filt_py_ch = Channel.fromPath(params.host_filt_py)
phytoplasm_ref_ch = Channel.fromPath(params.phytoplasm_ref)

basecalled_ch.into { basecalled_minimap2_ch; basecalled_host_filt_ch; basecalled  }
ref_ch.into { ref_minimap2_ch; ref_quality_bam_filter_ch }

// CONTIG SELECTION VARIABLES
params.contig_sel_py = "/nfs1/caliag/scripts/blast_contig_selection.py"
c_sel_py_ch = Channel.fromPath(params.contig_sel_py)
//

// PILON VARIABLES
params.r1 = "some/path"
params.r2 = "some/path"
r1 = file(params.r1)
r1_ch = Channel.fromPath(params.r1)
r2 = file(params.r2)
r2_ch = Channel.fromPath(params.r2)
name = file(params.name)



process minimap2 {
	input:
	file ref from ref_minimap2_ch
	file basecalled from basecalled_minimap2_ch

	output:
	file "${params.name}_minimap2.bam" into bam_file_ch
	// -a output in SAM format
	// -x map-ont for Nanopore reads to be aligned against the reference
	// -Sb to pass from a SAM to a BAM file (useful and binary == less memory usage)
	"""
	minimap2 -ax map-ont $ref $basecalled | samtools sort -O BAM -o ${params.name}_minimap2.bam
	"""
}

process quality_bam_filter {
	input:
	file ref from ref_quality_bam_filter_ch
	file $name_minimap2 from bam_file_ch

	output:
	file "tmp_minimap2_qfilt_21" into tmp_ch

	// -Sq 21 take all reads with >= 21 quality
	// -U write to file those reads that do not correspond to q >= 21 (-> those reads that do not align or align worse to the host genome)
	// -T the reference filter
	// the filte from which to filt out
	"""
  samtools view -Sq 21 -U tmp_minimap2_qfilt_21 -T $ref ${$name_minimap2}
  """
}

process id_filt_reads {
	input:
	file $tmp_minimap2_qfilt_21 from tmp_ch

	output:
	file "${params.name}_minimap2_qfilt_21" into q_filtered_ch

	// -f 1 take only the first argument of entries == readID
	// and place it into a file to be passed to the next process with -r
	"""
	cut -f 1 tmp_minimap2_qfilt_21 > ${params.name}_minimap2_qfilt_21
	"""
}

process id_filt_reads_unique {
	input:
	file $name_minimap2_qfilt_21 from q_filtered_ch

	output:
	file "${params.name}_minimap2_qfilt_21_uniq" into q_filtered_uniq_ch

	// sort, sorts the ids in a lexical way
	// -u report only unique entries

	"""
	sort -u ${$name_minimap2_qfilt_21} > ${params.name}_minimap2_qfilt_21_uniq
	"""
}

// python script to filter out reads from host genome and write to a separate
// file all the others
process host_filter_out {
	input:
	file basecalled from basecalled_host_filt_ch
	file filt_py from filt_py_ch
	file $name_minimap2_qfilt_21_uniq from q_filtered_uniq_ch

	output:
	file "${params.name}_host_filtered.fastq.gz" into host_filt_ch

	// -r see prev. process
	"""
  python $filt_py $basecalled ${params.name}_host_filtered.fastq.gz -r ${$name_minimap2_qfilt_21_uniq}
  """
}

// create instances of the same channel to not create downstream calls problems
host_filt_ch.into { host_filt_flye; host_filt_medaka; host_filt_pomoxis }

process flye_assembly {
	input:
	file $name_host_filtered from host_filt_flye

	output:
	file "assembly.fasta" into flye_assem_ch
	file "assembly_info.txt" into flye_info_ch
	file "flye.log" into flye_log_ch

	// -i polishing iteration number
	// -meta metagenomes analysis
	// --threads threads to be used for the process !ATTENTION! has to be the same as cpus in config file
	"""
  flye --nano-raw ${$name_host_filtered} --out-dir ./ --meta -i 5 --genome-size 600K --threads 15
  """
}

process medaka_cons {
	input:
	file $name_host_filtered from host_filt_medaka
	file assembly from flye_assem_ch

	output:
	file "consensus.fasta" into medaka_cons_ch
	file "*.bam*" into medaka_realign_ch
	// -i host filtered raw reads
	// -d draft assembly from flye
	// -o output dir
	// -t threads to be used for the process !ATTENTION! has to be the same as cpus in config file
  """
  medaka_consensus -i ${$name_host_filtered} -d $assembly -o . -t 15
  """
}

// create instances of the same channel to not create downstream calls problems
medaka_cons_ch.into { medaka_cons_blast; medaka_cons_blast_filt; medaka_cons_pomoxis; medaka_cons_md; medaka_cons_contig_sel; medaka_cons_pilon }
phytoplasm_ref_ch.into { phy_ref_blastn_check; phy_ref_blastn_filt }
host_filt_pomoxis.into { pom_quality; pom_align_md }

process blastn_check {
	input:
	file phytoplasm_ref from phy_ref_blastn_check
	file consensus from medaka_cons_blast
	output:
	file "${params.name}_consensus_blast_AT.t" into blastn_ch

	"""
	blastn -subject $phytoplasm_ref -query $consensus -outfmt "6 std qlen slen" -out ${params.name}_consensus_blast_AT.t
	"""
}

process blastn_check_filt {
	input:
	file phytoplasm_ref from phy_ref_blastn_filt
	file consensus from medaka_cons_blast_filt

	output:
	file "${params.name}_consensus_blast_AT_qcov20_ide80.t" into blastn_filt_ch

	"""
	blastn -subject $phytoplasm_ref -query $consensus -outfmt "6 std qlen slen" -qcov_hsp_perc 20 -perc_identity 80 -out ${params.name}_consensus_blast_AT_qcov20_ide80.t
	"""
}

process contig_selection {
	input:
	file contig_sel_py from c_sel_py_ch
	file consensus from medaka_cons_contig_sel
	file $name_consensus_blast_AT from blastn_ch

	output:
	file "${params.name}_assembly.fasta" into contig_sel_ch

	"""
	python $contig_sel_py -c $consensus -t ${$name_consensus_blast_AT} -p ${params.name} -o ./
	"""
}

process pilon {
	input:
	file consensus from medaka_cons_pilon
	file $name_assembly from contig_sel_ch
	file r1 from r1_ch
	file r2 from r2_ch

	output:
	file "${params.name}*.*" into pilon_ch

	"""
	#!/bin/bash

	bwa index $consensus
	bwa mem -M -t 20 -a $consensus $r1 $r2 | samtools sort -@ 4 -T tmp -m 5G --reference $consensus -O BAM -o ${params.name}_sorted_round1.bam
	samtools index ${params.name}_sorted_round1.bam
	java -Xmx400G -jar /opt/miniconda3/share/pilon-1.23-0/pilon-1.23.jar --genome $consensus --frags ${params.name}_sorted_round1.bam --output ${params.name}_pilon_round1 --outdir . --changes --vcf

	for round in 2 3 4 5 ; do
	    prev=\$( expr \$round - 1)
	    bwa index ${params.name}_pilon_round\${prev}.fasta
	    bwa mem -M -t 20 -a ${params.name}_pilon_round\${prev}.fasta $r1 $r2 | samtools sort -@ 4 -T tmp -m 5G --reference ${params.name}_pilon_round\${prev}.fasta -O BAM -o ${params.name}_sorted_round\${round}.bam
	    samtools index ${params.name}_sorted_round\${round}.bam
	    java -Xmx400G -jar /opt/miniconda3/share/pilon-1.23-0/pilon-1.23.jar --genome ${params.name}_pilon_round\${prev}.fasta --frags ${params.name}_sorted_round\${round}.bam --output ${params.name}_pilon_round\${round} --outdir . --changes --vcf
		done
	"""
// 	"""
// 	#!/bin/bash
//
// 	bwa index ${$name_assembly}
// 	bwa mem -M -t 20 -a ${$name_assembly} $r1 $r2 | samtools sort -@ 4 -T tmp -m 5G --reference ${$name_assembly} -O BAM -o ${params.name}_sorted_round1.bam
// 	samtools index ${params.name}_sorted_round1.bam
// 	java -Xmx400G -jar /opt/miniconda3/share/pilon-1.23-0/pilon-1.23.jar --genome ${$name_assembly} --frags ${params.name}_sorted_round1.bam --output ${params.name}_pilon_round1 --outdir . --changes --vcf
//
// 	for round in 2 3 4 5 ; do
// 			prev=\$( expr \$round - 1)
// 			bwa index ${params.name}_pilon_round\${prev}.fasta
// 			bwa mem -M -t 20 -a ${params.name}_pilon_round\${prev}.fasta $r1 $r2 | samtools sort -@ 4 -T tmp -m 5G --reference ${params.name}_pilon_round\${prev}.fasta -O BAM -o ${params.name}_sorted_round\${round}.bam
// 			samtools index ${params.name}_sorted_round\${round}.bam
// 			java -Xmx400G -jar /opt/miniconda3/share/pilon-1.23-0/pilon-1.23.jar --genome ${params.name}_pilon_round\${prev}.fasta --frags ${params.name}_sorted_round\${round}.bam --output ${params.name}_pilon_round\${round} --outdir . --changes --vcf
// 		done
// 	"""
// }
// process bwa_round1 {
// 	input:
// 	file consensus from medaka_cons_bwa
// 	file r1 from r1_ch
// 	file r2 from r2_ch
//
// 	output:
// 	file "${params.name}_bwa_round1.sam" into bwa_round1_ch
//
// 	"""
// 	bwa index $consensus
// 	bwa mem -M -t 20 -a $consensus $r1 $r2 > ${params.name}_bwa_round1.sam
// 	"""
//
// }
//
// bwa_round1_ch.into { bwa_samtoolsr1_ch; bwa_rounds_ch }
//
// process samtools_round1 {
// 	input:
// 	file consensus from medaka_cons_samtools
// 	file $name_bwa_round1 from bwa_samtoolsr1_ch
//
//
// 	output:
// 	file "${params.name}_sorted_round1.bam" into samtools_round1_ch
// 	file "${params.name}_sorted_round1.bam.bai" into samtools_index_round1_ch
//
// 	"""
// 	samtools sort ${$name_bwa_round1} -@ 4 -T tmp -m 5G --reference $consensus -O BAM -o ${params.name}_sorted_round1.bam
// 	samtools index ${params.name}_sorted_round1.bam
// 	"""
// }
//
// samtools_round1_ch.into { samtools_pilonr1_ch; samtools_rounds_ch }
// samtools_index_round1_ch.into { samtools_idxr1_ch; samtools_idx_rounds_ch }
//
// process pilon_round1 {
// 	input:
// 	file consensus from medaka_cons_pilon
// 	file $name_sorted_round1 from samtools_pilonr1_ch
// 	file $name_sorted_round1 from samtools_idxr1_ch
//
// 	output:
// 	file "${params.name}_pilon_round1.*" into pilon_round1_ch
//
// 	"""
// 	java -Xmx400G -jar /usr/local/share/pilon-1.23-3/pilon-1.23.jar --genome $consensus --frags ${params.name}_sorted_round1.bam --output ${params.name}_pilon_round1 --outdir . --changes --vcf
// 	"""
// }


// QUALITY CHECK
// process pomoxis_qual {
// 	input:
// 	file $name_host_filtered from pom_quality
// 	file consensus from medaka_cons_pomoxis
//
// 	output:
// 	file "${params.name}_assm.bam" into pom_assess_assembly_ch
// 	file "${params.name}_assm.bam.bai" into pom_assess_assembly_index_ch
// 	file "${params.name}_assm_stats.txt" into pomo_assm_stats_ch
// 	file "${params.name}_assm_summ.txt" into pomo_assm_summ_ch
//
//
// 	// -r uses as <reference> the consensus sequence generated by medaka
// 	// -i uses as <fastq> the basecalled reads filtered out of host genome
// 	// -C  catalogue errors
// 	// -t threads to be used for the process !ATTENTION! has to be the same as cpus in config file
//   """
// 	assess_assembly -r $consensus -i ${$name_host_filtered} -t 15 -p '${params.name}_assm'
//   """
// 	//assess_assembly -C -r $consensus -i ${$name_host_filtered} -t 15 -p '${params.name}_assm'
//
// }
//
// process pom_mini_align_md {
// 	input:
// 	file $name_host_filtered from pom_align_md
// 	file consensus from medaka_cons_md
//
// 	output:
// 	file "${params.name}_assm_MD_tag.bam" into pom_mini_align_ch
// 	file "${params.name}_assm_MD_tag.bam.bai" into pom_mini_align_index_ch
//
// 	"""
// 	mini_align -r $consensus -i ${$name_host_filtered} -m -p ${params.name}_assm_MD_tag -t 15
// 	"""
// }
//
// process pom_homopoly {
//   input:
// 	file $name_assm_MD_tag from pom_mini_align_index_ch
// 	file $name_assm_MD_tag from pom_mini_align_ch
//
//   output:
// 	file "homopolymers/hp_*" into homopoly_ch
// 	// count homopolymers
// 	"""
// 	assess_homopolymers count ${$name_assm_MD_tag}
// 	"""
// }
