---
tags:
  - lezione
  - scripting
aliases:
  - Scripting 02 — Decidere
---
# Scripting 02 — Decidere

Uno script che non decide è solo una lista di comandi. In shell ogni decisione si basa su una cosa sola: il codice di uscita di un comando.

```sh
./prepara.sh 02 && cd palestra/l02
```

## La mappa

| # | Problema | Stato |
|---|---|---|
| 1 | `utente-esiste.sh` — una domanda con risposta sì o no | — |
| 2 | `soglia-disco.sh` — l'allarme del disco pieno | — |
| 3 | `estrai.sh` — scegliere in base al nome | — |

---

## Problema 1 — `utente-esiste.sh`

**Situazione.** Prima di creare un account o una cartella vuoi sapere se l'utente c'è. La risposta serve ad altri script, quindi non deve stampare nulla: conta il codice di uscita.

**Compito.** `./utente-esiste.sh NOME [FILE]`. `FILE` ha il formato di `/etc/passwd`, che è anche il valore predefinito.

| Codice | Significato |
|---|---|
| 0 | L'utente esiste |
| 1 | Non esiste |
| 2 | Uso sbagliato (argomento mancante, file illeggibile): spiegazione su stderr, niente su stdout |

`mar` non deve trovare `mario`, `bash` e `1000` non sono nomi, `m.rio` non è `mario`.

**Verifica.** `../../verifica.sh 02 1`

> [!question]- Indizio 1
> Guarda una riga di `dati/passwd`. Su quale pezzo della riga vuoi cercare? Su tutta la riga, cosa può trovare per sbaglio?

> [!question]- Indizio 2
> Se il comando che usi per cercare trova o non trova, quale codice restituisce? Serve davvero confrontare il suo output?

> [!question]- Indizio 3
> `m.rio` trova `mario`: per il tuo comando di ricerca, cosa significa il punto? `man grep`: quali opzioni cambiano *cosa conta come corrispondenza*?

**Dopo.** `/etc/passwd` è l'unica fonte degli utenti di un sistema? Cosa fa `getent passwd`, e perché su una macchina aziendale la tua soluzione potrebbe rispondere in modo sbagliato?

---

## Problema 2 — `soglia-disco.sh`

**Situazione.** Un disco pieno ferma database e log. I sistemi di monitoraggio come Nagios usano una convenzione semplice: una riga di testo per l'umano e il codice per la macchina.

**Compito.** `df -P | ./soglia-disco.sh AVVISO CRITICO [MOUNT]`. Legge da stdin; il mount predefinito è `/`. Per provare: `./soglia-disco.sh 80 90 /var < dati/df.txt`.

| Uso del disco | Stampa | Codice |
|---|---|---|
| Sotto `AVVISO` | `OK /var 42%` | 0 |
| Da `AVVISO` in su | `WARNING /var 85%` | 1 |
| Da `CRITICO` in su | `CRITICAL /var 96%` | 2 |
| Mount inesistente, soglie non numeriche o mancanti, `AVVISO` ≥ `CRITICO` | spiegazione su stderr | 3 |

**Verifica.** `../../verifica.sh 02 2`

> [!question]- Indizio 1
> Guarda `dati/df.txt`: `/var` e `/var/log` iniziano allo stesso modo. Come distingui una colonna intera da un pezzo di testo?

> [!question]- Indizio 2
> `/boot` è al 9% ma il tuo script grida? Quale ordine usa il confronto che hai scritto, e cosa viene prima fra `"9"` e `"80"` in un dizionario?

> [!question]- Indizio 3
> `85%` non è un numero. Come togli un carattere dalla fine di una variabile senza lanciare altri comandi? Cerca in `man bash` la sezione *Parameter Expansion*.

> [!question]- Indizio 4
> Come riconosci che una stringa è fatta solo di cifre? Cosa accetta `[[ ]]` a destra di `=~`?

**Dopo.** Prova `./soglia-disco.sh 80 90 "/var/log"` e poi un mount con uno spazio nel nome: cosa fa il tuo script? Perché `df -P` e non `df -h`? Cosa fa la `P`?

---

## Problema 3 — `estrai.sh`

**Situazione.** Arrivano archivi in formati diversi e ricordare ogni volta le opzioni è una perdita di tempo. Vuoi un comando solo. Il manuale Rocky elenca i formati nel capitolo sui backup.

**Compito.** `./estrai.sh ARCHIVIO CARTELLA` crea la cartella ed estrae lì dentro.

| Nome | Azione |
|---|---|
| `.tar` | Estrae |
| `.tar.gz`, `.tgz` | Estrae |
| `.gz` | Decomprime nella cartella, togliendo `.gz`, e lascia l'originale al suo posto |

Codici: 1 numero di argomenti sbagliato, 2 formato non supportato, 3 archivio inesistente.

**Verifica.** `../../verifica.sh 02 3`

> [!question]- Indizio 1
> Con una catena di `if` dovresti ripetere molte volte lo stesso test. Il quiz del manuale cita una struttura pensata per scegliere fra tanti valori: quale?

> [!question]- Indizio 2
> `.tar.gz` finisce anche con `.gz`. Se metti le regole in un certo ordine, quale scatta per prima?

> [!question]- Indizio 3
> `gzip` di solito sostituisce il file che gli dai. `man gzip`: c'è un modo per mandare il risultato altrove?

**Dopo.** Il nome di un file garantisce cosa contiene? Prova `file dati/strano.rar`. Come cambierebbe lo script se decidesse guardando il contenuto?

---

## Diario

Domande numerate, risposte e correzioni di questa lezione.

## Sintesi

Da scrivere a lezione finita, con le tue parole.

---

← [[01-primo-script|Lezione 01]] · ↑ [[00-percorso|Il percorso]] · → [[03-cicli-e-nomi|Lezione 03]]
