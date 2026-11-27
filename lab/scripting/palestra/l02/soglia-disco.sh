#!/usr/bin/env bash

AVVISO=$1
CRITICO=$2
MOUNT_POINT=${3:-/}

[[ $AVVISO =~ ^[0-9]+$ ]] || { echo "soglia $AVVISO non numerica" >&2 && exit 3; }
[[ $CRITICO =~ ^[0-9]+$ ]] || { echo "soglia $CRITICO non numerica" >&2 && exit 3; }
[[ $AVVISO -lt $CRITICO ]] || { echo "soglia di avviso è maggioredi soglia critica $AVVISO >= $CRITICO" >&2 && exit 3; }


mount_line=$(tail -n +2 | grep " ${MOUNT_POINT}$") || { echo "$0: Mount inesistente" >&2 && exit 3; }
read filesys blocks used aval percentuale mount <<< "$mount_line" 

if [[ ${percentuale%\%} -lt $AVVISO ]]; then
    echo "OK $MOUNT_POINT $percentuale"
elif [[ ${percentuale%\%} -ge $CRITICO ]]; then
    echo "CRITICAL $MOUNT_POINT $percentuale" && exit 2
else echo "WARNING $MOUNT_POINT $percentuale" && exit 1
fi
