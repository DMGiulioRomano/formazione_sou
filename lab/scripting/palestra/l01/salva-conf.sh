#!/usr/bin/env bash
set -e
new_filename="$(basename "$1").$(date +%Y%m%d)"
mkdir -p "$2"
cp "$1" "$2"/"$new_filename"

