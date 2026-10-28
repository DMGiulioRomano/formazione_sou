---
tags:
  - hardware-boot
  - nota
aliases:
  - Initramfs
---
# Initramfs

L'**initramfs** è un archivio compresso. Linux, nello Stage 2, lo estrae dentro una cartella tmpfs in RAM.

Il kernel lancia `/sbin/init` → carica moduli/driver hardware necessari.

Ora che i driver sono avviati, il sistema operativo può vedere l'hard disk fisico.

Initramfs usa `switch_root` con il quale si auto-smonta dalla RAM e imposta il vero hard disk come partizione principale, ovvero `/`.

Da qui parte il padre di tutti, ovvero **systemd**, che avvia quasi tutto **IN PARALLELO**.

---

**Area:** [[mappa-hardware-boot|Hardware e boot]]  
**Vedi anche:** [[bootloader-grub|Bootloader e GRUB]] · [[systemd|systemd]] · [[dispositivi-moduli-kernel|Dispositivi e moduli del kernel]] · [[mount-fstab|Mount e fstab]]
