#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"

read -r -p "Cancellare VM '$VM' e tutti i suoi dischi? [y/N] " ans
[[ "$ans" == "y" || "$ans" == "Y" ]] || { echo "Annullato."; exit 0; }

if VBoxManage list vms | grep -q "\"$VM\""; then
  # spegni se accesa
  VBoxManage controlvm "$VM" poweroff 2>/dev/null || true
  sleep 1
  VBoxManage unregistervm "$VM" --delete
fi

# dischi extra (non appartengono alla VM)
if [[ -d "$DISCHI_DIR" ]]; then
  rm -f "$DISCHI_DIR"/disk*.vdi
fi

echo "Pulito."