#!/usr/bin/env bash
set -euo pipefail

# trova la cartella dello script, così funziona da qualsiasi CWD
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=SCRIPTDIR/config.sh
source "$SCRIPT_DIR/config.sh"

if [[ ! -f "$ISO" ]]; then
  echo "ISO non trovata: $ISO" >&2
  echo "Aggiorna ISO in lab/config.sh o scarica il file." >&2
  exit 1
fi

if VBoxManage list vms | grep -q "\"$VM\""; then
  echo "Esiste già una VM '$VM'. Usa distruggi-lab.sh o cambia nome in config.sh." >&2
  exit 1
fi

VBoxManage createvm --name "$VM" --ostype Debian_64 --register
VBoxManage modifyvm "$VM" --memory 2048 --cpus 2 --vram 32 \
  --nic1 nat --audio-driver none --usb off --graphicscontroller vmsvga

VDI="$VMDIR/$VM/$VM-disk1.vdi"
mkdir -p "$VMDIR/$VM"
VBoxManage createmedium disk \
  --filename "$VDI" --size 12288 --format VDI --variant Standard

VBoxManage storagectl "$VM" --name SATA --add sata --controller IntelAhci --portcount 4
VBoxManage storageattach "$VM" --storagectl SATA --port 0 --device 0 \
  --type hdd --medium "$VDI"
VBoxManage storageattach "$VM" --storagectl SATA --port 1 --device 0 \
  --type dvddrive --medium "$ISO"

VBoxManage startvm "$VM" --type "$VMSTART"
