---
tags:
  - lezione
  - scripting
aliases:
  - Scripting 16 — Array e dati strutturati
---
# Scripting 16 — Array e dati strutturati

Finché i dati sono una riga alla volta basta un ciclo. Quando devi raggruppare, contare per categoria, ricordare cosa hai già visto o passare un elenco a una funzione, servono strutture: gli array indicizzati, quelli associativi, e i modi per riempirli senza perdere spazi e a capo. Si fa dopo la lezione 04. Riferimento: `man bash`, sezione *Arrays*, e `help mapfile`.

```sh
./prepara.sh 16 && cd palestra/l16
```

## La mappa

| # | Problema | Stato |
|---|---|---|
| 1 | `inventario.sh` — cosa gira dove | — |
| 2 | `ini-get.sh` — leggere una configurazione a sezioni | — |
| 3 | `doppioni.sh` — lo stesso file tre volte | — |
| 4 | `carica-conf.sh` — una funzione che riempie un array altrui | — |

---

## Problema 1 — `inventario.sh`

**Situazione.** L'elenco delle macchine sta in un file di testo che modificano in tanti. Ti chiedono quante macchine ci sono per ruolo e per ambiente, e il file contiene sempre qualche doppione o riga storta.

> [!info] Il contesto
> **Lo scenario.** In un'azienda piccola l'elenco dei server sta in un file condiviso, che ognuno aggiorna quando accende o spegne una macchina. Il responsabile chiede quante macchine servono a ogni cosa, per capire dove spendere.
> - **Ruolo**: il lavoro che fa una macchina, come server web (`web`), database (`db`) o memoria veloce (`cache`).
> - **Ambiente**: il contesto in cui gira, come produzione (`prod`, quella dei clienti) o prova (`test`).
> - **Riga storta**: una riga scritta a metà, con un campo mancante o un separatore sbagliato. In un file toccato da tante mani ce n'è sempre qualcuna.
>
> **Perché conta.** Un doppione contato due volte fa credere di avere una macchina in più. Una riga storta ignorata in silenzio ne fa sparire una.

**Compito.** `./inventario.sh FILE`, con righe `host;ruolo;ambiente`. Righe vuote e `#` si ignorano. Per `dati/macchine.txt` stampa:

```text
cache (1): cache01
db (2): db01 db02
web (3): web01 web02 web03
ambienti: prod=4 test=2
```

- Un ruolo per riga, in ordine alfabetico, con il numero di host e gli host in ordine alfabetico. I ruoli si confrontano in minuscolo: `Web` e `web` sono lo stesso ruolo.
- In fondo gli ambienti, in ordine alfabetico, con il numero di host.
- Un host già visto si ignora, con `riga N: host duplicato: NOME` su stderr. Una riga senza tre campi non vuoti si ignora, con `riga N: ...` su stderr.
- Codice 0 se non ci sono state segnalazioni, 1 se ce ne sono state, 2 se il file non si legge o mancano argomenti.

**Verifica.** `../../verifica.sh 16 1`

> [!question]- Indizio 1
> Per ogni ruolo devi accumulare una lista di host. Quale struttura ha per indice una parola invece di un numero? Come si dichiara, e cosa succede se dimentichi di dichiararla?

> [!question]- Indizio 2
> Come elenchi le *chiavi* di un array associativo, invece dei valori? In che ordine escono?

> [!question]- Indizio 3
> Per i doppioni ti serve ricordare tutti gli host visti. Come chiedi se una chiave esiste già? Cerca `-v` fra le espressioni di `[[ ]]`.

**Dopo.** Cosa stampa `declare -p` su uno dei tuoi array? A cosa ti serve? Perché le chiavi di un array associativo escono in un ordine che sembra a caso? Come faresti lo stesso lavoro con un solo `awk`?

---

## Problema 2 — `ini-get.sh`

**Situazione.** Molti programmi usano file INI: sezioni fra quadre e righe `chiave = valore`. Uno script di manutenzione deve leggere host e porta del database da `dati/app.ini` senza installare un parser.

> [!info] Il contesto
> **Lo scenario.** Un'applicazione tiene le sue impostazioni in un file di testo diviso in sezioni. Uno script di manutenzione deve sapere dove sta il suo database, e su quella macchina non si possono installare programmi nuovi.
> - **INI** (da *initialization*, «inizializzazione»): il formato dei file di configurazione nato con le prime versioni di Windows, fatto di `[sezioni]` e righe `chiave = valore`. Lo usano anche molti programmi Linux.
> - **Parser** (inglese *to parse*, dal latino *pars orationis*, «parte del discorso», cioè analizzare una frase): il programma che legge un formato e ne estrae i pezzi.
> - **`\r\n`**: il modo in cui Windows chiude le righe, con un carattere in più, invisibile, rispetto a Linux.
>
> **Perché conta.** Un valore letto con uno spazio o un `\r` in coda sembra giusto a vederlo, ma non si collega a niente, e il guasto è difficile da vedere.

