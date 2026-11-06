# formazione_sou

Repository personale di studio autonomo durante lo stage: sistemi operativi Linux, macchine virtuali, partizioni e volumi, filesystem, processi, shell e scripting.

## Le cartelle

| Cartella | Contenuto | Destinatario |
|---|---|---|
| `report/` | resoconto di ogni settimana; `2026-WSS.md` è il modello | tutor |
| `esercizi/` | esercizi dei tutor: consegna, implementazione, resoconto | tutor |
| `studio/` | vault Obsidian con appunti e lezioni, si parte da `00-home.md` | io |
| `lab/vm/` | script per creare e gestire le VM, con i profili per distribuzione | io |
| `lab/scripting/` | kit delle lezioni di scripting: `prepara.sh`, `verifica.sh` | io |

`CLAUDE.md` contiene le regole per le sessioni con Claude Code, `TODO.md` le cose da fare.

## Esercizi dei tutor

- Ogni consegna ha una cartella sotto `esercizi/`: per una serie di esercizi, `esercizi/<serie>/<numeri>/` (es. `esercizi/track-extra/1-4/`); per un esercizio singolo, `esercizi/AAAA-MM-GG-nome/`, con la data di assegnazione.
- Il testo sta sempre nel `README.md` della cartella, così GitHub lo mostra aprendola. Parte da `esercizi/TEMPLATE.md`; se la cartella raccoglie più esercizi, ognuno ha la sua sezione con consegna, implementazione e resoconto.
- Accanto al `README.md` stanno i file dell'implementazione (script, configurazioni), collegati dal testo con un link relativo.
- Il report della settimana rimanda all'esercizio con un link relativo.
- I concetti riusabili vanno nelle note di `studio/`.

## Ambiente

- **Host:** macOS, con zsh; gli script sono in bash.
- **Hypervisor:** VirtualBox, usato da riga di comando con `VBoxManage`.
- **Task runner:** Make. `make help` elenca i comandi, `make doctor` verifica i prerequisiti.
- **Distribuzione del lab:** Debian (ISO netinst) per impostazione predefinita, Arch con `make lab-crea PROFILO=arch`.

## Convenzioni

### Script bash

- `#!/usr/bin/env bash` e `set -euo pipefail` in cima.
- `SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"`, poi `source "$SCRIPT_DIR/config.sh"`.
- Percorsi sempre tra virgolette (`"$VMDIR"`): possono contenere spazi.
- `$HOME`, mai `~`, dentro `${...:-...}`.
- `exec` per delegare ad altri script: propaga il codice di uscita e Ctrl+C.

### Makefile

- Un target corrisponde a uno script, senza logica nel Makefile: ogni target lab chiama `$(SCRIPTS)/lab.sh <comando>`.
- `?=` ed `export` per le variabili sovrascrivibili, con `make VAR=valore`.
- `make lab-test` esegue i controlli statici: `bash -n`, `shellcheck -x` e i comandi di sola lettura del dispatcher.

### Appunti

- File e cartelle in kebab-case: le regole `%.pdf` del Makefile non gestiscono gli spazi.
- Link Obsidian `[[slug|Titolo]]`, immagini in `assets/`.
- pandoc legge i wikilink grazie a `wikilinks_title_after_pipe` in `.style/config-typst.yaml`.

### Dischi delle VM

- I file `.vdi` stanno in `$DISCHI_DIR`, fuori dalle cartelle delle VM: `unregistervm --delete` non li elimina, `distruggi-lab.sh` li rimuove con `rm -f`.
- `aggiungi-dischi.sh` salta l'attach se la porta SATA è già occupata.
- Il controller SATA della VM deve chiamarsi `SATA`, il nome predefinito di VirtualBox.
