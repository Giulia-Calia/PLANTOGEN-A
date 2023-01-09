#!/usr/bin/env nextflow

// GENERAL WORKFLOW PARAMETERS
host_ref = file(params.host_ref)
host_ref_ch = Channel.fromPath(params.host_ref)
host_ref_ch.into { host_ref_minimap2_ch; host_ref_quality_bam_filter_ch }
basecalled = file(params.basecalled)
basecalled_ch = Channel.fromPath(params.basecalled)
basecalled_ch.into { basecalled_qcheck_ch; basecalled_stats_ch; basecalled_minimap2_ch; basecalled_host_filt_ch; basecalled }
symbiont_target_ref = file(params.symbiont_target_ref)
symbiont_target_ref_ch = Channel.fromPath(params.symbiont_target_ref)
r1 = file(params.r1)
r1_ch = Channel.fromPath(params.r1)
r1_ch.into { ill1_qcheck_ch; ill1_stats_ch; pilon_corr1_ch }
r2 = file(params.r2)
r2_ch = Channel.fromPath(params.r2)
r2_ch.into { ill2_qcheck_ch; ill2_stats_ch; pilon_corr2_ch }
//
// SCRIPTS
stats_py = file(params.stats_py)
stats_py_ch = Channel.fromPath(stats_py)
stats_py_ch.into { raw_basecalled_stats_py_ch; illumina_stats_py_ch; host_filt_stats_py_ch }
host_filt_py = file(params.host_filt_py)
filt_py_ch = Channel.fromPath(params.host_filt_py)
contig_sel_py = file(params.contig_sel_py)
c_sel_py_ch = Channel.fromPath(params.contig_sel_py)
rename_sel_py = file(params.rename_sel_py)
r_sel_py_ch = Channel.fromPath(params.rename_sel_py)
assembly_stats_py = file(params.fasta_stats_py)
assembly_stats_py_ch	= Channel.fromPath(params.fasta_stats_py)
//

process basecalled_qcheck {
	input:
	file basecalled from basecalled_qcheck_ch

	output:
	file "*_fastqc*" into basecalled_fastqc_ch
	"""
	fastqc --outdir . --dir . -t 6 $basecalled
	"""
}

process illumina_qcheck {
	input:
	file r1 from ill1_qcheck_ch
	file r2 from ill2_qcheck_ch

	output:
	file "*_fastqc*" into ill_fastqc_ch

	"""
	fastqc --outdir . --dir . -t 6 $r1 $r2
	"""
}

process basecalled_stats {
	input:
	file basecalled from basecalled_stats_ch
	file stats_py from raw_basecalled_stats_py_ch

	output:
	file "${params.name}_basecalled_stats.txt" into basec_stats_ch
	"""
	python $stats_py -i $basecalled > ${params.name}_basecalled_stats.txt
	"""
}

process illumina_stats {
	input:
	file r1 from ill1_stats_ch
	file r2 from ill2_stats_ch
	file stats_py from illumina_stats_py_ch
	output:
	file "${params.name}_ill_1_stats.txt" into ill1_computed_stats_ch
	file "${params.name}_ill_2_stats.txt" into ill2_computed_stats_ch

	"""
	python $stats_py -i $r1 > ${params.name}_ill_1_stats.txt
	python $stats_py -i $r2 > ${params.name}_ill_2_stats.txt
	"""
}

process minimap2 {
	input:
	file host_ref from host_ref_minimap2_ch
	file basecalled from basecalled_minimap2_ch

	output:
	file "${params.name}_minimap2.bam" into bam_file_ch
	// -a output in SAM format
	// -x map-ont for Nanopore reads to be aligned against the host_reference
	// -Sb to pass from a SAM to a BAM file (useful and binary == less memory usage)
	"""
	minimap2 -ax map-ont $host_ref $basecalled | samtools sort -O BAM -o ${params.name}_minimap2.bam
	"""
}

