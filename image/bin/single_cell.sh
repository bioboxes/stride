#!/bin/bash

set -o errexit
set -o pipefail
set -o xtrace

SEQ_FILES=/usr/local/bbmap/resources

TMP_READS_1=$(mktemp -d)/reads.fq.gz
TMP_READS_2=$(mktemp -d)/reads.fq.gz
TMP_OUT=$(mktemp -d)
TMP_CONTIGS=$(mktemp -d)/contigs.fa

INPUT=$1
OUTPUT=$2

clumpify.sh \
	interleaved=t \
	pigz=t \
	unpigz=t \
	zl=4 \
	passes=1 \
	reorder \
	in1=${INPUT} \
	out1=${TMP_READS_1}

bbduk.sh \
	interleaved=t \
	ktrim=r \
	ordered \
	minlen=51 \
	minlenfraction=0.33 \
	mink=11 \
	tbo \
	tpe \
	rcomp=f \
	overwrite=true \
	k=23 \
	hdist=1 \
	hdist2=1 \
	ftm=5 \
	zl=4 \
	ow=true \
	rqc=hashmap \
	loglog \
	ref=${SEQ_FILES}/adapters.fa \
	in1=${TMP_READS_1} \
	out1=stdout.fq \
| bbduk.sh \
	interleaved=t \
	ordered \
	overwrite=true \
	k=20 \
	hdist=1 \
	pigz=t \
	zl=6 \
	ow=true \
	ref=${SEQ_FILES}/short.fa \
	in1=stdin.fq \
	out1=${TMP_READS_2}

# normalize filtered fastq
bbnorm.sh \
	cells=${BBNORM_CELLS} \
	bits=32 \
	min=2 \
	target=100 \
	pigz \
	unpigz \
	ow=t \
	in=${TMP_READS_2} \
	out=${TMP_READS_1}


# subsample to 20m unpaired reads
reformat.sh \
	samplereadstarget=10000000 \
	ow=t \
	in=${TMP_READS_1} \
	out=${TMP_READS_2}

stride.sh ${TMP_READS_2} ${TMP_CONTIGS}

# trim contigs & scaffolds - remove 200 bp at the start and end of each contig
# drop contig if less than 2000 bp
bbmap.sh \
	nodisk \
	ambig=all \
	maxindel=100 \
	minhits=2 \
	in=${TMP_READS_2} \
	ref=${TMP_CONTIGS} \
	covstats=${TMP_OUT}/coverage_stats.txt

filterbycoverage.sh \
	mincov=2 \
	minr=6 \
	minp=95 \
	minl=2000 \
	trim=200 \
	in=${TMP_CONTIGS} \
	out=${OUTPUT} \
	cov=${TMP_OUT}/coverage_stats.txt

rm -rf ${TMP_OUT} ${TMP_READS_1} ${TMP_READS_2} ${TMP_CONTIGS}
