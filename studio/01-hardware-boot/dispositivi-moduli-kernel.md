---
tags:
  - hardware-boot
  - nota
aliases:
  - Dispositivi e moduli del kernel
---
# Dispositivi e moduli del kernel

I dispositivi, in base a come si possono collegare e scollegare, vengono definiti **plug**:

- **Cold**: a computer spento.
- **Hot**: a computer acceso.

## Elenco dispositivi PCI

Come vedo l'elenco dei dispositivi PCI? Con `lspci`.

E se metto `-t` vedo la struttura ad albero, così capisco come sono collegati.

## Dispositivi dinamici

Dal kernel 2.6 i device vengono creati dinamicamente: in questo modo non ho una lista infinita anche di device che non sono collegati in questo momento. Lo posso vedere nella cartella `/dev`.

## Driver e moduli del kernel

Qualsiasi device, che sia cold o hot, deve avere i driver per comunicare. Come vedo tutti i driver presenti? Con `lsmod`, che elenca tutti i moduli del kernel attualmente caricati in memoria.

### La differenza principale

- **Driver**: è il concetto teorico. Il software che dice al sistema operativo come comunicare con un pezzo di hardware (la scheda Wi-Fi, la scheda video, il mouse).
- **Modulo del kernel**: è lo strumento pratico. Un pezzo di codice che può essere caricato o rimosso dal "cuore" del sistema operativo (il kernel) in qualsiasi momento, senza dover riavviare il computer.

Tutti i moduli si trovano dentro `/lib/modules`.

Se con `lsmod` li vedo tutti quelli presenti, con `rmmod` li elimino, con `insmod` li inserisco (con il giusto path). Oppure, per farla ancora più semplice, uso `modprobe`: bastano il flag `-r` per eliminare e nessun flag per aggiungerlo.

> (?) `modprobe.conf` o `modprobe.d`

## D-Bus

D-Bus è il bus di sessione, che praticamente fa da tramite tra più componenti del sistema operativo.

D-Bus di solito gestisce due "canali" (chiamati bus) separati:

- **System Bus (Bus di Sistema)**: è unico per tutto il computer. Viene usato per i messaggi che riguardano l'hardware, la rete, la batteria o la sicurezza. Viene avviato quando accendi il PC.
- **Session Bus (Bus di Sessione)**: ce n'è uno per ogni utente connesso. Gestisce la comunicazione tra le tue applicazioni grafiche (ad esempio, permette al lettore musicale di mandare il titolo della canzone al widget del pannello o permette a un programma di mandare una notifica desktop).

---

**Area:** [[mappa-hardware-boot|Hardware e boot]]  
**Vedi anche:** [[pseudo-filesystem-sys-proc|Pseudo-filesystem /sys e /proc]] · [[kernel|Kernel Linux]] · [[journalctl|journalctl]] · [[clonazione-vm-cloud-init|Clonazione VM e cloud-init]]
