#!/usr/bin/env bash

name=$1
file=${2:-/etc/passwd}

if [ -z "$name" ]; then
    echo "$0: argomento nome utente non presente" >&2
    exit 2
elif [ ! -f "$file" ]; then
    echo "$0: file" \'"$file"\' "non esistente o non è regular file" >&2
    exit 2
elif [ ! -r "$file" ]; then
    echo "$0: file" \'"$file"\' "illeggibile" >&2
    exit 2
fi

cut -d ":" -f 1 "$file" | grep -Fwxq "$name" >/dev/null || { echo "$0: L'utente" \'"$name"\' "non esiste" >&2 && exit 1; }



