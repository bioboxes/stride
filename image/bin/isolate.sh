#!/bin/bash

set -o errexit
set -o pipefail
set -o xtrace

SEQ_FILES=/usr/local/bbmap/resources

FILTERED_READS=$(mktemp -d)/reads.fq.gz
TMP_READS_1=$(mktemp -d)/reads.fq.gz
TMP_READS_2=$(mktemp -d)/reads.fq.gz
TMP_CONTIGS=$(mktemp -d)/contigs.fa
TMP_OUT=$(mktemp -d)

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

reformat.sh \
	interleaved=t \
	samplereadstarget=5000000 \
	pigz=t \
	unpigz=t \
	in1=${TMP_READS_2} \
	out1=${FILTERED_READS}

stride.sh ${FILTERED_READS} ${TMP_CONTIGS}

reformat.sh \
	in=${TMP_CONTIGS} \
	out=${OUTPUT} \
	minlength=1000
