# FILE SYSTEM

  

Il file system è il software e l'insieme di regole che il sistema operativo usa per organizzare, catalogare e rintracciare i file all'interno di un volume.

## A cosa serve?

- Gestione dei nomi e delle cartelle.
- Tiene traccia di quali settori del disco sono occupati da dati e quali sono liberi.
- Salva i metadati dei file.
- Stabilisce i permessi di sicurezza.
## I tipi di file system

possono essere:
- FISICI --> **organizzare un dispositivo di archiviazione fisico e tangibile**.
- LOGICI (o pseudo-file system) --> software che **si comporta esattamente come un file system, ma non scrive nulla sul disco fisso**. a che serve?
	1. per mostrare info complesse sotto forma di file
	2. per liberare la RAM appena spegni il pc.

i tipi in base a cosa differiscono?
- dimensione massima che un singolo volume può avere
- dimensione massima a livello di singolo file
- lunghezza massima del nome di un file
- lunghezza massima di un percorso (path)
- efficienza velocità di lettura I/O
- compatibilità con altri FS
- journaling
- altri funzionalità per gestire dati e garantirne l'integrità
- ACL
- ottimizzazione

Ogni sistema operativo usa dei file system:
- **NTFS** (New technology file system): è il file system standard di Windows moderno. Supporta file enormi, gestisce la sicurezza dei dati e ha sistemi di recupero in caso di blackout.
- **APFS** (Apple File system): è il file system moderno usato da Apple su macOS e iOS, ottimizzato per le memorie SSD veloci e la crittografia.
- **ext4**: è lo standard del mondo Linux. Molto stabile, veloce e leggero.
- **FAT32** (Five allocation table): è il file system universale del passato. Oggi ha un limite severo: non può salvare file più grandi di 4 GB. Ha però il vantaggio di essere letto e scritto da qualsiasi dispositivo al mondo (TV, autoradio, Windows, Mac, Linux, PlayStation).
- **exFAT** (Extended Five allocation table): è l'evoluzione di FAT32. Rimuove il limite dei 4 GB e mantiene un'ottima compatibilità tra Windows e Mac. È il formato ideale per le chiavette USB e gli hard disk esterni.
- **BTRFS** (B-tree file system): supporta cow, raid, controllo integrità etc

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


## journaling

memorizza dati e metadati. serve ad evitare la corruzione del file system se ci sono black out e si spegne il computer. come? c'è una zona del disco che si chiama JOURNAL (un'area di memoria riservata e circolare).
 
 ### Le fasi tecniche della scrittura con Journaling (Modalità standard: _Data Ordered_)
1. **Scrittura dei Dati sul disco**: il file system scrive i blocchi di dati grezzi del file all'interno dei cluster liberi della partizione. In questa fase, i metadati generali del sistema non sono ancora stati modificati: il computer ha scritto i bit sul disco, ma il sistema operativo non sa ancora che esistono.
2. **Scrittura nel Journal (Fase di _Log_)**: Il file system prepara una transazione atomica contenente tutte le modifiche che dovranno essere applicate ai metadati (es. _Aggiornare l'inode X per puntare ai nuovi blocchi Y, sottrarre i blocchi Y dalla mappa dello spazio libero_). Questa transazione viene scritta interamente all'interno dell'area del Journal. Alla fine della transazione viene scritto un blocco speciale chiamato **Commit Block**.
3. **Modifica dei Metadati reali (_Checkpointing_)**: Solo dopo che il _Commit Block_ è stato scritto fisicamente nel Journal, il file system copia le modifiche dal Journal ai metadati effettivi del disco (la tabella degli inodi principale, l'indice della directory, ecc.). Una volta terminata la copia, la transazione nel Journal viene marcata come "rimossa" o rilasciata.

come viene gestito il recovery dopo un crash?
Se l'alimentazione si interrompe, al riavvio il kernel del sistema operativo non esegue una scansione completa di tutti i nodi del disco (`fsck` o `chkdsk`). Esegue invece una scansione sequenziale del solo **Journal**, che richiede pochi millisecondi.


## blocks e block group
Il file system organizza lo spazio logico in blocks che è l'unità di misura base del file system. la grandezza dipende dal tipo di file system, per esempio in ext4 è 4KiB.
Questi block sono organizzati in blockgroups che contengono sia metadati che dati sui files. 

![[Infografica sui Block Group ext_ext4.png]]