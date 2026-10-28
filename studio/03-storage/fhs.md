---
tags:
  - storage
  - nota
aliases:
  - FHS
---
# FHS

Standard che definisce l'albero delle directory con scopi precisi.

**Directory importanti da considerare per partizioni separate:**
- `/home` - dati utente
- `/var` - dati variabili e log
- `/boot` - specialmente con LVM (boot non lo utilizza)

## Log rotation

`/var/log` contiene log che possono riempire il filesystem. Buona pratica: partizione separata.

> [!question] Da approfondire
> - Studiare pathname.com/fhs per il comportamento specifico delle directory

---

**Area:** [[mappa-storage|Storage]]  
**Fonte:** [[lezione-4-installazione-pacchetti|Lezione 4 — Installazione e package management]]  
**Vedi anche:** [[mount-fstab|Mount e fstab]] · [[lvm|LVM]] · [[journalctl|journalctl]] · [[librerie-condivise|Librerie condivise]]
