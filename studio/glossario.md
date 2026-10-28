---
tags:
  - glossario
aliases:
  - Glossario
---
# Glossario

**Fisico (Hardware):** Tutto ciò che è tangibile. Esempi: [[disco-settori|Disco e settori]], [[dispositivi-moduli-kernel|Dispositivi e moduli del kernel]].

**Logico (Software / Astratto):** Una rappresentazione creata dal codice. È il modo in cui il software organizza o "immagina" l'hardware. Esiste solo nella memoria del computer. Esempi: [[partizioni|Partizioni]], [[lvm|LVM]], [[filesystem|Filesystem]].

**Settore:** unità minima del disco, di solito 512 byte → [[disco-settori|Disco e settori]].

**Block / cluster:** unità minima del filesystem (4 KiB in ext4) → [[block-group|Block e block group]].

**Inode:** la scheda dei metadati di un file → [[inode|Inode e scrittura dei file]].

**Journal:** area circolare che registra le transazioni prima di applicarle → [[journaling|Journaling]].

**PV / VG / LV:** physical volume, volume group, logical volume → [[lvm|LVM]].

**PE (Physical Extent):** unità di allocazione di LVM → [[lvm|LVM]].

**ESP:** partizione di sistema EFI → [[partizioni|Partizioni]], [[firmware-bios-uefi|Firmware, BIOS e UEFI]].

**PID:** identificativo di un processo → [[gestione-processi|Gestione dei processi]], [[pseudo-filesystem-sys-proc|Pseudo-filesystem /sys e /proc]].

**Modulo del kernel:** codice caricabile a caldo nel kernel → [[dispositivi-moduli-kernel|Dispositivi e moduli del kernel]].

**Target:** obiettivo di avvio di systemd → [[systemd|systemd]].

**Namespace / cgroup:** isolamento e limiti dei processi → [[namespaces-cgroups|Namespaces e cgroups]].

**Layer:** strato in sola lettura di un'immagine container → [[immagini-container|Immagini container]].

**Digest:** hash crittografico che identifica un contenuto → [[hashsum|Hash e checksum]], [[immagini-container|Immagini container]].

---

↑ [[00-home|Home]]
