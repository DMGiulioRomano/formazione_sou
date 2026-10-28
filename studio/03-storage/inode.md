---
tags:
  - storage
  - nota
aliases:
  - Inode e scrittura dei file
---
# Inode e scrittura dei file

## Come funziona quando salvi un file
  
Quando salvi un file, il file system avvia una complessa operazione di scomposizione e registrazione, dividendo il lavoro in 3 fasi principali.
### La frammentazione in "cluster" (la scomposizione)

Siccome il file system lavora in cluster, ovvero blocchi logici di settori, prima capisce quanto spazio è necessario, poi va alla ricerca dei settori liberi anche distanti fra loro. È questo il motivo per cui si chiama frammentazione.
### Scrittura fisica sul disco

Il file system invia i comandi all'hardware, cioè alla testina dell'hard disk o ai chip della memoria SSD, e ordina di scrivere i dati suddivisi per cluster.

A questo livello, l'hardware ha scritto solo una sequenza di 0 e 1 magnetici o elettrici.
### La registrazione nell'indice centrale

Ogni file system ha un indice centrale, chiamato **MFT** su Windows NTFS o **Tabella degli inode** su Linux.

La tabella è fatta così:
```text

INODE: 125403

--------------------------------------------------------------------------

Tipo di file:      File regolare (non è una cartella o un link)

Permessi (Chmod):  rw-r--r-- (lettura/scrittura per il proprietario,

                   solo lettura per gli altri)

ID Proprietario:   1000 (utente: matteo)

ID Gruppo:         1000 (gruppo: users)

Dimensione:        245760 bytes (240 KB)

Conteggio Link:    1 (quanti nomi puntano a questo inode)

  

DATE E ORARI:

  Accesso (atime):  19 Ottobre 2026, 10:15:22

  Modifica (mtime): 19 Ottobre 2026, 12:30:00

  Cambio (ctime):   19 Ottobre 2026, 12:30:00

  

MAPPA DEI BLOCCHI FISICI (dove stanno i dati sul disco):

  [Blocco 0] -> Settore 4500123

  [Blocco 1] -> Settore 4500124

  [Blocco 2] -> Settore 4500125

  [Blocco 3] -> Settore 4580900  <-- (Vedi? Il file è frammentato, fa un salto!)

  [Blocco 4] -> Settore 4580901

--------------------------------------------------------------------------

```

  

L'inode contiene solo le proprietà del file, cioè chi lo possiede, quando è stato modificato e i permessi di sicurezza, oltre all'elenco esatto dei blocchi fisici di memoria in cui sono sparsi i pezzi del file.

## Come si collega la tabella degli inode ai file?

I file hanno ognuno il proprio inode, che non dipende dal nome del file o dalla sua posizione. È un identificativo numerico.

Infatti, quando cambi la posizione del file o lo rinomini, cambia solo la posizione all'interno della cartella in cui lo posizioni o il suo nome nel file della cartella, ma l'inode rimane lo stesso.

---

**Area:** [[mappa-storage|Storage]]  
**Vedi anche:** [[filesystem|Filesystem]] · [[block-group|Block e block group]] · [[journaling|Journaling]] · [[integrita-fsck|Integrità del filesystem e fsck]]
