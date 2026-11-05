---
tags:
  - lezione
  - scripting
aliases:
  - Scripting 12 — Processi, pipe e subshell
---
# Scripting 12 — Processi, pipe e subshell

Tutto parte da una riga vera: `... | grep 'Forwarding' | read p | echo "$p $vm"` stampava il nome della VM ma non la regola. Qui impari a dire, guardando una riga di shell, quanti processi nascono, chi vede quali variabili e chi decide il codice di uscita. Riferimenti: [[pipe|Come funziona una pipe]], [[while-read|Leggere righe con while read]], [[file-descriptor|File descriptor]].

Serve saper scrivere `if`, `while` e funzioni: si può affrontare dopo la lezione 03, anche se i problemi 4 e 7 sono più facili dopo la 06.

```sh
./prepara.sh 12 && cd palestra/l12
```

`dati/bin/` contiene programmi finti (`VBoxManage`, `remoto`, `dump`). Per provarli a mano:

```sh
export PATH="$PWD/dati/bin:$PATH"
```

## La mappa

| # | Problema | Stato |
|---|---|---|
| 0 | Previsioni — carta e penna, poi la prova | — |
| 1 | `chi-gira.sh` — chi è quale processo | — |
| 2 | `riepilogo-vm.sh` — il totale che sparisce | — |
| 3 | `su-tutte.sh` — il ciclo che si ferma alla prima macchina | — |
| 4 | `esporta-db.sh` — il backup vuoto che risulta riuscito | — |
| 5 | `prime.sh` — quando un errore non è un errore | — |
| 6 | `confronta.sh` — due flussi, nessun file temporaneo | — |
| 7 | `ogni-cartella.sh` — spostarsi senza spostarsi | — |

---

## Problema 0 — Previsioni

**Situazione.** Prima di scrivere, serve un modello mentale. Il modello è giusto solo se prevede.

**Compito.** Per ogni riga, in `bash`, scrivi **prima** cosa stampa e perché. Solo dopo lanciala. Dove sbagli, il modello va corretto prima di proseguire.

```sh
x=1; ( x=2 ); echo "$x"
x=1; { x=2; }; echo "$x"
x=1; echo ciao | x=2; echo "$x"
echo ciao | read p; echo "[$p]"
echo ciao | read p | echo "[$p]"
echo ciao | { read p; echo "[$p]"; }
( cd /tmp ); pwd
( exit 3 ); echo "$?"
false | true; echo "$?"
true | false; echo "$?"
x=1; bash -c 'echo "[$x]"'
x=1; ( echo "[$x]" )
export x=1; bash -c 'x=2'; echo "$x"
echo "$$ $(echo $$)"
sleep 3 | echo subito
```

**Verifica.** Si controlla a mano, con Claude: spiega ogni errore di previsione.

**Dopo.** Che differenza c'è fra una variabile ereditata con `fork()` e una passata attraverso `exec()`? Perché le righe 11 e 12 danno risultati diversi? In quale ordine compaiono l'output e il prompt nell'ultima riga, e perché? Cosa cambia se ripeti le righe 3-6 in zsh?

---

## Problema 1 — `chi-gira.sh`

**Situazione.** Prima di fidarti di una riga complicata vuoi vedere coi tuoi occhi quali pezzi girano in quale processo.

**Compito.** `./chi-gira.sh` stampa su stdout queste righe, in qualsiasi ordine, ciascuna con il PID del processo che **esegue davvero** quel pezzo:

```text
principale: PID      il corpo dello script
parentesi: PID       dentro ( ... )
graffe: PID          dentro { ...; }
sostituzione: PID    dentro $( ... )
sinistra: PID        comando a sinistra di una pipe
destra: PID          comando a destra della stessa pipe
```

**Verifica.** `../../verifica.sh 12 1`

> [!question]- Indizio 1
> Se tutti i numeri ti escono uguali, il numero è davvero del processo che lo stampa? Leggi in `man bash` cosa dice il parametro speciale `$` a proposito delle subshell.

> [!question]- Indizio 2
> La frase che hai trovato rimanda a un'altra variabile? Cerca nella sezione *Shell Variables*.

> [!question]- Indizio 3
> Ti manca la riga `sinistra`? Dove va lo stdout di quel comando, e chi deve farla proseguire fino al terminale?

**Dopo.** Una subshell è il risultato di quali chiamate di sistema, e un comando esterno di quali? Cosa ti dice `BASH_SUBSHELL` in più rispetto al PID? Bash deve sempre creare un processo per `( comando )`? Prova a guardare con `strace -f -e trace=clone,clone3,fork,execve` (`pacman -S strace`).

---

## Problema 2 — `riepilogo-vm.sh`

**Situazione.** Vuoi un inventario delle porte inoltrate dalle VM, e in fondo il numero totale di regole.

