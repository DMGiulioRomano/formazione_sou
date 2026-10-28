---
tags:
  - lezione
aliases:
  - Lezione 4 — Installazione e package management
---
# Lezione 4 — Installazione e package management

Indice della lezione: il contenuto di ogni parte vive nella nota collegata.

## Percorso

1. **Gestione dei dischi e partizionamento** → [[strumenti-partizionamento|Strumenti di partizionamento]], [[mbr-gpt|MBR e GPT]], [[mount-fstab|Mount e fstab]]
2. **Gestione della swap** → [[swap|Swap]]
3. **Filesystem e mount point** → [[mount-fstab|Mount e fstab]], [[fhs|FHS]], [[file-directory|File e directory]]
4. **LVM** → [[lvm|LVM]]
5. **Boot e GRUB** → [[firmware-bios-uefi|Firmware, BIOS e UEFI]], [[bootloader-grub|Bootloader e GRUB]]
6. **Librerie condivise** → [[librerie-condivise|Librerie condivise]]
7. **Pacchetti Debian/Ubuntu** → [[dpkg-apt|dpkg e APT]]
8. **Pacchetti RPM** → [[rpm-yum-dnf-zypper|rpm, YUM, DNF e Zypper]]
9. **Virtualizzazione e containerizzazione** → [[vm-vs-container|VM vs container]]
10. **Cloud computing** → [[cloud-iaas-paas-saas|Cloud: IaaS, PaaS, SaaS]]
11. **Cloning di macchine virtuali** → [[clonazione-vm-cloud-init|Clonazione VM e cloud-init]]

## RIEPILOGO COMANDI PRINCIPALI

### Dischi
```bash
parted -l                        # Lista partizioni
fdisk -l                         # Lista partizioni (MBR)
parted /dev/sdb mklabel gpt      # Crea tabella GPT
partprobe /dev/sdb               # Aggiorna tabella
```

### Filesystem
```bash
mkfs.ext4 /dev/sdb1              # Crea ext4
mount /dev/sdb1 /media           # Monta
df -hT                           # Lista filesystem
du -sh /path                     # Dimensione
```

### Swap
```bash
mkswap /dev/sdb1                 # Inizializza swap
swapon /dev/sdb1                 # Attiva
swapoff -a                       # Disattiva tutto
```

### Debian/Ubuntu
```bash
apt-get update && apt-get upgrade
apt-get install pacchetto
dpkg -i pacchetto.deb
```

### RPM
```bash
yum install pacchetto
dnf install pacchetto
rpm -qa
```

### LVM
```bash
# (comandi specifici non trattati in dettaglio nel testo)
```

### GRUB
```bash
grub2-mkconfig -o /boot/grub2/grub.cfg
```

## Domande aperte

Sono state spostate, come callout `[!question]`, nelle note di riferimento: [[mount-fstab|Mount e fstab]], [[swap|Swap]], [[dpkg-apt|dpkg e APT]], [[fhs|FHS]], [[lvm|LVM]], [[clonazione-vm-cloud-init|Clonazione VM e cloud-init]].

---

↑ [[00-home|Home]]
