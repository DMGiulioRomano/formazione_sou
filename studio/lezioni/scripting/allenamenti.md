---
tags:
  - lezione
  - scripting
aliases:
  - Scripting — Allenamenti
---
# Scripting — Allenamenti

Ottanta esercizi brevi, da due a dieci righe ciascuno, divisi in otto aree. Servono come riscaldamento quotidiano: venti o trenta minuti prima del problema del giorno, finché le cose semplici escono senza pensarci. Non hanno indizi e non hanno domande «Dopo»: se uno ti blocca per più di dieci minuti, torna alla lezione dell'area e riprovalo il giorno dopo.

```sh
./prepara.sh a1 && cd palestra/a1
vim k01.sh
../../verifica.sh a1 1     # area a1, esercizio 1
../../verifica.sh a1       # tutta l'area
```

Ogni esercizio è uno script `kNN.sh` nella cartella dell'area. Dove si parla di stdin, il correttore passa il testo sullo standard input. Dove non si dice altro, lo script esce con 0.

## La mappa

| Area | Argomento | Dopo la lezione | Stato |
|---|---|---|---|
| a1 | Argomenti ed espansioni | 13 | — |
| a2 | Test e condizioni | 02 | — |
| a3 | Cicli | 03 | — |
| a4 | Filtri di testo | 04 | — |
| a5 | `sed` | 05 | — |
| a6 | `awk` | 05 | — |
| a7 | Stringhe senza comandi esterni | 15 | — |
| a8 | Array | 16 | — |

---

## a1 — Argomenti ed espansioni

| # | Compito | Esempio |
|---|---|---|
| 1 | Stampa `ciao, NOME!`, con `mondo` se manca l'argomento | `mario` → `ciao, mario!` |
| 2 | Stampa il numero di argomenti | `"a b" c` → `2` |
| 3 | Stampa ogni argomento fra quadre, uno per riga | `"a b" "" c` → `[a b]`, `[]`, `[c]` |
| 4 | Stampa l'ultimo argomento | `a b "c d"` → `c d` |
| 5 | Dato `N`, stampa `file01.txt` … `fileNN.txt` su una riga, separati da spazi | `3` → `file01.txt file02.txt file03.txt` |
| 6 | Stampa gli argomenti in ordine inverso, uno per riga | `a "b c" d` → `d`, `b c`, `a` |
| 7 | Stampa `oggi: AAAA-MM-GG` con la data di oggi | `oggi: 2026-11-03` |
| 8 | Stampa la somma degli argomenti, interi anche negativi | `1 2 3 -4` → `2` |
| 9 | Stampa i primi due argomenti scambiati, poi gli altri, su una riga | `a b c d` → `b a c d` |
| 10 | Stampa `testo: $HOME valore: ` seguito dal valore vero di `HOME` | `testo: $HOME valore: /home/mario` |

## a2 — Test e condizioni

| # | Compito | Esempio |
|---|---|---|
| 1 | Dato un percorso, stampa `file`, `cartella`, `altro` o `manca` | `/etc` → `cartella` |
| 2 | Stampa `pari` o `dispari`; se non è un intero, codice 2 | `7` → `dispari` |
| 3 | Stampa il maggiore di due interi | `3 -5` → `3` |
| 4 | Codice 0 se l'argomento è vuoto o manca, 1 altrimenti | `""` → codice 0 |
| 5 | Stampa `nascosto` se il nome inizia con un punto, altrimenti `visibile` | `.bashrc` → `nascosto` |
| 6 | Codice 0 se l'anno è bisestile, 1 se no | `1900` → codice 1 |
| 7 | Codice 0 se il percorso è un file normale eseguibile, 1 altrimenti | `/usr/bin/ls` → codice 0 |
| 8 | Stampa `numero` per un intero (anche negativo), `parola` per sole lettere, `altro` per il resto | `-12` → `numero` |
| 9 | Codice 0 se il file A è più recente del file B, 1 altrimenti | |
| 10 | Dato un voto da 0 a 30: `insufficiente` sotto 18, `sufficiente` fino a 24, `buono` fino a 29, `ottimo` a 30; fuori, codice 2 | `27` → `buono` |

## a3 — Cicli

| # | Compito | Esempio |
|---|---|---|
| 1 | Conta alla rovescia da `N` a 1, un numero per riga | `3` → `3`, `2`, `1` |
| 2 | Stampa la tabellina di `N` da 1 a 10, righe `N x I = R` | `7` → … `7 x 10 = 70` |
| 3 | Stampa le righe di un file numerate, `1: riga`, conservando spazi e righe vuote | |
| 4 | Stampa in ordine i nomi dei file normali di una cartella, anche con spazi; nessun file, nessun output | |
| 5 | Stampa i primi `N` numeri di Fibonacci su una riga | `5` → `0 1 1 2 3` |
| 6 | Legge numeri dallo stdin, uno per riga, e stampa il massimo; le righe vuote si ignorano | |
| 7 | Stampa i numeri primi fino a `N` su una riga | `20` → `2 3 5 7 11 13 17 19` |
| 8 | Stampa `PAROLA` ripetuta `N` volte su una riga, separata da spazi | `ciao 3` → `ciao ciao ciao` |
| 9 | Stampa le righe dello stdin fino alla prima `FINE`, esclusa | |
| 10 | Disegna un triangolo di `*` alto `N` | `3` → `*`, `**`, `***` |

