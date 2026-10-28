---
tags:
  - shell
  - nota
aliases:
  - Redirezione e pipe
---
# Redirezione e pipe

**Idea guida**: ogni comando ha input, output ed errori; possiamo reindirizzarli e concatenare comandi.

## 4.1 Redirezione dell’output e degli errori
| Comando | Significato |
|--------|-------------|
| `ls > out.txt` | Redirige l’output standard (stdout) di `ls` nel file `out.txt`. |
| `ls 2> err.txt` | Redirige gli errori standard (stderr) nel file `err.txt`. |
| `ls &> out.txt` | Redirige sia stdout sia stderr in `out.txt`. |
| `cat < in.txt` | Redirige l’input standard di `cat` da `in.txt`. |

**Esempio**
```bash
ls -l /etc > elenco.txt
ls /cartella_inesistente 2> errori.txt
```

## 4.2 Pipe
| Comando | Significato |
|--------|-------------|
| `prog1 \| prog2` | Collega l’output di `prog1` all’input di `prog2`. |

**Esempio**
```bash
ls -l | wc -l          # conta quanti file/righe elenca ls
cat /etc/passwd | cut -d ':' -f1 | head -n 5
```

---

**Area:** [[mappa-shell|Shell]]  
**Fonte:** [[lezione-comandi-essenziali|Lezione — Comandi essenziali]]  
**Vedi anche:** [[manipolare-testo|Manipolare testo]] · [[gestione-processi|Gestione dei processi]] · [[hashsum|Hash e checksum]]
