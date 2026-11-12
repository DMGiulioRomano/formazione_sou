---
tags:
  - shell
aliases:
  - Codici di uscita e set -e
---
# Codici di uscita e `set -e`

Ogni comando, finendo, restituisce al processo padre un numero da 0 a 255: il **codice di uscita** (*exit status*). 0 vuol dire riuscito, qualsiasi altro numero fallito. La shell lo conserva in `$?`, che vale per il comando appena finito.

## Da dove viene il codice

| Caso | Codice |
| --- | --- |
| comando semplice | quello del comando |
| pipeline `a \| b` | quello dell'ultimo comando (salvo `set -o pipefail`) |
| `a \|\| b`, `a && b` | quello dell'ultimo comando eseguito |
| script senza `exit` | quello dell'ultimo comando eseguito |
| `exit N` | N |
| assegnazione `x=valore` | 0 |
| assegnazione con `$( )`, `x=$(cmd)` | quello dell'ultima sostituzione di comando, cioè di `cmd` |

L'ultima riga è il caso sorprendente: `x=$(false); echo $?` stampa 1. L'assegnazione in sé non fallisce, ma bash le dà il codice dell'ultima `$( )` che ha eseguito (manuale di bash, *Simple Command Expansion*).

Attenzione: con `local x=$(cmd)` o `export x=$(cmd)` il codice è quello di `local` o `export`, cioè 0. Il fallimento di `cmd` si perde.

## `$( )` e la subshell

`$( )` (*command substitution*, sostituzione di comando) esegue il comando in una **subshell**, una copia della shell creata con `fork`. La shell principale ne raccoglie l'output e il codice di uscita. La subshell è un processo separato: qualunque cosa faccia, non può far uscire la shell principale. `$BASHPID` mostra il PID della shell in cui ti trovi: `echo $BASHPID $(echo $BASHPID)` stampa due numeri diversi.

## `set -e`

`set` imposta le opzioni della shell; `-e` sta per *errexit*, «esci all'errore». Con `set -e` lo script esce appena un comando restituisce un codice diverso da 0, e il suo codice di uscita è quello del comando fallito. Vale anche per un'assegnazione con `$( )` che fallisce, perché ha il codice di quel comando.

Non scatta per i comandi il cui codice serve come condizione: la parte a sinistra di `&&` e `||`, la condizione di `if` e `while`, un comando preceduto da `!`. Per questo `[ -f "$1" ] || exit $?` resta lo strumento per decidere tu il codice con cui uscire.

Vedi anche: [[eseguire-uno-script|Eseguire uno script]], [[variabili-opzioni|Variabili e opzioni]].
