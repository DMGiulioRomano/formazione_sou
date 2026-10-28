---
tags:
  - hardware-boot
  - nota
aliases:
  - Firmware, BIOS e UEFI
---
# Firmware, BIOS e UEFI

## Firmware

Un **firmware** è un tipo di software specifico che è "cablato" (scritto in modo permanente) all'interno di un piccolo chip di memoria non volatile (chiamata Flash ROM) situato direttamente sulla scheda madre del computer. È a metà strada tra l'hardware (i circuiti fisici) e il software (i programmi come Linux). Per esempio può essere per computer o BIOS o UEFI/EFI.

## BIOS

Il **BIOS** (acronimo di *Basic Input/Output System*) è il primo software che viene eseguito quando accendi il computer. È un **firmware** (programma integrato direttamente in un piccolo chip di memoria) e deve fare da ponte tra l'hardware fisico del PC e il sistema operativo.

Ha 4 funzioni principali:

1. **POST** (*Power-On Self-Test*), ovvero lancia tutti i test → se qualcosa non funziona, il computer si blocca e riproduce dei segnali acustici (i famosi beep).
2. **Inizializzazione** → attiva e configura i componenti fondamentali della scheda madre e del chipset, impostando le frequenze e le tensioni corrette.
3. **Lettura delle impostazioni (CMOS)** → recupera l'ora del sistema, la data e le tue preferenze personalizzate (come l'ordine di avvio dei dischi). Perché CMOS? Perché è il nome di questa piccola memoria che rimane accesa tramite una piccola batteria sulla scheda madre.
4. **Bootstrap (Il Boot)** → il bootstrap (o semplicemente boot) è l'intera catena di eventi automatici che permette al computer di "sollevarsi da solo", partendo dal minuscolo frammento di codice dentro il chip del BIOS/UEFI fino ad arrivare al caricamento del sistema operativo completo in RAM.

## UEFI

I computer nuovi hanno l'**UEFI** (*Unified Extensible Firmware Interface*) che ha interfaccia grafica e include Secure Boot; inoltre, a differenza del BIOS il cui codice è in assembly, UEFI ha un linguaggio di programmazione.

## Dalla lezione 4: UEFI vs BIOS

**UEFI (Moderno)**
- Cerca partizione ESP (EFI System Partition) nel disco
- Supporta GPT nativamente

**BIOS (Legacy)**
- Non può fare boot da GPT

---

**Area:** [[mappa-hardware-boot|Hardware e boot]]  
**Fonte:** [[lezione-4-installazione-pacchetti|Lezione 4 — Installazione e package management]]  
**Vedi anche:** [[bootloader-grub|Bootloader e GRUB]] · [[mbr-gpt|MBR e GPT]] · [[partizioni|Partizioni]]
