#!/usr/local/bin/python3
# encoding: utf-8
"""
fasta_filter -- filter fasta file to keep only seq larger than min_size

@author:     Diego

@copyright:  2016 organization_name. All rights reserved.

@license:    license


@deffield    updated: Updated
"""

import argparse
import glob
import gzip
import sys
from Bio import SeqIO
from mimetypes import guess_type
from functools import partial


def get_opt():
    """Command line options."""
    try:
        # Setup argument parser
        parser = argparse.ArgumentParser(formatter_class=argparse.ArgumentDefaultsHelpFormatter)
        parser.add_argument('input', type=str, help='Input File ')
        parser.add_argument('output', type=str, help='Output File')
        parser.add_argument('--outfmt', default='fastq', choices=['fasta', 'fastq'],
                            help='Output format')
        parser.add_argument('--nocompressout', action='store_true',
                            help='Produce not gzip compressed output')
        parser.add_argument('--infmt', default='fastq', choices=['fasta', 'fastq'],
                            help='Input format')
        parser.add_argument('-r', '--reads-to-keep', help='File with the list of reads to keep. One id per row')
        parser.add_argument('-m', '--min-read-length', default=500, type=int, help='minimum read length')
        
        if len(sys.argv) == 1:
            parser.print_help()
            sys.exit(1)
        else:
            return parser.parse_args()
    
    except Exception as e:
        print('\nUnexpected error. Read the help\nErrorType:', e)
        # parser.print_help()
        return 2


def main():
    args = get_opt()
    read2keep = set()
    if args.reads_to_keep:
        for line in open(args.reads_to_keep):
            read2keep.add(line.strip().split()[0])
    if args.nocompressout:
        _openout = open
    else:
        _openout = gzip.open
    with _openout(args.output, 'wt') as fout:
        for fin in glob.glob(args.input):
            print(fin)
            encoding = guess_type(args.input)[1]  # uses file extension
            _open = partial(gzip.open, mode='rt') if encoding == 'gzip' else open
            with _open(fin) as ofin:
                if args.infmt == 'fasta':
                    _parser = SeqIO.FastaIO.SimpleFastaParser(ofin)
                elif args.infmt == 'fastq':
                    _parser = SeqIO.QualityIO.FastqGeneralIterator(ofin)
                for values in _parser:
                    if args.infmt == 'fasta':
                        (title,seq),qual = values, None
                    elif args.infmt == 'fastq':
                        (title,seq,qual) = values
                    #continue
                    if title.split()[0] in read2keep and len(seq) > args.min_read_length:
                        if args.outfmt == 'fasta':
                            # write a fastA
                            fout.write('\n'.join(['>' + title, seq])+'\n')
                        elif args.outfmt == 'fastq':
                            #  write a fastQ
                            #fout.write('@' + str(title) + '\n' + str(seq) + '\n+\n' + str(qual))
                            print(f'@{str(title)}\n{str(seq)}\n+\n{str(qual)}', file=fout)
                        else:
                            print('Unknow output format')
                            break

    
if __name__ == "__main__":
    main()
