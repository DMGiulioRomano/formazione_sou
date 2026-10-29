#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=SCRIPTDIR/config.sh
source "$SCRIPT_DIR/config.sh"

# ─────────────────────────────────────────────────────────────
# Stato rapido della VM del lab (una riga)
# ─────────────────────────────────────────────────────────────

cmd_stato() {
  local state
  if state="$(VBoxManage showvminfo "$VM" --machinereadable 2>/dev/null \
              | grep '^VMState=')"; then
    printf '%s\n' "$state"
  else
    echo "VM '$VM' non registrata"
  fi
}

# ─────────────────────────────────────────────────────────────
# Verifica completa: file .vdi, stato VM, attach al controller
# ─────────────────────────────────────────────────────────────
cmd_verifica() {
  echo "== File .vdi =="
  if compgen -G "$DISCHI_DIR/${DISCO_PREFIX}*.vdi" > /dev/null; then
    ls -lh "$DISCHI_DIR"/"${DISCO_PREFIX}"*.vdi
  else
    echo "  (nessuno in $DISCHI_DIR)"
  fi

  echo
  echo "== Stato VM =="
  if VBoxManage showvminfo "$VM" --machinereadable 2>/dev/null \
       | grep -q '^VMState='; then
    VBoxManage showvminfo "$VM" --machinereadable | grep '^VMState='
  else
    echo "  VM '$VM' non registrata"
  fi

  echo
  echo "== Attach $CTL =="
  if VBoxManage showvminfo "$VM" 2>/dev/null \
       | grep -qE "^$CTL \\([0-9]+, [0-9]+\\):"; then
    VBoxManage showvminfo "$VM" \
      | grep -E "^$CTL \\([0-9]+, [0-9]+\\):"
  else
    echo "  (nessun disco attaccato)"
  fi
}
# ─────────────────────────────────────────────────────────────
# Elenco di tutte le VM registrate, con il loro stato
# ─────────────────────────────────────────────────────────────
cmd_vms() {
  local v state
  printf "%-28s %s\n" "NOME" "STATO"
  printf "%-28s %s\n" "────────────────────────────" "─────"

  # Se non ci sono VM, evita che il while non entri e sembri "bloccato"
  local vms
  vms="$(VBoxManage list vms)"
  if [[ -z "$vms" ]]; then
    echo "(nessuna VM registrata)"
    return 0
  fi

  while IFS= read -r v; do
    state="$(VBoxManage showvminfo "$v" --machinereadable \
             | grep '^VMState=' | cut -d'"' -f2)"
    printf "%-28s %s\n" "$v" "$state"
  done < <(printf '%s\n' "$vms" | cut -d'"' -f2)
}

# ─────────────────────────────────────────────────────────────
# Solo le VM accese in questo momento
# ─────────────────────────────────────────────────────────────
cmd_running() {
  local running
  running="$(VBoxManage list runningvms | cut -d'"' -f2)"

  if [[ -z "$running" ]]; then
    echo "(nessuna VM accesa)"
  else
    printf '%s\n' "$running"
  fi
}

# ─────────────────────────────────────────────────────────────
# Usage
# ─────────────────────────────────────────────────────────────
usage() {
  cat <<EOF
Uso: $(basename "$0") <comando>

Comandi:
  crea       Crea la VM del lab       (crea-lab.sh)
  distruggi  Distrugge la VM del lab  (distruggi-lab.sh)
  dischi     Crea e attacca i dischi alla VM (aggiungi-dischi.sh)
  stato      Stato rapido della VM (una riga)
  verifica   Verifica completa: file .vdi, stato VM, attach SATA
  vms        Elenca tutte le VM registrate con il loro stato
  running    Elenca solo le VM accese
EOF
}

# ─────────────────────────────────────────────────────────────
# Dispatch
# ─────────────────────────────────────────────────────────────
case "${1:-}" in
  crea)      exec "$SCRIPT_DIR/crea-lab.sh" ;;
  distruggi) exec "$SCRIPT_DIR/distruggi-lab.sh" ;;
  dischi)    exec "$SCRIPT_DIR/aggiungi-dischi.sh" ;;
  stato)     cmd_stato ;;
  verifica)  cmd_verifica ;;
  vms)       cmd_vms ;;
  running)   cmd_running ;;
  ""|help|-h|--help) usage ;;
  *)
    echo "Comando sconosciuto: $1" >&2
    usage >&2
    exit 1
    ;;
esac
