---
tags:
  - shell
  - nota
aliases:
  - Eseguire uno script
---
# Eseguire uno script

Cosa succede fra il momento in cui scrivo `./scheda.sh` e quello in cui lo script parte: chi legge cosa, e quali permessi servono.

## Lo shebang `#!`

**Il nome.** *Shebang* unisce *sharp* o *hash*, cioè `#`, e *bang*, cioè `!`. L'ha introdotto Dennis Ritchie ai Bell Labs nel 1980.

**Chi lo legge: il kernel, non la shell.**

1. La shell crea un processo figlio e chiede al kernel di eseguire il file con la chiamata di sistema `execve`.
2. Il kernel guarda i primi byte. `\x7fELF` indica un programma compilato. `#!` indica uno script: il kernel lancia l'interprete scritto sulla riga e gli passa lo script come argomento.
3. `./scheda.sh` diventa così `/usr/bin/env bash ./scheda.sh`. Per bash quella prima riga è solo un commento.

Se lo shebang manca, `execve` fallisce con `ENOEXEC` (*exec format error*). Bash allora esegue il file da solo, come script di shell, ma un altro programma non lo farebbe.

```sh
head -c 2 scheda.sh | od -c   # i due byte che guarda il kernel
man 2 execve                  # sezione «Interpreter scripts»
```

## `#!/usr/bin/env bash` o `#!/bin/bash`

`env` (da *environment*, ambiente) lancia un programma cercandolo nel `PATH`. Il kernel invece non cerca niente e vuole un percorso assoluto. `bash` però non sta dappertutto nello stesso posto: su Linux è in `/bin/bash`, su FreeBSD in `/usr/local/bin`, su macOS c'è la 3.2 in `/bin/bash` e quella di Homebrew altrove. `env` invece si trova quasi sempre in `/usr/bin/env`.

| | Pro | Contro |
|---|---|---|
| `/usr/bin/env bash` | Portabile: usa il primo `bash` del `PATH` | Dipende dal `PATH` di chi lancia (con `sudo` e `cron` cambia); su Linux passa all'interprete un solo argomento |
| `/bin/bash` | Prevedibile | Si rompe dove `bash` sta altrove |

## `bash scheda.sh` contro `./scheda.sh`

In tutti e due i casi nasce un **nuovo processo bash**, figlio della mia shell. Non è una subshell in senso stretto: la subshell è una copia della shell creata con `fork`, come `( ... )` o `$(...)`.

| | Chi esegue il kernel | Lo shebang | Permesso che serve su `scheda.sh` |
|---|---|---|---|
| `bash scheda.sh` | `bash`, che poi **legge** lo script come testo | Ignorato (è un commento) | `r` |
| `./scheda.sh` | Il file stesso | Sceglie l'interprete | `x` (più `r`, perché l'interprete deve leggerlo) |

Con le mie parole: con `bash` lancio un comando che ho già il permesso di eseguire, e quel processo, che ha i miei permessi, si limita a leggere `scheda.sh`.

Prova:

```sh
chmod u-x scheda.sh
./scheda.sh        # Permission denied
bash scheda.sh     # funziona
chmod u+x scheda.sh
```

`chmod u+x` dà il permesso di esecuzione (`x`) solo al proprietario del file (`u`, *user*).

## Perché serve `./`

Se il nome di un comando **non contiene `/`**, la shell lo cerca nell'ordine alias, funzioni, builtin e poi nelle cartelle del [[path|PATH]]. Se **contiene `/`**, la shell usa il percorso così com'è: vanno bene `./scheda.sh`, `l01/scheda.sh` e qualsiasi percorso assoluto.

La cartella corrente `.` non sta nel `PATH` per sicurezza. Se ci fosse, un eseguibile chiamato `ls` lasciato in `/tmp` verrebbe lanciato con i miei permessi appena entro in quella cartella e scrivo `ls`. MS-DOS invece cercava prima nella cartella corrente.

---

Da: [[01-primo-script|Scripting 01]], problema 1 · ↑ [[mappa-shell|Shell]]
