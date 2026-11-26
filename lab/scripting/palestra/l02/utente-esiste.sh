#!/usr/bin/env bash

name=$1
file=$2
file=${file:-/etc/passwd}

# debug
#echo "questo è name: $name"
#echo "questo è file: $file"

{   
    [ -z "$name" ] && \
    {
        echo "$0: argomento nome utente non presente" 1>&2
        exit 2
    } && [ ! -e "$file" ] && \
    {
        echo "$0: file" "$file" "non esiste" 1>&2
        exit 2
    } || [ ! -f "$file" ] && \
    {
        echo "$0: file" "$file" "not a regular file" 1>&2 
        exit 2
    }
}

cut -d ":" -f 1 $file | while read nUser; do 
    [ "$nUser" == "$name" ] && break; 
done

[ $? == 0 ] || { echo "$0: L'utente" \'"$name"\' "non esiste" 1>&2 && exit 1; }
