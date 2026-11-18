#!/usr/bin/env bash

declare -i totale=0

printf "%-12s %-20s %9s %7s\n" UTENTE HOME MB QUOTA

flt=$(grep -ve "^$" -ve "^#" dati/spazio.txt)

while IFS=';' read utente home mb quota; do 
    LC_NUMERIC=C printf "%-12.12s %-20s %9s %6.1f%%\n" "$utente" "$home" "$mb" "$quota"; 
    totale+=$mb; 
#done <<< $flt
done <<< $(grep -ve "^$" -ve "^#" dati/spazio.txt)


printf "%-33s %9s\n" TOTALE $totale
