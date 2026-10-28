---
tags:
  - comandi
  - nota
aliases:
  - Manipolare testo
---
# Manipolare testo

**Idea guida**: estrarre, contare, visualizzare e suddividere dati testuali in modo efficiente.

## 3.1 Visualizzazione e conteggio
| Comando | Significato |
|--------|-------------|
| `head -n 10 file.txt` | Mostra le prime 10 righe. |
| `tail -n 10 file.txt` | Mostra le ultime 10 righe. |
| `wc -l file.txt` | Conta le righe. |
| `wc -c file.txt` | Conta i caratteri. |
| `less file.txt` | Visualizza il file poco per volta; frecce su/giù per navigare. |

**Esempio**
```bash
head -n 5 registro.log
tail -n 20 registro.log
wc -l registro.log
less registro.log
```

## 3.2 Estrazione di colonne
| Comando | Significato |
|--------|-------------|
| `cut -d ':' -f 1 ab.txt` | Imposta `:` come separatore e stampa la prima colonna. |
| `cut -d ':' -f1,7 ab.txt` | Stampa le colonne 1 e 7. |

**Esempio**
```bash
cut -d ':' -f1 /etc/passwd     # nomi utente
```
Estrarre dal campo 2 fino alla fine

```bash
cut -d ':' -f2- utenti.txt

```

Output:

```text
rossi:30:roma
bianchi:25:milano
verdi:40:torino
```

`-f2-` = dal campo 2 in poi.

### Cambiare il delimitatore in uscita

```bash
cut -d ':' -f1,3 --output-delimiter=' | ' utenti.txt
```

Output:

```text
mario | 30
luisa | 25
anna | 40
```

Utile per rendere l’output più leggibile.

## 3.3 File compressi senza decomprimere
| Comando | Significato |
|--------|-------------|
| `zcat file.txt.gz` | Visualizza un file compresso `.gz`. |
| `bzcat file.txt.bz2` | Visualizza un file compresso `.bz2`. |
| `xzcat file.txt.xz` | Visualizza un file compresso `.xz`. |

**Esempio**
```bash
zcat log.gz | head -n 20
```

## 3.4 Suddivisione e ricomposizione
| Comando | Significato |
|--------|-------------|
| `split -l 100 file.txt` | Divide `file.txt` in file da 100 righe ciascuno. |
| `split -b 5m video.mp4` | Divide un file binario in porzioni da 5 MB. |
| `cat video* > unito.mp4` | Unisce tutti i file con prefisso `video` in `unito.mp4`. |

**Esempio**
```bash
split -l 500 grande.txt parte_
cat parte_* > grande_ricomposto.txt
```

---

**Area:** [[mappa-comandi|Comandi]]  
**Fonte:** [[lezione-comandi-essenziali|Lezione — Comandi essenziali]]  
**Vedi anche:** [[redirezione-pipe|Redirezione e pipe]] · [[file-directory|File e directory]]
