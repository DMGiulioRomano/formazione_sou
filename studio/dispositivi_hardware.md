# DISPOSITIVI HARDWARE

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

## La directory virtuale `/sys`

Dentro la directory virtuale `sys` ci sono device divisi seguendo una logica gerarchica che rispecchia la struttura fisica e funzionale dell'hardware:

- `/sys/devices/`: mappa fisica e gerarchica.
- `/sys/bus`: divisione per tipo di canale.

## D-Bus

D-Bus è il bus di sessione, che praticamente fa da tramite tra più componenti del sistema operativo.

D-Bus di solito gestisce due "canali" (chiamati bus) separati:

- **System Bus (Bus di Sistema)**: è unico per tutto il computer. Viene usato per i messaggi che riguardano l'hardware, la rete, la batteria o la sicurezza. Viene avviato quando accendi il PC.
- **Session Bus (Bus di Sessione)**: ce n'è uno per ogni utente connesso. Gestisce la comunicazione tra le tue applicazioni grafiche (ad esempio, permette al lettore musicale di mandare il titolo della canzone al widget del pannello o permette a un programma di mandare una notifica desktop).

## Firmware

Un **firmware** è un tipo di software specifico che è "cablato" (scritto in modo permanente) all'interno di un piccolo chip di memoria non volatile (chiamata Flash ROM) situato direttamente sulla scheda madre del computer. È a metà strada tra l'hardware (i circuiti fisici) e il software (i programmi come Linux). Per esempio può essere per computer o BIOS o UEFI/EFI.

## BIOS

Il **BIOS** (acronimo di *Basic Input/Output System*) è il primo software che viene eseguito quando accendi il computer. È un **firmware** (programma integrato direttamente in un piccolo chip di memoria) e deve fare da ponte tra l'hardware fisico del PC e il sistema operativo.

Ha 4 funzioni principali:

1. **POST** (*Power-On Self-Test*), ovvero lancia tutti i test → se qualcosa non funziona, il computer si blocca e riproduce dei segnali acustici (i famosi beep).
2. **Inizializzazione** → attiva e configura i componenti fondamentali della scheda madre e del chipset, impostando le frequenze e le tensioni corrette.
3. **Lettura delle impostazioni (CMOS)** → recupera l'ora del sistema, la data e le tue preferenze personalizzate (come l'ordine di avvio dei dischi). Perché CMOS? Perché è il nome di questa piccola memoria che rimane accesa tramite una piccola batteria sulla scheda madre.
4. **Bootstrap (Il Boot)** → il bootstrap (o semplicemente boot) è l'intera catena di eventi automatici che permette al computer di "sollevarsi da solo", partendo dal minuscolo frammento di codice dentro il chip del BIOS/UEFI fino ad arrivare al caricamento del sistema operativo completo in RAM.

## UEFI

I computer nuovi hanno l'**UEFI** (*Unified Extensible Firmware Interface*) che ha interfaccia grafica e include Secure Boot; inoltre, a differenza del BIOS il cui codice è in assembly, UEFI ha un linguaggio di programmazione.

## Bootstrap e bootloader

Il processo di bootstrap viene iniziato dal BIOS/UEFI che lancia il **bootloader**.

Il **bootloader** (caricatore di avvio) è il programma specifico che si occupa della fase cruciale del bootstrap. Di solito è **GRUB** (*Grand Unified Bootloader*); precedentemente c'era **LILO** (*Linux Loader*). Poiché il codice che il BIOS può caricare all'inizio è microscopico, GRUB è diviso in fasi:

- **STAGE 1**: è un codice piccolissimo (appena 512 byte) memorizzato nel primissimo settore del disco (l'MBR) o nel settore di avvio UEFI. Il suo unico scopo nella vita è sapere dove si trova sul disco il pezzo successivo, leggermente più grande.
- **STAGE 1.5** (o intermedi): contiene i driver minimi per permettere al computer di leggere il file system (es. ext4 o xfs) dove risiede il resto del bootloader.
- **STAGE 2**: è il vero e proprio menu grafico di GRUB che vedi sullo schermo. Ti permette di scegliere quale sistema operativo avviare. Quando selezioni Linux, lo Stage 2 carica in memoria due cose fondamentali: il Kernel Linux e l'**initramfs** (o initrd).

## Initramfs

L'**initramfs** è un archivio compresso. Linux, nello Stage 2, lo estrae dentro una cartella tmpfs in RAM.

Il kernel lancia `/sbin/init` → carica moduli/driver hardware necessari.

Ora che i driver sono avviati, il sistema operativo può vedere l'hard disk fisico.

Initramfs usa `switch_root` con il quale si auto-smonta dalla RAM e imposta il vero hard disk come partizione principale, ovvero `/`.

Da qui parte il padre di tutti, ovvero **systemd**, che avvia quasi tutto **IN PARALLELO**.

## Cosa fa systemd?

Ha dei **target**, ovvero obiettivi da raggiungere. Infatti si chiamano `.target`:

- `sysinit.target`: controlla lo stato dei dischi fissi e monta tutte le partizioni fondamentali.
- `basic.target`: con cui vengono avviati i servizi di base come la gestione dei log di sistema (`journald`) ecc.
- `network.target`: dove attiva la rete internet e il computer ottiene l'indirizzo IP.
- `multi-user.target`: vengono avviati servizi di rete tipo `sshd` e prompt di testo per fare login `agetty`.
- Se è in modalità desktop e non in modalità server → lanciato `graphical.target` che avvia il display manager.

Poi il display manager avvia la tua sessione grafica. Da questo momento in poi systemd svolge monitoraggio e gestione degli eventi:

- gestisce l'energia (sospensione processi quando si spegne lo schermo);
- gestisce servizi in background e quelli che crashano li riavvia in automatico;
- registra quello che succede nel log `journald`, così si possono consultare i problemi. Come vedo tutte le info loggate? Con `journalctl` → studiare il modo in cui filtrare i log!

## Cosa fa il kernel Linux dopo l'avvio di systemd

Una volta lanciato systemd, il kernel Linux fa 3 cose:

1. **Scheduler** → gestisce il traffico dei vari processi dentro la CPU instradandolo nei core. La cosa figa è che alterna i programmi da un millisecondo all'altro, così velocemente da darti l'impressione che stiano girando tutti insieme.
2. **Memory manager** → regola la parte di RAM allocata per un certo processo o una certa applicazione in modo da liberare la memoria e pulirla se l'applicazione crasha. In questo modo sono tutte compartimentate e divise in due zone invalicabili: **kernel space** (dove risiede il codice compilato del kernel e dei suoi moduli, e qui ha potere assoluto) e **user space** (la zona dove vengono caricati systemd, server grafico e browser; in questo spazio sono protetti e non possono toccare direttamente l'hardware).
3. **Driver e system call** → i programmi nello userspace, quando hanno bisogno dell'hardware, fanno chiamate a sistema e il kernel se ne occupa.

Il kernel è scritto in C quasi interamente.

## systemctl

`systemctl` è il comando da terminale principale utilizzato per controllare, gestire e monitorare systemd, ovvero il sistema di inizializzazione che governa l'intero sistema operativo Linux.

Puoi avviare, fermare o riavviare qualsiasi programma in background, configurare l'avvio automatico, cambiare il target (per esempio da multi-user a graphical), anche controllare l'alimentazione per spegnere o sospendere.

---