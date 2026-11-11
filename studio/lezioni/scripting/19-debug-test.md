---
tags:
  - lezione
  - scripting
aliases:
  - Scripting 19 — Debug, test e prestazioni
---
# Scripting 19 — Debug, test e prestazioni

Scrivere uno script è la metà del lavoro. L'altra metà è capire perché non fa ciò che credi, dimostrare che lo fa, e farlo in un tempo ragionevole. Qui trovi sei script rotti con i difetti più comuni nel mondo reale, poi scrivi i tuoi test, una traccia degli errori e la versione veloce di uno script lentissimo. Si fa dopo la lezione 06; il problema 7 usa `versione.sh` della lezione 15.

```sh
./prepara.sh 19 && cd palestra/l19
```

Per tutti i problemi da riparare vale lo stesso metodo della lezione 01: prima **prevedi** cosa farà lo script, poi controlli con `bash -x` o con `shellcheck`, poi correggi un difetto alla volta. Una traccia più leggibile:

```sh
PS4='+ ${BASH_SOURCE##*/}:${LINENO}: ' bash -x ./script.sh argomenti
```

## La mappa

| # | Problema | Stato |
|---|---|---|
| 1 | `somma-usato.sh` — arriva da un collega | — |
| 2 | `stato-servizio.sh` — sempre attivo, anche quando è fermo | — |
| 3 | `trova-grandi.sh` — senza argomenti cerca ovunque | — |
| 4 | `archivia.sh` — l'archivio finisce nel posto sbagliato | — |
| 5 | `ha-errori.sh` — tutti i file hanno errori | — |
| 6 | `fine-mese.sh` — ad agosto si rompe | — |
| 7 | `prova-lib.sh` e `test-versione.sh` — test che trovano i difetti | — |
| 8 | `veloce.sh` — da minuti a un secondo | — |
| 9 | `traccia-errori.sh` — dove è fallito? | — |

---

## Problemi 1-6 — Sei script rotti

**Situazione.** Ti passano sei script «che funzionavano». Li trovi già in `palestra/l19/`. Ognuno ha uno o due difetti fra i più comuni negli script veri. Per ciascuno: leggi cosa dovrebbe fare, provalo, scrivi nel diario cosa ti aspettavi e cosa è successo, poi riparalo. Non riscriverlo da capo: il difetto va capito.

| # | Script | Cosa dovrebbe fare |
|---|---|---|
| 1 | `somma-usato.sh FILE` | Somma la colonna *Used* di un output di `df -P` salvato in `FILE` e stampa `usati: N` |
| 2 | `stato-servizio.sh NOME` | Stampa `NOME: attivo` con codice 0, oppure `NOME: fermo (stato)` con codice 1. Lo stato lo dà il finto `servizio is-active NOME` in `dati/bin` |
| 3 | `trova-grandi.sh CARTELLA [MB]` | Elenca in ordine i file più grandi di `MB` megabyte, 10 se manca. Senza `CARTELLA`, codice 2. La cartella può avere spazi |
| 4 | `archivia.sh SORGENTE DEST` | Crea `DEST/archivio.tar.gz` con dentro la cartella `SORGENTE`, e stampa il percorso. Entrambi possono essere relativi e avere spazi. `DEST` mancante: codice 1, e nessun archivio da nessuna parte |
| 5 | `ha-errori.sh FILE...` | Stampa i file che contengono `ERROR`, codice 1 se ce n'è almeno uno, 0 altrimenti |
| 6 | `fine-mese.sh AAAA-MM-GG` | Stampa quanti giorni mancano alla fine del mese. Data non valida: codice 2 |

Per provare il 2 a mano: `PATH="$PWD/dati/bin:$PATH" ./stato-servizio.sh httpd`.

**Verifica.** `../../verifica.sh 19 1`, e così via fino al 6.

> [!question]- Indizio per tutti
> Il messaggio d'errore dice *dove* e *cosa*: leggilo parola per parola, compresi i caratteri strani. Se non c'è un messaggio, stampa i valori delle variabili subito prima del punto sospetto: `declare -p` mostra anche i caratteri invisibili.

