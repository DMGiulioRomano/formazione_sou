---
tags:
  - processi
  - nota
aliases:
  - Gestione dei processi
---
# Gestione dei processi

**Idea guida**: spostare processi in background, monitorare l’uso di CPU/RAM/disco, terminare processi in modo controllato.

## 5.1 Background e foreground
| Comando | Significato |
|--------|-------------|
| `CTRL+z` | Manda un processo in background e in pausa. |
| `jobs` | Mostra i processi in background. |
| `fg <n>` | Riporta in foreground il processo numero `n`. |

**Esempio**
```bash
sleep 100
# premi CTRL+z
jobs
fg 1
```

## 5.2 Monitoraggio
| Comando | Significato |
|--------|-------------|
| `ps aux` | Mostra tutti i processi in esecuzione. |
| `top` / `htop` | Mostra interattivamente i processi e l’uso delle risorse. |
| `free -m` | Mostra l’uso della memoria RAM in MB. |
| `df -h` | Mostra l’uso del disco per partizione in formato leggibile. |
| `iotop` | Mostra l’uso del disco (letture/scritture correnti e processi coinvolti). |

**Esempio**
```bash
ps aux | grep firefox
free -m
df -h
```

## 5.3 Esecuzione persistente e terminazione
| Comando | Significato |
|--------|-------------|
| `nohup <cmd>` | Esegue `cmd` in modo che non venga interrotto alla chiusura della shell o alla disconnessione. |
| `kill [-S] <pid>` | Termina il processo con un dato PID; `-S` specifica il segnale (es. `-15`, `-9`). |
| `killall <nome>` | Termina tutti i processi con un certo nome. |

**Esempio**
```bash
nohup ./server.sh &
kill -15 1234
killall firefox
```

---

**Area:** [[mappa-processi|Processi]]  
**Fonte:** [[lezione-comandi-essenziali|Lezione — Comandi essenziali]]  
**Vedi anche:** [[nice-renice|nice e renice]] · [[tmux|tmux]] · [[pseudo-filesystem-sys-proc|Pseudo-filesystem /sys e /proc]] · [[kernel|Kernel Linux]] · [[redirezione-pipe|Redirezione e pipe]]
