---
tags:
  - comandi
  - nota
aliases:
  - Orientarsi e documentarsi
---
# Orientarsi e documentarsi

**Idea guida**: prima di agire, bisogna sapere *dove siamo*, *cosa abbiamo intorno* e *come chiedere aiuto*.

## 1.1 Posizione e contenuto
| Comando | Significato |
|--------|-------------|
| `pwd` | Mostra il percorso della directory corrente. |
| `ls` | Elenca il contenuto della directory corrente. |
| `cd Scrivania` | Sposta il terminale nella cartella `Scrivania` (deve esistere nella directory locale). |

**Esempio**
```bash
pwd          # /home/studente
ls           # Documenti  Scrivania  download
cd Scrivania
pwd          # /home/studente/Scrivania
```

## 1.2 Informazioni sul sistema
| Comando | Significato |
|--------|-------------|
| `uname -a` | Mostra tutte le informazioni sul kernel in esecuzione. |
| `uname -r` | Mostra solo il numero di versione del kernel. |

**Esempio**
```bash
uname -r     # 6.8.0-45-generic
```

## 1.3 Aiuto in linea
| Comando | Significato |
|--------|-------------|
| `man <comando>` | Apre il manuale utente del comando. Non esiste per i comandi *shell builtin*. |
| `<comando> --help` | Mostra un aiuto sintetico. Spesso presente anche per i builtin. |

**Esempio**
```bash
man ls
ls --help
```

---

**Area:** [[mappa-comandi|Comandi]]  
**Fonte:** [[lezione-comandi-essenziali|Lezione — Comandi essenziali]]  
**Vedi anche:** [[file-directory|File e directory]] · [[comandi-ricerca|Comandi di ricerca]] · [[kernel|Kernel Linux]]