**Compito.** `./ini-get.sh FILE SEZIONE CHIAVE` stampa il valore.

- Le sezioni si scrivono `[nome]`, anche con spazi dentro le quadre (`[ cache ]` è la sezione `cache`). Le righe prima della prima sezione stanno nella sezione vuota `""`.
- Le righe che, dopo eventuali spazi, iniziano con `;` o `#` sono commenti. Un `;` o un `#` in mezzo al valore fa parte del valore.
- Spazi intorno alla chiave, all'`=` e al valore si tolgono. Il valore è tutto ciò che sta dopo il **primo** `=`.
- Una sezione può comparire più volte; se una chiave si ripete, vale l'ultima. Le chiavi distinguono maiuscole e minuscole.
- Il file può avere le righe alla maniera di Windows (`\r\n`): il valore stampato non contiene `\r`.
- Chiave o sezione non trovata: codice 1. File illeggibile o argomenti sbagliati: codice 2.

**Verifica.** `../../verifica.sh 16 2`

> [!question]- Indizio 1
> Leggi il file riga per riga e ricorda in quale sezione ti trovi. Cosa deve succedere a quella variabile quando incontri una riga con le quadre?

> [!question]- Indizio 2
> Come togli gli spazi all'inizio e alla fine di una variabile senza comandi esterni? Un'idea: con `extglob` attivo, cosa significa `${v##+([[:space:]])}`? Un'altra: `read` toglie già qualcosa, se lasci `IFS` com'è.

> [!question]- Indizio 3
> Il valore letto dal file di Windows sembra giusto ma il confronto fallisce? Guardalo con `printf '%q\n' "$v"`, oppure con `od -c`.

**Dopo.** Il tuo script legge tutto il file anche quando ha già trovato il valore. Puoi fermarti prima, viste le regole? Come faresti `ini-set.sh`, che cambia un valore in modo idempotente come `imposta.sh` della lezione 05? Su Rocky, quali file in `/etc` hanno questo formato? Guarda `/etc/dnf/dnf.conf` e `/etc/yum.repos.d/`.

---

## Problema 3 — `doppioni.sh`

**Situazione.** Una cartella condivisa è piena: le stesse foto e gli stessi documenti salvati più volte, con nomi diversi. Prima di cancellare qualsiasi cosa vuoi l'elenco dei gruppi di file identici.

> [!info] Il contesto
> **Lo scenario.** La cartella condivisa dell'ufficio ha esaurito lo spazio. Ognuno ha salvato la sua copia degli stessi file, con nomi come `copia di…` o `(1)`. Il responsabile chiede di fare ordine, ma non vuole che si perda nulla.
> - **Cartella condivisa**: una cartella su un server che più persone usano dalla rete, come se fosse sul loro computer.
> - **File identici**: file con gli stessi byte, anche se nome, data e cartella sono diversi.
>
> **Perché conta.** Il nome non dice se due file sono uguali. Cancellare in base al nome fa perdere documenti diversi che si chiamano allo stesso modo, e tiene i doppioni che si chiamano in modo diverso.

**Compito.** `./doppioni.sh CARTELLA` cerca, in tutto l'albero, i file normali con lo stesso contenuto, e stampa i gruppi:

```text
dati/foto/a capo?qui.txt
dati/foto/f.txt

dati/foto/copia di mare.jpg
dati/foto/vacanze/mare.jpg
dati/foto/vecchie/mare (1).jpg

dati/foto/doc/relazione finale.txt
dati/foto/doc/relazione.txt
```

- I percorsi iniziano con `CARTELLA` così come l'hai scritta. Un a capo dentro un nome si stampa come `?`.
- Dentro un gruppo i percorsi sono in ordine; i gruppi sono in ordine di primo percorso, separati da una riga vuota. L'ordine è quello di `LC_ALL=C sort`.
- I file vuoti e i link simbolici non contano.
- Codice 1 se ha trovato doppioni, 0 se non ce ne sono, 2 se la cartella non esiste o mancano argomenti. Come `diff`.

