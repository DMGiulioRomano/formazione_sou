---
tags:
  - hardware-boot
  - nota
aliases:
  - Bootloader e GRUB
---
# Bootloader e GRUB

Il processo di bootstrap viene iniziato dal BIOS/UEFI che lancia il **bootloader**.

Il **bootloader** (caricatore di avvio) è il programma specifico che si occupa della fase cruciale del bootstrap. Di solito è **GRUB** (*Grand Unified Bootloader*); precedentemente c'era **LILO** (*Linux Loader*). Poiché il codice che il BIOS può caricare all'inizio è microscopico, GRUB è diviso in fasi:

- **STAGE 1**: è un codice piccolissimo (appena 512 byte) memorizzato nel primissimo settore del disco (l'MBR) o nel settore di avvio UEFI. Il suo unico scopo nella vita è sapere dove si trova sul disco il pezzo successivo, leggermente più grande.
- **STAGE 1.5** (o intermedi): contiene i driver minimi per permettere al computer di leggere il file system (es. ext4 o xfs) dove risiede il resto del bootloader.
- **STAGE 2**: è il vero e proprio menu grafico di GRUB che vedi sullo schermo. Ti permette di scegliere quale sistema operativo avviare. Quando selezioni Linux, lo Stage 2 carica in memoria due cose fondamentali: il Kernel Linux e l'**initramfs** (o initrd).

## GRUB in pratica (lezione 4)

### 5.2 GRUB Legacy

```bash
# Installare GRUB nel MBR
grub-install /dev/sda

# Backup superblock
dd if=/dev/sda of=/home/user/sda.superblock count=1 bs=512

# File di configurazione
/boot/grub/menu.lst
```

### 5.3 GRUB 2

**File importanti:**
- `/boot/grub2/` - directory principale
- `device.map` - mappa dischi (hd0 = sda, partizioni da 1)
- `grub.cfg` - **NON MODIFICARE DIRETTAMENTE**

**Come funziona grub.cfg:**
- Generato automaticamente da script
- Prende informazioni da `/etc/default/grub` e `/etc/grub.d/`

**Rigenerare configurazione:**
```bash
grub2-mkconfig -o /boot/grub2/grub.cfg
```

**Modificare timeout:**
1. Modificare `GRUB_TIMEOUT` in `/etc/default/grub`
2. Rigenerare con `grub2-mkconfig`

**Nota**: Modifiche dirette a grub.cfg vengono perse alla rigenerazione, ma possono essere utili per modifiche temporanee.

---

**Area:** [[mappa-hardware-boot|Hardware e boot]]  
**Fonte:** [[lezione-4-installazione-pacchetti|Lezione 4 — Installazione e package management]]  
**Vedi anche:** [[firmware-bios-uefi|Firmware, BIOS e UEFI]] · [[initramfs|Initramfs]] · [[mbr-gpt|MBR e GPT]] · [[disco-settori|Disco e settori]]