> [!question]- Indizio per il 1
> `/usr/bin/env: 'bash\r'`: cos'è quel `\r`? Guarda il file con `cat -A` oppure `file somma-usato.sh`. Come si chiama la differenza fra i fine riga di Windows e quelli di Unix, e quali comandi la tolgono?

> [!question]- Indizio per il 2
> Cosa vale `$?` subito dopo `local stato=$(...)`? Di quale comando è quel codice? `shellcheck` ha un nome per questo avviso: cercalo.

> [!question]- Indizio per il 3
> Senza il secondo argomento, cosa vede `[` in `[ -n $2 ]`? Quanti argomenti riceve? Rileggi in `help test` cosa fa `test` con un solo argomento.

> [!question]- Indizio per il 4
> Cosa succede alla riga dopo un `cd` fallito? E se `SORGENTE` è relativa, dopo il `cd` da dove parte?

> [!question]- Indizio per il 5
> A quale comando appartiene il `$?` che controlli? Contali.

> [!question]- Indizio per il 6
> Prova `2026-08-09` e `2026-07-09`. Hai già incontrato questo errore nella lezione 14.

**Dopo.** Per ciascuno: `shellcheck` l'avrebbe trovato? Quale regola di scrittura, se la segui sempre, rende impossibile questo difetto? Fanne un elenco: è la tua lista di controllo personale.

---

## Problema 7 — `prova-lib.sh` e `test-versione.sh`

**Situazione.** Hai riparato e migliorato tanti script, ma ogni volta li riprovi a mano. Un test automatico lo scrivi una volta, e da lì ti avverte ogni volta che rompi qualcosa. Il correttore che usi da mesi è proprio questo. Ora tocca a te.

**Compito, prima parte.** `prova-lib.sh` è una libreria, caricata con `source`:

| Funzione | Comportamento |
|---|---|
| `assert_eq ATTESO OTTENUTO DESCRIZIONE` | Stampa `ok - DESCRIZIONE` se sono uguali, altrimenti `NO - DESCRIZIONE: atteso 'ATTESO', ottenuto 'OTTENUTO'` |
| `assert_code CODICE DESCRIZIONE COMANDO [ARG...]` | Esegue il comando senza mostrarne l'output e confronta il suo codice: `ok - ...` oppure `NO - DESCRIZIONE: codice atteso C, ottenuto N` |
| `riepilogo` | Stampa `passate: P, fallite: F` e restituisce 0 se F è 0, altrimenti 1 |

Una prova fallita non interrompe le successive.

**Compito, seconda parte.** `./test-versione.sh PERCORSO` usa la tua libreria per mettere alla prova un `versione.sh` (il problema 3 della lezione 15) che si trova in `PERCORSO`, ed esce con il codice di `riepilogo`. Scrivi almeno dieci prove.

Il correttore lancia i tuoi test sul tuo `../l15/versione.sh`, dove devono passare tutti, e poi su quattro versioni sbagliate che ha lui. Ciascuna si comporta come la tua, salvo un difetto tipico. Su ciascuna i tuoi test devono **fallire**: è così che si misura se un test serve.

**Verifica.** `../../verifica.sh 19 7`

> [!question]- Indizio 1
> Come fa `assert_code` a eseguire un comando ricevuto come argomenti, conservando gli spazi? L'hai fatto in `riprova.sh` della lezione 03.

> [!question]- Indizio 2
> I contatori stanno nella libreria e li aggiornano le funzioni. Dove vanno dichiarati perché `riepilogo` li veda?

> [!question]- Indizio 3
> Quali sbagli farebbe una persona che scrive `versione.sh` di fretta? Ogni sbaglio che ti viene in mente è un test da scrivere.

**Dopo.** Questa tecnica, introdurre difetti apposta per vedere se i test se ne accorgono, si chiama *mutation testing*. Quali difetti non riusciresti a scoprire con prove dall'esterno? Cosa offrono `bats-core` e `shunit2` in più della tua libreria?

