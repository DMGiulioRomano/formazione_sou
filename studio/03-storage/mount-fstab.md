---
tags:
  - storage
  - nota
aliases:
  - Mount e fstab
---
# Mount e fstab

## Cosa vuol dire montare

**Montare** significa agganciare un filesystem a una cartella dell'albero, così i programmi possono raggiungerne il contenuto tramite percorsi.

- **Il nome:** *mount* significa "montare, installare su un supporto". Probabilmente viene dai primi sistemi, dove un operatore montava fisicamente nastri e dischi rimovibili sul lettore prima di usarli.
- **Il punto di montaggio** (*mount point*): la cartella a cui si aggancia il filesystem.
- **`/mnt`:** abbreviazione di *mount*, la cartella indicata dalla FHS per i montaggi temporanei.

```sh
mount COSA DOVE
mount /dev/sda1 /mnt
```

### La formula corretta

Si **monta il filesystem di una partizione su una cartella**.

- "Montare il disco" è un'abbreviazione comoda ma imprecisa: non si monta il disco intero `sda`, ma il filesystem di una sua partizione.
- "Montare nel disco" significa un'altra cosa: usare come punto di aggancio una cartella che sta sul disco. Per esempio, una chiavetta montata su `/mnt/usb` quando `/mnt` è già `sda1`.

### `/` non appartiene a un disco

`/` è l'inizio dell'albero visto da un processo. Ogni filesystem ha una propria directory radice interna, che diventa visibile solo nel punto in cui viene montato:

| Filesystem | La sua radice interna è visibile come |
|---|---|
| overlay del live | `/` |
| ext4 su `sda1`, prima del montaggio | nessun percorso |
| ext4 su `sda1`, dopo `mount /dev/sda1 /mnt` | `/mnt` |
| ext4 su `sda1`, nel sistema installato | `/` |

`/mnt/sda1` non esiste: `sda1` non diventa una sottocartella, è `/mnt` stessa a mostrarne la radice.

```
PRIMA                       DOPO
/                           /
├── etc   (live)            ├── etc   (live)
├── usr   (live)            ├── usr   (live)
└── mnt   (vuota)           └── mnt ══ radice di sda1
                                └── lost+found
```

`/mnt` esiste già: fa parte dell'albero standard e `mount` non la crea. Se il punto di montaggio manca, `mount` dà errore. Montare **nasconde** ciò che la cartella conteneva: i dati non vengono cancellati e ricompaiono dopo `umount`.

## Cosa sta in RAM e cosa sul disco

Il montaggio non copia nulla e non sposta dati: cambia il modo in cui il kernel risolve un percorso.

| Cosa | Dove sta |
|---|---|
| file e cartelle, inode, journal | disco |
| tabella dei montaggi | RAM |
| codice del driver ext4, una volta caricato | RAM |
| strutture con cui il driver gestisce il filesystem | RAM |
| copie temporanee di file letti o da scrivere (*page cache*) | RAM |

Quindi allo spegnimento il montaggio si perde e i file restano. Le scritture possono restare per un po' in RAM prima di arrivare sul disco: `sync` le forza e `umount` le completa prima di smontare.

## Come arriva il driver ext4 al kernel

`mount` non fornisce il driver e di solito non sa dove si trovi: dice solo al kernel cosa montare e dove. Il driver è codice del kernel e può essere compilato dentro di esso oppure stare in un modulo `.ko` (*kernel object*), su Arch in `/usr/lib/modules/<versione>/kernel/fs/ext4/`. → [[dispositivi-moduli-kernel|Dispositivi e moduli del kernel]]

Con `mount /dev/sda1 /mnt`:

1. **Il programma riconosce il tipo.** `mount` (pacchetto *util-linux*), se il tipo non è indicato, legge la firma della partizione con *libblkid*.
2. **Chiede al kernel di montare.** Usa la system call `mount()` con sorgente, destinazione e tipo.
3. **Il kernel cerca il tipo** fra i filesystem registrati, visibili in `/proc/filesystems`.
4. **Se manca, chiede il modulo.** `request_module("fs-ext4")` avvia il programma `modprobe`.
5. **`modprobe` trova il file.** *Module probe* consulta `modules.alias`, dove `fs-ext4` corrisponde a `ext4`, e `modules.dep`, che elenca le dipendenze come `jbd2`, il driver del journal.
6. **Il modulo entra nel kernel** tramite la system call `finit_module()`.
7. **Il driver si registra** con `register_filesystem()`.
8. **Il driver legge la partizione.** Controlla nel superblocco il *magic number* `0xEF53` e prepara le strutture in memoria.
9. **Il kernel crea il ponte** aggiungendo il montaggio alla sua tabella.

Quando un programma apre `/mnt/prova`, il **VFS** (*Virtual File System*, lo strato comune del kernel per tutti i filesystem) smista la richiesta al driver ext4, che la traduce in blocchi su `sda1`.

Due conseguenze:

- un modulo funziona con il kernel per cui è stato compilato: per questo la cartella porta il numero di versione (`uname -r`);
- per leggere dal disco il modulo ext4 servirebbe già ext4: il circolo lo risolve l'[[initramfs|initramfs]], che contiene i moduli necessari a montare la radice.

```sh
grep ext4 /proc/filesystems     # il kernel conosce ext4?
lsmod | grep ext4               # list modules: è caricato come modulo?
modinfo ext4 | head -5          # informazioni e file del modulo
blkid /dev/sda1                 # tipo e UUID letti dalla partizione
dmesg | tail -5                 # EXT4-fs (sda1): mounted filesystem
```

## I ponti del sistema live

Il sistema live non usa il disco di destinazione. Con una chiavetta USB, l'avvio procede così:

1. il firmware avvia il bootloader che sta sulla chiavetta;
2. il bootloader carica in RAM kernel e initramfs e passa i parametri per ritrovare il supporto, come l'etichetta `ARCH_202610`;
3. il kernel usa l'initramfs come prima radice;
4. i programmi dell'initramfs trovano la chiavetta e chiedono al kernel di montarla su `/run/archiso/bootmnt`;
5. montano `airootfs.sfs` tramite un loop device su `/run/archiso/airootfs`;
6. creano un tmpfs per le modifiche, costruiscono l'overlay su `/new_root` e con `switch_root` lo rendono `/`;
7. parte `systemd`.

```
chiavetta ──> bootmnt ──> airootfs.sfs ──> airootfs ─┐
                                                     ├──> /  ──> /mnt ──> sda1
                              tmpfs in RAM ──────────┘
```

| Punto di montaggio | Cosa ci si vede | Dove stanno i dati |
|---|---|---|
| `/run/archiso/bootmnt` | contenuto del supporto | chiavetta o DVD |
| `/run/archiso/airootfs` | contenuto di `airootfs.sfs`, tramite `loop0` | supporto, in un file compresso |
| `/` | overlay: live in lettura + strato scrivibile | supporto + RAM |
| `/mnt` | ext4 di `sda1` | disco rigido |

### Dati e nomi

Sul supporto stanno i **dati**. I **nomi** con cui li si raggiunge li crea il sistema in esecuzione, in RAM.

| Cosa | Dove sta |
|---|---|
| kernel, initramfs, bootloader, `airootfs.sfs` | sul supporto |
| `/dev/sr0`, nome del lettore DVD | creato dal kernel in `/dev`, in RAM |
| cartelle in `/run/archiso/` | create all'avvio in `/run`, in RAM |
| strato scrivibile dell'overlay | tmpfs, in RAM |

`sr0` non è un file della ISO: è il nome del lettore. Con una chiavetta di solito non esiste e il supporto si chiama per esempio `/dev/sdb`. Anche il disco interno può allora non essere `sda`, ma `sdb` o `nvme0n1`: prima di scrivere si controllano dimensione e modello con `lsblk`.

