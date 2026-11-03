---
tags:
  - lezione
  - laboratorio
aliases:
  - Laboratorio — Installazione manuale di Arch Linux
---
# Laboratorio — Installazione manuale di Arch Linux

Installazione di Arch Linux a mano, su una VM VirtualBox creata dal lab del repo. Ogni passo risponde a tre domande: **cosa** fa il comando, **perché** serve in quel momento, **come** si chiama e da dove viene il nome. Le domande numerate sono quelle a cui ho risposto durante il percorso, con la correzione.

## La mappa

| # | Passo | Stato |
|---|---|---|
| 0 | Creare la VM | ✅ |
| 1 | Preparare l'ambiente live (tastiera, firmware, rete, orologio) | ✅ |
| 2 | Partizionare il disco | ✅ |
| 3 | Formattare le partizioni | ✅ |
| 4 | Montarle | ✅ |
| 5 | Installare il sistema base (`pacstrap`) | ✅ |
| 6 | Generare `fstab` (`genfstab`) | ✅ |
| 7 | Entrare nel nuovo sistema (`arch-chroot`) e configurarlo | ✅ |
| 8 | Installare il bootloader (GRUB) | ✅ |
| 9 | Riavviare senza ISO | ⏳ in corso |

Lo schema scelto:

| Partizione | Dimensione | Tipo (Id) | Filesystem | Mount | Boot |
|---|---|---|---|---|---|
| `sda1` | 17,5 GiB | 83 Linux | ext4 | `/` | `*` |
| `sda2` | 2,5 GiB | 82 Linux swap | swap | — | |

Tabella **MBR** (*dos*), firmware **BIOS**.

---

## 0. Creare la VM

### Scegliere l'OS type

VirtualBox vuole sapere che sistema ospiterà la VM (`--ostype`) per scegliere default sensati: controller, orologio, grafica.

```sh
VBoxManage list ostypes
make lab-ostypes          # solo Rocky/RedHat, Debian e Arch
```

- **`VBoxManage`**: *VirtualBox Manage*, il comando che controlla VirtualBox da terminale.
- Dalla versione 7.2 l'output ha la forma `ID / Description: ArchLinux_64 -- Arch Linux (64-bit)`, seguita dalle righe `Family` e `Architecture`. Il valore da usare è l'**ID**.
- L'ID deve corrispondere all'architettura della ISO: `archlinux-…-x86_64.iso` → **`ArchLinux_64`**. `_arm64` è per le ISO ARM; `ArchLinux` senza suffisso è a 32 bit.
- Rocky Linux non ha un ID suo: si usa `RedHat9_64`/`RedHat10_64`, perché Rocky è binario-compatibile con RHEL.

```sh
VM_OSTYPE=ArchLinux_64 ISO=archlinux-2026.10.01-x86_64.iso VM=lab-arch make doctor
VM_OSTYPE=ArchLinux_64 ISO=archlinux-2026.10.01-x86_64.iso VM=lab-arch make lab-crea
```

`doctor` va lanciato prima: verifica che l'ID esista e che l'architettura sia coerente con la ISO.

### Cosa crea `crea-lab.sh`

| Impostazione | Valore | Conseguenza |
|---|---|---|
| Firmware | non impostato → **BIOS legacy** | niente partizione EFI, GRUB in modalità BIOS |
| Disco | VDI 20 GiB, porta SATA 0 | `/dev/sda` |
| ISO | porta SATA 1, come DVD | `/dev/sr0` |
| RAM / CPU | 2 GB / 2 | |
| Rete | NAT | esce su internet tramite l'host, con DHCP |

All'avvio si entra nel **sistema live** (`root@archiso`): un Linux completo che non usa il disco `sda`. La sua radice è un **overlay**: `airootfs.sfs` dalla ISO in sola lettura (`loop0`), più uno strato scrivibile in RAM (*tmpfs*) che raccoglie ogni modifica. La ISO può anche essere copiata tutta in RAM (`copytoram`), ma nel lab `loop0` e `sr0` restano in uso. Arch non è ancora installato: tutto quello che si fa qui sparisce al riavvio finché non lo si scrive su disco.

> Per interrompere e riprendere: `VBoxManage controlvm lab-arch savestate` congela la VM con la RAM inclusa; `VBoxManage startvm lab-arch` la riprende. Se invece la spegni, il live riparte da zero, ma il disco resta com'era.

---

## 1. Preparare l'ambiente live

### 1a. Tastiera — `loadkeys it`

- **Nome:** *load keys*, carica la tabella dei tasti.
- **Cosa:** carica nel kernel la *keymap* italiana, cioè la tabella "tasto fisico → carattere". Vale solo per la console e solo per questa sessione.
- **Perché ora:** fra poco si scrivono password.

> **D1.** Che succede se imposti la password con la tastiera US credendo che sia italiana?
> **R.** Alcuni caratteri non corrispondono e al login non riesci più a entrare. ✅
> In più: nel sistema installato la tastiera va reimpostata in `/etc/vconsole.conf` (passo 7), altrimenti torna US.

### 1b. BIOS o UEFI — `ls /sys/firmware/efi`

- **Nome:** `/sys` è **sysfs**, un filesystem virtuale: non sta su disco, è il kernel che espone le sue informazioni sotto forma di file → [[pseudo-filesystem-sys-proc|Pseudo-filesystem /sys e /proc]].
- **Cosa:** se il kernel è stato avviato da UEFI, crea `/sys/firmware/efi`; se è stato avviato da BIOS, quella cartella non esiste.
- **Risultato:** `No such file or directory` → **BIOS**. Il `2` rosso nel prompt successivo è il **codice di uscita** di `ls` (0 = ok, 2 = problema serio).

> **D2.** Perché saperlo *prima* di toccare il disco?
> **R.** Il firmware decide come parte il computer, e quindi quali partizioni servono → [[firmware-bios-uefi|Firmware, BIOS e UEFI]]:
> - **UEFI** sa leggere un filesystem FAT32: cerca la *EFI System Partition* e avvia un file `.efi`;
> - **BIOS** non conosce i filesystem: legge i **primi 512 byte** del disco ed esegue il codice che ci trova.
>
> Non è solo "MBR o GPT": il BIOS avvia anche GPT, ma serve una partizione *BIOS boot* per GRUB.

**Altri modi per saperlo**, oltre a `ls /sys/firmware/efi`:

| Comando / indizio | UEFI | BIOS |
|---|---|---|
| `cat /sys/firmware/efi/fw_platform_size` (il metodo della wiki di Arch) | `64`, o `32` per un UEFI a 32 bit (raro, alcuni tablet: GRUB va installato con target `i386-efi`) | il file non esiste |
| `efibootmgr`, `efivar -l`, `ls /sys/firmware/efi/efivars` | le voci di avvio (`BootOrder`, `Boot0001`, …) | *"EFI variables are not supported on this system"* |
| `dmesg \| grep -i efi` | righe come `efi: EFI v2.x by …` con le tabelle (ACPI, SMBIOS) | quasi niente |
| Il menu della ISO all'avvio | **systemd-boot**: testo semplice su sfondo nero | **syslinux**: grafico, con il logo di Arch |

