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

---

**Area:** [[mappa-storage|Storage]]  
**Vedi anche:** [[disco-settori|Disco e settori]] · [[mbr-gpt|MBR e GPT]] · [[strumenti-partizionamento|Strumenti di partizionamento]] · [[lvm|LVM]] · [[swap|Swap]] · [[filesystem|Filesystem]]
