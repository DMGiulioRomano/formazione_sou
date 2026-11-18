#!/usr/bin/env bash
set -e
declare -i totale=0
script="$0"

#if ! { [ -r "$1" ] && [ -f "$1" ]; }; then exit 1; fi

if ! [ -f "$1" ]; then echo "${script##*/}": file \""$1"\" non esiste o non è un regular file >&2; exit 1; 
elif ! [ -r "$1" ]; then echo "${script##*/}": file \""$1"\": permesso di lettura negato >&2; exit 1; fi

printf "%-12s %-20s %9s %7s\n" UTENTE HOME MB QUOTA

while IFS=';' read -r utente home mb quota || test "$utente"; do 
    if [ -z "$utente" ] || [[ "$utente" == \#* ]]; then continue; fi
    LC_NUMERIC=C printf "%-12.12s %-20s %9s %6.1f%%\n" "$utente" "$home" "$mb" "$quota"; 
    totale+=$mb;
done <"$1"    # oppure "$(grep -ve "^$" -ve "^#" "$1")"

printf "%-33s %9s\n" TOTALE $totale
