---
tags:
  - lezione
  - scripting
aliases:
  - Scripting 23 — La shell interattiva
---
# Scripting 23 — La shell interattiva

Finora hai scritto script. Ma la shell in cui lavori tutto il giorno è anche lei un programma da configurare: legge dei file all'avvio, mostra un prompt, ricorda i comandi, completa con Tab. Chi la conosce lavora più veloce e sbaglia meno, perché vede sempre dove si trova e com'è andato l'ultimo comando. Si fa dopo la lezione 06. Riferimenti: [[tipi-di-shell|Tipi di shell e su]], [[alias-history|Alias e history]], sezioni *INVOCATION*, *PROMPTING* e *Programmable Completion* di `man bash`.

```sh
./prepara.sh 23 && cd palestra/l23
```

I tre file che scrivi qui sono pensati per finire nel tuo `~/.bashrc`, con una riga `source` ciascuno, quando funzionano.

## La mappa

| # | Problema | Stato |
|---|---|---|
| 0 | Previsioni — chi legge quale file | — |
| 1 | `prompt.sh` — un prompt che informa | — |
| 2 | `mie-funzioni.sh` — scorciatoie che un alias non sa fare | — |
| 3 | `completamento.sh` — Tab per i tuoi script | — |

---

## Problema 0 — Previsioni

**Situazione.** Aggiungi una variabile al `.bashrc`, entri via SSH, e non c'è. La metti nel `.bash_profile`, e manca nel cron. Ogni modo di avviare bash legge file diversi.

> [!info] Il contesto
> **Lo scenario.** Ogni sistemista personalizza la sua shell: variabili, alias, funzioni, il prompt. Le personalizzazioni stanno in file nascosti della home, che bash legge quando parte. Ma bash parte in tanti modi diversi.
> - **`.bashrc`**: la sigla *rc* viene da *RUNCOM* (*run commands*, «esegui comandi»), un programma del sistema CTSS del 1965 che leggeva una lista di comandi da un file. Da allora i file di avvio si chiamano così.
> - **`.bash_profile`** (inglese *profile*, «profilo»): l'altro file di avvio, quello delle impostazioni personali.
> - **File nascosto**: un file il cui nome inizia con un punto. Non è segreto, solo escluso dagli elenchi normali.
>
> **Perché conta.** Una variabile che c'è al terminale ma non nello script, o in SSH ma non in cron, fa funzionare le cose a mano e fallire in automatico. È uno dei guasti più difficili da capire.

**Compito.** Metti in fondo a `~/.bash_profile` la riga `echo "profile letto" >&2` e in fondo a `~/.bashrc` la riga `echo "bashrc letto" >&2`. Per ognuno di questi avvii scrivi **prima** quale messaggio comparirà, poi prova. Alla fine togli le due righe.

1. Entri dal Mac con `ssh -p 2223 studente@127.0.0.1`.
2. Nella sessione, scrivi `bash`.
3. `bash -c 'echo ciao'`
4. `ssh -p 2223 studente@127.0.0.1 'echo ciao'` dal Mac.
5. `su studente`, poi `su - studente`.
6. `sudo -i` e `sudo -s`.
7. Uno script con `#!/usr/bin/env bash` lanciato con `./`.
8. Un lavoro di `cron`.
9. `bash --login -c 'echo ciao'`

**Verifica.** Si controlla a mano, con Claude.

**Dopo.** Perché il `.bash_profile` di Rocky contiene già un `source ~/.bashrc`? Cosa legge una shell non interattiva, secondo la variabile `BASH_ENV`? Perché alias e funzioni definiti nel `.bashrc` non ci sono negli script? È un difetto o una protezione?

---

## Problema 1 — `prompt.sh`

**Situazione.** Lavori su sei macchine, in più cartelle, dentro repository git. Il prompt predefinito non dice se l'ultimo comando è fallito né su quale ramo sei, e un `git push` dal ramo sbagliato lo scopri dopo.

