#!/usr/bin/env bash
file = $1
righe=wc -l < $file
echo '$file: $righe righe'