## a4 — Filtri di testo

Tutti leggono lo stdin, salvo il 4.

| # | Compito | Esempio |
|---|---|---|
| 1 | Conta le righe che contengono almeno un carattere diverso da spazi e tabulazioni | |
| 2 | Parole una per riga: stampa quelle distinte, in ordine alfabetico | |
| 3 | Testo con parole separate da spazi: le tre più frequenti, `N parola`, dalla più frequente e a parità in ordine alfabetico | |
| 4 | Dato un file in formato `passwd`, le shell distinte in ordine | |
| 5 | Tutto in maiuscolo | `ciao` → `CIAO` |
| 6 | Righe CSV semplici `a,b,c`: stampa la seconda colonna | |
| 7 | Solo le righe che contengono un numero di almeno tre cifre | |
| 8 | Toglie le righe ripetute, tenendo la prima volta e l'ordine | |
| 9 | Stampa la lunghezza della riga più lunga | |
| 10 | Toglie spazi e tabulazioni all'inizio e alla fine di ogni riga | |

## a5 — `sed`

Tutti leggono lo stdin e devono usare `sed`.

| # | Compito | Esempio |
|---|---|---|
| 1 | Sostituisce ogni `foo` con `bar` | `foo foo` → `bar bar` |
| 2 | Toglie le righe vuote e quelle che, dopo eventuali spazi, iniziano con `#` | |
| 3 | Stampa solo le righe dalla 3 alla 5 | |
| 4 | Righe di due parole: le scambia | `a b` → `b a` |
| 5 | Mette `> ` davanti a ogni riga | |
| 6 | Trasforma ogni data `GG/MM/AAAA` in `AAAA-MM-GG`, ovunque nella riga | `il 03/11/2026` → `il 2026-11-03` |
| 7 | Toglie i tag HTML semplici, da `<` a `>` sulla stessa riga | `<b>ciao</b>` → `ciao` |
| 8 | Righe `chiave=valore`: stampa solo il valore della chiave `porta` | |
| 9 | Aggiunge la riga `# generato` prima della prima riga | |
| 10 | Riduce ogni gruppo di spazi a uno solo | |

## a6 — `awk`

Tutti leggono lo stdin e devono usare `awk`.

| # | Compito | Esempio |
|---|---|---|
| 1 | Righe `nome punti`: la somma dei punti | |
| 2 | Un numero per riga: la media con due decimali | `1`, `2` → `1.50` |
| 3 | L'ultimo campo di ogni riga | |
| 4 | Righe `nome punti`: il nome con più punti (il primo, a parità) | |
| 5 | File `passwd`: `nome uid` per gli UID da 1000 in su | |
| 6 | Righe `categoria valore`: la somma per categoria, `categoria somma`, in ordine di categoria | |
| 7 | Numera solo le righe non vuote, `N: riga`; le vuote restano vuote e non contano | |
| 8 | Campi separati da `;`: stampa il terzo e il primo, separati da una tabulazione | |
| 9 | Il numero di campi di ogni riga | |
| 10 | Solo le righe con più di tre campi | |

## a7 — Stringhe senza comandi esterni

Il correttore li lancia senza `PATH`, come nella lezione 15.

| # | Compito | Esempio |
|---|---|---|
| 1 | Il nome finale di un percorso | `/a/b/c.txt` → `c.txt` |
| 2 | La cartella di un percorso; senza `/`, `.` | `/a/b/c.txt` → `/a/b` |
| 3 | L'estensione, dopo l'ultimo punto; senza punto, nulla | `a.tar.gz` → `gz` |
| 4 | Il nome senza l'ultima estensione | `a.tar.gz` → `a.tar` |
| 5 | La lunghezza | `ciao` → `4` |
| 6 | In maiuscolo | `ciao` → `CIAO` |
| 7 | Al contrario | `ciao` → `oaic` |
| 8 | Quante volte compare il carattere `C` | `banana a` → `3` |
| 9 | Oltre i 6 caratteri, i primi tre, `...` e gli ultimi tre; altrimenti uguale | `abcdefgh` → `abc...fgh` |
| 10 | Spazi in `_`, poi via tutto ciò che non è lettera, cifra o `_` | `Ciao, mondo!` → `Ciao_mondo` |

## a8 — Array

| # | Compito | Esempio |
|---|---|---|
| 1 | Gli argomenti in ordine, uno per riga | |
| 2 | Gli argomenti senza doppioni, nell'ordine in cui compaiono | `b a b c a` → `b a c` |
| 3 | Il numero di argomenti distinti | `b a b` → `2` |
| 4 | Parole una per riga dallo stdin: `parola N`, in ordine di parola | |
| 5 | Gli argomenti in posizione pari, su una riga | `a b c d e` → `b d` |
| 6 | Dati `N` e degli argomenti, li ruota a sinistra di `N`, su una riga | `2 a b c d` → `c d a b` |
| 7 | Righe `chiave valore` dallo stdin: `chiave=valore` con l'ultimo valore, nell'ordine della prima comparsa | |
| 8 | L'argomento più lungo, il primo a parità | `aa bbb cc ddd` → `bbb` |
| 9 | Le righe dello stdin dall'ultima alla prima, senza `tac` | |
| 10 | Gli argomenti numerati da 1, `1 a`, `2 b`, una riga ciascuno | |

---

↑ [[00-percorso|Il percorso]]