**Compito.** `./riepilogo-vm.sh` interroga `VBoxManage list vms` e `VBoxManage showvminfo NOME --machinereadable`. Per ogni regola stampa `vm|nome-regola|porta-host`. Una VM senza regole stampa `vm|-|-`. In fondo `totale: N`. Codice 0.

```text
lab-arch|ssh|2222
lab rocky|ssh|2223
lab rocky|http|8080
senza rete|-|-
web|https|8443
totale: 4
```

Il finto `VBoxManage` è volutamente scomodo: nomi con spazi, campi vuoti nelle regole, e una riga di testo che somiglia a una regola ma non lo è.

**Verifica.** `../../verifica.sh 12 2`

> [!question]- Indizio 1
> Il totale esce 0, ma le righe sono giuste? In quale processo gira il corpo del tuo ciclo, e in quale il tuo `echo` finale?

> [!question]- Indizio 2
> Ci sono più strade. Può essere il ciclo a non stare in una pipeline, pur leggendo l'output di un comando? Cerca in `man bash` le espansioni che iniziano con `<`. Oppure: può il `echo` finale stare nello stesso processo del ciclo?

> [!question]- Indizio 3
> Con `IFS` puoi spezzare una riga su un carattere. Cosa succede ai campi vuoti se il separatore è `,` e se è uno spazio?

**Dopo.** Elenca tutti i modi che conosci per far sopravvivere il totale e dimmi cosa costa ciascuno. Perché `shopt -s lastpipe` funziona in uno script e di norma non al prompt? Perché in zsh il problema non si presenta?

---

## Problema 3 — `su-tutte.sh`

**Situazione.** Lanci un comando via SSH su una lista di macchine. Lo script termina senza errori, ma ha toccato solo la prima.

**Compito.** `./su-tutte.sh FILE COMANDO` esegue `remoto MACCHINA COMANDO` per ogni riga di `FILE`, saltando righe vuote e commenti (`#`). `remoto` si comporta come `ssh`, anche nel modo in cui tratta lo stdin. Se una macchina fallisce si prosegue. In fondo `falliti: N`. Codice 0 se N è 0, altrimenti 1. File illeggibile o numero di argomenti sbagliato: codice 2.

```sh
./su-tutte.sh dati/macchine.txt uptime
```

**Verifica.** `../../verifica.sh 12 3`

> [!question]- Indizio 1
> Metti un `echo` subito dopo il `read`: quante volte gira? Da dove legge `read`, e da dove legge il programma lanciato nel corpo del ciclo?

> [!question]- Indizio 2
> Un file descriptor è ereditato dai figli. Puoi decidere tu da dove legge un singolo comando?

> [!question]- Indizio 3
> Le macchine sono tutte, tranne l'ultima? Guarda l'ultimo byte con `tail -c1 dati/macchine.txt | od -c`. Cosa fa `read` con una riga senza `\n` finale: riempie la variabile? E con quale codice esce?

**Dopo.** Esiste una soluzione che riserva a `read` un descrittore tutto suo, così che il corpo del ciclo conservi lo stdin? Cosa cambierebbe se le macchine dovessero essere servite in parallelo, e come raccoglieresti i codici di uscita?

---

## Problema 4 — `esporta-db.sh`

**Situazione.** Il backup notturno è `dump | gzip > file`. Da settimane `dump` si interrompe a metà, ma il cron riceve sempre 0. Lo scopri il giorno del ripristino.

**Compito.** `./esporta-db.sh DB DEST` comprime con `gzip` l'output di `dump DB` in `DEST`.

- Successo: codice 0 e in `DEST` tutto il contenuto, senza altri file accanto.
- Se fallisce un pezzo della catena, esce con il codice di quel pezzo (`dump rotto` esce con 3).
- Un fallimento non lascia archivi mutilati né avanzi, e un `DEST` già esistente resta **intatto**.
- Cartella di destinazione mancante: codice diverso da 0.
- Numero di argomenti sbagliato: codice 2.

**Verifica.** `../../verifica.sh 12 4`

> [!question]- Indizio 1
> Di quale comando è il `$?` di una pipeline? Quanti codici di uscita sono stati prodotti, e dove li ha messi bash? Cerca in `man bash` fra le variabili.

> [!question]- Indizio 2
> Quella variabile sopravvive al comando successivo, anche se è solo un test?

> [!question]- Indizio 3
> In che momento, rispetto all'avvio di `dump`, la redirezione `> DEST` svuota il file? Come sostituisci un file in un colpo solo? Perché il file provvisorio conviene sullo stesso filesystem?

**Dopo.** `pipefail` da sola basta a dirti *quale* pezzo è fallito? Cosa dice `man bash` sul codice restituito quando ne falliscono due? Cosa cambierebbe usare `set -e`? Se `gzip` fallisse per disco pieno, cosa accadrebbe a `dump`?

---

## Problema 5 — `prime.sh`

