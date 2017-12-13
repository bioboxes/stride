#!/bin/bash

set -o errexit
set -o nounset
set -o xtrace

BUILD="wget ca-certificates"

# Build dependencies
apt-get update --yes
apt-get install --yes --no-install-recommends ${BUILD}

export PATH=/usr/local/bin/install:$PATH

stride.sh

# Clean up dependencies
apt-get autoremove --purge --yes ${BUILD}
apt-get clean
rm -rf /var/lib/apt/lists/*
