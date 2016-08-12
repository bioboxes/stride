#!/bin/bash

set -o errexit
set -o nounset
set -o xtrace

TASK=$1
CMD=$(fetch_task_from_taskfile.sh $TASKFILE $TASK)
READS=$(biobox_args.sh 'select(has("fastq")) | .fastq | map(.value) | join(" ")')


# Stride requires decompressed reads
TMP_READS="$(mktemp -d)/reads.fq"
mkfifo $TMP_READS
zcat $READS > $TMP_READS &

KMER=51

cd /tmp
stride preprocess --pe-mode 2 $TMP_READS --discard-quality --out reads.fa
stride index reads.fa --algorithm ropebwt2 --threads $(nproc)

# Create corrected reads
stride correct --algorithm overlap --kmer-size ${KMER} --kmer-threshold 3 --outfile corrected.fa --threads $(nproc) reads.fa
rm reads.*
stride index --threads $(nproc) corrected.fa
stride fmwalk --min-overlap 50 --threads $(nproc) --kmer-size ${KMER} --prefix corrected corrected.fa

# Create merged reads
cat corrected.merge.fa corrected.kmerized.fa > merged.fa
rm corrected.*
stride index --threads $(nproc) merged.fa
stride filter --threads $(nproc) --no-kmer-check merged.fa

# Assemble merged and filtered reads
stride overlap --min-overlap 50 --threads $(nproc) merged.filter.pass.fa
stride assemble -k ${KMER} --kmer-threshold 3 --prefix merged.filter.pass -r 150 -i 275 merged.filter.pass.asqg.gz

mv StriDe-contigs.fa ${OUTPUT}/contigs.fa

cat << EOF > ${OUTPUT}/biobox.yaml
version: 0.9.0
arguments:
  - fasta:
    - id: contigs_1
      value: contigs.fa
      type: contigs
EOF