**Attenzione:** tutti questi controlli dicono come ha fatto il boot la *ISO live*, non cosa sa fare la macchina. Un PC UEFI con il **CSM** (*Compatibility Support Module*, l'emulazione del BIOS) attivo può avviare la chiavetta in modalità legacy, e allora `/sys/firmware/efi` non c'è. Il sistema installato partirà come è partita la ISO: se ti aspettavi UEFI e risulta BIOS, riavvia e scegli la voce `UEFI: <nome chiavetta>` dal menu di avvio.

In VirtualBox decide solo *Impostazioni → Sistema → Abilita EFI*: spuntato = UEFI, altrimenti BIOS.

### 1c. Rete — `ip link`, `ping`

- **`ip`**: comando della suite *iproute2*, che sostituisce `ifconfig`. **`link`** = il livello "collegamento", cioè la scheda in sé, prima degli indirizzi IP.
- **`ping`**: dal suono del sonar. Manda un pacchetto ICMP *echo request* e aspetta l'eco. `-c 3` = *count*, 3 pacchetti e poi si ferma.

Nell'output di `ip link`:

- **`lo`** — *loopback*: interfaccia software con cui la macchina parla con sé stessa (`127.0.0.1`).
- **`enp0s3`** — la scheda virtuale di VirtualBox (emula una Intel PRO/1000). È un nome **prevedibile**, costruito da systemd/udev in base alla posizione fisica:

  | Pezzo | Significato |
  |---|---|
  | `en` | **E**ther**n**et (Wi-Fi sarebbe `wl`, *wireless LAN*) |
  | `p0` | bus **P**CI 0 |
  | `s3` | **s**lot 3 |

  Si verifica con `lspci | grep -i ethernet` (*list PCI*) → `00:03.0` = bus 00, slot 03, funzione 0.
- **`altname enx0800274d73fc`**: nome alternativo, `en` + `x` + MAC.
- **`state UP`**: interfaccia attiva. **`link/ether 08:00:27:…`**: il MAC address. `08:00:27` è il prefisso di Oracle/VirtualBox: i primi tre byte identificano il produttore.

> **D5.** Perché non `eth0` come una volta?
> **R.** `eth0`, `eth1` venivano assegnati nell'ordine in cui il kernel trovava le schede, che **non è garantito**. Se l'ordine si inverte, le regole del firewall per internet finiscono sulla scheda interna. Un nome legato alla posizione fisica non cambia finché nessuno sposta la scheda.

> **D3.** La ISO contiene già un Linux: perché serve internet?
> **R.** La ISO è un'**istantanea** pensata per girare in RAM, non un archivio di pacchetti da installare. `pacstrap` scarica i pacchetti dai mirror, e così si ottengono anche le versioni aggiornate: Arch è *rolling release*, la ISO esce una volta al mese.

**A cosa serve la rete, in pratica:**

- **scaricare i pacchetti**: con `pacstrap` al passo 5, e poi nel chroot con `pacman -S` (bootloader, editor, NetworkManager…);
- **sincronizzare l'orologio**: `timedatectl` usa NTP (vedi 1d);
- **ordinare i mirror**: all'avvio del live gira **`reflector`**, che sceglie i mirror più veloci e riscrive `/etc/pacman.d/mirrorlist`.

**"Linux non ha già tutti i driver?"** Sì, e infatti il controllo non riguarda i driver. Il kernel della ISO ha quasi tutti i driver e la live include i firmware, quindi la scheda viene quasi sempre riconosciuta (`ip link` la mostra). Ma *avere un'interfaccia* non vuol dire *essere connessi*. Il controllo verifica che:

| Cosa | Come |
|---|---|
| il cavo sia collegato e l'interfaccia `UP` | `ip link` |
| il DHCP abbia dato un indirizzo | `ip addr` |
| col Wi-Fi ci si sia autenticati: nessun driver conosce la password | `iwctl` |
| l'interfaccia non sia bloccata (es. Wi-Fi spento dal tasto hardware) | `rfkill` |
| connettività **e** DNS funzionino | `ping -c 3 archlinux.org` |

I casi in cui manca davvero un driver o un firmware esistono (alcune schede Wi-Fi recenti o esotiche), ma sono rari.

**Perché prima del partizionamento:** partizionare e formattare sono i passi **distruttivi**. Se cancelli il disco e solo dopo scopri che non hai rete, resti con un disco vuoto e nessun modo di installare. Si verifica tutto quello che serve *prima* di toccare il disco. In VirtualBox con la rete NAT funziona da sola: il DHCP di VirtualBox dà l'indirizzo e basta il `ping` di verifica.

### 1c-bis. Kernel, driver e firmware

Sono due cose diverse che lavorano in coppia: il **driver** gira sulla CPU del computer, il **firmware** sul processore del dispositivo. Molti dispositivi (Wi-Fi, GPU, Bluetooth, alcune schede di rete) contengono un piccolo processore, e quel processore ha bisogno di un suo programma: il firmware.

| | Driver | Firmware |
|---|---|---|
| Dove gira | sulla CPU, dentro il kernel | sul microcontrollore del dispositivo |
| Cosa fa | fa da interfaccia fra sistema operativo e dispositivo | fa funzionare internamente il dispositivo |
| Dove sta | nel kernel o in un modulo (`.ko`) → [[dispositivi-moduli-kernel\|Dispositivi e moduli del kernel]] | file binario in `/usr/lib/firmware/` |
| Licenza | GPL, parte del kernel | spesso proprietario: un *blob* chiuso |

**Come si incontrano.** Molti dispositivi **non conservano il firmware in modo permanente**: costa meno e si aggiorna senza flashare l'hardware. A ogni avvio:

1. il kernel rileva il dispositivo e carica il driver (es. `iwlwifi` per il Wi-Fi Intel);
2. il driver chiama **`request_firmware()`** chiedendo un file preciso, es. `iwlwifi-cc-a0-77.ucode`;
3. il kernel lo cerca in `/usr/lib/firmware/`;
4. il driver lo invia al dispositivo, che solo allora funziona davvero.

Se il file manca, il driver si carica ma il dispositivo resta muto. In `dmesg`:

```
iwlwifi 0000:00:14.3: Direct firmware load for iwlwifi-cc-a0-77.ucode failed with error -2
```

**Perché sono separati.** Il kernel è GPL e non può includere codice proprietario; i firmware stanno quindi nel pacchetto a parte **`linux-firmware`**. Per questo al passo 5 si installano esplicitamente tutti e due: `pacstrap … linux linux-firmware`.

```sh
dmesg | grep -i firmware        # firmware caricati o mancanti
modinfo -F firmware iwlwifi     # quali file può chiedere un driver
ls /usr/lib/firmware            # firmware presenti sul sistema
```

**Serve internet per i firmware?** Dipende dal sistema:

- **Live ISO: no.** I firmware sono già nella ISO. Deve essere così: per scaricarli servirebbe la rete, e senza firmware il Wi-Fi non andrebbe. Un circolo vizioso.
- **Sistema installato: sì.** Il disco è vuoto e `pacstrap` non copia i file dalla live: scarica `linux-firmware` dai mirror come `base` e `linux`. Al primo riavvio i driver lo troveranno su disco. Gli aggiornamenti arrivano con `pacman -Syu`.

Il kernel **non scarica mai niente**: cerca solo file su disco. Internet serve a `pacman` per metterceli.

**Da non confondere:**

- **microcode della CPU** (`intel-ucode`, `amd-ucode`): firmware anche quello, ma per il processore principale. Lo carica il bootloader prima del kernel, per correggere bug della CPU;
- **firmware di sistema** (BIOS/UEFI): stessa parola, altra cosa. È il programma sulla scheda madre che avvia la macchina (1b).

In VirtualBox i dispositivi virtuali (scheda e1000, disco, video) non hanno bisogno di firmware: `linux-firmware` sarebbe superfluo, ma lo si installa comunque.

### 1d. Orologio — `timedatectl`

- **Nome:** *time* + *date* + *ctl* (*control*), lo schema dei tool di systemd (`systemctl`, `journalctl`, `hostnamectl`).
- **Cosa guardare:** `System clock synchronized: yes`, `NTP service: active`. L'ora è in UTC; il fuso italiano si imposta al passo 7.

> **D4.** Che c'entra l'ora con l'installare pacchetti?
> **R.** HTTPS sì. E poi le **firme**: i pacchetti sono firmati con chiavi PGP, e chiavi e certificati hanno una **data di validità**. Con l'orologio sbagliato una firma valida sembra "non ancora valida" o "scaduta", e `pacman` rifiuta. Le *versioni* dei pacchetti invece non dipendono dall'orologio.

**Se l'ora sembra sbagliata.** Prima di tutto controllare che lo sia davvero: il live usa **UTC**, quindi rispetto all'ora italiana è indietro di 1 ora d'inverno e di 2 d'estate. Non è un errore. Contano le righe `System clock synchronized: yes` e `NTP service: active`.

Se è davvero sbagliata:

1. **Controllare la rete.** Il live sincronizza da solo con **`systemd-timesyncd`**, ma solo se è connesso: spesso l'ora è sbagliata perché la rete non va ancora.
2. **Forzare NTP:**
   ```sh
   timedatectl set-ntp true
   systemctl restart systemd-timesyncd
   timedatectl timesync-status      # server NTP usato ed esito
   ```
3. **Se NTP non passa** (es. rete aziendale che blocca la porta UDP 123), impostarla a mano. NTP va disattivato prima, altrimenti il comando viene rifiutato:
   ```sh
   timedatectl set-ntp false
   timedatectl set-time "2026-10-30 13:05:00"    # in UTC
   ```

Nel chroot (passo 7) si imposta il fuso e si salva l'ora nell'orologio hardware (**RTC**, *Real-Time Clock*):

```sh
ln -sf /usr/share/zoneinfo/Europe/Rome /etc/localtime
hwclock --systohc       # system clock → hardware clock
```

In VirtualBox la VM prende l'ora dall'host all'avvio, quindi di solito è giusta. Se è sfasata di qualche ora: *Impostazioni → Sistema → Scheda madre → "Orologio hardware in ora UTC"* va spuntato, perché Linux si aspetta l'RTC in UTC.

---

## 2. Partizionare il disco

Prima di scrivere, si guarda → [[disco-settori|Disco e settori]], [[partizioni|Partizioni]].

### 2a. `lsblk`

- **Nome:** *list block devices*.
- **Dispositivi a blocchi vs a caratteri:** quelli a **blocchi** (dischi) li leggi a pezzi di dimensione fissa, in qualsiasi punto. Quelli a **caratteri** (tastiera, terminale) sono un flusso da leggere in ordine. Un filesystem si crea solo su un dispositivo a blocchi.

> **D6.** Su quale dispositivo installiamo?
> **R.** **`sda`**: `TYPE disk`, `SIZE 20G`, nessuna partizione. Gli altri due:
> - **`sr0`** — *SCSI ROM*, il DVD virtuale con la ISO. È di sola lettura.
> - **`loop0`** — un *loop device*: un **file** presentato come disco. È `airootfs.sfs` dentro la ISO, il sistema live compresso in **squashfs**. È di sola lettura perché lo è il suo filesystem, non il dispositivo.

**Le colonne `RM` e `RO`.**

- **`RM`** = *removable*: `1` rimovibile, `0` fisso. Nel lab `sr0` ha `RM 1`, `sda` ha `RM 0`. Il valore viene da `/sys/block/<dispositivo>/removable` e dice se il **supporto** si può togliere dal dispositivo (il CD dal lettore), non se il dispositivo si stacca dal computer. Per le cose USB non è affidabile: molti dischi esterni risultano `RM 0`, alcune chiavette `RM 1`.
- **`RO`** = *read-only*: `1` sola lettura, come `sr0`.

Per scegliere il disco su cui installare contano soprattutto **dimensione** e **nome**, oppure:

```sh
lsblk -o NAME,SIZE,TRAN,MODEL     # TRAN = transport: sata, nvme, usb
```

### 2b. Progettare lo schema → [[mbr-gpt|MBR e GPT]]

| | **MBR** (*dos*) | **GPT** |
|---|---|---|
| Nasce | 1983, PC IBM | anni 2000, con UEFI |
| Indice | nei primi 512 byte | all'inizio, **più una copia alla fine** |
| Partizioni | 4 primarie | 128 |
| Max disco | 2 TiB | praticamente illimitato |
| Controllo errori | nessuno | CRC32 |

**Il settore 0 è l'MBR** (*Master Boot Record*) e non è una partizione: sta fuori da tutte. Contiene:

- il **codice di avvio** (446 byte) → lo scrive GRUB al passo 8;
- la **tabella delle partizioni** (64 byte = 4 voci da 16) → la scrive `fdisk`.

`fdisk` fa iniziare la prima partizione al **settore 2048**: i settori 1–2047 (~1 MiB) restano vuoti e GRUB ci mette la parte di sé che non sta nei 446 byte. Con GPT quello spazio non è garantito, e serve una partizione *BIOS boot* da 1 MiB.

**Perché proprio 2048: l'allineamento.** Quel MiB non esiste per GRUB: GRUB lo sfrutta perché è vuoto. I dischi moderni e gli SSD lavorano a blocchi fisici da **4096 byte**, anche se si presentano con settori logici da 512. Se una partizione inizia in un punto non multiplo di 4 KiB, ogni blocco del filesystem sta a cavallo di due blocchi fisici, e ogni scrittura diventa "leggi due, modifica, riscrivi".

| Epoca | Prima partizione al settore… | Spazio prima | Perché |
|---|---|---|---|
| DOS, anni '80–2000 | **63** | 62 settori ≈ 31 KiB | allineamento alla geometria cilindri/testine/settori: 63 settori per traccia |
| Dal 2009 circa | **2048** | ≈ 1 MiB | 2048 × 512 = 1 MiB, multiplo di 4 KiB e delle dimensioni interne di SSD e RAID |

In VirtualBox i settori fisici dichiarati sono da 512 byte, quindi l'allineamento conta poco, ma `fdisk` applica la convenzione comunque.

> **D7.** MBR o GPT? → **MBR**: è il più semplice con un BIOS e non richiede la partizione *BIOS boot*. Sui sistemi veri si trova quasi sempre GPT: da rifare per confronto.

> **D8.** Lo schema? → root + swap ([[swap|Swap]]). 2 GB di RAM → 2,5 GB di swap. Lo spazio prima della prima partizione **non** va riservato a mano: lo lascia `fdisk`.

> **D9.** Cosa fare dello spazio che avanza? → **darlo a root.** Allargare una partizione dopo è scomodo: lo spazio libero deve stare **subito dopo** di lei. Lasciato in fondo dietro la swap, per usarlo bisognerebbe prima spostarla.

### 2c. `fdisk /dev/sda` → [[strumenti-partizionamento|Strumenti di partizionamento]]

- **Nome:** *fixed disk*. IBM chiamava così il disco rigido, "fisso" in opposizione al floppy.
- **Cosa conta:** lavora **in memoria**. Niente è scritto finché non premi `w`; `q` esce senza salvare.

| Tasto | Significato | Risposte |
|---|---|---|
| `p` | *print*: mostra la tabella | |
| `o` | nuova tabella MBR vuota (residuo storico di "DOS") | |
| `n` | *new* → root | `p`, `1`, Invio (2048), **`-2560M`** |
| `n` | *new* → swap | `p`, `2`, Invio, Invio |
| `t` | *type* | `2`, **`82`** |
| `a` | *active*: flag boot | `1` |
| `p` | ricontrolla | |
| `w` | *write* | |

**Last sector** accetta tre forme: un numero di settore, `+15G` (dopo l'inizio) oppure **`-2560M`** (2560 MiB *prima della fine* dello spazio libero). Il `-` evita i conti; `fdisk` non accetta decimali come `2.5G`.

**Primary / extended:** i 4 posti dell'MBR. Per averne di più, una partizione diventa **estesa**, cioè un contenitore di partizioni **logiche**. È una toppa degli anni '80; GPT non ne ha bisogno.

Verifica dei conti: 41.943.040 settori × 512 byte = 20 GiB.

**La tabella esiste già all'apertura?** Solo in memoria. Su un disco vuoto `fdisk` avvisa *"Device does not contain a recognized partition table. Created a new DOS (MBR) disklabel…"*: per questo `p` mostra subito `Disklabel type: dos` (*disklabel* è il nome che `fdisk` dà alla tabella). Premere `o` la ricrea uguale e cambia solo il *disk identifier*.

**`Disk identifier`** (es. `0xf5d3b357`): un numero casuale da 32 bit scritto nell'MBR. Linux lo usa per costruire il **PARTUUID** delle partizioni (`f5d3b357-01`, `-02`): un nome che resta valido anche se `sda` diventa `sdb`. È casuale apposta, per distinguere i dischi fra loro.

> **D10.** `t` cambia solo un'etichetta (83 Linux, 82 swap): a chi serve?
> **R.** **Non al kernel**: una partizione diventa swap per la *firma* di `mkswap` e per `swapon`. L'etichetta la leggono gli **umani e gli strumenti** (`fdisk`, `lsblk`, installer, altri sistemi operativi). È come l'estensione di un file: chiamare `foto.jpg` un file di testo non lo rende un'immagine.

> **D11.** Perché il flag *boot*, se GRUB non ne ha bisogno?
> **R.** In origine il codice MBR di DOS avviava la partizione attiva: cambiando il flag si cambiava sistema. Oggi alcuni BIOS **controllano la tabella prima di eseguire l'MBR** e, se non c'è una partizione attiva, considerano il disco non avviabile. Metterlo non costa niente.

**Cos'è il flag *boot*.** Un solo byte: il **primo** dei 16 di ogni voce della tabella MBR. `0x80` = attiva, `0x00` = normale. In `fdisk` compare come `*` nella colonna `Boot`. Kernel e filesystem lo ignorano: è una "freccia" per il codice dell'MBR.

Il codice MBR di DOS/Windows è un **chain loader**: non sa caricare kernel né mostra menu. Scorre le 4 voci, trova quella con `0x80`, carica il **primo settore di quella partizione** (*VBR*, *Volume Boot Record*) e gli cede il controllo. Il flag è quindi **una scelta scritta in anticipo**, il modo di scegliere quando non c'è un menu.

| Chi | Guarda il flag? |
|---|---|
| GRUB (`boot.img` nell'MBR) | ❌ va dritto a `core.img` |
| Syslinux (`mbr.bin`) | ✅ funziona come l'MBR di DOS |
| MBR di Windows | ✅ |
| Alcuni BIOS | ⚠️ senza partizione attiva non eseguono l'MBR |

Si mette su `sda1` perché `/boot` sta lì; sulla swap non c'è niente da avviare.

**Boot manager e bootloader.** Il *boot manager* ti fa **scegliere** cosa avviare; il *bootloader* **carica** il kernel. GRUB fa entrambe le cose.

| Configurazione | "Chi parte?" lo decide… |
|---|---|
| BIOS + MBR generico + bootloader nella partizione | il **flag boot** |
| BIOS + GRUB nell'MBR | il **menu di GRUB** (`grub.cfg`) |
| UEFI | il **`BootOrder`** nella NVRAM del firmware (`efibootmgr`): l'erede del flag |

Caso intermedio: GRUB installato **nella partizione** e codice generico nell'MBR che ci arriva tramite il flag. Si faceva per non toccare l'MBR di un Windows già presente.

> **D20.** *(aperta)* `fdisk` permette il flag su **due** partizioni. Cosa farebbe l'MBR di DOS, che ne cerca una? E GRUB?

> **D21.** *(aperta)* Nella nostra VM chi fa da boot manager e chi da bootloader? Se Windows sovrascrivesse l'MBR con il suo codice generico, cosa succederebbe con il flag su `sda1`? E senza?

> **D22.** *(aperta)* Se cloni il disco con `dd` e colleghi entrambi alla stessa macchina, che problema crea l'avere lo stesso *disk identifier* per un sistema che cerca root tramite PARTUUID?

### 2d. Cosa succede con `w`

1. `fdisk` scrive i 64 byte della tabella nel settore 0.
2. Chiama **`ioctl()`** (*input/output control*, la system call "jolly" per comandi ai dispositivi): `BLKRRPART` (*BLocK ReRead PARTition table*) o la variante più fine `BLKPG`.
3. Il kernel legge la tabella e crea in memoria un **dispositivo a blocchi** per ogni partizione.
4. Il kernel aggiunge `sda1`, `sda2` in `/dev`, che è **devtmpfs**, e manda un *uevent* a **udev**, che sistema permessi e link come `/dev/disk/by-uuid/…`. Per vederlo in diretta: `udevadm monitor`.

> **D12.** Chi crea `/dev/sda1`?
> **R.** ✅ `ioctl` → il kernel rilegge la tabella. Due precisazioni:
> - il kernel **non crea le partizioni**: quelle sono già i dati nel settore 0. Crea i **dispositivi** che le rappresentano;
> - **interrupt ≠ system call.** L'interrupt è un segnale hardware → CPU ("ho finito"); la system call è una richiesta programma → kernel. Sui vecchi x86 a 32 bit le syscall passavano da un interrupt software (`int 0x80`), oggi c'è l'istruzione `syscall`.
>
> Il kernel rilegge la tabella solo all'avvio o su richiesta. A mano: `partprobe`.

`lsblk` mostra anche **`MAJ:MIN`** (8:0, 8:1, 8:2): è così che il kernel identifica davvero un dispositivo. Il **major** dice quale driver lo gestisce (8 = dischi SCSI/SATA); il **minor** quale dispositivo di quel driver (0 = disco intero, 1, 2 = partizioni) → [[dispositivi-moduli-kernel|Dispositivi e moduli del kernel]].

> **D13.** `lsblk -f`: cosa manca? → il **filesystem**: `FSTYPE` è vuoto per `sda1` e `sda2`. ✅
> Nello stesso output: `loop0` → `squashfs`; `sr0` → `iso9660` con etichetta `ARCH_202610`, che il live usa per trovare sé stesso.

### 2e. Approfondimento: avvio e bootloader → [[bootloader-grub|Bootloader e GRUB]], [[firmware-bios-uefi|Firmware, BIOS e UEFI]]

**La catena di avvio.** Non è il kernel a far partire il bootloader, ma il contrario:

```
accensione → firmware (BIOS) → bootloader (GRUB) → kernel → init (systemd)
```

1. **Accensione.** La CPU parte da un indirizzo fisso, il *reset vector*, dove c'è il **firmware**. Il firmware non sta sul disco ma in un chip flash sulla scheda madre; nella VM lo fornisce VirtualBox.
2. **BIOS.** Fa il *POST* (*Power-On Self Test*), sceglie il disco, **copia il settore 0 in RAM all'indirizzo `0x7C00`** e ci salta dentro. Prima controlla che il settore finisca con la firma **`55 AA`**; senza, passa al disco successivo.
3. **Bootloader.** `boot.img` (446 byte nell'MBR) carica `core.img` (nel gap dopo l'MBR), che legge `/boot/grub/grub.cfg` e mostra il menu.
4. **GRUB carica il kernel.** Mette in RAM `vmlinuz` e l'initramfs e salta all'inizio del kernel.
5. **Kernel.** Inizializza l'hardware, con l'initramfs monta root e lancia **`init`** (`systemd`, PID 1).

**Cosa fa un bootloader**, chiunque sia:

1. trova il **kernel** (`vmlinuz`) e l'**initramfs**;
2. li carica in RAM;
3. passa al kernel la **riga di comando** (es. `root=/dev/sda1`);
4. salta all'inizio del kernel.

**Il *setup header*.** All'inizio di `vmlinuz` c'è una piccola zona che fa da **contratto** fra bootloader e kernel: GRUB la legge per sapere come caricare il kernel e ci scrive dove ha messo initramfs e riga di comando. È il *Linux boot protocol*: per questo qualsiasi bootloader che lo rispetti può avviare Linux.

**Si può avviare senza bootloader?**

| Firmware | Senza bootloader? | Chi carica il kernel |
|---|---|---|
| BIOS (la nostra VM) | ❌ | GRUB, Syslinux, … |
| UEFI | ✅ con **EFISTUB** o **UKI** | il firmware stesso |

- **BIOS:** esegue solo 512 byte e non conosce i filesystem, quindi non può trovare un kernel da oltre 10 MB dentro ext4. Serve sempre un programma intermedio.
- **Storia:** fino al kernel 2.6.24 (2008 circa) Linux aveva un **proprio settore di avvio**: scritto su floppy con `dd`, partiva senza bootloader, perché il floppy non aveva né partizioni né filesystem. Oggi quel settore stampa solo *"Direct floppy boot is not supported. Use a boot loader program instead."*
- **UEFI + EFISTUB:** il kernel è compilato come programma `.efi` (*stub* = "mozzicone", il pezzo che lo rende avviabile) e si registra nel firmware con `efibootmgr`. La **UKI** (*Unified Kernel Image*) è un unico `.efi` con kernel, initramfs e riga di comando. Si perde il menu, per questo molti usano comunque `systemd-boot`.
- **Casi esotici:** *coreboot* + *LinuxBoot* mettono un kernel Linux nella flash della scheda madre (datacenter); **PXE** scarica il bootloader dalla rete, che quindi c'è sempre, solo che arriva da fuori.

**Gli scenari del gap dopo l'MBR (BIOS + MBR).**

| Scenario | Cosa succede |
|---|---|
| **A. GRUB nel gap** (scelta del lab) | `boot.img` (446 byte) nell'MBR, `core.img` (decine di KiB, capisce MBR ed ext4) nel gap, il resto come file in `/boot/grub`. Standard su Debian e Rocky/RHEL. |
| **B. GRUB senza gap** | `core.img` non ha dove stare: `grub-install` fallisce con *"embedding is not possible"*. Ripiego: installarlo nel primo settore di una partizione, con la posizione di `core.img` salvata come elenco di blocchi (*blocklist*). Fragile: se il filesystem sposta il file, il sistema non parte. GRUB lo sconsiglia. |
| **C. Syslinux (extlinux)** | Non usa il gap. Nell'MBR un codice minimale che avvia la partizione con il flag *boot*; lì `extlinux`, che legge il resto dal filesystem. Semplice, ma supporta meno filesystem, è fermo da anni ed è raro sui server. |
| **D. Usare il MiB per i dati** | Si può scriverci con `dd`, ma non è una partizione: nessun filesystem lo gestisce e un bootloader lo sovrascrive senza chiedere. In passato alcuni software proprietari ci salvavano licenze e rompevano GRUB. E vale lo 0,005% di 20 GiB. |
| **E. Prima partizione prima del 2048** | Alcuni tool lo permettono (`sfdisk` accetta il settore esatto), ma si perde l'allineamento e si ricade in B. |

Per confronto: con **BIOS + GPT** dopo il settore 0 c'è la tabella GPT, quindi GRUB vuole una partizione *BIOS boot* esplicita. Con **UEFI** non c'è codice nell'MBR né spazio nascosto: il bootloader è un file `.efi` in una partizione FAT32.

> **D23.** *(aperta)* Se `fdisk` lascia il MiB comunque, la scelta del bootloader cambia la tabella che stiamo scrivendo, o si può rimandare al passo 8? (Cosa serve a Syslinux che stiamo già mettendo?)

> **D24.** *(aperta)* GRUB o Syslinux? Consiglio: **GRUB**, perché è quello che si trova su Debian e Rocky e che bisogna saper riparare. Syslinux va bene per un esperimento su un'altra VM.

> **D25.** *(aperta)* Perché il kernel ha bisogno che il bootloader gli dica `root=…`? Non potrebbe cercarsi la partizione da solo? (Pensa a tre dischi e due Linux installati.)

> **D26.** *(aperta)* Mentre il kernel gira, dov'è GRUB? Se GRUB si rompe, un sistema già acceso se ne accorge, o il problema esce solo al riavvio?

### 2f. Approfondimento: quanta swap → [[swap|Swap]]

**Cosa fa.** Linux divide la memoria in **pagine** da 4 KiB. Quando la RAM scarseggia, il kernel sposta su disco quelle usate meno di recente; se un programma le cerca, la CPU genera un *page fault* e il kernel le riporta in RAM. *Swap* = "scambio" fra RAM e disco.

In swap va solo la memoria **anonima** (variabili, heap, stack). Le pagine che sono copie di file (codice dei programmi, file letti) il kernel le può buttare e rileggere dal file.

**Swap più grande della RAM?** Sì, nessun vincolo: nel lab sono già 2,5 GB contro 2 GB.

| Situazione | Effetto |
|---|---|
| La memoria **usata** sta in RAM | swap quasi vuota, solo spazio disco occupato |
| C'è roba **ferma** (programmi aperti ma inattivi) | finisce in swap, la RAM liberata va a chi lavora: il caso utile |
| La memoria **usata attivamente** supera la RAM | **thrashing**: il kernel sposta pagine avanti e indietro, il sistema è lentissimo (un SSD è circa mille volte più lento della RAM, un disco meccanico molto di più) |
| RAM **e** swap piene | **OOM killer** (*Out Of Memory*): il kernel uccide un processo |

Una swap enorme non dà "più RAM": dà più spazio per la roba ferma e più tempo prima dell'OOM killer. Con un carico che supera davvero la RAM, la macchina può "agonizzare" per minuti invece di perdere subito un processo.

**La regola "swap = 2× RAM"** viene dagli anni '90: RAM di pochi MB, swap usata di continuo, e alcuni Unix che riservavano in swap una copia di tutta la memoria allocata. Linux non funziona così da molto tempo. Oggi:

- **ibernazione** (*suspend to disk*): il kernel scrive in swap tutta la RAM, quindi la swap deve essere ≥ RAM usata. È il motivo per cui sui portatili si fa ancora swap ≥ RAM;
- **server**: swap piccola o nessuna, perché un processo ucciso subito è meglio di una macchina lenta;
- **VM del lab**: l'ibernazione non serve, per mettere in pausa c'è `savestate`.

**`swappiness`** = *swap* + *-iness*, la "propensione a swappare". Quando deve liberare RAM, il kernel ha due strade:

1. **scartare la *page cache***: le copie in RAM dei file letti di recente. Se non sono modificate, basta buttarle; costo: una lettura da disco *in futuro, forse*. Per questo su Linux la RAM "libera" sembra sempre poca: è piena di cache, e non è uno spreco;
2. **mandare in swap la memoria anonima**: va *scritta* adesso, e riletta quando servirà.

| Valore (0–200, default 60) | Comportamento |
|---|---|
| **0** | evita la swap il più possibile, la usa solo per evitare l'OOM killer. **Non** la disattiva. |
| **60** | preferisce un po' scartare cache, ma manda in swap la roba ferma |
| **100** | le due strade costano uguale |
| **> 100** | preferisce la swap: ha senso con *zram*, swap compressa in RAM |

**Mito:** "60 vuol dire che la swap parte quando la RAM è piena al 40%". **Falso.** Non è una soglia ma un **peso** fra le due strade, e conta solo quando il kernel deve liberare memoria.

```sh
cat /proc/sys/vm/swappiness                                 # leggerlo
sysctl vm.swappiness                                        # idem
sysctl -w vm.swappiness=10                                  # subito, si perde al riavvio
echo 'vm.swappiness=10' > /etc/sysctl.d/99-swappiness.conf  # permanente
free -h                                                     # buff/cache e available
```

- **`sysctl`** = *system control*. `vm.swappiness` corrisponde a `/proc/sys/vm/swappiness` con i punti al posto delle barre; `vm` è *virtual memory*, non "virtual machine". `/proc/sys` è un filesystem virtuale: ogni file è una manopola del kernel.
- In `free -h`, **`available`** è la memoria davvero disponibile, **compresa** la cache che il kernel può scartare.

> **D27.** *(aperta)* La swap della VM sta nel `.vdi`, che sta sull'SSD del Mac: cosa succede fisicamente durante il thrashing? Il Mac stesso usa una swap? (`sysctl vm.swapusage` sul Mac.)

> **D28.** *(aperta)* `swappiness` su un server di database che tiene i dati in memoria: alzarla o abbassarla? E su un portatile pieno di programmi aperti ma usati di rado? Quale strada è meno dannosa da sacrificare in ciascun caso?

---

## 3. Formattare → [[filesystem|Filesystem]]

**Formattare** vuol dire scrivere nella partizione le strutture per ritrovare i file: indice dei blocchi, cartelle, permessi.

### 3a. `mkfs.ext4 /dev/sda1`

- **Nome:** `mkfs` = *make filesystem*; `.ext4` dice quale. `mkfs` da solo è uno smistatore verso `mkfs.xfs`, `mkfs.vfat`, …
- **ext4** = *fourth extended filesystem*, quarta generazione di una famiglia nata nel 1992. Il primo *ext* "estendeva" il filesystem di Minix.
- Scrive *inode tables* ([[inode|Inode]]), *journal* ([[journaling|Journaling]]), *superblocks* ([[block-group|Block e block group]]).

### 3b. `mkswap /dev/sda2`

- **Nome:** *make swap*. Scrive solo una **firma**: un'intestazione che dice "questa è swap, grande tanto".

> **D14.** Perché alla swap basta una firma?
> **R.** Il kernel ci sposta **pagine** di memoria (4 KiB) e l'indice "pagina X → slot N" lo tiene **lui stesso in RAM**. Non servono nomi né cartelle, e il contenuto non deve sopravvivere al riavvio (salvo l'ibernazione).

### 3c. `lsblk -f` e gli UUID

> **D15.** Perché in `fstab` si preferisce l'UUID a `/dev/sda1`?
> **R.** Come per `eth0`: se si collega un altro disco, l'ordine può cambiare e `sda` diventa un altro. Però l'UUID **non identifica l'hardware**: è scritto nell'**intestazione del contenuto formattato**, cioè nel superblock per ext4 e nell'intestazione per la swap. Quindi cambia se riformatti, e due dischi clonati byte per byte hanno lo stesso UUID.

| | Dove sta | Cambia se… |
|---|---|---|
| **UUID** | dentro la partizione (superblock / intestazione swap) | riformatti |
| **PARTUUID** | nella tabella delle partizioni (MBR: *disk identifier* + numero, es. `b6e10011-01`) | rifai la tabella |

```sh
lsblk -o NAME,FSTYPE,UUID,PARTUUID
```

Non si dice "partizione logica": in MBR *logica* vuol dire "dentro una estesa", e le nostre sono primarie.

> **D16.** A cosa serve il journal?
> **R.** È un registro *scritto prima* delle modifiche: ext4 annota "sto per fare questo", lo fa e poi segna "fatto". Dopo un crash, rilegge il journal e completa o annulla: il filesystem resta **coerente**. Per default contiene i **metadati**, non il contenuto dei file. Prima dei journal serviva un `fsck` su tutto il disco → [[integrita-fsck|Integrità e fsck]].

---

## 4. Montare → [[mount-fstab|Mount e fstab]], [[fhs|FHS]]

In Linux c'è **un solo albero** che parte da `/`, senza `C:` e `D:`. **Montare** vuol dire agganciare il filesystem di una partizione a una cartella, che diventa la porta d'accesso. Dettagli completi → [[mount-fstab|Mount e fstab]].

```sh
mount /dev/sda1 /mnt
swapon /dev/sda2
lsblk
free -h
```

- **`mount`**: "montare, installare su un supporto", probabilmente dai nastri e dischi che un operatore montava sul lettore. La forma è `mount COSA DOVE`.
- **`/mnt`**: *mount*, la cartella convenzionale per i montaggi temporanei. Esiste già nell'albero del live: non l'abbiamo creata noi e `mount` non la crea.
- **`swapon`**: *swap on*. La swap non si monta (non ha cartelle): si dice al kernel di usarla. Il contrario è `swapoff`.
- **`lsblk`**: in `MOUNTPOINTS` devono comparire `/mnt` e `[SWAP]`.
- **`free -h`**: memoria libera; `-h` = *human*. La riga `Swap` deve indicare circa 2,5 G.

### I punti da ricordare

- **Non c'è copia:** i file restano su `sda1`. In RAM stanno tabella dei montaggi, driver, strutture di gestione e page cache.
- **`/mnt` è `sda1`:** `/mnt/sda1` non esiste. La radice di `sda1` si vede come `/mnt`.
- **La `/` del live non è su `sda`:** è un overlay fra `airootfs.sfs`, letto dal supporto, e uno strato scrivibile in RAM.
- **Il driver lo trova il kernel:** `mount` chiede, il kernel usa il driver se è già presente, altrimenti lo fa caricare con `modprobe`.

> Con la chiavetta cambiano i nomi: il supporto non è `sr0` ma per esempio `sdb`, e il disco interno può non essere `sda`. Si controlla sempre con `lsblk`.

> **D17.** Perché `pacstrap` non scrive direttamente su `/dev/sda1`?
> **R.** `/dev/sda1` è una fila di byte senza concetto di file. Scrivere `/bin/bash` in ext4 vuol dire trovare blocchi liberi, scriverli, creare l'inode, aggiungere la voce in `/bin`, aggiornare la mappa dei blocchi e il journal. Quella logica è il **driver ext4 nel kernel**. **Montare** collega il driver alla partizione: i programmi ragionano in file e percorsi, il kernel li traduce in blocchi.
> `pacstrap` è presente nella ISO (pacchetto `arch-install-scripts`, verificabile con `which pacstrap`).
> Analogia: `sda1` non montato è un magazzino senza magazziniere. Il driver ext4 è il magazziniere, `mount` è il momento in cui lo assumi.

> **D18.** Perché attivare la swap adesso, se per installare non serve?
> **R.** Perché `genfstab` (passo 6) non chiede niente: scrive `fstab` guardando cosa è montato sotto `/mnt` e quali swap sono attive in `/proc/swaps`. Se la swap non è attiva, non entra in `fstab` e il sistema installato parte senza swap, **senza alcun errore**. ❌ Risposta spiegata dopo due tentativi.
> Correzione: non dipende dal tipo 82 della partizione, che è solo un'etichetta (D10), e non serve a `pacstrap`. Un errore all'avvio ci sarebbe se `fstab` elencasse una swap inesistente, per esempio con un UUID non più valido.

> **D19.** Ai programmi del sistema installato interessa sapere che durante l'installazione stavano sotto `/mnt`?
> **R.** No: il prefisso `/mnt` non è scritto sul disco, esiste solo nel modo in cui il live raggiunge quei file. Anche `genfstab` lo toglie e registra la radice come `/`. Risposta spiegata, non data da me.

> **D29.** `/mnt` l'abbiamo creata noi?
> **R.** No, esiste già nell'albero del live. `mount` non la crea: senza cartella darebbe errore.

> **D30.** Quando il punto di montaggio passa da `/mnt` a `/`?
> **R.** Davvero solo al riavvio, con un montaggio nuovo: GRUB passa `root=UUID=…`, l'initramfs monta `sda1` su `/new_root` e `switch_root` la rende `/`. Con `arch-chroot` il cambio è solo apparente: il montaggio resta su `/mnt`, ma la shell e i suoi figli lo vedono come `/`.

> **D31.** Perché `sda1` va su `/mnt` e non su `/`?
> **R.** Perché servono due sistemi visibili insieme: `pacstrap` gira dal live e scrive sul disco. Montare su `/` non cambierebbe la radice dei processi già avviati; passando davvero a `sda1` con `chroot` si perderebbero i comandi, perché è vuota.
> Correzione: avevamo detto che i comandi sarebbero stati cercati su `sda1`, con *command not found*. Per i processi già avviati è falso.

> **D32.** Il live non girava in RAM? E con la chiavetta siamo dentro `sda`?
> **R.** Non siamo dentro `sda`: la `/` del live non sta su quel disco. "In RAM" è una semplificazione: le modifiche stanno in RAM, i programmi vengono letti dal supporto quando servono. In RAM stanno per intero solo con `copytoram`; nel lab `sr0` è ancora montato su `/run/archiso/bootmnt`, quindi la copia non è attiva. ✅ La mia obiezione era corretta.

> **D33.** `sr0` e `bootmnt` stanno nella chiavetta?
> **R.** Solo i dati. `sr0` è il nome del lettore, creato dal kernel; `bootmnt` è una cartella in `/run`, in RAM. Attraverso quella cartella si vede il contenuto del supporto.

> **D34.** Montare è creare un ponte fra `/mnt` e `sda1`, per vederla come cartelle e file?
> **R.** Sì. ✅ Precisazioni: sono i programmi dell'initramfs a chiedere al kernel i montaggi del live; il ponte non è scritto in `/mnt`, ma nella tabella dei montaggi del kernel, in RAM.

> **D35.** Come arriva il driver ext4 al kernel?
> **R.** Non lo fornisce `mount`. Il programma chiede il montaggio con la system call `mount()`; se ext4 non è registrato, il kernel fa caricare a `modprobe` il modulo da `/usr/lib/modules/<versione>/`. Il driver si registra, controlla il superblocco e il kernel aggiunge il montaggio alla tabella.

> **D36.** Sto montando il disco o nel disco?
> **R.** Si monta il filesystem di una partizione su una cartella. "Montare il disco" è un'abbreviazione imprecisa; "montare nel disco" vorrebbe dire usare come aggancio una cartella che sta sul disco.

> **D37.** Perché `sda1` e `sda2` stanno allo stesso livello di `sda` in `/dev`, e non dentro una cartella `sda/`?
> **R.** Perché `sda` deve essere un file di dispositivo, leggibile byte per byte (MBR e gap di GRUB non stanno in nessuna partizione), e un elemento non può essere insieme file e directory. Il legame sta nel nome e nei numeri (`8,0`, `8,1`, `8,2`); la gerarchia vera si vede in `/sys/block/sda/`. L'idea della cartella è esistita: devfs usava `/dev/discs/disc0/part1`. → [[partizioni|Partizioni]]

**Sintesi.** `mount` aggancia il filesystem di `sda1` a `/mnt`, senza copiare dati: quello che si scrive lì resta su disco, quello che si scrive altrove nel live sparisce. `swapon` attiva la swap adesso perché `genfstab` possa registrarla al passo 6. Esito riferito a voce: `mount` e `swapon` riusciti, output non incollato.

---

## 5. Installare il sistema base

```sh
pacstrap -K /mnt base linux
```

Su una macchina fisica il comando include anche `linux-firmware`. Nella VM è stato omesso: l'hardware emulato usato qui non dovrebbe averne bisogno, e si può aggiungere dopo con `pacman -S linux-firmware`.

- **`pacstrap`**: *pac*(man) + *strap*, da *bootstrap*. Script del pacchetto `arch-install-scripts`: usa il `pacman` del live per installare in `/mnt`.
- **`-K`**: crea in `/mnt` un portachiavi `pacman` nuovo, con chiavi proprie invece di quelle del live.
- **`base`**: il pacchetto con le fondamenta del sistema. Non contiene il kernel.
- **`linux`**: il kernel e i suoi moduli.

> **D38.** Il live ha già kernel e programmi: perché installare un sistema dentro `/mnt`?
> **R.** Perché il live sta sul supporto e nella RAM, mentre `sda1` contiene solo un ext4 vuoto. Senza ISO, al passo 9, dal disco non partirebbe nulla: il sistema va scritto su `sda1` per restare dopo il riavvio. ✅ Al secondo tentativo.
> Correzioni: il live non è una versione ridotta, contiene più programmi di `base`. Al passo 9 la ISO è tolta, quindi non viene montata; e anche quando c'è, non viene copiata in RAM senza `copytoram`.

### Verifica

```sh
ls /mnt /mnt/boot
df -h /mnt
pacman -Q | wc -l
pacman -r /mnt -Q | wc -l
```

| Risultato | Significato |
|---|---|
| `bin`, `lib`, `lib64` di un altro colore | collegamenti simbolici verso `usr/` |
| `lost+found` | creata da `mkfs.ext4`, non da `pacstrap` |
| `vmlinuz-linux` | il kernel: *virtual memory*, *linux*, `z` per *compresso* |
| `initramfs-linux.img` | *initial RAM filesystem*, generato da `mkinitcpio` → [[initramfs\|Initramfs]] |
| `df`: 18G, usati 1.1G, disponibili 16G, 7% | *disk free*. I conti non tornano a mano per l'arrotondamento, per i metadati e per il 5% che ext4 riserva a root di norma |
| 455 pacchetti nel live, 141 in `/mnt` | conferma D38: il live non è la versione ridotta |

I due `warning` su `core` ed `extra` riguardano il `pacman` del live: i database di sincronizzazione sono stati scaricati in `/mnt`, non nel live. `-Q` legge solo i pacchetti installati, quindi il conteggio resta valido.

**Sintesi.** `pacstrap` usa il `pacman` del live per scrivere il sistema su `sda1`. Sul disco ci sono ora kernel e initramfs, ma mancano ancora `fstab`, configurazione e bootloader.

---

## 6. Generare `fstab` → [[mount-fstab|Mount e fstab]]

```sh
genfstab -U /mnt >> /mnt/etc/fstab
cat /mnt/etc/fstab
blkid
```

- **`genfstab`**: *generate fstab*. Legge cosa è montato sotto `/mnt` e quali swap sono attive, toglie il prefisso `/mnt` e stampa il risultato.
- **`-U`**: identifica le partizioni per UUID (*Universally Unique Identifier*), che resta valido anche se il disco cambia nome.
- **`>>`**: aggiunge in fondo al file, senza cancellare le righe esistenti. Lanciato due volte, duplica le voci.
- **`fstab`**: *filesystem table*, in `/etc`: il sistema installato la legge a ogni avvio.

> **D39.** Che fine fanno al riavvio i montaggi e la swap del passo 4, e cosa deve esistere su `sda1`?
> **R.** Si perdono, perché la tabella sta in RAM. Su `sda1` deve esserci una tabella permanente: `/etc/fstab`, che elenca cosa montare, dove, con quale filesystem e con quali opzioni. L'UUID è solo il modo di indicare la partizione. ✅ Precisata la formulazione.

**Verifica.** Due voci, `/` in ext4 e `none` in swap. Gli UUID coincidono con quelli di `blkid` e `/mnt` non compare. Nello screenshot le colonne di opzioni, `dump` e `pass` erano tagliate.

**Sintesi.** `fstab` porta su disco ciò che al passo 4 stava solo in RAM. `genfstab` lo ricava dallo stato attuale, e per questo la swap doveva essere già attiva.

---

## 7. Entrare nel nuovo sistema e configurarlo

### 7a. `arch-chroot /mnt`

- **`chroot`**: *change root*. Cambia la radice di un processo e dei suoi figli: `/` viene cercata a partire da `/mnt`.
- **`arch-chroot`**: script di `arch-install-scripts`. Prima di `chroot` monta `/proc`, `/sys`, `/dev` e `/run` nel nuovo albero e rende disponibile la configurazione DNS; all'uscita li smonta.
- Il kernel in esecuzione resta quello del live: non è un avvio.

> **D40.** Perché per la configurazione si entra con `arch-chroot /mnt` invece di restare nel live?
> **R.** Perché i comandi usano il proprio `/etc`: `passwd` lanciato dal live cambierebbe `/etc/shadow` del live, in RAM, e al riavvio la modifica sparirebbe. Dentro il chroot programmi, librerie e file di configurazione sono quelli di `sda1`. Non è sempre obbligatorio: i file si possono scrivere con `/mnt/etc/...` e alcuni comandi hanno un'opzione apposita come `passwd --root /mnt`. È il modo più semplice e serve davvero ai programmi che devono girare nel sistema installato. Spiegata dopo due tentativi.

> **D41.** Perché non basta `cd /mnt/sda1` e lavorare lì?
> **R.** `/mnt/sda1` non esiste: la radice di `sda1` si vede come `/mnt`. E `cd /mnt` non basterebbe: cambia la cartella corrente, non la radice. I percorsi relativi partono da `/mnt`, ma quelli assoluti come `/etc/shadow` e i programmi cercati in `PATH` restano quelli del live. Prova: da `/mnt`, `grep -c UUID /etc/fstab etc/fstab` legge due file diversi.

**Verifica dentro il chroot.**

| Comando | Risultato | Significato |
|---|---|---|
| `pacman -Q \| wc -l` | `141`, senza `warning` | è il `pacman` di `sda1`, non più quello del live (455) |
| `uname -r` | `7.2.7-arch1-1` | il kernel in esecuzione è quello del live |
| `ls /usr/lib/modules` | `7.2.14-arch1-1` | il kernel installato su `sda1` |
| `ls /mnt` | vuoto | è la cartella `mnt` di `sda1`, che ora si chiama `/mnt` nel chroot |

Il prompt dice ancora `archiso` perché il nome della macchina è un dato del kernel in esecuzione.

### 7b. Fuso orario

```sh
ln -sf /usr/share/zoneinfo/Europe/Rome /etc/localtime
hwclock --systohc
```

- **`ln -sf`**: *link*; `-s` *symbolic*, `-f` *force*, sostituisce il collegamento se esiste già.
- **`/usr/share/zoneinfo/`**: il database dei fusi orari, con le regole di ogni zona, compresa l'ora legale.
- **`/etc/localtime`**: il file che le librerie leggono per convertire l'ora in ora locale.
- **`hwclock --systohc`**: *hardware clock*, *system to hardware clock*: copia l'ora di sistema sull'orologio hardware e crea `/etc/adjtime`.

> **D42.** Il fuso orario sta nell'orologio hardware o in un file su `sda1`?
> **R.** In un file su `sda1`. ✅ Precisazione: non dipende da dove sta il sistema, ma da come è configurato. L'orologio hardware conserva solo data e ora, senza fuso; il kernel conta in UTC e la conversione avviene quando un programma mostra l'ora.

Esito riferito a voce: verifica come atteso, output non incollato.

### 7c. Lingua

```sh
sed -i 's/^#en_US.UTF-8/en_US.UTF-8/; s/^#it_IT.UTF-8/it_IT.UTF-8/' /etc/locale.gen
locale-gen
echo 'LANG=en_US.UTF-8' > /etc/locale.conf
```

- **`locale`**: l'insieme delle convenzioni di una lingua e di un paese, divise in categorie `LC_*` (`LC_TIME`, `LC_NUMERIC`, `LC_MONETARY`, `LC_MESSAGES`, ...).
- **`/etc/locale.gen`**: l'elenco dei locale da generare; quelli attivi sono le righe senza `#`.
- **`locale-gen`**: *locale generate*, compila i locale scelti in `/usr/lib/locale/`.
- **`LANG`**: il locale predefinito, scritto in `/etc/locale.conf`.

> **D43.** Il *locale* cambia solo la lingua dei messaggi?
> **R.** No: anche il formato di date, numeri e valuta. ✅ Inoltre l'ordinamento alfabetico (`LC_COLLATE`) e la codifica dei caratteri (`LC_CTYPE`).

**Verifica.** `locale-gen` ha generato i due locale; `locale -a` elenca `C`, `C.utf8`, `POSIX`, `en_US.utf8`, `it_IT.utf8`. Il primo tentativo aveva `locale-gen` sulla stessa riga di `sed`, che l'ha preso per un file: l'errore non ha fatto danni.

### 7d. Tastiera

```sh
echo 'KEYMAP=it' > /etc/vconsole.conf
```

- **`vconsole`**: *virtual console*, le console di testo gestite dal kernel.
- **`KEYMAP`**: *mappa dei tasti*, letta all'avvio da `systemd-vconsole-setup`, che applica la mappa come fa `loadkeys`.

> **D44.** Cosa succede alla tastiera al primo avvio se non si fa altro?
> **R.** Torna americana, perché `loadkeys` carica la mappa nel kernel in esecuzione e la mappa si perde allo spegnimento. ✅

### 7e. Nome della macchina

```sh
echo arch-lab > /etc/hostname
cat /etc/hostname
cat /proc/sys/kernel/hostname
```

- **`hostname`**: *host name*, il nome della macchina. *Host*, "ospite che accoglie": il computer che ospita i programmi.
- **`/etc/hostname`**: il nome salvato su disco; `systemd` lo legge all'avvio e lo passa al kernel.
- **`/proc/sys/kernel/hostname`**: il nome che il kernel sta usando ora: resta `archiso` fino al riavvio.

> **D45.** Cosa dirà il prompt dopo il riavvio senza `/etc/hostname`?
> **R.** `archlinux`, il nome di ripiego con cui Arch compila `systemd`, perché il file non esiste. ✅

**Verifica 7e.** Esito riferito a voce: `/etc/hostname` contiene `arch-lab`, il kernel in esecuzione dice ancora `archiso`.

### 7f. Rete

```sh
printf '[Match]\nName=en*\n\n[Network]\nDHCP=yes\n' > /etc/systemd/network/20-wired.network
systemctl enable systemd-networkd systemd-resolved
```

Fuori dal chroot, prima del riavvio:

```sh
ln -sf ../run/systemd/resolve/stub-resolv.conf /mnt/etc/resolv.conf
```

- **`systemd-networkd`**: gestisce le interfacce e il DHCP. Fa parte di `systemd`, quindi è già installato.
- **`systemd-resolved`**: risolve i nomi DNS. `stub-resolv.conf` indirizza i programmi verso di lui.
- **`.network`**: `[Match]` sceglie le interfacce (`en*`, ethernet), `[Network]` dice cosa farne.
- **`systemctl enable`**: crea i collegamenti che fanno partire il servizio all'avvio. Non lo avvia, quindi funziona anche nel chroot.
- **Fuori dal chroot:** `arch-chroot` monta `/etc/resolv.conf` del live sopra quello di `sda1`, quindi da dentro il collegamento non si può creare.

> **D46.** La rete funzionerà da sola al primo avvio?
> **R.** No: nessun servizio di rete è abilitato. Nel live li attiva l'immagine ISO, che però non viene copiata sul disco. ✅

**Verifica 7f.** Esito riferito a voce: `is-enabled` stampa `enabled` per i due servizi.

### 7g. Password di root

```sh
passwd -S root
passwd
passwd -S root
```

- **`passwd`**: *password*, imposta la password e ne scrive l'hash in `/etc/shadow`.
- **`/etc/shadow`**: *ombra*, leggibile solo da root: gli hash stavano in `/etc/passwd`, che tutti possono leggere.
- **`passwd -S`**: *status*: `L` bloccato (*locked*), `P` password utilizzabile, `NP` nessuna password.

> **D47.** Cosa succede al primo avvio senza password di root?
> **R.** Non si può entrare: l'account è bloccato, e `/etc/shadow` contiene `*` al posto dell'hash. È più scomodo che pericoloso; si rimedia riavviando dalla ISO e rifacendo `arch-chroot`. ✅

**Verifica 7g.** Esito riferito a voce: `passwd -S` da `L` a `P`.

**Sintesi.** `arch-chroot` fa lavorare i comandi con la radice su `sda1`, sul kernel del live. Fuso, lingua, tastiera, nome, rete e password sono scritti in `/etc`: ciò che nel live valeva solo fino allo spegnimento ora resta.

---

## 8. Installare il bootloader → [[bootloader-grub|Bootloader e GRUB]]

```sh
pacman -S grub
grub-install --target=i386-pc /dev/sda
grub-mkconfig -o /boot/grub/grub.cfg
```

- **`pacman -S`**: *sync*, scarica e installa un pacchetto. Stavolta dentro il chroot, quindi su `sda1`.
- **GRUB**: *GRand Unified Bootloader*.
- **`--target=i386-pc`**: la piattaforma BIOS, che parte in modalità compatibile col 386.
- **`/dev/sda`**: il disco intero, non `sda1`: il codice va nel settore 0 e nel gap.
- **`grub-mkconfig -o`**: *make config*, *output*: cerca i kernel in `/boot` e genera il menu con `root=UUID=…`.

> **D48.** Con kernel e initramfs in `/boot`, perché il BIOS non riesce a farli partire?
> **R.** Il BIOS non sa leggere ext4: carica solo il settore 0 ed esegue il codice che trova. Serve un bootloader nell'MBR. ✅

**Verifica.** `grep -m1 'root=UUID' /boot/grub/grub.cfg` riporta `root=UUID=d42f6102-d58d-47d7-9b6c-3e…`, l'UUID di `sda1` (riga tagliata nello screenshot). L'output di `grub-install` non è stato incollato.

**Sintesi.** `boot.img` nel settore 0 carica `core.img` dal gap; `core.img` legge ext4 e il menu in `/boot/grub`; GRUB carica kernel e initramfs e passa `root=UUID=…`.

---

## 9. Riavviare senza ISO ⏳

```sh
exit
ln -sf ../run/systemd/resolve/stub-resolv.conf /mnt/etc/resolv.conf
ls -l /mnt/etc/resolv.conf
umount -R /mnt
lsblk
poweroff
```

- **`exit`**: esce dal chroot, e `arch-chroot` smonta ciò che aveva montato.
- **`umount -R`**: *unmount* (il nome è davvero senza la `n`), `-R` *recursive*: smonta `/mnt` e ciò che sta sotto.
- **`poweroff`**: spegne. Solo a VM spenta si toglie la ISO.

> **D49.** Cosa si rischia spegnendo di colpo con `sda1` montata e scritture recenti?
> **R.** I dati appena scritti stanno nella page cache in RAM e andrebbero persi. ✅ `umount` li scrive sul disco prima di staccare il filesystem. Il journal protegge la coerenza del filesystem, non quei dati.

**Verifica fino a qui.** `exit`, `ln`, `umount -R` e `lsblk` riusciti: `sda1` senza punto di montaggio, `[SWAP]` su `sda2`.

**Verifica dopo il riavvio (3 novembre 2026).** ISO tolta e avvio dal disco riuscito: `lsblk`, `swapon --show`, `ip -br addr` e `ping` sono a posto (vedi [[laboratorio-vm-headless-ssh|VM senza interfaccia e SSH]]).

- **`uname -r`**: `7.2.14-arch1-1`, cioè versione del kernel `7.2.14`, revisione di Arch `arch1`, rilascio del pacchetto `1`.
- **`timedatectl`**: ora giusta, fuso `Europe/Rome`, `RTC in local TZ: no`. L'orologio RTC (*Real-Time Clock*, quello del firmware) è in UTC: anche se `crea-lab.sh` non lo imposta, la VM ha `rtcuseutc="on"`.
- **Da sistemare**: `System clock synchronized: no` e `NTP service: inactive`.

> **📍 Si riprende da qui (3 novembre 2026).** Mancano l'attivazione di NTP nel sistema installato, `dmesg | grep -i firmware` (`linux-firmware` omesso) e il valore predefinito di `copytoram`.

---

↑ [[00-home|Home]] · [[mappa-storage|Storage]] · [[mappa-hardware-boot|Hardware e boot]]
