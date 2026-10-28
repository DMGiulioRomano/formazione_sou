---
tags:
  - storage
  - nota
aliases:
  - Filesystem
---
# Filesystem

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

---

**Area:** [[mappa-storage|Storage]]  
**Vedi anche:** [[inode|Inode e scrittura dei file]] · [[journaling|Journaling]] · [[block-group|Block e block group]] · [[integrita-fsck|Integrità del filesystem e fsck]] · [[mount-fstab|Mount e fstab]] · [[pseudo-filesystem-sys-proc|Pseudo-filesystem /sys e /proc]] · [[immagini-container|Immagini container]]
