---
tags:
  - lezione
  - scripting
aliases:
  - Scripting — Il percorso
---
# Scripting — Il percorso

L'informatica si impara programmando: qui i comandi Linux si incontrano perché servono a risolvere un problema da sistemista. Ogni problema descrive una situazione e il comportamento atteso, non come ottenerlo. Il metodo per le sessioni con Claude è nella sezione «Modalità problema» di `CLAUDE.md`.

## La mappa

| # | Lezione | Il caso pratico | Stato |
|---|---|---|---|
| 01 | [[01-primo-script\|Il primo script]] | Una macchina sconosciuta da inquadrare | — |
| 02 | [[02-decisioni\|Decidere]] | Allarme disco, utenti, archivi | — |
| 03 | [[03-cicli-e-nomi\|Cicli e nomi di file]] | Ritentare, rinominare, fare pulizia | — |
| 04 | [[04-testo-come-dati\|Il testo come dati]] | Chi ci sta attaccando? | — |
| 05 | [[05-sed-awk\|sed e awk]] | Rapporti e configurazioni | — |
| 06 | [[06-robustezza\|Funzioni e robustezza]] | Il bug che cancella tutto | — |
| 07 | [[07-utenti-permessi\|Utenti e permessi]] | Nuovi assunti e audit | — |
| 08 | [[08-backup\|Backup e rotazione]] | Un backup mai ripristinato non esiste | — |
| 09 | [[09-processi-segnali\|Processi e segnali]] | Blocchi, scadenze, consumi | — |
| 10 | [[10-automazione\|Automazione]] | Funziona a mano ma non di notte | — |
| 11 | [[11-progetto-finale\|Progetto finale]] | La tua sentinella | — |
| 12 | [[12-processi-pipe-subshell\|Processi, pipe e subshell]] | Il totale che sparisce, il backup vuoto che risulta riuscito | — |

## Come funziona un problema

1. **Situazione:** cosa è successo e perché serve uno script.
2. **Compito:** cosa deve fare, con argomenti e codici di uscita precisi.
3. **Il tuo tentativo:** ragioni, scrivi, provi. La documentazione (`man`, `--help`, `apropos`) è parte del lavoro.
4. **Indizi:** sono domande, chiuse in riquadri da aprire uno alla volta, e nessuna contiene la soluzione.
5. **Verifica:** il correttore prova il comportamento dall'esterno.
6. **Dopo:** le domande finali ti fanno spiegare ciò che hai scritto.

## Preparare la macchina

Il kit va usato su Linux: su macOS molti comandi hanno opzioni diverse. Si lavora sulla VM `lab-rocky`, la stessa dei due libri, quindi prima si chiude il [[laboratorio-installazione-rocky|laboratorio Rocky]] fino al passo 8.

La ISO minimal non installa alcuni strumenti che servono qui. `ShellCheck` e `dash` arrivano da EPEL (*Extra Packages for Enterprise Linux*), il repository aggiuntivo curato da Fedora:

```sh
sudo dnf install -y epel-release
sudo dnf install -y git vim-enhanced man-db man-pages less tar gzip bc \
    ShellCheck jq strace lsof psmisc nmap-ncat cronie zsh dash bash-completion
```

Se `dash` non si trova, la lezione 22 lo segnala e prosegue con il solo ShellCheck. Si entra con l'utente creato al passo 6 del laboratorio, non come root: gli script si provano senza poteri speciali, così un errore fa meno danni. Rocky 9 ha bash 5.1: il kit è scritto per quella versione.

Prima di cominciare conviene una fotografia della VM, da lanciare sul Mac a VM spenta:

```sh
VBoxManage snapshot lab-rocky take prima-di-scripting
```

Il kit si scarica da GitHub, una volta che questo lavoro è su `main`:

```sh
git clone https://github.com/DMGiulioRomano/formazione_sou.git
cd formazione_sou/lab/scripting
./prepara.sh 01
```

Si lavora in `palestra/lNN/`, dove `dati/` si rigenera e i tuoi script restano:

```sh
cd palestra/l01
vim scheda.sh
../../verifica.sh 01 1     # lezione 01, problema 1
../../verifica.sh 01       # tutta la lezione
```

## Le fonti

