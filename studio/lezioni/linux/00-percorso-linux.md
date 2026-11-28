---
tags:
  - lezione
  - linux
aliases:
  - Linux — Il percorso
---
# Linux — Il percorso

L'amministrazione di Linux si impara facendo il lavoro: ogni problema è un ticket, un incidente o un cambio pianificato, come quelli che arrivano a un sistemista. Si parte dal disco nudo e si arriva a una macchina che non si avvia più e va riparata. Il metodo per le sessioni con Claude è nella «Modalità problema» di `CLAUDE.md`; il kit è in `lab/linux/`.

Il percorso copre la parte di sistema dell'esame RHCSA (EX200): storage, avvio, systemd, SELinux e firewall. La mappa sugli obiettivi è in fondo.

## La mappa

| # | Lezione | Il caso pratico | Ore | Stato |
|---|---|---|---|---|
| 01 | [[01-dischi-partizioni\|Dischi e partizioni]] | Il disco nuovo, l'apparato MBR, una partizione a caldo | 5 | — |
| 02 | [[02-filesystem\|Filesystem]] | Tre filesystem, la posta ferma, il disco ingrandito | 6 | — |
| 03 | [[03-mount-fstab-uuid\|Mount, fstab e UUID]] | Il montaggio che sparisce, i dischi che cambiano nome, il disco che a volte non c'è, la cartella del gruppo | 6 | — |
| 04 | [[04-swap\|Swap]] | Il database ucciso di notte, swap senza spazio libero, swap da togliere | 3 | — |
| 05 | [[05-lvm\|LVM]] | Un volume più grande dei dischi, lo spazio che finisce, il disco che sta per rompersi, il disco di un altro server | 7 | — |
| 06 | [[06-lvm-snapshot\|Snapshot LVM]] | La fotografia prima dell'aggiornamento, il ritorno indietro, l'etichetta cancellata per sbaglio | 5 | — |
| 07 | [[07-fsck-emergency\|fsck ed emergency mode]] | I log spariti, il filesystem da ripulire, il log da rigiocare, la macchina ferma in emergenza | 7 | — |
| 08 | [[08-avvio-grub\|Avvio e GRUB]] | Il target sbagliato, l'avvio di manutenzione, i parametri del fornitore, il kernel che non parte | 6 | — |
| 09 | [[09-systemd\|systemd]] | L'applicazione lanciata a mano, i limiti dei lavori di cron, il report per New York, l'avvio lento | 6 | — |
| 10 | [[10-selinux-firewalld\|SELinux e firewalld]] | Il sito che non si vede, SELinux in permissive, Apache che non riparte, il proxy che risponde 503 | 7 | — |
| 11 | [[11-progetto-finale\|Progetto finale]] | La macchina che non torna su dopo la manutenzione notturna: otto guasti lungo la catena di avvio, e il resoconto dell'incidente | 8 | — |

Si fanno nell'ordine dei numeri: ogni lezione usa ciò che hanno costruito le precedenti.

## Due settimane

Una proposta per otto ore al giorno, con un po' di margine per il report e il lavoro dei tutor. Se una lezione sfora, si sposta tutto avanti: conta capire, non finire.

| Giorno | Lezioni | Ore |
|---|---|---|
| 1 | Preparare la macchina, 01 | 7 |
| 2 | 02 | 6 |
| 3 | 03 | 6 |
| 4 | 04, inizio 05 | 7 |
| 5 | Fine 05, 06 | 8 |
| 6 | 07 | 7 |
| 7 | 08 | 6 |
| 8 | 09 | 6 |
| 9 | 10 | 7 |
| 10 | 11 | 8 |

## Come funziona un problema

