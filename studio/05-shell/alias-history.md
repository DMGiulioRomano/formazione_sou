---
tags:
  - shell
  - nota
aliases:
  - Alias e history
---
# Alias e history

**Idea guida**: ridurre la digitazione, recuperare comandi passati e capire che tipo di comando stiamo usando.

## 6.1 Alias e identificazione dei comandi
| Comando | Significato |
|--------|-------------|
| `alias <abbreviazione>='<comando completo>'` | Crea un alias. |
| `type <comando>` | Distingue se il comando è un alias, un builtin della shell o un eseguibile su disco. |

**Esempio**
```bash
alias ll='ls -l'
type ll        # ll è un alias di ls -l
type cd        # cd è un builtin della shell
type ls        # ls è /usr/bin/ls
```

## 6.2 Cronologia dei comandi
| Comando / scorciatoia | Significato |
|----------------------|-------------|
| `history` | Mostra i comandi digitati in precedenza. |
| `history -c` | Pulisce la cronologia. |
| `CTRL+r` | Avvia la ricerca nella cronologia. |
| `!!` | Esegue nuovamente l’ultimo comando. |
| `!$` | Richiama l’ultimo parametro dell’ultimo comando. |

**Esempio**
```bash
mkdir nuova_cartella
cd !$          # equivale a: cd nuova_cartella
```

## 6.3 Dove finisce la cronologia
- **Il file:** `HISTFILE`, predefinito `~/.bash_history`. Durante la sessione la cronologia sta in memoria; bash la scrive **all'uscita** e, senza `shopt -s histappend`, sovrascrive il file. Con due terminali vince l'ultimo chiuso; con un `kill -9` la sessione va persa. `history -a` scrive subito le righe nuove.
- **`HISTTIMEFORMAT`** (*HISTory TIME FORMAT*): formato per `strftime(3)`, gli stessi segnaposto di `date +…`. Se ha un valore, `history` mostra l'ora; se esiste, nel file compare prima di ogni comando una riga `#<epoch>`, così l'ora sopravvive alla sessione. Di base non esiste: `declare -p HISTTIMEFORMAT` lo distingue da una variabile vuota.
- **`HISTCONTROL`**: lista separata da `:`.

| Valore | Effetto |
|---|---|
| `ignorespace` | non annota le righe che iniziano con uno spazio |
| `ignoredups` | non annota una riga uguale a quella subito prima |
| `ignoreboth` | `ignorespace:ignoredups` |
| `erasedups` | cancella le copie precedenti, tiene l'ultima |

La cronologia annota **righe**, non comandi: `echo a; echo a` è una voce sola.

**Rischio:** un segreto scritto sulla riga di comando (`mysql -p'…'`) finisce in chiaro nel file; uno spazio davanti con `ignorespace` lo evita, ma solo per la cronologia, non per un registro come quello di `riesegui.sh`.

---

**Area:** [[mappa-shell|Shell]]  
**Fonte:** [[lezione-comandi-essenziali|Lezione — Comandi essenziali]]  
**Vedi anche:** [[comandi-ricerca|Comandi di ricerca]] · [[tipi-di-shell|Tipi di shell e su]]
