---
tags:
  - storage
  - nota
aliases:
  - Block e block group
---
# Block e block group

Il file system organizza lo spazio logico in blocks che è l'unità di misura base del file system. la grandezza dipende dal tipo di file system, per esempio in ext4 è 4KiB.
Questi block sono organizzati in blockgroups che contengono sia metadati che dati sui files. 

![[ext4-block-group.png]]

---

**Area:** [[mappa-storage|Storage]]  
**Vedi anche:** [[filesystem|Filesystem]] · [[inode|Inode e scrittura dei file]] · [[disco-settori|Disco e settori]] · [[integrita-fsck|Integrità del filesystem e fsck]]
