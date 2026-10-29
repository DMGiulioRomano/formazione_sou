# shellcheck shell=bash
# Le variabili sono usate dagli script che fanno source di questo file
# shellcheck disable=SC2034
# # Configurazione del laboratorio VirtualBox
# Sorgente: viene caricato dagli altri script con `source`
# ─────────────────────────────────────────────────────────────
# Configurazione del lab
# Ogni variabile è sovrascrivibile da ambiente:
#   VM=foo make lab-crea
#   VM=foo ./lab/scripts/lab.sh crea
# ─────────────────────────────────────────────────────────────

VM="${VM:-lab-test}"
# Cartella delle ISO e ISO da usare. ISO può essere un nome di file
# (cercato in ISODIR) o un percorso, che si usa così com'è:
#   ISO=debian-12.iso make lab-crea          → $ISODIR/debian-12.iso
#   ISO=/Volumes/usb/debian.iso make lab-crea
ISODIR="${ISODIR:-$HOME/Downloads}"
ISO="${ISO:-debian-13.7.0-amd64-netinst.iso}"
[[ "$ISO" == */* ]] || ISO="$ISODIR/$ISO"
VMDIR="${VMDIR:-$HOME/VirtualBox VMs}"
DISCHI_DIR="${DISCHI_DIR:-$VMDIR/lab-dischi}"
# Tipo di avvio della VM: gui | headless | separate
VMSTART="${VMSTART:-gui}"

# ─────────────────────────────────────────────────────────────
# Hardware della VM
# ─────────────────────────────────────────────────────────────

# Tipo di sistema operativo (non OSTYPE: in bash è già definita e vale
# "darwin..."). Valori validi con `VBoxManage list ostypes`.
# Deve corrispondere all'architettura della ISO (amd64 → Debian_64,
# arm64 → Debian_arm64); doctor.sh lo verifica.
VM_OSTYPE="${VM_OSTYPE:-Debian_64}"
RAM_MB="${RAM_MB:-2048}"
CPUS="${CPUS:-2}"
VRAM_MB="${VRAM_MB:-32}"
# Scheda di rete 1: nat | bridged | hostonly | intnet | natnetwork | none
NIC1="${NIC1:-nat}"
# Controller grafico: vmsvga (Linux) | vboxsvga (Windows) | vboxvga
GFX="${GFX:-vmsvga}"
# Disco di sistema, in MB
DISK_MB="${DISK_MB:-20480}"

# ─────────────────────────────────────────────────────────────
# Dischi extra (aggiungi-dischi.sh)
# ─────────────────────────────────────────────────────────────

DISCHI_EXTRA_N="${DISCHI_EXTRA_N:-2}"
DISCHI_EXTRA_MB="${DISCHI_EXTRA_MB:-2048}"

# ─────────────────────────────────────────────────────────────
# Costanti interne, condivise fra gli script: non pensate per
# essere cambiate, ma definite qui una volta sola.
# ─────────────────────────────────────────────────────────────

# Nome del controller SATA della VM
CTL="SATA"
# Prefisso dei file .vdi: disco di sistema "<VM>-disk1.vdi",
# dischi extra "disk2.vdi", "disk3.vdi", ...
DISCO_PREFIX="disk"
# Layout delle porte SATA: 0 = disco di sistema, 1 = DVD (ISO),
# dalla 2 in poi i dischi extra
PORTA_SISTEMA=0
PORTA_DVD=1
PRIMA_PORTA_EXTRA=2
PORTCOUNT=$(( PRIMA_PORTA_EXTRA + DISCHI_EXTRA_N ))

# Assert: le variabili necessarie devono esistere (e non essere vuote)
: "${VM:?VM non definita in config.sh}"
: "${ISO:?ISO non definita in config.sh}"
: "${VMDIR:?VMDIR non definita in config.sh}"
: "${DISCHI_DIR:?DISCHI_DIR non definita in config.sh}"
: "${VM_OSTYPE:?VM_OSTYPE non definita in config.sh}"
