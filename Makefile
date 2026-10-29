# Makefile (alla radice del progetto)

# ─────────────────────────────────────────────────────────────
# Appunti
# Con ':=' Make lancia il comando della shell una sola volta all'avvio, 
# salva il testo fisso dentro la variabile e poi usa sempre quella stringa istantanea.
# ─────────────────────────────────────────────────────────────

SHELL := /usr/bin/env bash
.SHELLFLAGS := -euo pipefail -c
.DEFAULT_GOAL := help

SCRIPTS := lab/scripts
VM ?= lab-test
ISO ?= $(HOME)/Downloads/debian-13.7.0-amd64-netinst.iso
VMDIR ?= $(HOME)/VirtualBox VMs
DISCHI_DIR ?= $(VMDIR)/lab-dischi
VMSTART ?= gui

ALL_MD := $(shell find ./studio -name "*.md" -not -path "./studio/.style*" -not -path "./studio/INBOX/*")
ALL_PDF:= $(ALL_MD:.md=.pdf)

export VM
export ISO
export VMDIR
export DISCHI_DIR
export VMSTART

.PHONY: help doctor \
        lab lab-crea lab-distruggi lab-dischi lab-stato lab-verifica \
        report report-lista report-oggi \
        studio studio-lista \
        clean pdf

# ─────────────────────────────────────────────────────────────
# Help (default)
# ─────────────────────────────────────────────────────────────
help:  ## Mostra questo aiuto
	@echo "Comandi disponibili:"
	@grep -E '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) \
	  | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-18s\033[0m %s\n", $$1, $$2}'
	@echo
	@echo "Sezioni: lab=VM e dischi, report=resoconti, studio=appunti"

# ─────────────────────────────────────────────────────────────
# Lab (VM + dischi) — tutto passa da lab.sh
# ─────────────────────────────────────────────────────────────
lab: lab-crea  ## Alias di lab-crea

lab-crea:  ## Crea la VM  del lab
	@$(SCRIPTS)/lab.sh crea

lab-distruggi:  ## Distrugge la VM  del lab
	@$(SCRIPTS)/lab.sh distruggi

lab-dischi:  ## Crea e attacca i dischi alla VM
	@$(SCRIPTS)/lab.sh dischi

lab-stato:  ## Stato rapido della VM
	@$(SCRIPTS)/lab.sh stato

lab-verifica:  ## Verifica file .vdi, attach e stato VM
	@$(SCRIPTS)/lab.sh verifica

lab-vms:      ## Tutte le VM registrate con stato
	@$(SCRIPTS)/lab.sh vms

lab-running:  ## Solo le VM accese
	@$(SCRIPTS)/lab.sh running

lab-test:  ## Controlli statici + comandi read-only (nessun effetto collaterale)
	@echo "== 1/6  Sintassi bash =="
	@bash -n $(SCRIPTS)/*.sh
	@echo "        OK"
	@echo
	@echo "== 2/6  ShellCheck =="
	@shellcheck -x $(SCRIPTS)/*.sh
	@echo "        OK"
	@echo
	@echo "== 3/6  Dispatcher: help =="
	@$(SCRIPTS)/lab.sh help > /dev/null
	@echo "        OK"
	@echo
	@echo "== 4/6  Dispatcher: comando sconosciuto deve fallire =="
	@if $(SCRIPTS)/lab.sh comando-inesistente > /dev/null 2>&1; then \
	  echo "        ERRORE: comando sconosciuto non ha fallito" >&2; \
	  exit 1; \
	else \
	  echo "        OK (fallisce come previsto)"; \
	fi
	@echo
	@echo "== 5/6  Dispatcher: vms =="
	@$(SCRIPTS)/lab.sh vms
	@echo
	@echo "== 6/6  Dispatcher: running =="
	@$(SCRIPTS)/lab.sh running
	@echo
	@echo "Tutti i test statici passati."

# ─────────────────────────────────────────────────────────────
# Report
# ─────────────────────────────────────────────────────────────
report: report-lista  ## Alias di report-lista

report-lista:  ## Elenca i resoconti per settimana
	@for d in report/*/; do \
	  echo "== $$d"; \
	  ls "$$d"*.md 2>/dev/null | sed 's/^/  /' || echo "  (nessuno)"; \
	done

report-oggi:  ## Apre il resoconto più recente (macOS: con open)
	@latest=$$(ls -t report/*/*.md 2>/dev/null | head -1); \
	  if [[ -z "$$latest" ]]; then echo "Nessun resoconto." >&2; exit 1; fi; \
	  echo "Apro $$latest"; \
	  open "$$latest"

# ─────────────────────────────────────────────────────────────
# Studio
# ─────────────────────────────────────────────────────────────
studio: studio-lista  ## Alias di studio-lista

studio-lista:  ## Elenca gli appunti
	@find studio -name "*.md" -not -path "studio/.*" -not -path "studio/INBOX/*" | sort | sed 's/^/  /'

all_pdf: $(ALL_PDF)


%.pdf: %.md 
	pandoc $< -d studio/.style/config-typst.yaml -o $@

# ─────────────────────────────────────────────────────────────
# Clean
# ─────────────────────────────────────────────────────────────
clean:  ## Rimuove i file temporanei
	@rm -f lab/scripts/*.tmp
	@echo "Pulito."

clean-pdf:
	@rm -f $(ALL_PDF)

doctor:  ## Verifica prerequisiti (tool, ISO, directory)
	@$(SCRIPTS)/doctor.sh
