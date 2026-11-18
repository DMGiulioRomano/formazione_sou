---
tags:
  - lezione
  - linux
aliases:
  - Linux 08 — Avvio e GRUB
---
# Linux 08 — Avvio e GRUB

Fra l'accensione e il prompt c'è una catena: firmware, GRUB, kernel, initramfs, systemd. Qui decidi dove si ferma systemd, entri una volta sola in modalità di soccorso dal menu, dai al kernel i parametri di un fornitore e salvi una macchina da un kernel nuovo che non parte. Gli appunti di partenza sono [[mappa-hardware-boot|Hardware e boot]], [[bootloader-grub|Bootloader e GRUB]], [[initramfs|Initramfs]], [[kernel|Kernel Linux]] e [[systemd|systemd]].

```sh
cd formazione_sou/lab/linux
sudo ./prepara.sh 08        # problema 1; poi sudo ./prepara.sh 08 2, e così via
```

> [!warning] Prima di cominciare
> - **Una fotografia della VM**, a VM spenta: `VBoxManage snapshot lab-rocky take prima-di-08`. Qui si tocca l'avvio della macchina, non solo i dischi dedicati.
> - **La password di root** (`sudo passwd -S root` deve dire `PS`): la modalità di soccorso la chiede.
> - **La finestra della VM** aperta: il menu di GRUB compare lì, e resta solo pochi secondi.
>
> `prepara.sh` fotografa la configurazione di avvio la prima volta che lo lanci con questa versione del kit, di solito nella lezione 07 (in `/var/lib/lab-linux/base/avvio/`). Ogni `prepara.sh` successivo la riporta com'era, compreso il kernel finto del problema 4.

## La mappa

| # | Problema | Stato |
|---|---|---|
| 1 | Parte in modalità grafica, e non serve | — |
| 2 | Un avvio di manutenzione | — |
| 3 | I parametri del fornitore | — |
| 4 | Il kernel nuovo non parte | — |
| P | Pulizia — riportare l'avvio allo standard | — |

---

## Problema 1 — Parte in modalità grafica, e non serve

**Situazione.** La macchina è nata con l'ambiente grafico, poi tolto. Parte ancora in modalità grafica e il controllo di conformità la segnala: un server deve partire nella modalità multi-utente senza grafica.

> [!info] Il contesto
> **Lo scenario.** Server installati da un profilo sbagliato, immagini copiate da una postazione: capita spesso di trovarne uno che punta alla grafica. Si corregge a caldo, senza spegnere niente.
> - **Target** (inglese, «obiettivo»): un gruppo di unità che systemd porta su insieme. È l'erede dei *runlevel* di SysV init ([[prima-di-systemd|Prima di systemd]]).
> - **Target predefinito** (*default target*): quello che systemd raggiunge all'avvio se nessuno gli chiede altro.
> - **multi-user.target** e **graphical.target**: il secondo contiene il primo e aggiunge il login grafico.
>
> **Perché conta.** Cambiare il predefinito non cambia la macchina adesso, e cambiare la macchina adesso non cambia il prossimo avvio. Servono entrambe le cose.

**Compito.** Esegui `palestra/l08/ticket-1.txt`:

- da ora la macchina parte in multi-user;
- ci passa subito, senza riavviare;
- i servizi che girano già, come `sshd`, non si fermano.

Criteri di accettazione: `sudo ./verifica.sh 08 1` esce con 0, e `systemctl get-default` stampa `multi-user.target`.

**Verifica.** `sudo ./verifica.sh 08 1`

> [!question]- Indizio 1
> Rileggi [[systemd|systemd]]: quali target conosci, e quale contiene l'altro? `systemctl list-dependencies graphical.target | head` lo mostra.

> [!question]- Indizio 2
> Dove sta scritto il target predefinito? `ls -l /etc/systemd/system/default.target`. In `man systemctl` cerca *default*.

> [!question]- Indizio 3
> Il predefinito vale al prossimo avvio. In `man systemctl` c'è anche un comando che porta la macchina in un target adesso, fermando ciò che a quel target non serve.

