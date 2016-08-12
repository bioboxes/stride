#!/bin/bash

set -o errexit
set -o nounset
set -o xtrace

BUILD="wget ca-certificates"

# Build dependencies
apt-get update --yes
apt-get install --yes --no-install-recommends ${BUILD}

# Install tool
URL="https://github.com/ythuang0522/StriDe/raw/master/StriDe_Linux64bit_v1.0.tar.gz"
wget ${URL} --quiet --output-document - \
  | tar xzf - --directory /usr/local/bin

# Clean up dependencies
apt-get autoremove --purge --yes ${BUILD}
apt-get clean
rm -rf /var/lib/apt/lists/*
