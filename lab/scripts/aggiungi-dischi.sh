#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"

mkdir -p "$DISCHI_DIR"

if VBoxManage showvminfo "$VM" --machinereadable | grep -q '^VMState="running"'; then
  echo "La VM '$VM' è accesa. Spegnila prima con: VBoxManage controlvm $VM acpipowerbutton" >&2
  exit 1
fi

for n in 2 3; do
  VDI="$DISCHI_DIR/disk${n}.vdi"
  [[ -f "$VDI" ]] || VBoxManage createmedium disk \
    --filename "$VDI" --size 2048 --format VDI --variant Standard

  VBoxManage storageattach "$VM" --storagectl SATA \
    --port "$((n))" --device 0 --type hdd --medium "$VDI"
done

echo "Dischi aggiunti. Avvia '$VM' e verifica con 'lsblk' dentro la VM."