---
tags:
  - storage
  - nota
aliases:
  - MBR e GPT
---
# MBR e GPT

## Tabella di partizione

Viene salvata sul dispositivo di archiviazione fisico stesso e occupa i primi settori del disco (vedi più avanti).

Ci sono due standard per definire questa mappa:

- **MBR** (*Master Boot Record*): standard classico, usabile in dischi di 2 TB max e consente di creare max 4 partizioni primarie.
- **GPT** (*GUID Partition Table*): legato ai computer UEFI. Supera i limiti di MBR.

## I tipi di partizione nello schema MBR

Lo spazio non può essere diviso liberamente. Per questo motivo sono nati tre tipi di partizioni:

- **Partizione Primaria**: quella principale. È l'unica che può ospitare i file di avvio del sistema operativo ed essere contrassegnata come attiva.
- **Partizione Estesa**: se servono più di 4 partizioni, una delle 4 viene trasformata in "estesa" e funge da contenitore.
- **Partizioni Logiche**: interne alla partizione estesa.

> Questa suddivisione in GPT è superata.

## Dove si trova nel merito la tabella di partizione?

- **MBR**: nel settore 0, anche chiamato Master Boot Record. È composto da codice di avvio (*Boot code*) di 446 byte e tabella di partizione vera e propria di 64 byte (infatti può contenere solo 4 partizioni da 16 byte l'una).
- **GPT**: nei primi 34 settori (il primo settore viene lasciato vuoto) c'è la tabella principale (*primary GPT*), ma c'è anche la tabella di backup negli ultimi 33 settori del disco per sicurezza e ridondanza.

## Come fa il computer a leggerla? (Il flusso)

Quando accendi il PC, la scheda madre (il chip BIOS o UEFI) riceve corrente. La primissima cosa che fa via hardware è inviare un comando al disco: "Leggimi il Settore 0 (o i primi settori)".

Il disco rigido invia questi pochissimi byte alla memoria RAM temporanea. L'UEFI li analizza, capisce com'è diviso il disco tramite la tabella e solo a quel punto sa in quale partizione deve andare a cercare Windows, macOS o Linux per avviarlo.

## Origine del Master Boot Record

Lo standard creato all'inizio era Master Boot Record (MBR). Si chiama così perché è il registro principale che gestisce l'avvio del computer. È lo schema di partizionamento creato per essere usato dal firmware che doveva trovare il MASTER BOOT CODE.

Il master boot code nel MBR viene scritto nel primo settore della partizione. 

![[mbr.png]]

## Dalla lezione 4: schemi di partizionamento

**MBR (msDOS)**
- Supporta massimo 4 partizioni primarie
- Una partizione primaria può essere estesa per contenere partizioni logiche
- Permette di superare il limite di 4 partizioni

**GPT (GUID Partition Table)**
- Tabella a 64 bit
- Supporta fino a 128 partizioni primarie
- Dimensione massima per partizione: 8 Zettabyte
- **Nota importante**: Un sistema BIOS tradizionale non può fare boot da GPT, solo UEFI può farlo
- Un disco BIOS può comunque usare GPT come dispositivo secondario

---

**Area:** [[mappa-storage|Storage]]  
**Fonte:** [[lezione-4-installazione-pacchetti|Lezione 4 — Installazione e package management]]  
**Vedi anche:** [[partizioni|Partizioni]] · [[disco-settori|Disco e settori]] · [[firmware-bios-uefi|Firmware, BIOS e UEFI]] · [[bootloader-grub|Bootloader e GRUB]] · [[strumenti-partizionamento|Strumenti di partizionamento]]