1. **Situazione** e riquadro **Il contesto**: dove si incontra quel caso nel lavoro vero, le parole del mestiere con il loro nome e cosa va storto se lo si fa male.
2. **Compito**: arriva come ticket, che `prepara.sh` stampa e salva in `lab/linux/palestra/lNN/ticket-P.txt`. Dice cosa deve essere vero alla fine e con quali vincoli (a caldo, senza perdere dati, senza riavvio). I **criteri di accettazione** sono comandi con il codice di uscita atteso: almeno `sudo ./verifica.sh NN P`, che deve uscire con 0.
3. **Il tuo tentativo**: ragioni, cerchi nella documentazione (`man`, `--help`, `man -k`), provi.
4. **Indizi**: domande chiuse in riquadri, da aprire una alla volta. Nessuna contiene la soluzione.
5. **Verifica**: il correttore guarda lo stato della macchina, non l'output dei tuoi comandi.
6. **Dopo**: domande per spiegare ciò che hai fatto e scendere ai meccanismi.

Alcuni problemi hanno forme particolari:

- **Previsioni**: conti e risposte sulla carta prima di toccare la macchina. Si controllano a mano con Claude.
- **Automatizza**: uno script con argomenti e codici di uscita, come nel percorso di scripting. Il correttore lo prova solo su dischi di prova.
- **Con riavvio** (dalla lezione 07): il correttore guarda la macchina dopo il reboot e i log degli avvii precedenti.

Uno scenario alla volta: ogni `prepara.sh NN P` azzera i dischi dedicati e prepara solo il problema P. Ogni lezione finisce con una **Pulizia**, in cui dismetti a mano ciò che la lezione lascia sulla macchina.

> [!warning] Non leggere il kit prima di risolvere
> Per preparare la Pulizia, `prepara.sh` ricostruisce la macchina come la lasciano i problemi risolti: chi lo legge vede le soluzioni. Aprilo solo a lezione finita, per confrontarlo con ciò che hai fatto tu.
>
> `verifica.sh` è meno pericoloso, ma dice esattamente cosa controlla, e quindi cosa serve. Quando una verifica fallisce, basta il suo messaggio: parti da lì.

## Il kit e la sicurezza

Le operazioni distruttive si fanno solo sui **bersagli**: i dischi dedicati della VM, o in alternativa immagini collegate a dispositivi loop. Il disco di sistema non si tocca mai.

```sh
sudo ./prepara.sh dischi          # inventario dei bersagli, una volta sola
sudo ./prepara.sh 01 [P]          # azzera i bersagli e prepara il problema P
sudo ./prepara.sh 01 pulizia      # la macchina com'è a fine lezione
sudo ./prepara.sh azzera          # bersagli vuoti
sudo ./prepara.sh 01 3 --a-secco  # stampa ciò che farebbe, senza scrivere
sudo ./verifica.sh 01 [P]         # il problema preparato ora, o P
sudo ./verifica.sh stato          # gli esiti registrati
```

**L'inventario.** `prepara.sh dischi` propone solo dischi con modello «VBOX HARDDISK», fino a 16 GiB, che non portano a nulla di montato e non contengono swap o PV di LVM. Ognuno lo confermi scrivendo le ultime cifre del seriale. I bersagli si chiamano D1, D2, D3 e sono registrati per seriale, perché i nomi come `sdb` possono cambiare a ogni avvio. L'inventario fotografa anche `/etc/fstab`, per poterlo confrontare a fine lezione.

**La guardia.** Prima di ogni scrittura, e prima che il correttore guardi un disco, `lib/comune.sh` controlla da capo che:

1. il disco sia nell'inventario e abbia ancora quel seriale, quel modello e al massimo 16 GiB;
2. nessun filesystem montato fuori dai punti del kit (`/srv/archivio`, `/srv/app`, …) venga da quel disco: per questo il disco di sistema, che porta a `/`, viene sempre rifiutato;
3. nessun VG di LVM usi insieme quel disco e un disco che non è un bersaglio;
4. la macchina sia virtuale.

Se un controllo fallisce, il kit si ferma con codice 3 e non tocca niente.

**Azzerare.** Ogni `prepara.sh` comincia da `azzera`, che riporta allo stato dell'inventario solo ciò che il kit tocca:

