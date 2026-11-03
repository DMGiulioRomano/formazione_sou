#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=SCRIPTDIR/config.sh
source "$SCRIPT_DIR/config.sh"

if VBoxManage list vms | grep -q "\"$VM\""; then
  read -r -p "Cancellare VM '$VM' e tutti i suoi dischi? [y/N] " ans
  [[ "$ans" == "y" || "$ans" == "Y" ]] || { echo "Annullato."; exit 0; }

  # spegni se accesa
  VBoxManage controlvm "$VM" poweroff 2>/dev/null || true
  sleep 1
  VBoxManage unregistervm "$VM" --delete
  echo "VM '$VM' eliminata."
else
  echo "VM '$VM' non registrata, salto."
fi

# dischi extra (non appartengono alla VM)
if compgen -G "$DISCHI_DIR/${DISCO_PREFIX}*.vdi" > /dev/null 2>&1; then
  rm -f "$DISCHI_DIR"/"${DISCO_PREFIX}"*.vdi
  echo "Rimossi dischi in $DISCHI_DIR."
fi
