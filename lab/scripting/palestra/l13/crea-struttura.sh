#!/usr/bin/env bash
set -e
if [[ ! ($# -eq 2 && $2 -ge 1 && $2 -le 99) ]]; then exit 2; fi

# --- con eval
#num=01..$2
#eval 'mkdir -p "$1"/{prod,staging}/web'"{$num}"'/{bin,conf,log}'
#------------

# --- con for, seq e printf
#for n in $(seq 1 $2); do
#	printf -v nn '%02d' "$n"
#	mkdir -p "$1"/{prod,staging}/web"$nn"/{bin,conf,log}
#done
#------------

# --- con for e seq
#for n in $(seq -f '%02g' 1 $2); do
#	mkdir -p "$1"/{prod,staging}/web"$n"/{bin,conf,log}
#done
#------------


# --- con for stile c e printf 
#for (( n=1; n <= $2; n+=1 )); do
# 	printf -v nn '%02d' "$n"
#	mkdir -p "$1"/{prod,staging}/web"$nn"/{bin,conf,log}
#done
#------------


# --- con while e printf 
#n=1
#while (( n <= $2 )) ; do
# 	printf -v nn '%02d' "$n"
#	mkdir -p "$1"/{prod,staging}/web"$nn"/{bin,conf,log}
#   (( ++n )) #oppure n=$(( n + 1 ))
#done
#------------


# --- con while  eprintf ma con il declare e il += senza necessità di arithmetic exapnsion 
declare -i n=1
while (( n <= $2 )) ; do
 	printf -v nn '%02d' "$n"
	mkdir -p "$1"/{prod,staging}/web"$nn"/{bin,conf,log}
    n+=1
done
#------------

# --- versione con xargs, ma molto pesante perché lancia un mkdir pari al numero di cose generate da seq, qunidi al numero div argomenti di xargs
#seq -f '%02g' 1 $2 | xargs -I X mkdir -p "$1"/{prod,staging}/webX/{bin,conf,log}
#------------



