---
tags:
  - hardware-boot
  - mappa
aliases:
  - Hardware e boot
---
# Hardware e boot

Dall'accensione al kernel in esecuzione. Le note seguono l'ordine della catena di avvio.

- [[firmware-bios-uefi|Firmware, BIOS e UEFI]] — il primo codice eseguito: POST, CMOS, Secure Boot
- [[bootloader-grub|Bootloader e GRUB]] — stage 1/1.5/2, configurazione di GRUB 2
- [[initramfs|Initramfs]] — il filesystem temporaneo in RAM e `switch_root`
- [[kernel|Kernel Linux]] — scheduler, memoria, kernel space e user space
- [[dispositivi-moduli-kernel|Dispositivi e moduli del kernel]] — cold/hot plug, `lspci`, moduli, D-Bus
- [[pseudo-filesystem-sys-proc|Pseudo-filesystem /sys e /proc]] — l'hardware e i processi visti come file

---

↑ [[00-home|Home]]