**Dopo.** Cosa si è fermato quando hai cambiato target a caldo? Cosa fermerebbe lo stesso comando verso `rescue.target`, lanciato da una sessione SSH? Cosa vuol dire `AllowIsolate=yes` in `systemctl cat multi-user.target`? Come si chiamavano questi due target ai tempi dei runlevel?

---

## Problema 2 — Un avvio di manutenzione

**Situazione.** Il fornitore dello storage chiede un controllo completo del filesystem di `/srv/dati`, forzato anche se risulta pulito, con la macchina avviata in modalità di soccorso: niente servizi, niente rete, solo root in console. Un avvio solo: poi la macchina torna normale.

> [!info] Il contesto
> **Lo scenario.** Alcune manutenzioni si fanno con la macchina ferma, ma non spenta: nessun servizio che scrive sui dischi, nessun utente collegato. Si sceglie dal menu di GRUB, per quell'avvio soltanto.
> - **Modalità di soccorso** (*rescue mode*): systemd monta i filesystem locali e si ferma, con una shell di root sulla console. È l'erede del *single user*.
> - **Riga di comando del kernel** (*kernel command line*): i parametri che GRUB passa al kernel. Alcuni li legge il kernel, altri systemd (`cat /proc/cmdline`).
> - **Voce del menu** (*menu entry*): dal menu di GRUB si può modificare prima di avviarla. La modifica vale per quell'avvio e non si salva da nessuna parte.
>
> **Perché conta.** Una modifica fatta per un avvio solo e poi dimenticata in configurazione fa ripartire la macchina in soccorso al prossimo aggiornamento, senza rete, di notte.

**Compito.** `sudo ./prepara.sh 08 2`, poi esegui `palestra/l08/ticket-2.txt`:

- un solo avvio in modalità di soccorso, scelto a mano dal menu di GRUB, senza cambiare né il target predefinito né la configurazione;
- in quell'avvio, il controllo completo e forzato del filesystem di `/srv/dati`;
- poi la macchina riparte normale, con `/srv/dati` montato come da `/etc/fstab` e i dati intatti.

Criteri di accettazione: dopo l'avvio normale, `sudo ./verifica.sh 08 2` esce con 0.

**Verifica.** `sudo ./verifica.sh 08 2`

> [!question]- Indizio 1
> Il menu resta pochi secondi: appena compare, premi una freccia per fermarlo. Cosa dicono le righe in fondo allo schermo? Quale tasto modifica la voce evidenziata?

> [!question]- Indizio 2
> Come si chiede a systemd un target diverso dalla riga del kernel? Cercalo in `man kernel-command-line` o in `man systemd`, sezione *KERNEL COMMAND LINE*. E in quale delle righe della voce va scritto?

> [!question]- Indizio 3
> In modalità di soccorso `/srv/dati` è montato? Si può controllare un filesystem montato?

> [!question]- Indizio 4
> Il controllo ha risposto in un attimo che è tutto pulito? Leggi in `man e2fsck` come si chiede un controllo anche quando il filesystem dice di essere a posto.

**Dopo.** Dov'è finita la tua modifica dopo il riavvio? Cosa mostra `journalctl -b -1 -k | grep 'Command line'`? Che differenza c'è fra soccorso ed emergenza? Cosa succederebbe con root bloccato (`passwd -S root`)? Chiunque abbia la console può modificare le voci del menu: come lo si impedisce, e a che prezzo (`grub2-setpassword`)?

---

## Problema 3 — I parametri del fornitore

**Situazione.** Il fornitore del database vuole le *transparent huge pages* disattivate fin dall'avvio, con il parametro del kernel `transparent_hugepage=never`, su tutti i kernel di adesso e su quelli che arriveranno. E vuole il menu di GRUB visibile 10 secondi.

