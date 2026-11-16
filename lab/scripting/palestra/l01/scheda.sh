#!/usr/bin/env bash

echo "host: $(hostname)"
echo "kernel: $(uname -r)"
echo "utente: $(whoami)"
echo "core: $(lscpu | grep "^CPU(s)" | tr -s " " | cut -d " " -f2)"
echo "ram_mib: $(free -m | grep "^Mem" | tr -s " " | cut -d " " -f2)"
echo "disco_root_libero: $(df -h / | tail -1 | tr -s " " | cut -d " " -f4)"
