---
tags:
  - lezione
  - laboratorio
aliases:
  - Laboratorio — Installazione di Rocky Linux da terminale
---
# Laboratorio — Installazione di Rocky Linux da terminale

Installazione di Rocky Linux 9.8 (ISO minimal) su una VM VirtualBox creata con `VBoxManage`, senza passare da `make lab-crea`.

## La mappa

| # | Passo | Stato |
|---|---|---|
| 1 | Definire la VM | ✅ |
| 2 | Darle risorse e hardware | ✅ |
| 3 | Avviare l'installer | ✅ |
| 4 | Installare Rocky | ✅ |
| 5 | Togliere la ISO, riavviare e verificare | ✅ |
| 6 | Creare un utente e trovare i comandi | ✅ |
| 7 | Collegarsi via SSH dal Mac | ✅ |
| 8 | Dare un nome al sistema | ✅ |

## Passo 1 — Definire la VM

```bash
VBoxManage createvm --name lab-rocky --ostype RedHat9_64 --register
```

Crea e registra la VM. Per ora esiste solo la sua descrizione, nel file `~/VirtualBox VMs/lab-rocky/lab-rocky.vbox`: niente disco e nessun sistema.

- `--ostype RedHat9_64`: Rocky non ha un ID suo in VirtualBox, ma è binario-compatibile con RHEL.
- `--register`: aggiunge la VM all'elenco di VirtualBox.
- L'UUID (*Universally Unique Identifier*) identifica la VM come il nome, ma senza ambiguità.

> **D1.** Quali componenti servono a una VM vuota perché l'installer parta e abbia dove scrivere il sistema?
> **R.** CPU, RAM, disco e ISO nel lettore. ✅ Da aggiungere: il controller di archiviazione, a cui si collegano disco e lettore, e la scheda di rete, che all'installer della ISO minimal non serve ma è necessaria dopo per aggiornamenti e SSH.

## Passo 2 — Darle risorse e hardware

### 2a. RAM, CPU, video e rete

```bash
VBoxManage modifyvm lab-rocky --memory 2048 --cpus 1
VBoxManage modifyvm lab-rocky --graphicscontroller vmsvga
VBoxManage modifyvm lab-rocky --vram 16 --nic1 nat
VBoxManage showvminfo lab-rocky | grep -iE '^(memory|number of cpu|graphics|vram|nic 1)'
```

Verificato con `showvminfo`: 2048 MB di RAM, 1 CPU, 16 MB di VRAM, controller VMSVGA, NIC 1 in NAT.

Attenzione al copia-incolla: un comando spezzato su due righe diventa due comandi, perché la shell tratta l'a capo come fine del comando.

> **D2.** Cosa succede se dai alla VM quasi tutta la RAM e tutti i core del Mac?
> **R.** Il Mac rallenta o si blocca, perché macOS resta senza risorse e ricorre allo swap. Bastano 2048 MB di RAM, 1 CPU e 20 GB di disco. ✅

### 2b. Disco e lettore

```bash
D="$HOME/VirtualBox VMs/lab-rocky/lab-rocky.vdi"
VBoxManage createmedium disk --filename "$D" --size 20480 --variant Standard
VBoxManage storagectl lab-rocky --name SATA --add sata --portcount 2
VBoxManage storageattach lab-rocky --storagectl SATA --port 0 --type hdd --medium "$D"
I="$HOME/Downloads/Rocky-9.8-x86_64-minimal.iso"
VBoxManage storageattach lab-rocky --storagectl SATA --port 1 --type dvddrive --medium "$I"
VBoxManage showvminfo lab-rocky --machinereadable | grep -i '^"SATA'
```

Il controller è l'intermediario tra processore e dischi: `storagectl` lo aggiunge, `storageattach` collega disco e ISO alle sue porte. Le chiavi `"SATA-0-0"` e `"SATA-1-0"` indicano controller, porta e unità. Per gli script conviene `--machinereadable`, che ha un formato stabile.

> **D3.** Come fa un disco da 20 GB a occupare all'inizio pochi MB sul Mac, e con quale rischio?
> **R.** Non con un logical volume, che appartiene a LVM e organizza lo spazio di dischi già esistenti. ❌ Risposta spiegata: è l'allocazione dinamica, in cui il file `.vdi` contiene solo ciò che la VM ha scritto e cresce fino al massimo. Il rischio è che il disco del Mac si riempia: la VM crede di avere spazio, ma le scritture falliscono.

