---
tags:
  - shell
  - nota
aliases:
  - Variabili e opzioni della shell
---
# Variabili e opzioni della shell

## Variabili

```bash
pino=1
export pino
```

Quando le definisco normalmente sono locali. Ho bisogno di `export` per renderle globali.

Oppure la creo direttamente come globale:

```bash
export varGlob=1
```

Come le eliminiamo le variabili? Uso `unset`.

Ovviamente anche se globali sono valide nella sessione corrente: quando chiudo il terminale si eliminano.

## Espansioni

Prima di eseguire una riga, la shell sostituisce le espressioni con il loro valore.

| Scrittura | Diventa |
|-----------|---------|
| `"uname -r"` | il testo `uname -r`, così com'è: fra virgolette non parte nessun comando |
| `$(uname -r)` | l'output del comando (*command substitution*) |
| `${var#prefisso}` | il valore di `var` senza `prefisso` all'inizio (*parameter expansion*). Funziona solo su una variabile, quindi l'output di un comando va salvato prima. |

```bash
krn=kernel-5.14.0-687; echo "${krn#kernel-}"    # 5.14.0-687
```

### Virgolette dentro [ ]

`[` è un comando e riceve gli argomenti dopo le espansioni. Una variabile vuota senza virgolette **sparisce** dalla riga:

```bash
v=""
[ abc = $v ]      # [ riceve: abc =  -> errore "atteso operatore unario"
[ abc = "$v" ]    # [ riceve: abc = "" -> falso, senza errori
```

Dopo l'errore l'`if` va comunque nel ramo `else`, quindi la risposta sembra valida. Le variabili dentro `[ ]` vanno sempre fra virgolette.

## Opzioni della shell

Ma io posso attivare delle opzioni della shell con `set`.

La logica dei simboli meno (`-`) e più (`+`) può sembrare al contrario a prima vista, ma funziona così:

- `set -o nome_opzione`: **ATTIVA** (accende) l'opzione.
- `set +o nome_opzione`: **DISATTIVA** (spegne) l'opzione.

### Shell options

Ho anche `shopt` (abbreviazione di *shell options*): è un comando integrato della shell Bash che serve ad attivare, disattivare e mostrare le opzioni avanzate della shell.

A differenza del comando `set` (usato per le opzioni standard POSIX), `shopt` gestisce funzionalità specifiche di Bash che modificano il comportamento dei comandi, del completamento automatico e della gestione dei file.

> **Nota:** non è uno standard POSIX, quindi non è presente in tutte le shell Unix. Solo in Bash.

---

**Area:** [[mappa-shell|Shell]]  
**Vedi anche:** [[tipi-di-shell|Tipi di shell e su]] · [[path|PATH]]