process quality_bam_filter {
	input:
	file host_ref from host_ref_quality_bam_filter_ch
	file $name_minimap2 from bam_file_ch

	output:
	file "tmp_minimap2_qfilt_21" into tmp_ch

	// -Sq 21 take all reads with >= 21 quality
	// -U write to file those reads that do not correspond to q >= 21 (-> those reads that do not align or align worse to the host genome)
	// -T the host_reference filter
	// the filte from which to filt out
	"""
  samtools view -Sq 21 -U tmp_minimap2_qfilt_21 -T $host_ref ${$name_minimap2}
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
// check statistics on filtering

// create instances of the same channel to not create downstream calls problems
host_filt_ch.into { host_filt_stats_ch; host_filt_flye; host_filt_medaka; host_filt_pomoxis }

process host_filtered_stats {
	input:
	file $name_host_filtered from host_filt_stats_ch
	file $stats_py from host_filt_stats_py_ch

	output:
	file "${params.name}_host_filtered_stats.txt" into hostfilt_stats_ch

	"""
	python $stats_py -i ${$name_host_filtered} > ${params.name}_host_filtered_stats.txt
	"""
}

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
symbiont_target_ref_ch.into { symb_ref_blastn_check; symb_ref_blastn_filt }
host_filt_pomoxis.into { pom_quality; pom_align_md }

process blastn_check {
	input:
	file symbiont_targetref from symb_ref_blastn_check
	file consensus from medaka_cons_blast
	output:
	file "${params.name}_consensus_blast_AT.t" into blastn_ch

	"""
	blastn -subject $symbiont_target_ref -query $consensus -outfmt "6 std qlen slen" -out ${params.name}_consensus_blast_AT.t
	"""
}

process blastn_check_filt {
	input:
	file symbiont_target_ref from symb_ref_blastn_filt
	file consensus from medaka_cons_blast_filt

	output:
	file "${params.name}_consensus_blast_AT_qcov20_ide80.t" into blastn_filt_ch

	"""
	blastn -subject $symbiont_target_ref -query $consensus -outfmt "6 std qlen slen" -qcov_hsp_perc 20 -perc_identity 80 -out ${params.name}_consensus_blast_AT_qcov20_ide80.t
	"""
}

process blast_contig_selection {
	input:
	file contig_sel_py from c_sel_py_ch
	file consensus from medaka_cons_contig_sel
	file $name_consensus_blast_AT from blastn_ch

	output:
	file "${params.name}_flye_medaka_genomic.fasta" into contig_sel_ch

	"""
	python $contig_sel_py -c $consensus -t ${$name_consensus_blast_AT} -p ${params.name} -o .
	"""
}

contig_sel_ch.into { for_pilon_exec_ch; for_pilon_c_rename_ch }
process pilon {
	input:
	file consensus from medaka_cons_pilon
	file $name_flye_medaka_genomic from for_pilon_exec_ch
	file r1 from pilon_corr1_ch
	file r2 from pilon_corr2_ch

	output:
	file "${params.name}*.*" into pilon_ch
	file "${params.name}_pilon_round5.fasta" into pilon_for_rename_ch

	"""
	#!/bin/bash

	bwa index ${$name_flye_medaka_genomic}
	bwa mem -M -t 20 -a ${$name_flye_medaka_genomic} $r1 $r2 | samtools sort -@ 4 -T tmp -m 5G --reference ${$name_flye_medaka_genomic} -O BAM -o ${params.name}_sorted_round1.bam
	samtools index ${params.name}_sorted_round1.bam
	java -Xmx400G -jar /opt/miniconda3/share/pilon-1.23-0/pilon-1.23.jar --genome ${$name_flye_medaka_genomic} --frags ${params.name}_sorted_round1.bam --output ${params.name}_pilon_round1 --outdir . --changes --vcf

	for round in 2 3 4 5 ; do
	    prev=\$( expr \$round - 1)
	    bwa index ${params.name}_pilon_round\${prev}.fasta
	    bwa mem -M -t 20 -a ${params.name}_pilon_round\${prev}.fasta $r1 $r2 | samtools sort -@ 4 -T tmp -m 5G --reference ${params.name}_pilon_round\${prev}.fasta -O BAM -o ${params.name}_sorted_round\${round}.bam
	    samtools index ${params.name}_sorted_round\${round}.bam
	    java -Xmx400G -jar /opt/miniconda3/share/pilon-1.23-0/pilon-1.23.jar --genome ${params.name}_pilon_round\${prev}.fasta --frags ${params.name}_sorted_round\${round}.bam --output ${params.name}_pilon_round\${round} --outdir . --changes --vcf
		done
	"""
}

process rename_pilon_contigs {
	input:
	file $name_pilon_round5 from pilon_for_rename_ch
	file $name_flye_medaka_genomic from for_pilon_c_rename_ch
	file rename_sel_py from r_sel_py_ch

	output:
	file "${params.name}_genomic.fasta" into renamed_pilon_ch
	"""
	python $rename_sel_py -fmf ${$name_flye_medaka_genomic} -pf ${$name_pilon_round5} -op ./${params.name}
	"""

}

process assembly_stats {
	input:
	file $name_genomic from renamed_pilon_ch
	file assembly_stats_py from assembly_stats_py_ch

	output:
	file "${params.name}_assembly_stats.txt" into asby_stats_ch
	"""
	python $assembly_stats_py -i ${$name_genomic} > ${params.name}_assembly_stats.txt
	"""
}
