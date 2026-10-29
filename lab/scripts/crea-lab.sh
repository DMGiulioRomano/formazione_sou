#!/usr/bin/env bash
set -euo pipefail

# trova la cartella dello script, così funziona da qualsiasi CWD
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=SCRIPTDIR/config.sh
source "$SCRIPT_DIR/config.sh"

if [[ ! -f "$ISO" ]]; then
  echo "ISO non trovata: $ISO" >&2
  echo "Aggiorna ISO/ISODIR in lab/scripts/config.sh (o da ambiente) o scarica il file." >&2
  exit 1
fi

if VBoxManage list vms | grep -q "\"$VM\""; then
  echo "Esiste già una VM '$VM'. Usa distruggi-lab.sh o cambia nome in lab/scripts/config.sh." >&2
  exit 1
fi

VBoxManage createvm --name "$VM" --ostype "$VM_OSTYPE" --register
VBoxManage modifyvm "$VM" --memory "$RAM_MB" --cpus "$CPUS" --vram "$VRAM_MB" \
  --nic1 "$NIC1" --audio-driver none --usb off --graphicscontroller "$GFX"

VDI="$VMDIR/$VM/$VM-${DISCO_PREFIX}1.vdi"
mkdir -p "$VMDIR/$VM"
VBoxManage createmedium disk \
  --filename "$VDI" --size "$DISK_MB" --format VDI --variant Standard

VBoxManage storagectl "$VM" --name "$CTL" --add sata --controller IntelAhci \
  --portcount "$PORTCOUNT"
VBoxManage storageattach "$VM" --storagectl "$CTL" --port "$PORTA_SISTEMA" --device 0 \
  --type hdd --medium "$VDI"
VBoxManage storageattach "$VM" --storagectl "$CTL" --port "$PORTA_DVD" --device 0 \
  --type dvddrive --medium "$ISO"

VBoxManage startvm "$VM" --type "$VMSTART"
