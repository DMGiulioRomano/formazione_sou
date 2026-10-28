---
tags:
  - comandi
  - nota
aliases:
  - File e directory
---
# File e directory

**Idea guida**: creare, copiare, spostare, eliminare, cercare e proteggere i dati.

## 2.1 Operazioni fondamentali
| Comando | Significato |
|--------|-------------|
| `cp file.txt new.txt` | Crea una copia di `file.txt` chiamata `new.txt`. |
| `cp -r cart1 cart2` | Copia ricorsivamente la directory `cart1` in `cart2`. |
| `mv old new` | Rinomina `old` in `new`. |
| `mv old Desktop/new` | Sposta `old` sul Desktop e lo rinomina `new`. |
| `rm file.txt` | Elimina `file.txt`. |
| `rm -r folder` | Elimina ricorsivamente la directory `folder` e il suo contenuto (`-f` forza l’operazione). |
| `mkdir folder` | Crea la directory `folder`. |
| `mkdir -p folder/ciao` | Crea `folder` e, al suo interno, `ciao` con un solo comando. |

**Esempio**
```bash
mkdir -p progetto/src
cp progetto/src/main.c progetto/src/main_backup.c
mv progetto/src/main_backup.c progetto/backup/
```

## 2.2 Dimensione e integrità
| Comando | Significato |
|--------|-------------|
| `du -sh folder` | Dimensione totale della directory `folder`, inclusi i file contenuti. |
| `md5sum file` | Calcola l’MD5 di `file`; utile per confrontare copie e verificarne l’integrità. |

**Esempio**
```bash
du -sh progetto
md5sum progetto/src/main.c
```

## 2.4 Archivi e compressione
| Comando | Significato |
|--------|-------------|
| `gzip file` | Comprime `file` in `file.gz`, **eliminando l’originale**. |
| `gunzip file.gz` | Estrae `file.gz`, **eliminando la versione compressa**. |
| `tar -czf var.tar.gz var` | Comprime la directory `var` in `var.tar.gz`. |
| `tar -xzf var.tar.gz` | Estrae l’archivio `var.tar.gz` nella directory corrente. |

**Esempio**
```bash
tar -czf backup_progetto.tar.gz progetto
tar -xzf backup_progetto.tar.gz
```

## 2.5 Clonazione bit a bit
| Comando | Significato |
|--------|-------------|
| `dd if=/file of=new` | Copia bit a bit `file` in `new`; spesso usato per clonare supporti di memorizzazione. |

**Esempio**
```bash
dd if=/dev/sdb of=backup_usb.img
```

## Analisi dimensioni directory (lezione 4)

```bash
# Dimensione totale cartella
du -sh /home/utente

# Dettaglio di tutte le sottocartelle
du -h

# Aiuto
du --help
```

---

**Area:** [[mappa-comandi|Comandi]]  
**Fonte:** [[lezione-comandi-essenziali|Lezione — Comandi essenziali]] · [[lezione-4-installazione-pacchetti|Lezione 4 — Installazione e package management]]  
**Vedi anche:** [[hashsum|Hash e checksum]] · [[comandi-ricerca|Comandi di ricerca]] · [[manipolare-testo|Manipolare testo]] · [[swap|Swap]] · [[fhs|FHS]]