> [!info] Il contesto
> **Lo scenario.** Chi lavora su molte macchine, in molte cartelle e su molti progetti perde facilmente l'orientamento. Il prompt è l'unica informazione che vede sempre, prima di ogni comando.
> - **Prompt** (inglese, «sollecito», come il suggeritore in teatro): la scritta con cui la shell ti invita a scrivere.
> - **Repository** (latino *repositorium*, «deposito»): una cartella di cui git conserva tutta la storia.
> - **Ramo** (in inglese *branch*): una linea di sviluppo separata dentro lo stesso repository, come `main` o una correzione in corso. **`git push`** («spingi») manda i tuoi cambiamenti al repository condiviso.
>
> **Perché conta.** Un comando lanciato sulla macchina sbagliata, o un push dal ramo sbagliato, si scopre quando il danno è fatto. Un prompt che lo dice prima costa niente.

**Compito.** `prompt.sh`, caricato con `source`, definisce la funzione `__mio_prompt` e la aggiunge a `PROMPT_COMMAND`, senza togliere ciò che c'era già. La funzione imposta `PS1` in modo che il prompt appaia così:

```text
[1] studente@lab-rocky:~/progetti/sito (main)$ 
```

- `[CODICE]` c'è solo se l'ultimo comando è uscito con un codice diverso da 0.
- Poi utente, nome breve della macchina, cartella corrente con `~` al posto della home.
- ` (RAMO)` c'è solo dentro un repository git.
- In fondo `$ `, oppure `# ` per root.
- La funzione non cambia `$?`: chi la chiama ritrova il codice di prima.

**Verifica.** `../../verifica.sh 23 1`. Il correttore espande il tuo `PS1` come farebbe bash al momento di mostrarlo.

> [!question]- Indizio 1
> `man bash`, sezione *PROMPTING*: quali sequenze danno utente, macchina e cartella? Quando vengono espanse, rispetto al momento in cui assegni `PS1`?

> [!question]- Indizio 2
> Il codice dell'ultimo comando è in `$?`, ma solo fino al comando successivo. In che punto della funzione lo salvi? E come fa la funzione a restituirlo alla fine?

> [!question]- Indizio 3
> Quale comando di git stampa il ramo corrente, e cosa fa fuori da un repository? Dove mandi il suo stderr?

**Dopo.** Il nome del ramo può contenere `$(...)`? Cosa succederebbe se lo mettessi in `PS1` così com'è, visto che bash espande `PS1` a ogni prompt? Cerca `promptvars` in `man bash`. Quanto costa lanciare `git` a ogni prompt in un repository enorme?

---

## Problema 2 — `mie-funzioni.sh`

**Situazione.** Hai un alias per tutto, ma alcune scorciatoie un alias non le sa fare: un alias non riceve argomenti in mezzo, e niente che giri in un processo figlio può cambiarti cartella.

> [!info] Il contesto
> **Lo scenario.** Dopo qualche mese di lavoro ognuno ha le sue scorciatoie per le cose che ripete cento volte al giorno: entrare in una cartella appena creata, salvare una copia, cercare un testo in un progetto.
> - **Alias** (latino, «altrimenti», da cui «detto anche»): un nome corto che la shell sostituisce con un comando più lungo, prima di eseguirlo.
> - **Funzione**: un piccolo programma con un nome, definito dentro la shell stessa.
> - **Processo figlio**: un processo lanciato da un altro, che parte con una copia del suo stato e non può cambiare quello del padre.
>
> **Perché conta.** Una scorciatoia scritta male, caricata in ogni shell, fa danni ogni giorno: chiude la shell, sporca le variabili o cerca la cosa sbagliata.

**Compito.** `mie-funzioni.sh`, caricato con `source`, definisce:

| Funzione | Comportamento |
|---|---|
| `mkcd DIR` | Crea `DIR`, anche su più livelli, e ci entra. Restituisce 1 se non ci riesce, e allora resti dov'eri |
| `bak FILE...` | Per ogni file crea accanto una copia `FILE.bak-AAAAMMGG-HHMMSS` con gli stessi permessi e la stessa data, e ne stampa il nome. Restituisce 1 se qualche copia fallisce, dopo aver provato tutte le altre |
| `cerca TESTO [CARTELLA]` | Stampa `percorso:riga:testo` per ogni riga che contiene `TESTO` alla lettera, nei file di testo sotto `CARTELLA` (quella corrente se manca), saltando le cartelle `.git`. Restituisce 1 se non trova nulla |

