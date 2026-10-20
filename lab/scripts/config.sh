# shellcheck shell=bash
# # Configurazione del laboratorio VirtualBox
# Sorgente: viene caricato dagli altri script con `source`
# ─────────────────────────────────────────────────────────────
# Configurazione del lab
# Ogni variabile è sovrascrivibile da ambiente:
#   VM=foo make lab-crea
#   VM=foo ./lab/scripts/lab.sh crea
# ─────────────────────────────────────────────────────────────

VM="${VM:-lab-test}"
ISO="${ISO:-$HOME/Downloads/debian-13.7.0-amd64-netinst.iso}"
VMDIR="${VMDIR:-$HOME/VirtualBox VMs}"
DISCHI_DIR="${DISCHI_DIR:-$VMDIR/lab-dischi}"
# Tipo di avvio della VM: gui | headless | separate
VMSTART="${VMSTART:-gui}"