---

## Problema 8 — `veloce.sh`

**Situazione.** Lo script `lento.sh`, che trovi in `palestra/l19/`, conta per ogni indirizzo IP le richieste fallite (stato 4xx o 5xx) di un log e stampa i dieci peggiori. È corretto, ma su `dati/grande.log`, 100 000 righe, impiega diversi minuti. Il cron che lo lancia ogni cinque minuti si accavalla con se stesso.

**Compito.** Scrivi `veloce.sh FILE` che stampa **esattamente** lo stesso output di `lento.sh` su qualsiasi log, e su `dati/grande.log` impiega meno di 3 secondi. Non lanciare `lento.sh` sul file grande: provalo su un pezzo, con `head -n 2000 dati/grande.log >piccolo.log`.

**Verifica.** `../../verifica.sh 19 8`. Il correttore confronta il tuo output con quello di `lento.sh` su file piccoli costruiti apposta, poi misura il tuo tempo sul file grande.

> [!question]- Indizio 1
> Misura prima di ottimizzare: `time ./lento.sh piccolo.log`. Quanto costa una riga? Quanti processi nascono per ogni riga? Contali leggendo lo script.

> [!question]- Indizio 2
> Un processo costa circa un millisecondo; 100 000 righe per tre processi fanno cinque minuti. Quanti processi deve creare in tutto la versione veloce?

> [!question]- Indizio 3
> L'output deve essere identico anche nei pareggi. Come ordina `lento.sh` quando due IP hanno lo stesso conteggio?

**Dopo.** Quanto è più veloce la tua versione? Prova una versione in bash puro, senza comandi esterni nel ciclo: è più veloce di `lento.sh`, ma di `awk`? Perché? Cosa fa `LC_ALL=C` alla velocità di `sort` e `grep`?

---

## Problema 9 — `traccia-errori.sh`

**Situazione.** Uno script lungo fallisce di notte con `set -e`, e il log dice solo che è uscito con 1. Quale comando, in quale funzione, chiamata da dove? I linguaggi veri stampano una *traccia dello stack*. Bash ha tutti i pezzi per farlo.

**Compito.** `traccia-errori.sh` è una libreria. Dopo `source traccia-errori.sh`, il primo comando che fallisce fuori da una condizione (`if`, `while`, `&&`, `||`, `!`) ferma lo script con il suo codice e scrive su stderr:

```text
ERRORE: 'false' è uscito con 1
  in prova.sh:7, nella funzione interna
  chiamata da prova.sh:11, nella funzione esterna
  chiamata da prova.sh:14
```

- La prima riga riporta il comando così come è scritto e il suo codice.
- Poi una riga per ogni livello, dal più interno: nome del file senza percorso, numero di riga, e funzione se c'è.
- Deve valere anche dentro le funzioni.

**Verifica.** `../../verifica.sh 19 9`

> [!question]- Indizio 1
> `help trap`: quale segnale finto scatta quando un comando fallisce? Perché da solo non scatta dentro le funzioni? Cerca `errtrace` in `help set`.

> [!question]- Indizio 2
> Quale variabile contiene il comando che si sta eseguendo? Cerca in *Shell Variables* di `man bash`.

> [!question]- Indizio 3
> `FUNCNAME`, `BASH_SOURCE` e `BASH_LINENO` sono tre array paralleli. Disegnali su carta per l'esempio, livello per livello, oppure stampali con `declare -p` dentro il gestore. Esiste anche `caller`.

**Dopo.** Il gestore come si comporta in una subshell o in `$( )`? Cosa cambia se il comando fallito sta in una pipeline e manca `pipefail`? Quando preferiresti questa libreria a `set -e`, e quando nessuna delle due?

---

## Diario

Domande numerate, risposte e correzioni di questa lezione.

## Sintesi

Da scrivere a lezione finita, con le tue parole.

---

← [[18-redirezioni|Lezione 18]] · ↑ [[00-percorso|Il percorso]] · → [[07-utenti-permessi|Lezione 07]]