- le swap attive dai dischi dedicati e i montaggi che vengono da lì;
- i VG di LVM che stanno solo sui dischi dedicati, con i loro LV, le etichette dei PV e le voci di quei dischi nel file dei dispositivi di LVM;
- le righe di `/etc/fstab` che li citano, quelle che ha scritto il kit anche se puntano a un dispositivo che non c'è più (la swap del progetto finale) e quelle sui punti del kit che non portano più a niente, con una copia del file prima della modifica in `/var/lib/lab-linux/` (si tengono le venti più recenti). Una riga tua che monta altro su un punto del kit (`/srv/www`, `/srv/dati`…) non si tocca: `azzera` si rifiuta (codice 3) finché non la sposti;
- le firme sui dischi dedicati;
- gli utenti e i gruppi di prova (anna, luca, marco, sviluppo), se li ha creati il kit;
- `vm.swappiness`, insieme ai file di `/etc/sysctl.d` nati dopo l'inventario che impostano solo quella;
- dalla lezione 07, il journal e l'avvio: i file di `/etc/systemd/journald.conf.d` nati dopo la fotografia, il target predefinito, le opzioni delle voci di GRUB, `/etc/default/grub`, `/etc/kernel/cmdline`, `/etc/sysconfig/kernel` e il kernel finto della lezione 08. La fotografia si fa al primo `prepara.sh` delle lezioni 07, 08, 10 o 11, in `/var/lib/lab-linux/base/avvio/`; i kernel veri installati nel frattempo restano;
- dalla lezione 09, i servizi: le unità della lezione (`lab-app`, `lab-report`, `lab-sincro`, `lab-backend`) dovunque siano scritte, comprese quelle transitorie del report, i ritocchi di `crond` nati dopo la fotografia (fatta al primo `prepara.sh` della 09 o della 11, in `/var/lib/lab-linux/base/servizi/`) e i programmi del kit in `/opt` e `/var/lib`;
- dalla lezione 10, Apache, firewalld e SELinux: i file di `/etc/httpd/conf.d` nati dopo la fotografia che non sono di un pacchetto, `/etc/firewalld` e la configurazione attiva del firewall, le personalizzazioni di `semanage`, i booleani, la modalità di SELinux e i moduli locali nati dopo. La fotografia si fa al primo `prepara.sh` della 10 o della 11 che li trova installati, in `/var/lib/lab-linux/base/web/`.

Journal e avvio, `crond`, Apache, firewalld e SELinux tornano alla fotografia solo se dall'ultimo `azzera` hai preparato un problema di una lezione che li usa: la configurazione che fai per conto tuo nelle altre lezioni (una porta, un booleano, un modulo di SELinux, un ritocco di un servizio) resta. Quando li riporta, `azzera` tiene prima una copia di ciò che toglie o cambia in `/var/lib/lab-linux/copie/` (le venti più recenti), con il percorso intero: i moduli di SELinux tolti, le personalizzazioni di `semanage`, i booleani e `/etc/firewalld`.

Tutto il resto della macchina non si tocca.

**Cosa la guardia non può fare:** fermare un comando sbagliato scritto a mano. Per quello valgono la fotografia della VM e un'abitudine: prima di ogni scrittura, `lsblk -o NAME,SIZE,MODEL,SERIAL,MOUNTPOINTS`.

**Codici di uscita** di `prepara.sh` e `verifica.sh`: 0 fatto o tutto passa, 1 non riuscito o qualcosa non passa, 2 uso sbagliato o scenario non preparato, 3 rifiuto, 4 serve root.

## Preparare la macchina

Si lavora sulla VM `lab-rocky` del [[laboratorio-installazione-rocky|laboratorio Rocky]].

**1. Tre dischi dedicati**, sul Mac e a VM spenta. Una cartella dei dischi solo per `lab-rocky` evita di agganciare i `.vdi` di un'altra VM:

```sh
VM=lab-rocky DISCHI_EXTRA_N=3 DISCHI_DIR="$HOME/VirtualBox VMs/lab-rocky-dischi" ./lab/vm/aggiungi-dischi.sh
```

**2. Una fotografia**, sempre a VM spenta, prima di cominciare e poi prima delle lezioni dalla 07 in poi:

```sh
VBoxManage snapshot lab-rocky take prima-di-linux
VBoxManage snapshot lab-rocky restore prima-di-linux   # per tornare indietro, a VM spenta
```

**3. Gli strumenti**, dentro la VM. La ISO minimal può non averli tutti:

```sh
sudo dnf install -y parted gdisk cloud-utils-growpart jq dosfstools xfsprogs e2fsprogs lvm2 psmisc \
    httpd firewalld policycoreutils-python-utils setroubleshoot-server
```

**4. Il kit e l'inventario:**

```sh
cd formazione_sou/lab/linux
sudo ./prepara.sh dischi
```

**5. La password di root**, che può servire dalla lezione 06 e servirà dalla 07: in emergency mode il sistema la chiede, e se root è bloccato non si entra. `sudo passwd -S root` dice com'è messo.

Si entra con l'utente del laboratorio e si usa `sudo` comando per comando, non una shell di root: si vede meglio cosa richiede poteri speciali.

## La mappa sull'esame RHCSA

Gli obiettivi sono nella formulazione dell'EX200 per RHEL 9. Secondo fonti non ufficiali l'esame oggi è basato su RHEL 10, senza la parte sui container e con Flatpak; per gli argomenti di questo percorso gli strumenti sono gli stessi. Vanno confrontati con la pagina ufficiale di Red Hat.

| Area | Obiettivo | Lezione |
|---|---|---|
| Configure local storage | List, create, delete partitions on MBR and GPT disks | 01 |
| | Create and remove physical volumes; assign them to volume groups; create and delete logical volumes | 05 |
| | Configure systems to mount file systems at boot by UUID or label | 03 |
| | Add new partitions and logical volumes, and swap to a system non-destructively | 01, 04, 05 |
| Create and configure file systems | Create, mount, unmount, and use vfat, ext4, and xfs file systems | 02, 03 |
| | Extend existing logical volumes | 05 |
| | Create and configure set-GID directories for collaboration | 03 |
| | Diagnose and correct file permission problems | 03, 10 (in parte) |
| Operate running systems | Boot systems into different targets manually | 08 |
| | Interrupt the boot process in order to gain access to a system | fuori: vedi sotto |
| | Locate and interpret system log files and journals; preserve system journals | 07, 08, 09 |
| | Start, stop, and check the status of network services | 09, 10 |
| | Boot, reboot, and shut down a system normally | 07, 08 (in parte) |
| Deploy, configure, and maintain systems | Start and stop services and configure services to start automatically at boot | 09 |
| | Configure systems to boot into a specific target automatically | 08 |
| | Modify the system bootloader | 08 |
| | Schedule tasks | 09 per i timer; cron è nello scripting, lezione 10 |
| Manage security | Configure firewall settings using firewall-cmd/firewalld | 10 |
| | Set enforcing and permissive modes for SELinux | 10 |
| | List and identify SELinux file and process context; restore default file contexts | 10 |
| | Manage SELinux port labels; use boolean settings | 10 |
| | Diagnose and address routine SELinux policy violations | 10, 11 |

**Resta fuori:**

