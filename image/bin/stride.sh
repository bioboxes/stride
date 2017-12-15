#!/bin/bash

set -o errexit
set -o nounset
set -o xtrace

READS=$1
CONTIGS=$2

cd $(mktemp -d)

# Use the mode of the insert size estimation
# Mean cannot be used reliably because the observed distribution is not two-tailed.
ESTIMATED_INSERT_SIZE=$(bbmerge.sh in=${READS} merge=f 2>&1 \
	| grep Mode: \
	| tr -d " " \
	| tr -d "\t" \
	| cut -f 2 -d ':')

KMER=51
MIN_OVERLAP=20
MIN_KMER=2

# Stride requires decompressed reads
TMP_READS="$(mktemp -d)/reads.fq"
mkfifo $TMP_READS
zcat $READS > $TMP_READS &


stride preprocess --pe-mode 2 $TMP_READS --discard-quality --out reads.fa
stride index reads.fa --algorithm ropebwt2 --threads $(nproc)

# Create corrected reads
stride correct --algorithm overlap --kmer-size ${KMER} --kmer-threshold ${MIN_KMER} --outfile corrected.fa --threads $(nproc) reads.fa
rm reads.*
stride index --threads $(nproc) corrected.fa
stride fmwalk --min-overlap ${MIN_OVERLAP} --threads $(nproc) --kmer-size ${KMER} --prefix corrected corrected.fa

# Create merged reads
cat corrected.merge.fa corrected.kmerized.fa > merged.fa
rm corrected.*
stride index --threads $(nproc) merged.fa
stride filter --threads $(nproc) --no-kmer-check merged.fa

# Assemble merged and filtered reads
stride overlap --min-overlap ${MIN_OVERLAP} --threads $(nproc) merged.filter.pass.fa
stride assemble -k ${KMER} --kmer-threshold ${MIN_KMER} --prefix merged.filter.pass -r 150 -i ${ESTIMATED_INSERT_SIZE} merged.filter.pass.asqg.gz

mv StriDe-contigs.fa ${CONTIGS}
