---
tags:
  - storage
  - mappa
aliases:
  - Storage
---
# Storage

La catena dello storage, dal basso verso l'alto:

**disco → partizione → (LVM) → filesystem → mount**

- [[disco-settori|Disco e settori]] — il supporto fisico e i settori da 512 byte
- [[partizioni|Partizioni]] — dividere lo spazio fisico
- [[mbr-gpt|MBR e GPT]] — le due tabelle delle partizioni
- [[strumenti-partizionamento|Strumenti di partizionamento]] — `fdisk`, `parted`, `partprobe`
- [[lvm|LVM]] — physical volume, volume group, logical volume
- [[swap|Swap]] — memoria virtuale su partizione o file
- [[filesystem|Filesystem]] — a cosa serve, tipi a confronto
- [[inode|Inode e scrittura dei file]] — come viene salvato un file
- [[block-group|Block e block group]] — l'organizzazione dello spazio in ext4
- [[journaling|Journaling]] — resistere ai crash
- [[integrita-fsck|Integrità del filesystem e fsck]] — controllare e riparare
- [[mount-fstab|Mount e fstab]] — rendere un filesystem accessibile
- [[fhs|FHS]] — l'albero standard delle directory

---

↑ [[00-home|Home]]
