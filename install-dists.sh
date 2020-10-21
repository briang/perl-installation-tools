#!/bin/bash

PERLBREW="$HOME/perlbrew";
USAGE="./inster.sh <file-with-list-of-modules> <list-of-perlbrew-perl-installations>"

function __f () {
    local modules="$1";
    local perls="";
    shift

    if [[ ! -f "$modules" || -z "$@" ]] ; then
        echo "$USAGE" >&2
        return
    fi

    for perl in "$@" ; do
        perl=$(basename $perl)
        if [[ ! -d "$PERLBREW/perls/$perl" ]] ; then
            echo "unknown perl: [$perl]" >&2
            return
        fi
        perls="$perls $perl"
    done

    for perl in $perls ; do # leave unquoted
        echo "[$perl]"
        perlbrew use "$perl" && cpanm < "$modules"
    done
}
__f "$@"
