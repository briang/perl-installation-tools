#!/bin/bash
# Template from http://kvz.io/blog/2013/11/21/bash-best-practices/

set -o errexit  # exit on error
set -o pipefail # trap pipe fails
set -o nounset  # trap unset vars
# set -o xtrace

__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
__file="${__dir}/$(basename "${BASH_SOURCE[0]}")"
__base="$(basename ${__file} .sh)"
# __root="$(cd "$(dirname "${__dir}")" && pwd)"
# ^^^ change this as it depends on the script ^^^

arg1="${1:-}"
################################################################################
rm -rf $PERLBREW_ROOT/build/*
rm     $PERLBREW_ROOT/build.*.log
