---
tags:
  - hardware-boot
  - nota
aliases:
  - Scheda madre
  - Motherboard
---
# Scheda madre

La **scheda madre** (*motherboard*) è il circuito principale del computer: ospita la CPU, la RAM e le schede di espansione, e le collega fra loro e all'alimentazione. Questa nota passa in rassegna i suoi componenti.

## PCB

**PCB** sta per *Printed Circuit Board*, circuito stampato. È la lastra su cui è costruita la scheda madre.

- È fatta di **più strati** (*layer*) sovrapposti: le schede madri consumer ne hanno di solito da 4 a 8, quelle di fascia alta e i server anche 10-12 o più. Gli strati interni portano piste di segnale, massa e alimentazione.
- Il colore (spesso verde, ma anche nero o blu) viene dalla **solder mask**, uno strato di vernice isolante che protegge le piste di rame dall'ossidazione ed evita **cortocircuiti** fra piste vicine durante la saldatura.

## Socket della CPU

Il **socket** è l'alloggiamento che collega meccanicamente ed elettricamente la CPU alla scheda madre, permettendo di montarla e sostituirla senza saldarla. Socket e CPU devono essere compatibili (es. AM5 per AMD Ryzen 7000+, LGA1700 per Intel 12ª-14ª gen.).

| Tipo | Nome | Dove stanno i pin | Pro | Contro |
| --- | --- | --- | --- | --- |
| **LGA** | *Land Grid Array* | Sul socket; la CPU ha solo contatti piatti (*land*) | CPU più robusta, alta densità di contatti | Se un pin del socket si piega si rischia di dover sostituire la scheda madre |
| **PGA** | *Pin Grid Array* | Sotto la CPU | Socket più semplice ed economico | Pin della CPU fragili, si piegano facilmente maneggiandola |

Esiste anche il **BGA** (*Ball Grid Array*): la CPU è saldata direttamente sulla scheda, come nei portatili sottili, e non si può sostituire.

## Chipset

Il **chipset** è un chip della scheda madre che gestisce le connessioni fra la CPU e le periferiche "secondarie": porte USB, porte SATA per dischi (HDD e SSD SATA), Ethernet, Wi-Fi, audio integrato, slot NVMe e PCIe aggiuntivi.

> [!note] Correzione
> Nelle CPU moderne molte funzioni sono passate **dentro la CPU**: il controller della memoria, le linee PCIe per la GPU (lo slot x16 principale) e di solito il primo slot M.2 sono collegati direttamente al processore. Il chipset gestisce il resto ed è collegato alla CPU da un unico collegamento (DMI su Intel, PCIe su AMD). Un tempo era diviso in due chip: *northbridge* (memoria e grafica) e *southbridge* (I/O lento).

## Slot DIMM (RAM)

**DIMM** sta per *Dual In-line Memory Module*: sono gli slot che ospitano i moduli di RAM.

- Ogni generazione (DDR3, DDR4, DDR5) ha una **tacca** (*notch*) in posizione diversa, che impedisce di inserire un modulo di generazione sbagliata.
- Gli slot sono divisi in **canali di memoria**: un canale è un percorso dati indipendente fra il **controller di memoria della CPU** e un gruppo di slot. Più canali lavorano in parallelo, quindi aumentano la **banda** (dati trasferiti al secondo) e la capacità totale.
- Con due moduli negli slot giusti (vedi manuale, di solito A2 e B2) si attiva il **dual channel**, che raddoppia la banda teorica rispetto a un solo modulo. I server arrivano a 8 o 12 canali.

## VRM

**VRM** sta per *Voltage Regulator Module*. È il circuito, vicino al socket, che trasforma i 12 V in arrivo dall'alimentatore nella tensione bassa (circa 1-1,4 V), precisa e stabile richiesta dalla CPU, adattandola istante per istante al carico. Un VRM con più **fasi** scalda meno e regge meglio CPU potenti e overclock.

## Slot PCIe