> [!info] Il contesto
> **Lo scenario.** Database, macchine virtuali, driver: molti fornitori chiedono parametri del kernel precisi, e li ricontrollano dopo ogni aggiornamento.
> - **Pagina enorme** (*huge page*): una pagina di memoria da 2 MiB invece di 4 KiB. Con le *transparent huge pages* il kernel le crea da solo, e certi database rallentano.
> - **BLS** (*Boot Loader Specification*, specifica del caricatore di avvio): su Rocky 9 ogni kernel ha la sua voce del menu, un file in `/boot/loader/entries`, con i suoi parametri.
> - **Kernel futuri**: chi installa un kernel nuovo gli scrive una voce, con i parametri presi da un file di configurazione o, se manca, dal kernel che sta girando: non dalla voce predefinita.
>
> **Perché conta.** Un parametro scritto nel posto sbagliato sembra a posto. Si scopre che manca al primo aggiornamento del kernel, quando il supporto del fornitore lo cerca.

**Compito.** `sudo ./prepara.sh 08 3`, poi esegui `palestra/l08/ticket-3.txt`:

- `transparent_hugepage=never` su tutti i kernel installati, compreso quello di soccorso, e su quelli futuri;
- presente anche nelle impostazioni da cui si rigenera la configurazione di GRUB;
- il menu di GRUB visibile 10 secondi;
- alla fine, dopo il riavvio concordato, la macchina gira con il parametro.

Criteri di accettazione: dopo il riavvio, `sudo ./verifica.sh 08 3` esce con 0, e `cat /sys/kernel/mm/transparent_hugepage/enabled` mostra `[never]`.

**Verifica.** `sudo ./verifica.sh 08 3`

> [!question]- Indizio 1
> Rileggi [[bootloader-grub|Bootloader e GRUB]], poi guarda `/boot/loader/entries`: quante voci ci sono, e cosa c'è nella riga `options`?

> [!question]- Indizio 2
> Su RHEL c'è uno strumento fatto per cambiare le voci di tutti i kernel insieme. `man -k kernel` e `man -k grub`: quale descrizione parla di configurare il bootloader?

> [!question]- Indizio 3
> Da dove prende i parametri un kernel che si installa domani? Leggi `/usr/lib/kernel/install.d/20-grub.install` cercando *cmdline*.

> [!question]- Indizio 4
> Il tempo del menu non sta nelle voci. Dove sta, e chi lo trasforma nel file che GRUB legge davvero? Guarda le prime righe di `/boot/grub2/grub.cfg`.

**Dopo.** Oltre alle voci, quali file ha cambiato lo strumento? Confronta con la fotografia in `/var/lib/lab-linux/base/avvio/`. Cosa fa l'opzione `--update-bls-cmdline` di `grub2-mkconfig`? Rileggi [[bootloader-grub|Bootloader e GRUB]]: le fasi stage 1, 1.5 e 2 descrivono GRUB 2? E la frase di [[mbr-gpt|MBR e GPT]] «un sistema BIOS tradizionale non può fare boot da GPT»: cosa serve a GRUB per farlo (cerca *BIOS boot partition*)?

---

## Problema 4 — Il kernel nuovo non parte

**Situazione.** Stanotte gli aggiornamenti hanno installato un kernel nuovo e l'hanno reso il predefinito. Al riavvio la macchina si è bloccata. Il fornitore indaga: nel frattempo la macchina deve tornare in servizio con il kernel di prima.

> [!info] Il contesto
> **Lo scenario.** Un `/boot` pieno a metà aggiornamento, un modulo che manca, un driver che non va con l'hardware: un kernel nuovo che non parte è un classico. Per questo RHEL tiene installati anche i kernel precedenti.
> - **Kernel panic** («panico del kernel»): un errore da cui il kernel non sa riprendersi. Stampa il motivo e si ferma.
> - **Initramfs** (*initial RAM filesystem*): il piccolo filesystem che il kernel usa per trovare il disco di sistema ([[initramfs|Initramfs]]). Se è rotto, il kernel non trova la radice.
> - **Voce predefinita** (*default entry*): la voce che GRUB avvia se nessuno sceglie. La ricorda per nome in un piccolo file di variabili.
> - **Ripristina** (*reset*): in VirtualBox, il pulsante di reset della macchina (menu Macchina).
>
> **Perché conta.** Scegliere il kernel buono dal menu salva la notte, ma non il riavvio successivo. E il prossimo aggiornamento rimette il kernel nuovo davanti a tutti.