**Situazione.** Hai attivato `pipefail` su tutti gli script, e ora `produttore | head` fa fallire script che funzionavano. Ma senza `pipefail` non vedi i guasti veri.

**Compito.** `./prime.sh N COMANDO [ARG...]` stampa le prime `N` righe dell'output del comando. Esce con il codice del comando, con una distinzione: se il comando è stato fermato solo perché le righe bastavano, il codice è 0. `N` non numerico o pochi argomenti: codice 2.

```sh
./prime.sh 3 yes                                  # 3 righe, codice 0
./prime.sh 10 sh -c 'echo a; exit 5'              # 1 riga, codice 5
./prime.sh 1 comando-inesistente                  # codice 127
```

**Verifica.** `../../verifica.sh 12 5`

> [!question]- Indizio 1
> Lancia `yes | head -3 >/dev/null` e guarda i codici di tutti i pezzi. Quel numero è 128 più cosa? `kill -l` ti aiuta.

> [!question]- Indizio 2
> Quale codice significa «hai finito, nessuno ti ascolta più», e quale è un guasto?

**Dopo.** Cosa fa `yes` quando riceve quel segnale, e come va invece se il segnale è ignorato (`trap '' PIPE`)? Il tuo script confonde un comando ucciso davvero da quel segnale per altri motivi? Quale caso concreto lo mostra?

---

## Problema 6 — `confronta.sh`

**Situazione.** Devi confrontare i pacchetti installati su due macchine. Lo strumento adatto vuole due file ordinati, i tuoi non lo sono, e su quella macchina non puoi scrivere da nessuna parte.

**Compito.** `./confronta.sh A B` stampa `- x` per le righe solo in `A`, poi `+ y` per quelle solo in `B`, ciascun gruppo in ordine alfabetico e senza doppioni. Non crea alcun file. Codice 0 se i contenuti coincidono, 1 se differiscono, 2 per file illeggibile o argomenti sbagliati. Nomi con spazi ammessi.

```sh
./confronta.sh dati/pacchetti-a.txt dati/pacchetti-b.txt
```

```text
- curl
- vim
+ nginx
+ zsh
```

**Verifica.** `../../verifica.sh 12 6`

> [!question]- Indizio 1
> Una pipe dà a un comando un solo stdin. A te ne servono due. Il comando vuole *nomi di file*: esiste qualcosa che sembri un nome di file ma sia l'uscita di un comando?

> [!question]- Indizio 2
> Prova `echo <(true)`. Cosa stampa? Che cos'è quel percorso?

> [!question]- Indizio 3
> Il file mancante produce un messaggio ma il codice è sbagliato? Il codice di un comando dentro quella costruzione arriva a qualcuno?

**Dopo.** Chi aspetta i processi lanciati così? Perché un programma che fa `seek` su quel percorso fallisce? Rifai a mano lo stesso collegamento con `mkfifo`: perché una FIFO aperta in scrittura resta bloccata se nessuno legge?

---

## Problema 7 — `ogni-cartella.sh`

**Situazione.** Devi lanciare un comando in ogni progetto di una cartella. La versione col `cd` avanti e indietro, il giorno in cui un `cd` fallisce, ha eseguito il comando nel posto sbagliato.

**Compito.** `./ogni-cartella.sh RADICE COMANDO [ARG...]` per ogni sottocartella diretta di `RADICE`, in ordine alfabetico, stampa `== nome` e vi esegue il comando. Se il comando fallisce, o non si può entrare nella cartella, conta un fallimento, non esegue nulla altrove e prosegue. In fondo `falliti: N`. Codice 0 se N è 0, altrimenti 1. `RADICE` inesistente o pochi argomenti: codice 2. `RADICE` può essere relativa, e può non avere sottocartelle.

```sh
./ogni-cartella.sh dati/progetti ls
```

**Verifica.** `../../verifica.sh 12 7`

> [!question]- Indizio 1
> La directory corrente è di tutti i processi o di ciascuno? Se un processo figlio cambia cartella, cosa succede al padre? L'hai previsto nel problema 0.

> [!question]- Indizio 2
> Il contatore però deve restare nel padre. Il figlio può comunicargli qualcosa senza variabili?

> [!question]- Indizio 3
> Con una cartella senza sottocartelle, in cosa si espande il tuo glob? Cerca le opzioni di `shopt` che lo riguardano.

**Dopo.** Perché `cd` non può essere un programma esterno? Quali altre cose del processo si isolano così (`umask`, `set`, `trap`, variabili)? Cosa perde un `exit` dentro le parentesi? Cosa costa creare un processo per ogni giro su migliaia di cartelle?

---

## Diario

Domande numerate, risposte e correzioni di questa lezione.

## Sintesi

Da scrivere a lezione finita, con le tue parole.

---

← [[11-progetto-finale|Lezione 11]] · ↑ [[00-percorso|Il percorso]]
