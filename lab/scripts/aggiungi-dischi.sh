#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=SCRIPTDIR/config.sh
source "$SCRIPT_DIR/config.sh"

mkdir -p "$DISCHI_DIR"

if VBoxManage showvminfo "$VM" --machinereadable | grep -q '^VMState="running"'; then
  echo "La VM '$VM' è accesa. Spegnila prima con: VBoxManage controlvm $VM acpipowerbutton" >&2
  exit 1
fi

# Se la VM è stata creata con meno porte di quelle che servono ora
# (es. DISCHI_EXTRA_N aumentato), allarga il controller. Mai ridurlo:
# si staccherebbero dischi già attaccati.
info="$(VBoxManage showvminfo "$VM" --machinereadable)"
idx="$(printf '%s\n' "$info" \
       | sed -n "s/^storagecontrollername\([0-9]*\)=\"$CTL\"\$/\1/p")"
porte="$(printf '%s\n' "$info" \
         | sed -n "s/^storagecontrollerportcount${idx}=\"\([0-9]*\)\"\$/\1/p")"
if [[ -n "$porte" ]] && (( porte < PORTCOUNT )); then
  echo "  controller $CTL: porte da $porte a $PORTCOUNT"
  VBoxManage storagectl "$VM" --name "$CTL" --portcount "$PORTCOUNT"
fi

# Il numero del disco coincide con la porta: disk2 sulla porta 2, ...
for (( n = PRIMA_PORTA_EXTRA; n < PORTCOUNT; n++ )); do
  VDI="$DISCHI_DIR/${DISCO_PREFIX}${n}.vdi"
  [[ -f "$VDI" ]] || VBoxManage createmedium disk \
    --filename "$VDI" --size "$DISCHI_EXTRA_MB" --format VDI --variant Standard

  # se la porta è già occupata, salta
  if VBoxManage showvminfo "$VM" --machinereadable \
     | grep -q "^\"${CTL}-${n}-0\"="; then
    echo "  porta $CTL $n già occupata, salto"
  else
    VBoxManage storageattach "$VM" --storagectl "$CTL" \
      --port "$n" --device 0 --type hdd --medium "$VDI"
  fi
done

echo "Dischi aggiunti. Avvia '$VM' e verifica con 'lsblk' dentro la VM."
