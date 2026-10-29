# Contesto del progetto

> Questo file descrive il progetto, l'ambiente e le convenzioni. 

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
├── .gitignore
├── Makefile
├── README.md
├── docs
│   └── CONTEXT.md
├── lab
│   ├── .DS_Store
│   ├── partizioni
│   │   └── .gitkeep
│   └── scripts
│       ├── aggiungi-dischi.sh
│       ├── config.sh
│       ├── crea-lab.sh
│       ├── distruggi-lab.sh
│       ├── doctor.sh
│       └── lab.sh
├── report
│   ├── 1-week
│   │   ├── 20261016_resoconto.md
│   │   └── README.md
│   └── 2-week
│       └── 20261019_resoconto.md
└── studio                    # vault Obsidian, si parte da 00-home.md
    ├── .obsidian/              # config (graph.json: colori per area)
    ├── .style/                 # config pandoc/typst per i PDF
    ├── 00-home.md              # hub radice → mappe delle aree
    ├── glossario.md
    ├── 01-hardware-boot/       # ogni area: mappa-<area>.md + note atomiche
    ├── 02-init-servizi/
    ├── 03-storage/
    ├── 04-processi/
    ├── 05-shell/
    ├── 06-comandi/
    ├── 07-pacchetti-librerie/
    ├── 08-virtualizzazione-cloud/
    ├── 09-ai/
    ├── 10-storia/              # storia: software libero, virtualizzazione
    ├── lezioni/                # indici delle lezioni, linkano le note
    └── assets/                 # immagini

10 directories, 29 files


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
VMSTART="${VMSTART:-gui}"
```

Override via make VAR=valore o VAR=valore ./lab/scripts/lab.sh ...

### Comandi Rapidi

```bash
make                    # help
make doctor             # verifica prerequisiti
make lab-test           # test statici
make lab-crea           # crea la VM Debian
make lab-dischi         # crea e attacca 2 dischi da 2 GB
make lab-verifica       # verifica .vdi, stato VM, attach SATA
make lab-stato          # stato rapido
make lab-vms            # tutte le VM con stato
make lab-running        # solo VM accese
make lab-distruggi      # elimina la VM e i suoi file
make clean              # pulizia file temporanei
make report-lista       # elenca i resoconti
make report-oggi        # apre il resoconto più recente
make studio-lista       # elenca gli appunti (ricorsivo)
```

Note operative:
- I dischi .vdi stanno in $DISCHI_DIR (fuori da ~/VirtualBox VMs/), quindi unregistervm --delete non li elimina: vanno gestiti a parte.
- `aggiungi-dischi.sh` controlla se la porta SATA è già occupata e in quel caso salta l'attach.
- Il controller SATA della VM deve chiamarsi SATA (default VirtualBox).
- `make doctor` verifica `VBoxManage`, `shellcheck`, `make`, `bash`, ISO e directory scrivibili.
- Appunti (`studio/`): file e cartelle in kebab-case (le regole `%.pdf` del Makefile non
  gestiscono gli spazi); link Obsidian `[[slug|Titolo]]`, immagini in `assets/`.
  pandoc legge i wikilink grazie a `wikilinks_title_after_pipe` in `.style/config-typst.yaml`.
- `make lab-test` esegue controlli statici: `bash -n`, `shellcheck -x`, help del dispatcher,
  comando sconosciuto, `vms` e `running`.
- I dischi `.vdi` stanno in `$DISCHI_DIR`, fuori da `~/VirtualBox VMs/`.
  `unregistervm --delete` non li elimina, ma `distruggi-lab.sh` li rimuove esplicitamente con `rm -f`.

## Limiti noti / prossimi passi

- `doctor.sh` non controlla la versione di GNU Make; il Makefile usa `.SHELLFLAGS`.
- `aggiungi-dischi.sh` va testato due volte di fila per confermare l'idempotenza.
- `lab/partizioni/` contiene solo `.gitkeep`: il prossimo esercizio è partizionamento/filesystem.
- `report-lista` non gestisce bene directory vuote.
