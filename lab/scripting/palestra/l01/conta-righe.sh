#!/usr/bin/env bash
# Conta le righe del file passato come primo argomento.
file="$1"
righe=$(wc -l < "$file")
echo "$file: $righe righe"