**PCIe** sta per *Peripheral Component Interconnect Express*: sono i connettori per le **schede di espansione**. Il numero dopo la "x" indica le **linee** (*lane*), cioè i canali dati seriali paralleli:

| Formato | Uso tipico |
| --- | --- |
| **x1** | Schede a bassa banda: Wi-Fi, audio, porte USB aggiuntive |
| **x4** | Schede di rete veloci, adattatori NVMe, controller |
| **x8** | Schede di rete e RAID nei server |
| **x16** | Scheda video (GPU) |

Ogni generazione (PCIe 3.0, 4.0, 5.0) raddoppia la banda per linea. Uno slot fisicamente x16 può essere cablato con meno linee (es. x4): lo dice il manuale.

## Slot M.2

Gli slot **M.2** sono connettori compatti montati direttamente sulla scheda madre, usati soprattutto per **SSD** e per schede **Wi-Fi/Bluetooth**. M.2 è il **formato fisico**; il protocollo può essere:

- **M.2 SATA**: usa il protocollo SATA, limitato a circa **550-600 MB/s** (600 MB/s è il massimo teorico di SATA III).
- **M.2 NVMe**: usa le linee **PCIe** e il protocollo **NVMe** (*Non-Volatile Memory Express*), pensato per la memoria flash: da circa 3.500 MB/s (PCIe 3.0) a oltre 10.000 MB/s (PCIe 5.0).
- Alcuni slot supportano **entrambi**; altri solo uno dei due: va controllato nel manuale.

## Connettori di alimentazione

| Connettore | Cosa alimenta |
| --- | --- |
| **24 pin ATX** | La scheda madre: chipset, RAM, slot, porte |
| **8 pin EPS** (4+4) | La CPU, passando per il VRM; schede potenti ne hanno due |
| **6/8 pin PCIe** o **12VHPWR/12V-2x6** | La GPU (il cavo va alla scheda video, non alla scheda madre) |

**ATX** (*Advanced Technology eXtended*) è lo standard Intel del 1995 che definisce formato della scheda, alimentatore e connettori.

## Porte SATA

**SATA** sta per *Serial ATA*, cioè *Serial Advanced Technology Attachment*: è il connettore per HDD, SSD SATA da 2,5" e unità ottiche. Ha sostituito il vecchio **PATA/IDE** (parallelo).

Nel BIOS/UEFI le porte SATA possono funzionare in tre modalità:

- **AHCI** (*Advanced Host Controller Interface*): lo standard moderno, supporta hot-plug e NCQ.
- **IDE**: modalità legacy, compatibile con sistemi operativi vecchi.
- **RAID** (*Redundant Array of Independent Disks*): unisce più dischi per ridondanza o velocità.

## Chip del BIOS e batteria CMOS

- **Chip del BIOS/UEFI**: memoria flash che contiene il **firmware** → vedi [[firmware-bios-uefi|Firmware, BIOS e UEFI]].
- **Batteria CMOS** (di solito una pila a bottone CR2032): mantiene l'orologio di sistema (RTC) e, sulle schede più vecchie, le impostazioni del BIOS salvate nella memoria CMOS. Sulle schede moderne le impostazioni stanno nella flash; la batteria serve soprattutto all'orologio. Toglierla (o usare il jumper *Clear CMOS*) riporta le impostazioni ai valori di fabbrica.

## Rear I/O panel

Il pannello posteriore dove arrivano tutte le **connessioni esterne**: USB, Ethernet, audio, uscite video (per la grafica integrata), antenne Wi-Fi, a volte il pulsante di *BIOS flashback*.

## Front panel header

I pin a cui si collegano i cavi del **case**: pulsante di accensione, pulsante di reset, LED di alimentazione e di attività del disco. Senza il collegamento del pulsante di avvio il PC non si accende. Nelle vicinanze ci sono anche gli header per USB e audio frontali.

---

↑ [[mappa-hardware-boot|Hardware e boot]]