- L'interruzione dell'avvio per riprendere il controllo di una macchina di cui non si ha la password di root. Il percorso usa sempre la password di root, impostata prima della lezione 07; per questo obiettivo vale il materiale ufficiale di Red Hat.
- NFS e autofs: possibile lezione 12, con il server NFS sulla stessa VM.
- Rete con `nmcli`, risoluzione dei nomi.
- Utenti, password e sudo: lo scripting 07 ne tocca una parte.
- Pacchetti e repository: c'è la [[lezione-4-installazione-pacchetti|lezione 4]].
- Sincronizzazione dell'ora (chrony), profili di tuned, priorità dei processi e `kill`: ci sono gli appunti dei [[mappa-processi|processi]].
- `at`, `umask`, SSH con chiavi: c'è il [[laboratorio-vm-headless-ssh|laboratorio SSH]].
- Archivi e trasferimenti di file: lo scripting 08.
- Strumenti di base, testo e script: il [[00-percorso|percorso di scripting]].
- Container (RHEL 9) e Flatpak (RHEL 10).
- Fuori dall'esame, solo nominati nelle domande «Dopo»: thin pool, Stratis, VDO, RAID.

## Gli appunti da rileggere

Le lezioni rimandano agli appunti di `studio/01-hardware-boot`, `02-init-servizi` e `03-storage`, senza ripeterli. Alcune frasi di quegli appunti vanno controllate: le lezioni sono fatte apposta per metterle alla prova, e la correzione va scritta solo dopo averla scoperta.

| Appunto | La frase da controllare | Dove |
|---|---|---|
| [[mbr-gpt\|MBR e GPT]] | Nella GPT «il primo settore viene lasciato vuoto» | 01, previsioni |
| [[mbr-gpt\|MBR e GPT]] | Il codice dell'MBR «viene scritto nel primo settore della partizione» | 01, previsioni |
| [[mbr-gpt\|MBR e GPT]] | «Un sistema BIOS tradizionale non può fare boot da GPT» | 08 |
| [[strumenti-partizionamento\|Strumenti di partizionamento]] | `fdisk` è «progettato per funzionare con MBR» | 01 |
| [[swap\|Swap]] | La *swappiness* è una «soglia di attivazione» | 04 |
| [[bootloader-grub\|Bootloader e GRUB]] | Le fasi stage 1, 1.5 e 2 descrivono GRUB 2 | 08 |
| [[systemd\|systemd]] | `network.target` è il punto in cui il computer ottiene l'indirizzo IP | 09 |
| [[integrita-fsck\|Integrità e fsck]] | La sesta colonna di fstab vale allo stesso modo per ogni filesystem | 03, 07 |

## Le fonti

| Fonte | Cosa ho preso |
|---|---|
| Pagine di manuale di util-linux 2.37 (`sfdisk`, `fdisk`, `lsblk`, `findmnt`, `blkid`, `wipefs`), e2fsprogs 1.46, xfsprogs 6.4, parted 3.5 | Le opzioni e i comportamenti su cui si reggono scenari e controlli |
| Pagine di manuale di systemd 252 (`systemd.unit`, `.service`, `.exec`, `.resource-control`, `.timer`, `.time`, `.special`, `systemd-run`), firewalld 1.3 (`firewall-cmd`, `firewalld.zones`), policycoreutils 3.6 (`semanage`, `restorecon`, `setsebool`, `audit2why`) | Le stesse cose, per le lezioni 09 e 10 |
| Obiettivi dell'EX200 per RHEL 9 (Red Hat) | La mappa sull'esame |
| Guide di terze parti sull'EX200 per RHEL 10 ([GoLinuxCloud](https://www.golinuxcloud.com/rhcsa-tutorial/), [WebAsha](https://www.webasha.com/blog/online-rhcsa-ex200-training-certification-study-material-exam-readiness-for-rhel)) | Il passaggio a RHEL 10, senza container e con Flatpak: da confermare sul sito di Red Hat |

Le trappole dei problemi sono provate, non dedotte: ogni problema è stato collaudato su una Rocky Linux 9.8 con dischi SATA «VBOX HARDDISK», con una soluzione giusta, che passa, e una ingenua, che il correttore boccia. Le soluzioni non sono nel repo.

---

↑ [[00-home|Home]] · [[mappa-storage|Storage]] · [[mappa-hardware-boot|Hardware e boot]] · [[mappa-init-servizi|Init e servizi]]
