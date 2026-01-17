#!/bin/bash

set -o errexit  # exit on error
set -o pipefail # trap pipe fails
set -o nounset  # trap unset vars

function __f {
    local F P
    F=$(realpath "$1")
    P=${F/*\//} # remove path
    P=${P/perl-5./dev-} # replace "perl..." prefix with "dev-"
    P=${P/.tar.*/} # remove suffix
    cmd="perlbrew install $F --as $P --thread --ld -j 4 &"

    echo 'The command I would of run, if I were so inclined...'
    echo "    $cmd"
    # $cmd

    echo -ne "\nProceed? ";
    read ans;
    [[ $ans == 'y' ]] && $cmd
}

if [[ $# == 0 ]]; then
    echo "usage: $0 <name of perl tarball>"
    exit 1
fi

__f "$1"

unset -f __f
