---
tags:
  - storage
  - nota
aliases:
  - Strumenti di partizionamento
---
# Strumenti di partizionamento

## 1.1 Strumenti per la gestione delle partizioni

**fdisk**
- Visualizza e modifica lo schema delle partizioni
- Comando principale: `fdisk -l` per visualizzare le partizioni
- Progettato per funzionare con MBR (Master Boot Record)

**parted**
- Sintassi simile a fdisk per l'elenco delle partizioni
- Supporta sia MBR che GPT (GUID Partition Table)
- Comando: `parted -l`

## 1.3 Creazione di partizioni (esempi pratici)

```bash
# Creare tabella partizioni MBR
parted /dev/sdb mklabel msdos

# Creare partizione primaria
parted /dev/sdb -a cylinder mkpart primary linux-swap 2 102

# Visualizzare schema partizioni
parted /dev/sdb print

# Creare filesystem di swap
mkswap /dev/sdb1

# Creare tabella GPT
parted /dev/sdb mklabel gpt

# Modalità interattiva
parted
select /dev/sdb
mkpart
```

## parted (dagli appunti sull'integrità)

Permette di creare, distruggere, ridimensionare, spostare e copiare partizioni, oltre a gestire le tabelle delle partizioni (come GUID/GPT o MBR).
innanzitutto elenco i dischi e le partizioni con 
parted -l

---

**Area:** [[mappa-storage|Storage]]  
**Fonte:** [[lezione-4-installazione-pacchetti|Lezione 4 — Installazione e package management]]  
**Vedi anche:** [[partizioni|Partizioni]] · [[mbr-gpt|MBR e GPT]] · [[swap|Swap]] · [[mount-fstab|Mount e fstab]]
