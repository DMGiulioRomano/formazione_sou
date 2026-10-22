# LEZIONE STRUTTURATA: INSTALLAZIONE E PACKAGE MANAGEMENT

## PARTE 1: GESTIONE DEI DISCHI E PARTIZIONAMENTO

### 1.1 Strumenti per la gestione delle partizioni

**fdisk**
- Visualizza e modifica lo schema delle partizioni
- Comando principale: `fdisk -l` per visualizzare le partizioni
- Progettato per funzionare con MBR (Master Boot Record)

**parted**
- Sintassi simile a fdisk per l'elenco delle partizioni
- Supporta sia MBR che GPT (GUID Partition Table)
- Comando: `parted -l`

### 1.2 Schemi di partizionamento

**MBR (msDOS)**
- Supporta massimo 4 partizioni primarie
- Una partizione primaria può essere estesa per contenere partizioni logiche
- Permette di superare il limite di 4 partizioni

**GPT (GUID Partition Table)**
- Tabella a 64 bit
- Supporta fino a 128 partizioni primarie
- Dimensione massima per partizione: 8 Zettabyte
- **Nota importante**: Un sistema BIOS tradizionale non può fare boot da GPT, solo UEFI può farlo
- Un disco BIOS può comunque usare GPT come dispositivo secondario

### 1.3 Creazione di partizioni (esempi pratici)

```bash
# Creare tabella partizioni MBR
parted /dev/sdb mklabel msdos

# Creare partizione primaria
parted /dev/sdb -a cylinder mkpart primary linux-swap 2 102

# Visualizzare schema partizioni
parted /dev/sdb print

# Creare filesystem di swap
mkswap /dev/sdb1

# Creare tabella GPT
parted /dev/sdb mklabel gpt

# Modalità interattiva
parted
select /dev/sdb
mkpart
```

### 1.4 Montaggio e filesystem

```bash
# Creare filesystem ext4
mkfs.ext4 /dev/sdb1

# Montare il filesystem
mount /dev/sdb1 /media

# Aggiornare tabella partizioni se non corrisponde
partprobe /dev/sdb
```

**Importante**: Se perdi una partizione o la tabella dei file, puoi ricrearla senza perdere i dati, perché il filesystem rimane sul disco.

---

## PARTE 2: GESTIONE DELLA SWAP

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

---

## PARTE 3: FILESYSTEM E MOUNT POINT

### 3.1 Visualizzare filesystem montati

```bash
# Elenco filesystem
df

# Human readable + tipo filesystem
df -hT
```

### 3.2 FHS (Filesystem Hierarchy Standard)
Standard che definisce l'albero delle directory con scopi precisi.

**Directory importanti da considerare per partizioni separate:**
- `/home` - dati utente
- `/var` - dati variabili e log
- `/boot` - specialmente con LVM (boot non lo utilizza)

### 3.3 Analisi dimensioni directory

```bash
# Dimensione totale cartella
du -sh /home/utente

# Dettaglio di tutte le sottocartelle
du -h

# Aiuto
du --help
```

### 3.4 Log rotation
`/var/log` contiene log che possono riempire il filesystem. Buona pratica: partizione separata.

### 3.5 Copia e sincronizzazione

```bash
# Copia ricorsiva preservando permessi
rsync -arv /home/ /mnt/
# -a: preserva permessi
# -r: ricorsivo
# -v: verbose

# Monta tutto da fstab
mount -a
```

---

## PARTE 4: LVM (Logical Volume Manager)

### 4.1 Cos'è LVM
Livello di astrazione sopra lo storage fisico che permette di:
- Creare logical volumes che si estendono su più dischi fisici
- Superare i limiti dimensionali dei singoli dischi
- Nascondere la configurazione fisica al software

### 4.2 Vantaggi

**Flessibilità**
- Gestione dinamica dello spazio
- Ridimensionamento senza interrompere le applicazioni

**Performance**
- Striping: scrittura simultanea su più dischi per aumentare velocità

**Backup e Recovery**
- Snapshot per controllo integrità dati
- Disaster recovery nativo

