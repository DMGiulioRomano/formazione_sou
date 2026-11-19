#!/usr/bin/env bash

nex=$0

[[ $# == 1 ]] || \
        { echo "$nex: numero di argomenti != 1">&2; exit 1; } \
    && ! [[ -z $1 ]] || \
        { echo "$nex: stringa vuota">&2; exit 1; } \
    && ! [[ $1 == *[!0-9]* ]] || \
        { echo "$nex: stringa non valida, ricontrollare che sia un numero">&2; exit 1; } \
    && [[ $(( 10#$1 )) -gt 0 ]] || \
        { echo "$nex: numero minore o uguale a 0">&2; exit 1; } 

for i in $(seq 1 $1); do
    if ((i % 2)); then echo "$i: dispari"; else echo "$i: pari"; fi
done
