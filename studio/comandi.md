# Lezione: Comandi essenziali di Linux/Unix  
## Organizzata secondo fili logici

> **Nota**: questa lezione riorganizza il sommario del Cap. 103 in un percorso didattico coerente. Non sostituisce un formulario completo per l’esame, ma offre una struttura mentale per ricordare e usare i comandi.

---

## Obiettivi della lezione
Al termine, lo studente saprà:
- orientarsi nel filesystem e documentarsi sui comandi;
- gestire file, directory, archivi e copie di sicurezza;
- leggere e manipolare file di testo;
- controllare i flussi di input/output e collegare comandi;
- monitorare e gestire processi e risorse;
- personalizzare l’ambiente con alias e cronologia.

## Prerequisiti
- Nozioni di base su terminale, prompt, comandi, opzioni e argomenti.
- Concetti elementari di filesystem (directory, percorso assoluto/relativo).

---

# Filo logico 1 — Orientarsi e documentarsi

**Idea guida**: prima di agire, bisogna sapere *dove siamo*, *cosa abbiamo intorno* e *come chiedere aiuto*.

### 1.1 Posizione e contenuto
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

### 1.2 Informazioni sul sistema
| Comando | Significato |
|--------|-------------|
| `uname -a` | Mostra tutte le informazioni sul kernel in esecuzione. |
| `uname -r` | Mostra solo il numero di versione del kernel. |

**Esempio**
```bash
uname -r     # 6.8.0-45-generic
```

### 1.3 Aiuto in linea
| Comando | Significato |
|--------|-------------|
| `man <comando>` | Apre il manuale utente del comando. Non esiste per i comandi *shell builtin*. |
| `<comando> --help` | Mostra un aiuto sintetico. Spesso presente anche per i builtin. |

**Esempio**
```bash
man ls
ls --help
```

> **Collegamento**: una volta saputo dove siamo e come ottenere aiuto, possiamo iniziare a modificare l’ambiente.

---

# Filo logico 2 — Gestire file e directory

**Idea guida**: creare, copiare, spostare, eliminare, cercare e proteggere i dati.

### 2.1 Operazioni fondamentali
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

### 2.2 Dimensione e integrità
| Comando | Significato |
|--------|-------------|
| `du -sh folder` | Dimensione totale della directory `folder`, inclusi i file contenuti. |
| `md5sum file` | Calcola l’MD5 di `file`; utile per confrontare copie e verificarne l’integrità. |

**Esempio**
```bash
du -sh progetto
md5sum progetto/src/main.c
```

### 2.3 Ricerca nel filesystem
| Comando | Significato |
|--------|-------------|
| `find / -iname "ciao"` | Cerca in tutto il filesystem i file chiamati `ciao`, ignorando maiuscole/minuscole. |

**Esempio**
```bash
find /home -iname "*.pdf"
```

### 2.4 Archivi e compressione
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

### 2.5 Clonazione bit a bit
| Comando | Significato |
|--------|-------------|
| `dd if=/file of=new` | Copia bit a bit `file` in `new`; spesso usato per clonare supporti di memorizzazione. |

**Esempio**
```bash
dd if=/dev/sdb of=backup_usb.img
```

> **Collegamento**: gestire file significa anche saperne leggere e modificare il contenuto testuale.

---

# Filo logico 3 — Leggere e manipolare testo

**Idea guida**: estrarre, contare, visualizzare e suddividere dati testuali in modo efficiente.

### 3.1 Visualizzazione e conteggio
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

### 3.2 Estrazione di colonne
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

#### Cambiare il delimitatore in uscita

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

### 3.3 File compressi senza decomprimere
| Comando | Significato |
|--------|-------------|
| `zcat file.txt.gz` | Visualizza un file compresso `.gz`. |
| `bzcat file.txt.bz2` | Visualizza un file compresso `.bz2`. |
| `xzcat file.txt.xz` | Visualizza un file compresso `.xz`. |

