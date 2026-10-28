---
tags:
  - storage
  - nota
aliases:
  - Swap
---
# Swap

spazio su disco che kernel usa come memoria virtuale di emergenza. quando ram sta in difficoltà, sposta parte di memoria poco utilizzata nella swap così da liberare ram. È SENZA FILE SYSTEM.
o si fa partizione swap dedicata, oppure logical volum LVM usato come swap, oppur euno swap file dentro un file system già esistente /swapfile, oppure zram ovvero swap compresso in RAM.

## Dalla lezione 4

### 2.1 Cos'è la swap
Spazio su disco utilizzato quando la RAM è piena. Scarica dati su disco per liberare memoria e permettere l'esecuzione di altri programmi.

### 2.2 Dimensionamento
- **Regola generale**: 1,5-2 volte la dimensione della RAM (per sistemi con RAM limitata)
- **Sistemi con molta RAM** (es. 16GB): dimensioni proporzionalmente minori

### 2.3 Comandi utili

```bash
# Vedere unità minima di swap (es. 4096 = 4kB)
getconf PAGESIZE

# Visualizzare partizioni/file swap in uso
swapon -s
# oppure
cat /proc/swaps

# Attivare swap
swapon /dev/sdb1

# Disattivare swap
swapoff /dev/sdb1

# Disattivare tutta la swap
swapoff -a

# Visualizzare memoria
free -m
```

### 2.4 Swap su file

```bash
# Creare file swap da 100MB
dd if=/dev/zero of=/tmp/swapfile bs=10M count=10

# Inizializzare come swap
mkswap /tmp/swapfile

# Attivare
swapon /tmp/swapfile
```

### 2.5 Rendere permanente la swap

1. Ottenere UUID della partizione:
```bash
blkid /dev/sdb1
```

2. Modificare `/etc/fstab`:
```bash
vi /etc/fstab
# Aggiungere:
UUID="ID" swap swap sw,pri=5 0 0
```

**Trucco**: Dentro vi, usa `:r ! blkid /dev/sdb1` per incollare l'output del comando

### 2.6 Swappiness
Soglia di attivazione della swap prima che la RAM si saturi.

```bash
# Modifica permanente
vi /etc/sysctl.conf
# Aggiungere:
vm.swappiness=80
```

**Valori alti** = swap più aggressiva

> [!question] Da approfondire
> - Sintassi completa di fstab: `UUID="ID" swap swap sw,pri=5 0 0`
> - `free -m`: opzioni e interpretazione dell'output
> - Swappiness: valori ottimali per diversi scenari

---

**Area:** [[mappa-storage|Storage]]  
**Fonte:** [[lezione-4-installazione-pacchetti|Lezione 4 — Installazione e package management]]  
**Vedi anche:** [[partizioni|Partizioni]] · [[lvm|LVM]] · [[mount-fstab|Mount e fstab]] · [[kernel|Kernel Linux]] · [[strumenti-partizionamento|Strumenti di partizionamento]]
