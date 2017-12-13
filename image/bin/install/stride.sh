#!/bin/bash

set -o errexit
set -o nounset
set -o xtrace

mkdir -p /usr/local/stride/bin

URL="https://github.com/ythuang0522/StriDe/raw/master/StriDe_Linux64bit_v1.0.tar.gz"
wget ${URL} --quiet --output-document - \
  | tar xzf - --directory /usr/local/stride/bin
ln -s /usr/local/stride/bin/* /usr/local/bin
