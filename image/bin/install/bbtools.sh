#!/bin/bash

set -o errexit
set -o nounset
set -o xtrace

URL="http://downloads.sourceforge.net/project/bbmap/BBMap_${BBTOOLS_VERSION}.tar.gz"
fetch_archive.sh ${URL} bbmap
ln -s /usr/local/bbmap/*.sh /usr/local/bin

# Create set of sequencing artefacts shorted than 25bp
reformat.sh \
	in=/usr/local/bbmap/resources/sequencing_artifacts.fa.gz \
	out=/usr/local/bbmap/resources/short.fa \
	maxlen=24