| Fonte | Da dove viene | Cosa ho preso |
|---|---|---|
| *Learning Bash with Rocky* (ed. 2026/04/24) | Rocky Documentation Team, CC BY-SA 4.0 | La sequenza variabili, input, test, cicli e lo script di backup da far crescere |
| *Rocky Linux Admin Guide* (ed. 2026/04/24) | Rocky Documentation Team, CC BY-SA 4.0 | Comandi, utenti, `/etc/shadow`, permessi, backup, processi, cron |
| [Esercitazioni di SOL](https://didawiki.di.unipi.it/doku.php/informatica/sol/laboratorio/esercitazioni/start), 3 e 4 | Università di Pisa | Le idee di `gettingStarted`, `prettyPATH`, `printusr`, `dtar`, `modify`, `mycd`, `mykeyselect`, `makecmd`, riscritte e adattate |
| [Esercizi di ricapitolazione bash](https://twiki.di.uniroma1.it/pub/SOM/WebHome/Lezione12-Esercizi-bash-ricapitolazione.pdf) | A. Massini, Sapienza, A.A. 2024-25 | La personalizzazione di un modello con `sed` |
| [Bash Reference Manual](https://www.gnu.org/software/bash/manual/bash.html) | GNU | Pipeline, ambiente delle subshell, `PIPESTATUS`, `pipefail`, `lastpipe`, per la lezione 12 |
| [BashFAQ/024](https://mywiki.wooledge.org/BashFAQ/024) e [BashPitfalls](https://mywiki.wooledge.org/BashPitfalls) | Wooledge wiki | Le variabili perse nelle pipeline e le insidie del `cd`, per la lezione 12 |
| [Advanced Bash-Scripting Guide, cap. 21](https://sources.debian.org/data/main/a/abs-guide/10-2/HTML/subshells.html) | M. Cooper | La distinzione fra le subshell, per la lezione 12 |
| [Bash scripting guide, esercizi pratici](https://flowchart-learning-docs.pages.dev/bash-scripting-guide/12_interview/46_practical_exercises) | Sito di documentazione | Lo schema di sentinella, backup e analisi dei log |

I testi delle esercitazioni non sono copiati: i problemi sono riscritti come casi da sistemista e i dati sono generati da `prepara.sh`. Gli indirizzi IP dei log appartengono ai blocchi riservati alla documentazione, più `10.0.0.5` che è privato. Le parti derivate dalle guide Rocky restano sotto CC BY-SA 4.0.

## Quando leggi i due libri

I PDF restano utili come riferimento, con alcune avvertenze. Gli esempi qui sotto sono stati provati.

**Cosa manca.** *Learning Bash* non ha un capitolo su `if` e `case`, anche se il suo quiz finale li chiede, e non spiega `${variabile:=valore}`. Nessuno dei due libri spiega funzioni, `getopts` e `trap`, né insegna `sed` e `awk`. Le lezioni 02, 05, 06 e 09 esistono anche per questo.

**Cosa correggere.**

| Dove | Cosa dice | Come stanno le cose |
|---|---|---|
| *Learning Bash* 8.3 | `continue` torna «al primo comando dopo `done`» | Torna alla condizione del ciclo. Dopo `done` si arriva con `break` |
| *Learning Bash* 7.9 | `let` verifica se un carattere è numerico e non è coerente sullo 0 | `let` calcola un'espressione ed esce con 1 se il risultato è 0. `let AA` è 1 se `AA` non ha valore, 0 se `AA=5`: è coerente, ma non controlla i numeri |
| *Learning Bash* 7.1 | `[[ -s /etc/passwd ]]` stampa 1 | Refuso: il file non è vuoto, quindi il codice è 0 |
| *Learning Bash* 8.7 | Per leggere un file a righe usa `for` su `$(cat)` cambiando `IFS` | Salta le righe vuote ed espande i `*`. Vedi [[while-read\|while read]] |
| *Learning Bash* 8.7 | `for file in $(ls -d /tmp/*)` | Si spezza sui nomi con spazi. Il glob basta da solo |
| *Admin Guide* 4.6.2 | `find /tmp -name *.txt` | Senza virgolette la shell può espandere `*.txt` prima di `find`. Lo stesso libro, poco dopo, avverte di proteggere i metacaratteri |
| *Admin Guide* 5.2 | `find ... \| xargs tar cvfP` | Si rompe sui nomi con spazi. Se la lista è lunga, `xargs` lancia `tar` più volte e ogni `c` riscrive l'archivio |
| *Admin Guide* 7.3.6 | Giorni di `/etc/shadow`: `date +%s` / 86400 + 1 | Vale solo a est di Greenwich. Per il 2018-07-06 dà 17718 a Roma, ma 17719 in UTC e a New York. Si riprende nella lezione 07 |

**Rocky, i libri e il kit.** I libri parlano di Rocky, quindi comandi e percorsi coincidono con la VM. Qualche dettaglio da sapere:

| Cosa | Su Rocky 9 |
|---|---|
| Pacchetti | `dnf` scarica e installa, `rpm` interroga ciò che è installato. EPEL aggiunge ShellCheck e dash |
| Lavori periodici | `cronie` c'è già, e convive con i timer di systemd: la lezione 10 li usa entrambi |
| Log | `/var/log/secure` e `/var/log/messages` scritti da rsyslog, ma anche `journalctl` |
| Shell di chi non entra | `/sbin/nologin` |
| Bash | 5.1. La 5.2, che trovi su altre distribuzioni, cambia il significato di `&` nelle sostituzioni `${var/a/b}` |
| SELinux | Attivo in modalità *enforcing*: un servizio può fallire per un'etichetta sbagliata anche se i permessi Unix sono giusti. `ausearch -m avc` e `ls -Z` lo mostrano |

---

↑ [[00-home|Home]] · [[mappa-shell|Shell]] · [[mappa-comandi|Comandi]]
