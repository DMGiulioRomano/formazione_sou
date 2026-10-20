# Contesto del progetto

> Questo file descrive il progetto, l'ambiente e le convenzioni. Viene
> preposto automaticamente ai documenti generati (resoconti, appunti)
> dallo script `lab/scripts/context.sh`, così ogni file è autosufficiente.

## Cos'è questo repo

Repository personale per organizzare esercizi di **Sistemi Operativi**
con particolare attenzione a:

- **Virtual machine** (VirtualBox, gestite da CLI con `VBoxManage`)
- **Partizioni** e **volumi** (fdisk, parted, LVM)
- **Filesystem** (ext4, mount, fstab, journaling)
- **Processi, systemd, shell** (appunti teorici e pratica)

Il repo è sia un **laboratorio di studio** sia una **documentazione**
progressiva del percorso.

## Struttura
.
├── Makefile
├── README.md
├── docs
│   └── CONTEXT.md
├── lab
│   ├── partizioni
│   └── scripts
│       ├── aggiungi-dischi.sh
│       ├── config.sh
│       ├── crea-lab.sh
│       ├── distruggi-lab.sh
│       └── lab.sh
├── report
│   ├── 1-week
│   │   ├── 20261016_resoconto.md
│   │   └── README.md
│   └── 2-week
│       └── 20261019_resoconto.md
└── studio
    ├── Glossario.md
    ├── README.md
    ├── cartella-proc.md
    ├── dispositivi_hardware.md
    ├── filesystem.md
    ├── journal_ctl.md
    ├── partizioni.md
    ├── prima_di_systemd.md
    └── shell-variabili.md

9 directories, 20 files


## Ambiente

- **Host:** macOS (MacBook Pro), utente `giuliodemattia`
- **Hypervisor:** VirtualBox (uso da CLI)
- **Shell:** zsh (host) / bash (script)
- **Task runner:** Make
- **Distro target del lab:** Debian (ISO netinst)
- **Alternativa valutata:** Rocky Linux Minimal (per test su base RHEL)

## Convenzioni

### Script bash

- `#!/usr/bin/env bash` + `set -euo pipefail` in cima
- `SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"`
- `source "$SCRIPT_DIR/config.sh"` + assert `: "${VAR:?...}"`
- Path sempre tra virgolette (`"$VMDIR"`) — possono contenere spazi
- `$HOME` mai `~` dentro `${...:-...}`
- `exec` per delegare ad altri script (propaga exit code e Ctrl+C)

### Makefile

- Un target = uno script. **Niente logica nel Makefile**
- `@$(SCRIPTS)/lab.sh <comando>` per ogni target lab
- `?=` + `export` per le variabili sovrascrivibili

### `config.sh`

```bash
VM="${VM:-lab-test}"
ISO="${ISO:-$HOME/Downloads/debian-13.7.0-amd64-netinst.iso}"
VMDIR="${VMDIR:-$HOME/VirtualBox VMs}"
DISCHI_DIR="${DISCHI_DIR:-$VMDIR/lab-dischi}"
```

Override via make VAR=valore o VAR=valore ./lab/scripts/lab.sh ...

### Comandi Rapidi

```bash
make                    # help
make lab-crea           # crea la VM Debian
make lab-dischi         # crea e attacca 2 dischi da 2 GB
make lab-verifica       # verifica .vdi, stato VM, attach SATA
make lab-stato          # stato rapido (una riga)
make lab-vms            # tutte le VM con stato
make lab-running        # solo VM accese
make lab-distruggi      # elimina la VM (e i suoi file)
```

Note operative:
- I dischi .vdi stanno in $DISCHI_DIR (fuori da ~/VirtualBox VMs/), quindi unregistervm --delete non li elimina: vanno gestiti a parte.
- aggiungi-dischi.sh non è ancora idempotente su storageattach, (2ª esecuzione fallisce: porta occupata).
- Il controller SATA della VM deve chiamarsi SATA (default VirtualBox).