### "Gira in RAM" è una semplificazione

La `/` del live è un **overlay**, una sovrapposizione di due strati:

| Strato | Dove sta | Contenuto |
|---|---|---|
| inferiore, sola lettura | `airootfs.sfs` sul supporto, tramite `loop0` | programmi e file del live |
| superiore, scrivibile | **tmpfs** (*temporary filesystem*), in RAM | ogni file creato o modificato |

| Operazione | Cosa succede |
|---|---|
| leggere `/usr/bin/ls` | letto dal supporto e decompresso; solo la parte richiesta va in RAM, nella page cache |
| scrivere `/root/prova` | va nello strato in RAM e sparisce allo spegnimento |
| scrivere `/mnt/prova` | passa dal driver ext4 e resta su `sda1` |

I programmi in esecuzione stanno in RAM, ma non tutti i file sono in RAM.

Con **`copytoram`**, invece, `airootfs.sfs` viene copiato per intero in `/run/archiso/copytoram` e il supporto si può togliere. Il valore predefinito dovrebbe essere automatico e dipendere dalla RAM (da verificare, non controllato). Senza copia, togliere il supporto rende irraggiungibili i file non ancora letti.

```sh
ls /run/archiso/
findmnt -o TARGET,SOURCE,FSTYPE
```

## Perché `/mnt` e non `/` durante l'installazione

Per installare si devono vedere **due sistemi insieme**: quello che lavora, il live su `/`, e quello in costruzione, su una sottocartella. `pacstrap` gira dal primo e scrive nel secondo.

Montare `sda1` su `/` non servirebbe:

- ogni processo conserva un proprio riferimento alla radice, che il montaggio non aggiorna, e i figli lo ereditano: la shell continuerebbe a vedere il vecchio albero (comportamento noto del kernel, non provato nella VM del lab);
- per passare davvero alla nuova radice servirebbe `chroot` o `switch_root`, e a quel punto, con `sda1` vuota, non ci sarebbero più comandi, librerie e configurazione di `pacman`.

`/mnt` è solo una convenzione, vuota e quindi innocua. Andrebbe bene qualsiasi altra cartella vuota; una come `/usr` no, perché ne nasconderebbe il contenuto.

## Quando `sda1` diventa `/`

Il prefisso `/mnt` non è mai scritto sul disco: esiste solo nel modo in cui il live raggiunge quei file.

**`arch-chroot /mnt`, il cambio apparente.** *chroot* è *change root*. Il montaggio resta su `/mnt`, ma la nuova shell e i suoi figli vedono `/mnt` come `/`. La radice è una proprietà di ogni processo, non del sistema. Con `exit` si torna alla vista del live.

| Chi guarda | Stesso file su `sda1` |
|---|---|
| shell del live | `/mnt/etc/hosts` |
| shell nel chroot | `/etc/hosts` |

**Il riavvio, il cambio vero.** Non è uno spostamento, ma un montaggio nuovo, ripetuto a ogni avvio:

1. GRUB carica kernel e initramfs e passa `root=UUID=…`;
2. il kernel usa l'initramfs come prima radice;
3. l'initramfs monta `sda1` su `/new_root`;
4. `switch_root` la rende `/` e lancia `systemd`;
5. `systemd` legge `fstab`, applica le opzioni di `/` e attiva la swap.

## `cd` non è `chroot`

Ogni processo ha due riferimenti:

| Riferimento | Cosa decide | Chi lo cambia |
|---|---|---|
| cartella corrente | da dove partono i percorsi relativi (`etc/fstab`) | `cd` |
| radice | da dove partono i percorsi assoluti (`/etc/fstab`) | `chroot` |