---

## PARTE 5: BOOT E GRUB

### 5.1 UEFI vs BIOS

**UEFI (Moderno)**
- Cerca partizione ESP (EFI System Partition) nel disco
- Supporta GPT nativamente

**BIOS (Legacy)**
- Non può fare boot da GPT

### 5.2 GRUB Legacy

```bash
# Installare GRUB nel MBR
grub-install /dev/sda

# Backup superblock
dd if=/dev/sda of=/home/user/sda.superblock count=1 bs=512

# File di configurazione
/boot/grub/menu.lst
```

### 5.3 GRUB 2

**File importanti:**
- `/boot/grub2/` - directory principale
- `device.map` - mappa dischi (hd0 = sda, partizioni da 1)
- `grub.cfg` - **NON MODIFICARE DIRETTAMENTE**

**Come funziona grub.cfg:**
- Generato automaticamente da script
- Prende informazioni da `/etc/default/grub` e `/etc/grub.d/`

**Rigenerare configurazione:**
```bash
grub2-mkconfig -o /boot/grub2/grub.cfg
```

**Modificare timeout:**
1. Modificare `GRUB_TIMEOUT` in `/etc/default/grub`
2. Rigenerare con `grub2-mkconfig`

**Nota**: Modifiche dirette a grub.cfg vengono perse alla rigenerazione, ma possono essere utili per modifiche temporanee.

---

## PARTE 6: LIBRERIE CONDIVISE

### 6.1 Tipi di eseguibili

**Dinamically Linked**
- Fanno riferimento a librerie esterne
- Più comuni in Linux

**Staticly Linked**
- Contengono tutte le librerie necessarie
- Esempio: `ln` esiste in entrambe le versioni

### 6.2 Librerie condivise (.so)

```bash
# Vedere librerie necessarie a un eseguibile
ldd /bin/ln /sbin/sln

# Vedere tutte le librerie con percorsi
ldconfig -p
```

### 6.3 Dove vengono cercate le librerie

**Percorsi di default:**
- `/lib`
- `/lib64`

**Configurazione aggiuntiva:**
- `/etc/ld.so.conf.d/` - file di configurazione percorsi

**Aggiornare cache:**
```bash
# Come root
ldconfig
```

### 6.4 Variabili d'ambiente

```bash
# Impostare temporaneamente
export LD_LIBRARY_PATH=/lib2

# Verificare
ldd /bin/ls
```

### 6.5 Architettura sistema
```bash
uname -a
```

---

## PARTE 7: GESTIONE PACCHETTI - DEBIAN/UBUNTU

### 7.1 dpkg (basso livello)

```bash
# Installare pacchetto .deb
dpkg -i nome_pacchetto

# Info sul pacchetto
dpkg --info nome_pacchetto

# Lista file nel pacchetto
dpkg --listfile nome_pacchetto

# Da quale pacchetto viene un file
dpkg -S /percorso/file

# Percorso completo eseguibile
which nome_comando

# Alternanze (es. versioni Java)
update-alternatives --display nome

# Lista pacchetti installati
dpkg -L

# Filtrare per nome
dpkg -l tz*

# Riconfigurare pacchetto
dpkg-reconfigure tzdata

# Rimuovere (mantiene config)
dpkg -r nome_pacchetto

# Rimuovere tutto (config inclusa)
dpkg --purge nome_pacchetto
```

### 7.2 APT (alto livello, gestisce dipendenze)

```bash
# Cercare pacchetti
apt-cache search pdf

# Dettagli pacchetto
apt-cache showpkg nome_pacchetto

# Statistiche cache
apt-cache stats

# Dipendenze non soddisfatte
apt-cache unmet

# Dipendenze di un pacchetto
apt-cache depends nome_pacchetto

# Dipendenze inverse (chi dipende da questo)
apt-cache rdepends nome_pacchetto

# Ricerca per nome
apt-cache pkgnames nome

# Repository
vi /etc/apt/sources.list

# Aggiornare cache
apt-get update

# Aggiornare pacchetti installati
apt-get upgrade

# Installare
apt-get install virtualbox

# Simulazione
apt-get -s install virtualbox

# Solo download (in /var/cache/apt/archives)
apt-get install -d virtualbox

# Pulire cache
apt-get clean

# Rimuovere
apt-get remove virtualbox

# Rimuovere con dipendenze
apt-get autoremove virtualbox

# Rimuovere tutto
apt-get autoremove --purge virtualbox
```

