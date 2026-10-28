---
tags:
  - hardware-boot
  - nota
aliases:
  - Pseudo-filesystem /sys e /proc
---
# Pseudo-filesystem /sys e /proc

## /sys

Dentro la directory virtuale `sys` ci sono device divisi seguendo una logica gerarchica che rispecchia la struttura fisica e funzionale dell'hardware:

- `/sys/devices/`: mappa fisica e gerarchica.
- `/sys/bus`: divisione per tipo di canale.

## /proc

La directory `/proc` è un file system virtuale (chiamato **procfs**) che funge da vera e propria finestra sul "cuore" del sistema. Non contiene veri file salvati sul tuo hard disk o SSD, ma è una struttura generata al volo direttamente dal Kernel Linux nella memoria RAM.

Se la cartella `/sys` (di cui parlavamo all'inizio) descrive l'hardware, la cartella `/proc` descrive lo stato del Kernel e i processi software in esecuzione.

I file dentro `/proc` hanno tutti una dimensione apparente di 0 byte, ma se li apri con un comando di lettura (come `cat`), il kernel genera all'istante le informazioni in tempo reale.

### 1. Le cartelle dei processi (PID)

Se entri in `/proc` e dai un'occhiata, vedrai tantissime cartelle contrassegnate da soli numeri (es. `/proc/1`, `/proc/452`, `/proc/1820`).

Quei numeri sono i **PID** (*Process ID*) dei programmi attualmente in esecuzione sul PC.

- `/proc/1/`: è la cartella dedicata a `systemd` (il processo PID 1). Al suo interno troverai file che descrivono quanta memoria sta usando `systemd`, quali file ha aperto e i suoi permessi.

Se un processo muore o viene chiuso, la sua cartella numerata scompare all'istante da `/proc`.

### 2. I file di stato del sistema (Informazioni globali)

Accanto alle cartelle numerate, ci sono dei file di testo virtuali famosissimi che descrivono lo stato generale del computer. Molti comandi Linux che usi ogni giorno non fanno altro che leggere questi file:

- `/proc/cpuinfo`: contiene i dettagli tecnici del tuo processore (marca, modello, numero di core, frequenza, cache). Viene letto quando vuoi sapere che CPU hai.
- `/proc/meminfo`: mostra la situazione dettagliata della memoria RAM (libera, usata, cache, swap). È il file da cui il comando `free` prende i suoi dati.
- `/proc/modules`: questo è il file fondamentale da cui siamo partiti! Contiene l'elenco dei moduli del kernel caricati. Quando digiti il comando `lsmod`, quel comando non fa altro che aprire e formattare graficamente questo specifico file.
- `/proc/version`: ti dice la versione esatta del kernel Linux attualmente in esecuzione e con quale compilatore (GCC) è stato compilato.
- `/proc/uptime`: indica da quanti secondi il computer è acceso e funzionante (la base del comando `uptime`).

---

**Area:** [[mappa-hardware-boot|Hardware e boot]]  
**Vedi anche:** [[filesystem|Filesystem]] · [[dispositivi-moduli-kernel|Dispositivi e moduli del kernel]] · [[kernel|Kernel Linux]] · [[gestione-processi|Gestione dei processi]] · [[swap|Swap]]
