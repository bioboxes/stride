#!/bin/bash

set -o errexit
set -o nounset
set -o xtrace

function finish {
	rm -rf /tmp/tmp.*
}
trap finish EXIT


TASK=$1
CMD=$(fetch_task_from_taskfile.sh $TASKFILE $TASK)
export READS=$(biobox_args.sh 'select(has("fastq")) | .fastq | map(.value) | join(" ")')
export CONTIGS=/bbx/output/contigs.fa

# Specify memory usage for bbtools
MEM_IN_KB=$(grep MemTotal: /proc/meminfo | tr -s ' ' | cut -f 2 -d ' ')
USAGE_PERCENT=85
let HEAP_IN_KB=${MEM_IN_KB}*${USAGE_PERCENT}/100
export _JAVA_OPTIONS="-Xmx${HEAP_IN_KB}k -Xms${HEAP_IN_KB}k"

# Manually calculate number of cells for normalisation
BBNORM_CELLS_PER_KB=100
let BBNORM_CELLS=${MEM_IN_KB}*${BBNORM_CELLS_PER_KB}
export BBNORM_CELLS


eval ${CMD}

cat << EOF > ${OUTPUT}/biobox.yaml
version: 0.9.0
arguments:
  - fasta:
    - id: contigs_1
      value: contigs.fa
      type: contigs
EOF
