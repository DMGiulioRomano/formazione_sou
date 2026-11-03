---
tags:
  - shell
  - nota
aliases:
  - Come funziona una pipe
  - Pipe
---
# Come funziona una pipe

**Idea guida**: una pipe è una coda di byte gestita dal kernel, fra due processi che girano contemporaneamente e non sanno l'uno dell'altro. La sintassi di base è in [[redirezione-pipe|Redirezione e pipe]].

```
find  --stdout-->  [ pipe ]  --stdin-->  head
```

## Chi fa cosa

La pipe è un meccanismo del **kernel**. La shell offre solo il simbolo `|` e prepara i collegamenti:

1. `pipe()` chiede al kernel il buffer e due [[file-descriptor|file descriptor]], uno per scrivere e uno per leggere.
2. `fork()` crea i due processi.
3. `dup2()` collega lo stdout del primo al lato di scrittura e lo stdin del secondo al lato di lettura.
4. `exec()` avvia i programmi.

I due comandi lavorano insieme: la pipe non aspetta che il comando a monte abbia finito, ma passa il flusso di byte man mano che viene generato.

Poi la shell aspetta che finiscano: i byte passano attraverso il kernel, non attraverso la shell. Infatti una pipe si può creare anche senza shell:

```python
import os

r, w = os.pipe()         # chiede la pipe al kernel
os.write(w, b"ciao\n")
print(os.read(r, 100))   # b'ciao\n'
```

## Cosa contiene

Solo byte, uno dopo l'altro, non elementi distinti: la pipe non sa dove iniziano e finiscono le cose. Per lei il `\n` è un byte come gli altri: le righe esistono solo per chi legge.

```
lista:  [".zshrc", ".vimrc"]               # 2 elementi
pipe:   . z s h r c \n . v i m r c \n      # 14 byte
```

Internamente è un **buffer circolare**: memoria di dimensione fissa con una posizione di scrittura e una di lettura, che arrivate in fondo ripartono dall'inizio. Il comportamento è quello di una coda FIFO (*first in, first out*). Grazie a questa struttura il kernel non deve spostare i dati a ogni lettura: gli basta far avanzare la posizione di lettura.

```
        lettura        scrittura
           v              v
[ _ _ _ _  . v i m r c \n _ _ _ _ ]
  liberi   non ancora letti  liberi
```

## Perché i dati non si sovrascrivono

Chi scrive aggiunge in coda e chi legge preleva dalla testa. Lo spazio torna riutilizzabile solo dopo la lettura, quindi i byte non ancora letti restano protetti.

Se un processo è più veloce dell'altro, il kernel lo sospende. Questo meccanismo si chiama **backpressure**:

| Situazione | Cosa succede |
|------------|--------------|
| Pipe piena | chi scrive viene sospeso finché non si libera spazio |
| Pipe vuota, scrittore attivo | chi legge viene sospeso finché non arrivano byte |
| Pipe vuota, scrittore terminato | chi legge riceve la fine dell'input |
| Lettore terminato | chi scrive riceve il segnale `SIGPIPE` |

Sul mio Mac la capienza misurata è di 65536 byte (64 KiB).

**Esempio**: il produttore è veloce e il consumatore impiega un secondo per riga. Le righe `scrivo` escono subito, le righe `letto` una al secondo, in ordine e senza perdite.

```bash
for i in 1 2 3; do echo "scrivo $i" >&2; echo $i; done |
  while read -r l; do sleep 1; echo "letto $l"; done
```

## Più pipe in fila

Ogni `|` crea una pipe separata, e ogni comando legge solo da quella alla sua sinistra:

```
find --pipe 1--> while read ... done --pipe 2--> head -60 --> terminale
```

`head -60` copia i byte in uscita finché non ha contato 60 `\n`, poi termina. Da lì la chiusura si propaga all'indietro:

1. `head` termina e il lato di lettura della pipe 2 si chiude.
2. Alla scrittura successiva il ciclo riceve `SIGPIPE` e termina.
3. Nessuno legge più la pipe 1: alla scrittura successiva `find` riceve `SIGPIPE`.

Per questo anche un comando infinito si ferma subito. In bash si vede dai codici di uscita: `141` significa 128 + 13, dove 13 è il numero di `SIGPIPE`.

```bash
yes | head -3 >/dev/null; echo "${PIPESTATUS[@]}"    # 141 0
```

## Cosa non è

| Non è | Perché |
|-------|--------|
| Un file | è un buffer in memoria che si consuma leggendolo |
| Una lista | contiene byte, non elementi |
| Una funzione di bash | la fornisce il kernel; ogni shell la usa con `\|` |
| Un dialogo client-server | va in una sola direzione, senza richieste né risposte, e i processi non si cercano: li collega la shell |

L'immagine più vicina è un **nastro trasportatore**: un operaio appoggia i pezzi da un lato, un altro li prende dall'altro, e nessuno dei due parla con l'altro. Lo schema si chiama **produttore e consumatore**.

---

**Area:** [[mappa-shell|Shell]]  
**Vedi anche:** [[file-descriptor|File descriptor]] · [[while-read|Leggere righe con while read]] · [[redirezione-pipe|Redirezione e pipe]] · [[gestione-processi|Gestione dei processi]] · [[kernel|Kernel Linux]]
