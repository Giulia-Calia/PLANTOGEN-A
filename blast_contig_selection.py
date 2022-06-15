#!/usr/local/bin/python3
# encoding: utf-8

"""
@author:     Giulia

@copyright:  2021 organization_name. All rights reserved.

@license:    license


@deffield    updated: Updated
"""

from Bio import SeqIO
from textwrap import wrap
import pandas as pd
import numpy as np
import argparse


def fasta_formatter(fasta_seq):
    split_60 = wrap(str(fasta_seq), 60)  # wrap separate a single string into a list of strings with len = step
    concat_str = ""
    formatted_seq = [s + "\n" for s in split_60]  # add a \n at the end of each subseq to satisfy fasta format requirem.

    return concat_str.join(formatted_seq)


def contig_sel_from_blast(df):
    sel_ide = df[df[2] >= 90]
    sel_align = sel_ide[sel_ide[3]*100/sel_ide[12] >= 10]
    sel_size = sel_align[sel_align[12]*100/sel_align[13] >= 5]
    contig_numbers = [x[x.find("_") + 1:] for x in np.unique(sel_size[0])]

    return contig_numbers


if __name__ == '__main__':
    parser = argparse.ArgumentParser(usage="%(prog)s [options]",
                                     description="",
                                     epilog="")
    parser.add_argument("-c", "--consensus",
                        help="medaka consensus.fasta")
    parser.add_argument("-t", "--blastn_tab",
                        help="tabular blastn file obtained by aligning raw reads to the consensus.fasta")
    parser.add_argument("-p", "--prefix",
                        default="selection",
                        type=str,
                        help="indicate the output file prefix, default is 'selection'")
    parser.add_argument("-o", "--output_dir",
                        help="output directory PATH where to save the assembly")
    # parser.add_argument("-i", "--contig_ids",
    #                     nargs="+",
    #                     type=str,
    #                     default=[],
    #                     help="a sequence of number corresponding to the ids of selected contigs")
    # parser.add_argument("-sh", "--sh_usage", action="store_true", help="if the script is executed into an sh file")

    args = parser.parse_args()

    c = 1
    f = pd.read_csv(args.blastn_tab, sep="\t", header=None)
    with open(args.prefix + "_genomic.fasta", "w") as assembly:
        consensus = SeqIO.parse(args.consensus, "fasta")
        for record in consensus:
            list_contig_ids = contig_sel_from_blast(f)
            if not list_contig_ids:
                print("NO CONTIG CAN BE SELECTED")
            else:
                for i in list_contig_ids:
                    if "scaffold" in i and i in record.id:
                        seq = fasta_formatter(record.seq)
                        if c < 10:
                            seq_id = f"{args.prefix}_scaffold0{c} length = {len(record.seq)} original_flye_name = {record.id}"
                        else:
                            seq_id = f"{args.prefix}_scaffold{c} length = {len(record.seq)} original_flye_name = {record.id}"
                        # assembly.writelines('\n'.join(['>' + seq_id, seq]))
                        print('\n'.join(['>' + seq_id, seq]), file=assembly)
                        c += 1
                    elif i == record.id[record.id.find("_") + 1:]:
                        seq = fasta_formatter(record.seq)
                        if c < 10:
                            seq_id = f"{args.prefix}_contig0{c} length = {len(record.seq)} original_flye_name = {record.id}"
                        else:
                            seq_id = f"{args.prefix}_contig{c} length = {len(record.seq)} original_flye_name = {record.id}"
                        # assembly.writelines('\n'.join(['>' + seq_id, seq]))
                        print('\n'.join(['>' + seq_id, seq]), file=assembly)
                        c += 1
                        # each entry of the fasta file is given by
                        # >contig_n
                        # sequence