Dopo `cd /mnt`, `etc/fstab` è il file su `sda1`, ma `/etc/fstab` resta quello del live, come ogni percorso assoluto usato dai programmi. Dentro `arch-chroot /mnt`, `/etc/fstab` è il file su `sda1`. Il kernel però resta quello in esecuzione: `uname -r` e `ls /usr/lib/modules` possono dare versioni diverse.

## Le sei colonne di `fstab`

```text
# <file system>                            <dir>  <type>  <options>   <dump> <pass>
UUID=d42f6102-d58d-47d7-9b6c-3e954e936f38  /      ext4    rw,relatime 0      1
UUID=da53073e-2ddc-4ac9-b235-0d36e59f3d47  none   swap    defaults    0      0
```

| Colonna | Cosa dice | Valori |
|---|---|---|
| `file system` | cosa montare | `UUID=…`, oppure un nome come `/dev/sda1` |
| `dir` | dove | `/`; `none` per la swap, che non ha cartelle |
| `type` | con quale driver | `ext4`, `swap`, … |
| `options` | come | `rw` (*read-write*), `relatime` (*relative access time*), `defaults` |
| `dump` | se il vecchio programma di backup `dump` deve salvarlo | quasi sempre `0` |
| `pass` | ordine del controllo con `fsck` all'avvio | `1` per `/`, `2` per gli altri, `0` nessun controllo |

`relatime` aggiorna l'ora di ultimo accesso solo quando serve, evitando una scrittura a ogni lettura.

## `genfstab` e la swap

`genfstab` (*generate fstab*) fotografa lo stato presente: legge i filesystem montati sotto la cartella indicata e le swap attive in `/proc/swaps`, poi scrive le righe di `fstab` togliendo il prefisso.

| Al momento di `genfstab` la swap è… | In `fstab` | Al riavvio |
|---|---|---|
| attiva | c'è la riga con il suo UUID | viene attivata da sola |
| non attiva | nessuna riga | il sistema parte senza swap e senza errori |

Il tipo 82 della partizione non c'entra: è solo un'etichetta. Un errore all'avvio nasce invece da una riga di `fstab` che indica una swap inesistente, per esempio con un UUID non più valido.

## Verifica del montaggio

```sh
findmnt /mnt
touch /mnt/prova
ls -la /mnt
umount /mnt          # unmount: prova sparisce dalla vista
ls -la /mnt
mount /dev/sda1 /mnt # prova ricompare: era sul disco
ls -la /mnt
rm /mnt/prova
```

## 1.4 Montaggio e filesystem

```bash
# Creare filesystem ext4
mkfs.ext4 /dev/sdb1

# Montare il filesystem
mount /dev/sdb1 /media

# Aggiornare tabella partizioni se non corrisponde
partprobe /dev/sdb
```

**Importante**: Se perdi una partizione o la tabella dei file, puoi ricrearla senza perdere i dati, perché il filesystem rimane sul disco.

## 3.1 Visualizzare filesystem montati

```bash
# Elenco filesystem
df

# Human readable + tipo filesystem
df -hT
```

## 3.5 Copia e sincronizzazione

```bash
# Copia ricorsiva preservando permessi
rsync -arv /home/ /mnt/
# -a: preserva permessi
# -r: ricorsivo
# -v: verbose

# Monta tutto da fstab
mount -a
```

> [!question] Da approfondire
> - Sintassi completa di fstab: `UUID="ID" swap swap sw,pri=5 0 0`

---

**Area:** [[mappa-storage|Storage]]  
**Fonte:** [[lezione-4-installazione-pacchetti|Lezione 4 — Installazione e package management]] · [[laboratorio-installazione-arch|Laboratorio — Installazione manuale di Arch Linux]]  
**Vedi anche:** [[filesystem|Filesystem]] · [[swap|Swap]] · [[integrita-fsck|Integrità del filesystem e fsck]] · [[fhs|FHS]] · [[strumenti-partizionamento|Strumenti di partizionamento]] · [[initramfs|initramfs]] · [[dispositivi-moduli-kernel|Dispositivi e moduli del kernel]]