## Passo 3 — Avviare l'installer

```bash
VBoxManage startvm lab-rocky --type gui
```

Il firmware segue l'ordine di avvio e parte dal primo dispositivo avviabile. Un disco vuoto non ha bootloader, quindi viene saltato. La scelta tra BIOS e UEFI si fa prima di installare; il firmware si controlla con `VBoxManage showvminfo lab-rocky --machinereadable | grep -i '^firmware'`.

> **D4.** In base a cosa la VM decide da dove partire, e cosa succede se prova prima il disco vuoto?
> **R.** In base all'ordine di avvio. ✅ Completamento: il disco vuoto non ha un bootloader, quindi il firmware passa al dispositivo successivo.

> **D5.** A cosa servono la shell e le schede di log durante l'installazione?
> **R.** A navigare nei log e fare debug se qualcosa va storto. ✅ Con la shell si può anche ispezionare il sistema, per esempio dischi e rete, mentre l'installer è in corso.

## Passo 6 — Trovare i comandi da soli

- `man comando`: le sezioni `FILES` e `SEE ALSO` portano ai file e ai comandi collegati.
- `man -k parola`: cerca per argomento in un indice; se è vuoto si crea con `mandb`.
- `comando --help` e Tab: per le opzioni e i comandi con lo stesso prefisso.
- `rpm` installa file `.rpm` locali e interroga i pacchetti installati, ma non scarica dai repository.
- Il nome del programma e quello del pacchetto possono essere diversi.

## Passo 7 — Collegarsi via SSH dal Mac

### 7a. Una porta del Mac per ogni VM

```bash
VBoxManage modifyvm lab-arch --natpf1 delete ssh
VBoxManage modifyvm lab-arch --natpf1 "ssh,tcp,127.0.0.1,2223,,22"
```

Una regola non si modifica: si cancella e si ricrea. Con la VM accesa si usa `controlvm <vm> natpf1`. Ora `lab-rocky` è sulla 2222 e `lab-arch` sulla 2223; la porta della VM resta 22.

> **D6.** Le due VM hanno la stessa regola sulla porta 2222 del Mac: cosa cambiare per usarle insieme?
> **R.** La porta del Mac: una resta 2222 e l'altra diventa 2223. ✅

### 7b. Avvio headless e accesso con chiave

```bash
VBoxManage startvm lab-rocky --type headless
ssh-keygen -R "[127.0.0.1]:2222"
ssh-copy-id -p 2222 remoto@127.0.0.1
ssh -p 2222 remoto@127.0.0.1
```

Verificato: `whoami` risponde `remoto`, `hostname` rispondeva `localhost.localdomain` (nome predefinito), poi impostato: vedi il passo 8.

`startvm` ritorna quando la VM è accesa, non quando SSH è pronto. L'avviso `REMOTE HOST IDENTIFICATION HAS CHANGED` è comparso perché sulla stessa porta prima rispondeva `lab-arch`.

Errore da ricordare: a `Overwrite (y/n)?` di `ssh-keygen` ho risposto `y` e ho sostituito la chiave usata per GitHub. Va letto cosa si sovrascrive; per una chiave dedicata si sceglie un altro file con `-f`.

> **D7.** Perché `ssh` lanciato subito dopo l'avvio fallisce e un minuto dopo funziona?
> **R.** Il sistema stava ancora facendo il boot e `sshd` non era partito. ✅

## Passo 8 — Dare un nome al sistema

```bash
hostnamectl hostname lab-rocky
hostname
```

Verificato: dopo il riavvio `hostname` risponde `lab-rocky`, come il nome della VM in VirtualBox. Il comando non stampa nulla quando riesce, quindi il silenzio non è una verifica.

- `hostname nome` imposta il nome di solito solo fino al riavvio; `hostnamectl` lo salva in modo permanente in `/etc/hostname`. L'ho trovato cercando da `hostname`.
- Lettura dell'help: `[ ]` facoltativo, `{ }` gruppo da cui scegliere, `|` alternative. Un nome come `hostname` tra graffe è un segnaposto.
- *get* legge il valore, *set* lo imposta: spesso lo stesso comando fa il primo senza argomenti e il secondo con un argomento.
- `hostname -A` ha mostrato due nomi uguali perché cerca il nome di ogni indirizzo, e la VM ne ha due (`hostname -I`): IPv4 `10.0.2.15` e IPv6 `fd17:...`.