### 7.3 Aptitude

```bash
# Cercare
aptitude search nome_pacchetto

# Interfaccia testuale
# (premere U per aggiornare)
```

**Nota**: Aptitude è stato rimosso in favore di apt in molte distribuzioni.

---

## PARTE 8: GESTIONE PACCHETTI - RPM (Red Hat/Fedora/CentOS)

### 8.1 rpm (basso livello)

```bash
# Info pacchetto (senza installarlo)
rpm -qpi nome_pacchetto

# Lista file nel pacchetto
rpm -qpl nome_pacchetto

# Installare
rpm -ih nome_pacchetto
# (mostra dipendenze fallite se presenti)

# Lista tutti i pacchetti installati
rpm -qa

# Info su pacchetto installato
rpm -qi nome_pacchetto

# Da quale pacchetto viene un file
rpm -qf nome_file

# Estrarre archivio cpio da rpm
rpm2cpio nome_pacchetto.rpm > output.cpio
cpio -i --make-directories < output.cpio

# Rimuovere
rpm -e nome_pacchetto
```

### 8.2 YUM (obsoleto, sostituito da DNF)

```bash
# Aiuto
yum -help

# Cercare
yum search nome_pacchetto

# Quali pacchetti contengono un file
yum provides nome_file

# Info pacchetto
yum info nome_pacchetto

# Controllare aggiornamenti (non cachato)
yum check-update

# Aggiornare (come upgrade di apt)
yum update

# Lista pacchetti
yum list
yum list nome

# Installare
yum install pacchetto

# Rimuovere
yum remove pacchetto

# Gruppi
yum grouplist
yum groupinstall nome_gruppo
```

### 8.3 DNF (sostituto di YUM)

**Sintassi identica a yum**, quindi tutti i comandi sopra funzionano sostituendo `yum` con `dnf`.

### 8.4 ZYPPER (openSUSE)

```bash
# Cercare (lento ma completo, con tabella stato)
zypper search ssh

# Solo download
zypper download autossh
```

**Nota**: Zypper sostituisce yum downloader e può fare molte più operazioni.

---

## PARTE 9: VIRTUALIZZAZIONE E CONTAINERIZZAZIONE

### 9.1 Virtualizzazione (tradizionale)

**Architettura:**
```
Infrastruttura
    ↓
OS
    ↓
Hypervisor
    ↓
VM1  VM2  VM3  (ognuna con OS completo)
```

**Caratteristiche:**
- Ogni VM ha OS completo, librerie, binari propri
- Richiede supporto hardware (VTX/AMD-V)
- Avvio: ordine di minuti
- Disco: GB per VM
- RAM: allocata staticamente
- Sicurezza: isolamento completo
- Esempio: VirtualBox, VMware

### 9.2 Containerizzazione

**Architettura:**
```
Infrastruttura
    ↓
OS
    ↓
Demone container
    ↓
Container1  Container2  Container3
(app + librerie essenziali)
```

**Caratteristiche:**
- Condivide kernel e OS con l'host
- Nessun supporto hardware richiesto
- Soft virtualization a livello OS
- Avvio: secondi/millisecondi
- Disco: centinaia di MB
- RAM: allocazione dinamica
- Sicurezza: isolamento a livello processo
- Risorse condivise read-only
- Esempio: Docker, Podman

---

## PARTE 10: CLOUD COMPUTING

### 10.1 Modelli di servizio

**IaaS (Infrastructure as a Service)**
- **Per**: Amministratori di sistema
- **Gestito dal provider**: Virtualizzazione, hardware, networking, storage
- **Gestito da te**: OS, middleware, runtime, applicazioni, dati
- **Esempio**: VPS, Aruba, Rackspace

