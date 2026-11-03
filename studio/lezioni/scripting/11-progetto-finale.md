---
tags:
  - lezione
  - scripting
aliases:
  - Scripting 11 — Progetto finale
---
# Scripting 11 — Progetto finale

Niente è più guidato: due programmi da progettare da soli, mettendo insieme tutto il percorso. Qui contano le decisioni di progetto: prima di scrivere codice si discute la struttura, e la discussione si aggiunge al diario.

```sh
./prepara.sh 11 && cd palestra/l11
```

## La mappa

| # | Problema | Stato |
|---|---|---|
| 1 | `sentinella.sh` — il tuo sistema di controllo | — |
| 2 | `makecmd.sh` — rifare un pezzo di `make` | — |

---

## Problema 1 — `sentinella.sh`

**Situazione.** Hai scritto controlli sparsi. Ora ne vuoi uno solo, guidato da un file di configurazione, da lanciare ogni cinque minuti su qualsiasi macchina. In azienda lo fanno Nagios e simili: la logica di base la puoi capire scrivendola.

**Compito.** `./sentinella.sh [-q] [-c FILE]`, con configurazione predefinita `dati/sentinella.conf`. Ogni riga è un controllo; righe vuote e `#` si ignorano.

| Riga | Stato |
|---|---|
| `disco MOUNT AVVISO CRITICO` | In base all'uso, secondo `df -P MOUNT` |
| `file PERCORSO` | `OK` se esiste, altrimenti `CRITICAL` |
| `processo NOME` | `OK` se c'è un processo con esattamente quel nome, altrimenti `CRITICAL` |
| `comando RESTO DELLA RIGA` | `OK` se il comando riesce, altrimenti `CRITICAL`. Il suo output non si mostra |

Per ogni controllo, nell'ordine del file, stampa `STATO tipo parametri`. Il disco mostra solo il mount:

```text
OK disco /
WARNING disco /var
CRITICAL file /non/esiste
OK comando sh -c "exit 0"
```

- `-q` mostra solo ciò che non è `OK`.
- Il codice di uscita è il peggiore trovato: 0, 1 per `WARNING`, 2 per `CRITICAL`.
- Una riga di tipo sconosciuto ferma tutto **prima** di ogni controllo: niente su stdout, numero di riga su stderr, codice 3.
- Configurazione mancante o opzione sconosciuta: codice 3.

**Verifica.** `../../verifica.sh 11 1`

**Per finire.** Fallo girare ogni 5 minuti con un timer e registra i risultati nel journal. Fai un guasto vero nella VM, come un disco riempito con `dd` o un servizio fermato, e verifica di vederlo.

> [!question]- Indizio 1
> Quante letture del file di configurazione servono, per rispettare la regola sul tipo sconosciuto? Cosa aggiungi quando arriverà un quinto tipo di controllo: quante righe devi toccare?

> [!question]- Indizio 2
> Come fa una funzione di controllo ad aggiornare «il peggiore finora»? Se metti il controllo in una pipe o in `$( )`, la variabile sopravvive? Perché?

> [!question]- Indizio 3
> `comando sh -c "exit 0"` ha delle virgolette che stanno nel testo del file. Chi le interpreta, se le lasci a una variabile? Quale comando rifà leggere una stringa alla shell, e che rischio comporta in un file di configurazione?

> [!question]- Indizio 4
> Un comando del file può leggere dallo stesso stdin del tuo ciclo. Cosa succederebbe alle righe successive? Come lo isoli? Rileggi [[while-read|while read]].

**Dopo.** Chi può scrivere il file di configurazione, dato che esegue comandi? Se il controllo stesso resta appeso, cosa succede? Hai già scritto la soluzione nella lezione 09: integrala. Cosa manca a questo strumento rispetto a Nagios, per esempio sugli avvisi ripetuti?

---

## Problema 2 — `makecmd.sh`

**Situazione.** Usi `make` da tempo, con il `Makefile` di questo repo. La sua idea centrale è piccola e bella: rifai il lavoro solo se serve. La ricostruisci in shell.

**Compito.** `./makecmd.sh` legge da stdin una regola:

```text
report.txt: a.txt b.txt
	cat a.txt b.txt > report.txt
	echo fatto
```

- La prima riga ha la forma `bersaglio: dipendenze`. Se non contiene `:`, codice 2.
- Le altre, che iniziano con una tabulazione, sono comandi. Si eseguono solo se il bersaglio manca o se una dipendenza esistente è più recente. Le dipendenze assenti si ignorano.
- Ogni comando si stampa senza tabulazione e poi si esegue, come fa `make`. Redirezioni comprese.
- Se un comando fallisce ci si ferma, col suo codice.

**Verifica.** `../../verifica.sh 11 2`, e prova con `./makecmd.sh < dati/regola.txt` in una cartella con i due file.

> [!question]- Indizio 1
> `read` di norma mangia spazi e tabulazioni iniziali, ed elabora le barre. Rileggi la tabella delle opzioni in [[while-read|while read]]. Cosa ti serve conservare?

> [!question]- Indizio 2
> Quale test del manuale, al capitolo 7.2, confronta l'età di due file?

> [!question]- Indizio 3
> In una variabile c'è `cat a > b`. Eseguendola con `$comando`, `>` è una redirezione? Perché no? In quale fase la shell riconosce le redirezioni, rispetto all'espansione delle variabili?

**Dopo.** Il vero `make` confronta la data con quale risoluzione? Cosa succede a chi fa partire l'orologio indietro? Perché ogni riga di una ricetta di `make` gira in una shell separata, e la tua no? Prova `cd` su una riga e `pwd` sulla successiva, in entrambi.

---

## Diario

Decisioni di progetto, domande, risposte e correzioni di questa lezione.

## Sintesi

Da scrivere alla fine, con le tue parole: cosa rifaresti diversamente, e cosa useresti al posto di bash per un programma più grande.

---

← [[10-automazione|Lezione 10]] · ↑ [[00-percorso|Il percorso]]
