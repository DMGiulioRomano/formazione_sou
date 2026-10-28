---
tags:
  - storage
  - nota
aliases:
  - LVM
---
# LVM

I volumi sono una tecnologia che aiuta a rendere molto piu agile l'utilizzo dello spazio di archiviazione. 

Funzionano tramite un software che si chiama LVM (Logical Volume Manager) che divide lo spazio di un physical volume in unità di allocazione chiamate Physical Extent (PE) che di norma sono 1 PE = 4MiB

abbiamo:
- Physical Volume: spazio fisico gestito da LVM. Può essere un disco intero o una partizione. Una volta inizializzato ha etichetta e metadati LVM e la parte di spazio disponibile a LVM
- Voume Group: Insieme di piu PV. IN questo modo mette a disposizione uno spazio da cui creare nuove unità logiche che sono i LV.
- Logical Volume: spazio logico che l'OS usa. Per cosa si usano? per un qualsiasi scopo per cui si usano le partizioni del disco (però li puoi ridimensionare a piacimento):
	- partizionamento OS tipo per le cartelle di log
	- storage per database
	- spazio per VM o container
	- snapshot o backup a caldo
	- etc...


## Physical Volume

![[lvm-physical-volume.png]]

## Volume e partizione

è una divisione logica dei dati nel sistema operativo.
si potrebbe volere un unico volume con un file system montato su diverse partizioni subentrnao dei software chiamati LVM (Logical volume manager). 

## Dalla lezione 4

### 4.1 Cos'è LVM
Livello di astrazione sopra lo storage fisico che permette di:
- Creare logical volumes che si estendono su più dischi fisici
- Superare i limiti dimensionali dei singoli dischi
- Nascondere la configurazione fisica al software

### 4.2 Vantaggi

**Flessibilità**
- Gestione dinamica dello spazio
- Ridimensionamento senza interrompere le applicazioni

**Performance**
- Striping: scrittura simultanea su più dischi per aumentare velocità

**Backup e Recovery**
- Snapshot per controllo integrità dati
- Disaster recovery nativo

> [!question] Da approfondire
> - Comandi pratici per creazione e gestione volumi

---

**Area:** [[mappa-storage|Storage]]  
**Fonte:** [[lezione-4-installazione-pacchetti|Lezione 4 — Installazione e package management]]  
**Vedi anche:** [[partizioni|Partizioni]] · [[filesystem|Filesystem]] · [[swap|Swap]] · [[fhs|FHS]] · [[vm-vs-container|VM vs container]]
