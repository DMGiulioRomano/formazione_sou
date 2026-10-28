---
tags:
  - lezione
aliases:
  - Lezione — Comandi essenziali
---
# Lezione — Comandi essenziali

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

## Percorso

1. **Orientarsi e documentarsi** → [[orientarsi-documentarsi|Orientarsi e documentarsi]]

> **Collegamento**: una volta saputo dove siamo e come ottenere aiuto, possiamo iniziare a modificare l’ambiente.

2. **Gestire file e directory** → [[file-directory|File e directory]], [[comandi-ricerca|Comandi di ricerca]], [[hashsum|Hash e checksum]]

> **Collegamento**: gestire file significa anche saperne leggere e modificare il contenuto testuale.

3. **Leggere e manipolare testo** → [[manipolare-testo|Manipolare testo]]

> **Collegamento**: per combinare più comandi e gestire l’output, servono i flussi di dati.

4. **Controllare i flussi** → [[redirezione-pipe|Redirezione e pipe]]

> **Collegamento**: ora sappiamo combinare comandi, ma dobbiamo anche saper gestire i processi che li eseguono.

5. **Governare processi e risorse** → [[gestione-processi|Gestione dei processi]]

> **Collegamento**: per lavorare più rapidamente, possiamo personalizzare la shell con alias e cronologia.

6. **Personalizzare l'ambiente** → [[alias-history|Alias e history]]

## Mappa riassuntiva dei fili logici

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

### Esercizi guida (facoltativi, per fissare i fili)

1. **Orientamento**: crea una directory `lezione`, entraci, verifica con `pwd` e `ls`.
2. **File**: copia un file di testo in `lezione`, rinominalo, calcola `md5sum` prima e dopo una modifica.
3. **Testo**: estrai la prima colonna da un file con separatore `:`, conta le righe e mostra le prime 5.
4. **Flussi**: salva l’output di `ls -l` in `elenco.txt`, poi filtra con `grep` (se noto) o `wc -l`.
5. **Processi**: avvia `sleep 200`, sospendilo con `CTRL+z`, elenca con `jobs`, riprendilo con `fg`.
6. **Personalizzazione**: crea l’alias `ll='ls -l'`, verifica con `type ll`, poi richiama l’ultimo argomento con `!$`.

---

### Conclusione
I comandi del Cap. 103 non sono un elenco casuale: seguono un **flusso di lavoro reale**:
1. mi orientо e mi documento;
2. gestisco i file;
3. manipolo i contenuti;
4. controllo i flussi;
5. governо i processi;
6. ottimizzo il mio ambiente.

Questa struttura logica aiuta a ricordare i comandi e a scegliere quello giusto al momento giusto.

---

↑ [[00-home|Home]]
