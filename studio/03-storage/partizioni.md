---
tags:
  - storage
  - nota
aliases:
  - Partizioni
---
# Partizioni

## Partizione

Suddivisione logica di un singolo dispositivo di archiviazione fisico in sezioni separate. Quindi è una divisione logica dello SPAZIO FISICO.

Come fa il disco a sapere che è diviso in quelle parti? Attraverso la tabella di partizione.

## Perché partizionare

Perché ha senso dividere disco in partizioni?
- separare responsabilità: tenere separato sistema operativo e dati
- installare piu sistemi operativi
- gestione e manutenibilità
- vincoli di avvio e compatibilità

## Partizioni Speciali di Sistema

Quando si installa il OS vengono create delle partizioni speciali:

- **Partizione di Ripristino (Recovery)**: contiene gli strumenti d'emergenza del sistema operativo. Se il computer non si avvia correttamente, questa partizione permette di riparare il sistema o riportarlo alle condizioni di fabbrica.
- **Partizione di Sistema EFI (o ESP)**: è una piccola partizione (di solito 100-500 MB) formattata in FAT32, fondamentale nei sistemi GPT moderni. Contiene i programmi di avvio (bootloader) che dicono al computer quale sistema operativo far partire.
- **Partizione di Swap (o partizione di scambio)**: molto comune nei sistemi Linux. Viene usata come "estensione" della memoria RAM del computer: quando la RAM è piena, il computer sposta temporaneamente i dati meno usati in questa partizione del disco.

## Leggere la tabella delle partizioni

Cosa c'è scritto? Per ogni partizione ci sono:

- punto di inizio e fine (settori fisici del disco)
- la dimensione totale
- il tipo di partizione
- i flag di stato

Esempio:

```bash
$ fdisk -l /dev/sda
Disco /dev/sda: 476,94 GiB, 512110190592 byte, 1000215216 settori
Modello del disco: KINGSTON SEDC600M480G
Tipo etichetta disco: gpt
Identificativo disco: E8F7A1B2-C3D4-4E5F-6A7B-8C9D0E1F2A3B

Dispositivo  Inizio      Fine        Settori     Dimensione  Tipo
/dev/sda1    2048        1050623     1048576     500M        Sistema EFI
/dev/sda2    1050624     983431167   982380544   468,4G      Dati di base del file system
/dev/sda3    983431168   1000212479  16781312    8G          Partizione di scambio di Linux
```

I settori sono della grandezza di 512 byte.

L'identificativo del disco è generato a caso per riconoscere questo specifico pezzo di hardware.

la partizione è legata alla dimensione fisica dei settori del disco 

## Perché `sda1` sta accanto a `sda` in `/dev`

La partizione è contenuta nel disco, ma in `/dev` compaiono allo stesso livello:

```text
/dev/sda    /dev/sda1    /dev/sda2
```

`/dev` (*devices*, dispositivi) non descrive com'è fatto il disco: è un elenco di **file di dispositivo**, cioè punti di accesso ai driver del kernel. La gerarchia sta altrove.

### Il motivo: `sda` deve essere un file

Un elemento del filesystem ha un solo tipo: o è una directory o è un dispositivo a blocchi. `sda` deve poter essere aperto e letto byte per byte, perché esistono dati del disco che non stanno in nessuna partizione:

- la tabella MBR, nel settore 0, che `fdisk /dev/sda` legge e scrive;
- il codice di GRUB, che `grub-install /dev/sda` scrive nel settore 0 e nel gap fino al settore 2047.

Se `sda` fosse una directory, non si potrebbe leggere come fila di byte: `read()` su una directory fallisce con `EISDIR`. Quindi `sda/sda1` non può esistere.

### Il nome e i numeri

- **`sda1`**: *SCSI disk*, primo disco (`a`), prima partizione (`1`). Il legame col disco sta nel nome, per convenzione. I dischi SATA si chiamano `sd` perché il kernel li presenta attraverso il suo sottosistema SCSI.
- **`nvme0n1p1`**: controller 0, namespace 1, partition 1. La `p` serve perché il nome del disco finisce con una cifra.

Il kernel non usa il nome, ma due numeri, visibili con `ls -l /dev/sda*`:

```text
brw-rw---- 1 root disk 8, 0 ... /dev/sda
brw-rw---- 1 root disk 8, 1 ... /dev/sda1
brw-rw---- 1 root disk 8, 2 ... /dev/sda2
```

- **`b`**: *block device*, dispositivo a blocchi.
- **`8`**: *major number*, il numero principale, che indica il driver (qui i dischi SCSI).
- **`0`, `1`, `2`**: *minor number*, il numero secondario, che indica l'unità gestita da quel driver. Il driver riserva 16 valori per disco: `0` è il disco intero, `1`–`15` le partizioni. `sdb` parte da 16.

### Chi crea i file

1. `fdisk`, al comando `w`, scrive la tabella e chiede al kernel di aggiornare le partizioni.
2. Il kernel registra un dispositivo a blocchi per ogni partizione.
3. **devtmpfs** (*device temporary filesystem*), un filesystem del kernel che sta in RAM, fa comparire i file in `/dev`.
4. **udev** (*userspace /dev*) applica permessi e crea collegamenti aggiuntivi.

Sul disco non c'è nessun file `sda1`: `/dev` si ricrea a ogni avvio.

### Dove sta la gerarchia

| Dove | Cosa si vede |
|---|---|
| `/sys/block/sda/sda1/` | la gerarchia vera: la partizione è una sottocartella del disco |
| `lsblk` | l'albero disegnato leggendo `/sys` |
| `/dev/disk/by-uuid/`, `by-id/`, `by-path/` | sottocartelle reali in `/dev`: collegamenti creati da udev |

### L'idea della cartella è esistita

**devfs**, il filesystem di dispositivi dei kernel 2.4 e dei primi 2.6, usava percorsi gerarchici come `/dev/discs/disc0/part1`. Il disco intero era un file accanto alle partizioni, `/dev/discs/disc0/disc`, proprio perché non poteva essere la cartella. È stato rimosso in Linux 2.6.13, a favore di udev e dei nomi tradizionali.

---

**Area:** [[mappa-storage|Storage]]  
**Vedi anche:** [[disco-settori|Disco e settori]] · [[mbr-gpt|MBR e GPT]] · [[strumenti-partizionamento|Strumenti di partizionamento]] · [[lvm|LVM]] · [[swap|Swap]] · [[filesystem|Filesystem]] · [[dispositivi-moduli-kernel|Dispositivi e moduli del kernel]]
