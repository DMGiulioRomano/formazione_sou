# PARTIZIONI - lun 19

## Definizioni

### Partizione

Suddivisione logica di un singolo dispositivo di archiviazione fisico in sezioni separate.

Come fa il disco a sapere che è diviso in quelle parti? Attraverso la tabella di partizione.

### Tabella di partizione

Viene salvata sul dispositivo di archiviazione fisico stesso e occupa i primi settori del disco (vedi più avanti).

Ci sono due standard per definire questa mappa:

- **MBR** (*Master Boot Record*): standard classico, usabile in dischi di 2 TB max e consente di creare max 4 partizioni primarie.
- **GPT** (*GUID Partition Table*): legato ai computer UEFI. Supera i limiti di MBR.

### I tipi di partizione nello schema MBR

Lo spazio non può essere diviso liberamente. Per questo motivo sono nati tre tipi di partizioni:

- **Partizione Primaria**: quella principale. È l'unica che può ospitare i file di avvio del sistema operativo ed essere contrassegnata come attiva.
- **Partizione Estesa**: se servono più di 4 partizioni, una delle 4 viene trasformata in "estesa" e funge da contenitore.
- **Partizioni Logiche**: interne alla partizione estesa.

> Questa suddivisione in GPT è superata.

### Partizioni Speciali di Sistema

Quando si installa il OS vengono create delle partizioni speciali:

- **Partizione di Ripristino (Recovery)**: contiene gli strumenti d'emergenza del sistema operativo. Se il computer non si avvia correttamente, questa partizione permette di riparare il sistema o riportarlo alle condizioni di fabbrica.
- **Partizione di Sistema EFI (o ESP)**: è una piccola partizione (di solito 100-500 MB) formattata in FAT32, fondamentale nei sistemi GPT moderni. Contiene i programmi di avvio (bootloader) che dicono al computer quale sistema operativo far partire.
- **Partizione di Swap (o partizione di scambio)**: molto comune nei sistemi Linux. Viene usata come "estensione" della memoria RAM del computer: quando la RAM è piena, il computer sposta temporaneamente i dati meno usati in questa partizione del disco.

### Leggere la tabella delle partizioni

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

### Dove si trova nel merito la tabella di partizione?

- **MBR**: nel settore 0, anche chiamato Master Boot Record. È composto da codice di avvio (*Boot code*) di 446 byte e tabella di partizione vera e propria di 64 byte (infatti può contenere solo 4 partizioni da 16 byte l'una).
- **GPT**: nei primi 34 settori (il primo settore viene lasciato vuoto) c'è la tabella principale (*primary GPT*), ma c'è anche la tabella di backup negli ultimi 33 settori del disco per sicurezza e ridondanza.

### Come fa il computer a leggerla? (Il flusso)

Quando accendi il PC, la scheda madre (il chip BIOS o UEFI) riceve corrente. La primissima cosa che fa via hardware è inviare un comando al disco: "Leggimi il Settore 0 (o i primi settori)".

Il disco rigido invia questi pochissimi byte alla memoria RAM temporanea. L'UEFI li analizza, capisce com'è diviso il disco tramite la tabella e solo a quel punto sa in quale partizione deve andare a cercare Windows, macOS o Linux per avviarlo.

## Volume

*(sezione vuota nel file originale)*

## Radicazione

*(sezione vuota nel file originale)*

---