**PaaS (Platform as a Service)**
- **Per**: Sviluppatori
- **Gestito dal provider**: OS, middleware, runtime
- **Gestito da te**: Solo applicazioni e dati
- **Esempio**: Heroku

**SaaS (Software as a Service)**
- **Per**: Utenti finali
- **Gestito dal provider**: Tutto
- **Gestito da te**: Nulla (usi il servizio)
- **Esempio**: Social network, web app, Gmail

### 10.2 Componenti cloud

**Cloud Computing Instance**
- Virtualizzazione e server
- Ridondanza, failover, load balancing, calcolo distribuito

**Block Storage**
- Storage flessibile con snapshot
- Aumenti/riduci dinamicamente

**Cloud Networking**
- Software Defined Networking (SDN)
- Infrastruttura di rete virtuale e scalabile

---

## PARTE 11: CLONING DI MACCHINE VIRTUALI

### 11.1 Cosa cambiare dopo clonazione

**MAC Address**
- Virtuale, legato al sistema di virtualizzazione

**UUID dei dischi**
- Non viene cambiato automaticamente
- Cambiare con `tune2fs` per evitare confusione

**Hostname**
```bash
cat /etc/hostname
hostnamectl
```

**Chiavi SSH Host**
```bash
cat /etc/ssh/ssh_host_*
```
Importante per sicurezza: ogni host deve avere chiavi univoche

**UUID del D-Bus**
```bash
dbus-uuidgen --ensure
cat /var/lib/dbus/machine-id
```
Più importante per containerizzazione

**Software di integrazione**
- Cartelle condivise host/guest
- Accelerazione video
- Copia/incolla clipboard

### 11.2 Clonazione in VirtualBox

**Opzioni:**
1. **Clone completo**: copia fisica, indipendente dall'originale
2. **Clone collegato**: dipende dalla macchina originale

**Esportazione come template:**
```
File → Esporta applicazione virtuale → seleziona VM → formato .ova
```

### 11.3 Cloud-init

Strumento per personalizzare istanze cloud tramite file di configurazione (YAML).

**Cosa può fare:**
- Impostare hostname
- Cambiare chiavi SSH
- Configurare servizi
- Eseguire script custom (runcmd)

**Altri tool simili:**
- Puppet
- Ansible

---

## RIEPILOGO COMANDI PRINCIPALI

### Dischi
```bash
parted -l                        # Lista partizioni
fdisk -l                         # Lista partizioni (MBR)
parted /dev/sdb mklabel gpt      # Crea tabella GPT
partprobe /dev/sdb               # Aggiorna tabella
```

### Filesystem
```bash
mkfs.ext4 /dev/sdb1              # Crea ext4
mount /dev/sdb1 /media           # Monta
df -hT                           # Lista filesystem
du -sh /path                     # Dimensione
```

### Swap
```bash
mkswap /dev/sdb1                 # Inizializza swap
swapon /dev/sdb1                 # Attiva
swapoff -a                       # Disattiva tutto
```

### Debian/Ubuntu
```bash
apt-get update && apt-get upgrade
apt-get install pacchetto
dpkg -i pacchetto.deb
```

### RPM
```bash
yum install pacchetto
dnf install pacchetto
rpm -qa
```

### LVM
```bash
# (comandi specifici non trattati in dettaglio nel testo)
```

### GRUB
```bash
grub2-mkconfig -o /boot/grub2/grub.cfg
```

---

## DOMANDE APERTE (da approfondire)

1. **Fstab**: Approfondire sintassi completa `UUID="ID" swap swap sw,pri=5 0 0`
2. **Free -m**: Opzioni e interpretazione output
3. **Rdepends**: Cosa sono le dipendenze inverse e quando usarle
4. **FHS**: Studiare pathname.com/fhs per comportamento specifico directory
5. **LVM**: Comandi pratici per creazione e gestione volumi
6. **Swappiness**: Valori ottimali per diversi scenari
7. **Cloud-init**: Sintassi YAML e esempi pratici

---

**Fine lezione**