**Verifica.** `../../verifica.sh 16 3`

> [!question]- Indizio 1
> Due file sono uguali se hanno lo stesso contenuto. Quale comando riassume il contenuto in un numero, e l'hai già usato nella lezione 08? Cosa scegli come chiave dell'array, e cosa come valore?

> [!question]- Indizio 2
> Fra i file c'è un nome con un a capo dentro. Se leggi l'output di `find` riga per riga, quanti file vedi al suo posto? `man find`: come si separano i nomi con un carattere che non può stare in un nome? E chi lo legge, dall'altra parte? Cerca `-d` in `help mapfile` e in `help read`.

> [!question]- Indizio 3
> Come memorizzi più percorsi sotto una sola chiave, se un array associativo contiene una stringa per chiave? Ti serve un separatore che non può comparire in un percorso.

**Dopo.** Calcolare la somma di ogni file costa: su un disco da 2 TB quanto ci mette? Come lo eviti per la maggior parte dei file? Pensa alla dimensione. Due file con la stessa somma SHA-256 sono certamente uguali? Cosa sono gli *hard link*, e il tuo script come li tratta?

---

## Problema 4 — `carica-conf.sh`

**Situazione.** I tuoi script leggono configurazioni `CHIAVE=VALORE`. Il modo pigro è `source app.conf`, che esegue qualsiasi cosa ci sia dentro. Ti scrivi una funzione che legge i valori come dati e li consegna al chiamante.

> [!info] Il contesto
> **Lo scenario.** I tuoi script leggono porte, cartelle e nomi da un file di configurazione, e quel file lo modificano anche altre persone. Prima o poi qualcuno ci scriverà qualcosa di strano, per errore o di proposito.
> - **`source`** (inglese, «fonte»): il comando che esegue un file nella shell corrente, come se le sue righe fossero scritte lì.
> - **Libreria** (dall'inglese *library*, «biblioteca»): un file di funzioni pronte, che altri script caricano invece di riscriverle.
> - **Chiamante**: lo script che usa la funzione.
>
> **Perché conta.** Un file di configurazione eseguito come codice esegue tutto ciò che contiene. Un valore scritto male, o di proposito, diventa un comando, e gira con i permessi di chi lancia lo script.

**Compito.** `carica-conf.sh` è una libreria: definisce la funzione `carica_conf FILE NOME`, che riempie l'array associativo chiamato `NOME`, già dichiarato dal chiamante:

```sh
source ./carica-conf.sh
declare -A conf
carica_conf dati/app.conf conf
echo "${conf[PORTA]}"
```

- Righe vuote e `#` si ignorano, come gli spazi all'inizio di una riga.
- La chiave è fatta di lettere, cifre e `_`, e non inizia con una cifra. Il valore è tutto ciò che segue il primo `=`; se è chiuso fra virgolette doppie o singole, si tolgono.
- Il valore non si interpreta mai: `$(...)`, `$HOME` e `*` restano testo.
- Una riga non valida si salta con `riga N: ...` su stderr; alla fine la funzione restituisce 2. File illeggibile: restituisce 1 e lascia l'array com'era. Altrimenti 0.
- La funzione non crea né modifica altre variabili globali, non chiude mai la shell del chiamante, e funziona **qualunque nome** abbia l'array del chiamante.

**Verifica.** `../../verifica.sh 16 4`

> [!question]- Indizio 1
> La funzione riceve il *nome* di un array, cioè una stringa. Come fa a scrivere nell'array che ha quel nome? `help declare`: cosa fa l'opzione `-n`?

> [!question]- Indizio 2
> Prova a chiamare l'array del chiamante con lo stesso nome che hai usato per una variabile locale dentro la funzione. Cosa succede? Come lo eviti, visto che non sai che nomi userà il chiamante?

> [!question]- Indizio 3
> `exit` o `return`? Hai già risposto nella lezione 06. E le variabili che usi dentro, come restano dentro?

**Dopo.** Cosa farebbe `source dati/app.conf`? Che differenza c'è fra la tua funzione e `eval "$riga"`? Le variabili in bash hanno visibilità *dinamica*: una variabile `local` di una funzione è visibile nelle funzioni che lei chiama? Provalo. Perché questo rende i nameref pericolosi?

---

## Diario

Domande numerate, risposte e correzioni di questa lezione.

## Sintesi

Da scrivere a lezione finita, con le tue parole.

---

← [[04-testo-come-dati|Lezione 04]] · ↑ [[00-percorso|Il percorso]] · → [[17-regex|Lezione 17]]
