#!/usr/bin/env sh
set -e

hugo version

if [[ "$3" == "-no_aliases" ]]
then
    HUGO_DISABLEALIASES=true
    export HUGO_DISABLEALIASES
fi

if [[ "$2" == "-no_minify" ]]
then
    hugo --baseURL "$1"
else
    hugo --minify --baseURL "$1"
fi
