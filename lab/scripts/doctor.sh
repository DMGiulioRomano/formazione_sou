#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=SCRIPTDIR/config.sh
source "$SCRIPT_DIR/config.sh"

# Contatori (no exit-on-first-error: vogliamo il quadro completo)
errors=0
warnings=0

ok()   { printf '  \033[32m✓\033[0m %-14s %s\n' "$1" "$2"; }
warn() { printf '  \033[33m!\033[0m %-14s %s\n' "$1" "$2"; warnings=$(( warnings + 1 )); }
fail() { printf '  \033[31m✗\033[0m %-14s %s\n' "$1" "$2"; errors=$(( errors + 1 )); }

check_cmd() {
  local cmd="$1" hint="${2:-installalo}"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    fail "$cmd" "non trovato — $hint"
    return
  fi
  local bin out
  bin="$(command -v "$cmd")"
  out=$("$bin" --version 2>&1 | head -1 || true)
  ok "$cmd" "$out  ($bin)"
}

check_file() {
  local p="$1" label="$2"
  if [[ -f "$p" ]]; then ok "$label" "$p"
  else fail "$label" "file non trovato: $p"; fi
}

check_dir_writable() {
  local p="$1" label="$2"
  if [[ -e "$p" && ! -d "$p" ]]; then
    fail "$label" "$p esiste ma non è una directory"; return
  fi
  if [[ -d "$p" ]]; then
    if [[ -w "$p" ]]; then ok "$label" "$p"
    else fail "$label" "$p esiste ma non è scrivibile"; fi
    return
  fi
  # La directory non esiste: controlla che il primo antenato esistente sia scrivibile
  local q="$p"
  while [[ ! -e "$q" && "$q" != "/" ]]; do q="$(dirname "$q")"; done
  if [[ -w "$q" ]]; then
    warn "$label" "$p non esiste (verrà creato; antenato scrivibile: $q)"
  else
    fail "$label" "$p non esiste e l'antenato $q non è scrivibile"
  fi
}

echo "== Strumenti =="
check_cmd VBoxManage "brew install --cask virtualbox  (oppure https://virtualbox.org)"
check_cmd shellcheck "brew install shellcheck"
check_cmd make       "xcode-select --install  (oppure brew install make)"
check_cmd bash       "brew install bash"

# Bash < 4 è ancora installato di default su macOS: avvisa, non blocca
if command -v bash >/dev/null 2>&1; then
  bmajor="${BASH_VERSINFO[0]}"
  if (( bmajor < 4 )); then
    warn "bash" "versione $bmajor < 4 — alcune feature avanzate non disponibili"
  fi
fi

echo
echo "== File e path =="
check_file "$ISO" "ISO"

echo
echo "== Directory scrivibili =="
check_dir_writable "$VMDIR"      "VMDIR"
check_dir_writable "$DISCHI_DIR" "DISCHI_DIR"

echo
echo "== Riepilogo =="
printf '  errori: %d,  warning: %d\n' "$errors" "$warnings"
if (( errors > 0 )); then
  echo "  prerequisiti mancanti — correggi gli errori prima di procedere" >&2
  exit 1
fi
echo "  tutto pronto"
