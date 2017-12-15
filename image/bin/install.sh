#!/bin/bash

set -o errexit
set -o nounset
set -o xtrace

NON_ESSENTIAL_BUILD="ca-certificates wget"
BBTOOLS="openjdk-7-jre-headless pigz"


# Build dependencies
apt-get update --yes
apt-get install --yes --no-install-recommends ${NON_ESSENTIAL_BUILD} ${BBTOOLS}

export PATH=/usr/local/bin/install:$PATH

stride.sh
bbtools.sh

# Clean up dependencies
apt-get autoremove --purge --yes ${NON_ESSENTIAL_BUILD}
apt-get install --yes --no-install-recommends ${BBTOOLS}
apt-get clean
rm -rf /var/lib/apt/lists/*