**Compito.** `sudo ./prepara.sh 08 4`, poi esegui `palestra/l08/ticket-4.txt`. Il ticket ti fa riavviare con la console aperta. Alla fine:

- la macchina gira con il kernel di prima, che resta il predefinito anche ai prossimi riavvii;
- il kernel nuovo resta installato e nel menu;
- un altro aggiornamento del kernel non cambierà il predefinito.

Criteri di accettazione: `sudo ./verifica.sh 08 4` esce con 0, e `uname -r` stampa il kernel di prima.

**Verifica.** `sudo ./verifica.sh 08 4`

> [!question]- Indizio 1
> Leggi le ultime righe prima del blocco: cosa non riesce a montare il kernel? Rileggi [[initramfs|Initramfs]]: chi doveva trovarlo?

> [!question]- Indizio 2
> Nel menu di GRUB, in che ordine sono le voci? Da dove viene quell'ordine?

> [!question]- Indizio 3
> Con la macchina partita: dove ricorda GRUB la voce predefinita? `grub2-editenv list`. Lo strumento del problema 3 sa anche cambiarla: cerca *default* nella sua pagina di manuale.

> [!question]- Indizio 4
> Chi rende predefinito un kernel appena installato? Cerca fra i file di `/etc/sysconfig` quello che parla dei kernel.

**Dopo.** Perché il kernel nuovo non ha la sua cartella in `/lib/modules`, e sarebbe servita? Come si rigenera un initramfs (`man dracut`)? Quanti kernel tiene installati `dnf` (`installonly_limit` in `/etc/dnf/dnf.conf`)? Cosa fanno `boot_success` e `boot_indeterminate` in `grub2-editenv list`?

---

## Pulizia — Riportare l'avvio allo standard

**Situazione.** Il fornitore ha chiuso il caso e il database è stato spostato. Sulla macchina restano il kernel di prova, il parametro del fornitore dappertutto, il menu a 10 secondi, gli aggiornamenti del kernel bloccati e il disco dedicato con `/srv/dati`.

> [!info] Il contesto
> **Lo scenario.** Anche le eccezioni si dismettono. Un server che si discosta dallo standard senza un motivo scritto è un server che nessuno sa più gestire.
> - **Deriva della configurazione** (*configuration drift*): le differenze che si accumulano fra macchine che dovrebbero essere uguali.
>
> **Perché conta.** Un parametro tolto dalle voci ma non dalla configurazione dei kernel futuri torna da solo al prossimo aggiornamento.

**Compito.** `sudo ./prepara.sh 08 pulizia`, poi esegui `palestra/l08/ticket-pulizia.txt`:

- via i file e la voce del kernel di prova;
- via `transparent_hugepage=never` da tutti i kernel e da ogni configurazione, anche per i kernel futuri;
- il menu torna al tempo di prima, i kernel nuovi tornano predefiniti e il predefinito è il kernel più recente;
- il disco dedicato restituito pulito, `/etc/fstab` com'era prima della lezione.

Criteri di accettazione: `sudo ./verifica.sh 08 pulizia` esce con 0.

**Verifica.** `sudo ./verifica.sh 08 pulizia`

> [!question]- Indizio 1
> Togliere una voce dal menu toglie anche i file del kernel? Guarda in `/boot` dopo averlo fatto.

**Dopo.** In quanti posti stava il parametro del fornitore, e quale avresti dimenticato più facilmente? Perché il kernel di prova non si poteva togliere con `dnf`?

---

## Diario

Domande numerate, risposte, correzioni ed errori di questa lezione, problema per problema.

## Sintesi

Da scrivere insieme a lezione finita, partendo dalle mie parole.

---

↑ [[00-percorso-linux|Il percorso]] · ← [[07-fsck-emergency|Lezione 07]] · → [[09-systemd|Lezione 09]]
