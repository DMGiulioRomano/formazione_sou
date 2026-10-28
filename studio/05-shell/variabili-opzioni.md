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