**Esempio**
```bash
zcat log.gz | head -n 20
```

### 3.4 Suddivisione e ricomposizione
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

> **Collegamento**: per combinare più comandi e gestire l’output, servono i flussi di dati.

---

# Filo logico 4 — Controllare i flussi: redirezione e pipe

**Idea guida**: ogni comando ha input, output ed errori; possiamo reindirizzarli e concatenare comandi.

### 4.1 Redirezione dell’output e degli errori
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

### 4.2 Pipe
| Comando | Significato |
|--------|-------------|
| `prog1 \| prog2` | Collega l’output di `prog1` all’input di `prog2`. |

**Esempio**
```bash
ls -l | wc -l          # conta quanti file/righe elenca ls
cat /etc/passwd | cut -d ':' -f1 | head -n 5
```

> **Collegamento**: ora sappiamo combinare comandi, ma dobbiamo anche saper gestire i processi che li eseguono.

---

# Filo logico 5 — Governare processi e risorse

**Idea guida**: spostare processi in background, monitorare l’uso di CPU/RAM/disco, terminare processi in modo controllato.

### 5.1 Background e foreground
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

### 5.2 Monitoraggio
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

### 5.3 Esecuzione persistente e terminazione
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

> **Collegamento**: per lavorare più rapidamente, possiamo personalizzare la shell con alias e cronologia.

---

# Filo logico 6 — Personalizzare l’ambiente: alias, history e type

**Idea guida**: ridurre la digitazione, recuperare comandi passati e capire che tipo di comando stiamo usando.

### 6.1 Alias e identificazione dei comandi
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

### 6.2 Cronologia dei comandi
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

# Mappa riassuntiva dei fili logici

```
1. Orientarsi e documentarsi
   ├─ pwd, ls, cd
   ├─ uname -a, uname -r
   └─ man, --help

2. Gestire file e directory
   ├─ cp, mv, rm, mkdir
   ├─ du -sh, md5sum
   ├─ find
   ├─ gzip, gunzip, tar, dd
   └─ (split/cat per file grandi)

3. Leggere e manipolare testo
   ├─ head, tail, wc, less
   ├─ cut
   ├─ zcat, bzcat, xzcat
   └─ split, cat

4. Controllare i flussi
   ├─ >, 2>, &>, <
   └─ |

5. Governare processi e risorse
   ├─ CTRL+z, jobs, fg
   ├─ ps aux, top/htop, free, df, iotop
   ├─ nohup
   └─ kill, killall

6. Personalizzare l’ambiente
   ├─ alias, type
   └─ history, CTRL+r, !!, !$
```

---

## Esercizi guida (facoltativi, per fissare i fili)

1. **Orientamento**: crea una directory `lezione`, entraci, verifica con `pwd` e `ls`.
2. **File**: copia un file di testo in `lezione`, rinominalo, calcola `md5sum` prima e dopo una modifica.
3. **Testo**: estrai la prima colonna da un file con separatore `:`, conta le righe e mostra le prime 5.
4. **Flussi**: salva l’output di `ls -l` in `elenco.txt`, poi filtra con `grep` (se noto) o `wc -l`.
5. **Processi**: avvia `sleep 200`, sospendilo con `CTRL+z`, elenca con `jobs`, riprendilo con `fg`.
6. **Personalizzazione**: crea l’alias `ll='ls -l'`, verifica con `type ll`, poi richiama l’ultimo argomento con `!$`.

---

## Conclusione
I comandi del Cap. 103 non sono un elenco casuale: seguono un **flusso di lavoro reale**:
1. mi orientо e mi documento;
2. gestisco i file;
3. manipolo i contenuti;
4. controllo i flussi;
5. governо i processi;
6. ottimizzo il mio ambiente.

Questa struttura logica aiuta a ricordare i comandi e a scegliere quello giusto al momento giusto.
