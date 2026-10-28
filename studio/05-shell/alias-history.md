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

---

**Area:** [[mappa-shell|Shell]]  
**Fonte:** [[lezione-comandi-essenziali|Lezione — Comandi essenziali]]  
**Vedi anche:** [[comandi-ricerca|Comandi di ricerca]] · [[tipi-di-shell|Tipi di shell e su]]