Nessuna funzione chiude la shell, e nessuna lascia variabili globali.

**Verifica.** `../../verifica.sh 23 2`

> [!question]- Indizio 1
> Perché `mkcd` non può essere uno script? L'hai già scoperto con `mycd.sh` nella lezione 06.

> [!question]- Indizio 2
> `man cp`: quale opzione conserva permessi e date? E `man grep`: quali opzioni cercano in modo ricorsivo, alla lettera, mostrano il numero di riga, saltano i file binari ed escludono una cartella?

> [!question]- Indizio 3
> `cerca -n` cerca il testo `-n` o passa un'opzione a `grep`? Come lo eviti?

**Dopo.** Cosa stampa `type mkcd`? E `type ll`, se hai l'alias? In che ordine bash cerca un nome fra alias, funzioni, comandi interni e `PATH`? Cosa fanno `command` e `\ls`?

---

## Problema 3 — `completamento.sh`

**Situazione.** `ruota.sh` della lezione 08 ha argomenti che non ricordi mai: la cartella, il prefisso dei backup, il numero, `--cancella`. Il Tab potrebbe suggerirteli.

> [!info] Il contesto
> **Lo scenario.** Gli script che usi poco hanno argomenti che non ricordi mai, e aprire il codice per rileggerli fa perdere tempo. Con i comandi di sistema invece basta premere Tab, e la shell suggerisce.
> - **Tab** (da *tabulator*, il tasto delle macchine da scrivere che portava il carrello alla colonna successiva): sulla riga di comando chiede alla shell di finire la parola.
> - **Completamento** (in inglese *completion*): la funzione della shell che propone come continuare una parola. Era già nel sistema TENEX degli anni Settanta; bash permette di programmarlo per ogni comando.
>
> **Perché conta.** Un argomento scritto a memoria, sbagliato, in uno script che cancella, cancella la cosa sbagliata. Un suggerimento basato su ciò che c'è davvero sul disco riduce l'errore.

**Compito.** `completamento.sh`, caricato con `source`, definisce la funzione `_ruota` e la registra per `ruota.sh` e `./ruota.sh`. Riempie `COMPREPLY` secondo la posizione della parola che si sta completando:

| Posizione | Suggerimenti |
|---|---|
| 1 | Le cartelle che iniziano con la parola scritta |
| 2 | I prefissi dei backup nella cartella scritta in posizione 1, cioè la parte prima del primo `_` dei nomi dei file, senza doppioni, che iniziano con la parola scritta |
| 3 | Nulla: è un numero |
| 4 | `--cancella`, se inizia con la parola scritta |

**Verifica.** `../../verifica.sh 23 3`. Il correttore riempie `COMP_WORDS` e `COMP_CWORD` come fa bash quando premi Tab, poi chiama la tua funzione.

> [!question]- Indizio 1
> `help complete` e `help compgen`. Quali variabili riceve una funzione di completamento, e in quale deve lasciare i suggerimenti?

> [!question]- Indizio 2
> `compgen -d -- web` cosa stampa? E `compgen -W "a b c" -- b`?

> [!question]- Indizio 3
> Come ottieni i prefissi dai nomi dei file senza `ls`? Glob e *Parameter Expansion*, più un array associativo per i doppioni.

**Dopo.** Dove stanno su Rocky i completamenti già pronti? Guarda `/usr/share/bash-completion/completions/`. Cosa offre `_init_completion` del pacchetto `bash-completion`? Come gestiresti una cartella con spazi nel nome?

---

## Diario

Domande numerate, risposte e correzioni di questa lezione.

## Sintesi

Da scrivere a lezione finita, con le tue parole.

---

← [[22-sicurezza-portabilita|Lezione 22]] · ↑ [[00-percorso|Il percorso]] · → [[11-progetto-finale|Lezione 11]]
