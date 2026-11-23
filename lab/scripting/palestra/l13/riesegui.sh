#!/usr/bin/env bash

[ "$#" -le 0 ] && { echo "$0 : Inserisci almeno un argomento" >&2;  exit 2; }
REGISTRO=${REGISTRO:=~/.riesegui.log}
time_date=$(date +%FT%H:%M:%S)
"$@"; status=$?

printf -v com '%q ' "$@"
printf '%s %s %s\n' "$time_date" $status "${com% }">> "$REGISTRO"
exit $status
