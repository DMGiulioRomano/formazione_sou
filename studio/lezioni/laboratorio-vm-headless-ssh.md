---
tags:
  - lezione
  - laboratorio
aliases:
  - Laboratorio — VM senza interfaccia e accesso via SSH
---
# Laboratorio — VM senza interfaccia e accesso via SSH

Avviare `lab-arch` senza finestra grafica e usarla dal terminale del Mac. Ogni passo risponde a tre domande: **cosa** fa il comando, **perché** serve in quel momento, **come** si chiama e da dove viene il nome. Le domande numerate sono quelle a cui ho risposto durante il percorso, con la correzione.

## La mappa

| # | Passo | Stato |
|---|---|---|
| 1 | Togliere la ISO e avviare dal disco | ✅ |
| 2 | Preparare SSH nella VM | ✅ |
| 3 | Inoltrare la porta e avviare senza interfaccia | ✅ |
| 4 | Collegarsi dal Mac | ✅ |
| 5 | Spegnere la VM senza finestra | ✅ |

---

## 1. Togliere la ISO e avviare dal disco

La VM è spenta e la ISO di Arch è ancora inserita nel lettore virtuale.

```sh
VBoxManage storageattach lab-arch --storagectl "SATA" --port 1 --device 0 --medium emptydrive
```

- **`storageattach`**: *storage* + *attach*, collega o cambia un supporto in una posizione del controller.
- **`lab-arch`**: la VM da modificare.
- **`--storagectl "SATA"`**: *storage controller*, il controller virtuale. `SATA` è il nome scelto in `crea-lab.sh`, non il tipo.
- **`--port 1`**: il connettore del controller. Nella VM: 0 il disco, 1 il lettore DVD.
- **`--device 0`**: il dispositivo su quella porta. In SATA ogni porta ne ha uno solo, quindi è sempre 0. Serve per IDE, dove un canale ne ospita due.
- **`--medium emptydrive`**: il supporto da inserire. `emptydrive` lascia il lettore vuoto, `none` toglierebbe il lettore.

> **D1.** Dopo il comando, che fine fanno il lettore DVD virtuale e il file `.iso` in `Downloads`?
> **R.** Il lettore resta, vuoto; il file `.iso` resta in `Downloads`. ✅ Cambia solo la configurazione della VM.

**Perché togliere la ISO.** L'ordine di avvio è floppy, DVD, disco: finché la ISO è inserita parte il live e il disco non viene raggiunto.

**In alternativa, l'ordine di avvio.** Si cambia dal Mac a VM spenta:

```sh
VBoxManage modifyvm lab-arch --boot1 disk --boot2 dvd --boot3 none --boot4 none
```

Dal live non si può: l'ordine sta nella configurazione della VM sul Mac e il BIOS virtuale lo riceve all'accensione. Con UEFI, in generale, un sistema può cambiarlo con `efibootmgr`. Per una sola volta basta `F12` all'avvio. Qui si toglie la ISO, così una VM senza interfaccia non dipende da un file in `Downloads`.

> **D2.** Come si capisce con certezza che è partito il sistema sul disco e non il live?
> **R.** Da `lsblk`: nella colonna `MOUNTPOINTS` `sda1` è montata su `/` e `loop0` non c'è più. ✅ Prima risposta incompleta: `uname -r` non distingue i due sistemi, e `sr0` può restare perché il lettore rimane, vuoto. Colonna trovata con un indizio; il valore `/` spiegato.

**Avviare e verificare.** Sul Mac:

```sh
VM=lab-arch make start
```

Nella VM, come `root`:

```sh
lsblk
swapon --show
ip -br addr
ping -c 3 archlinux.org
```

- **`lsblk`**: *list block devices*, elenca i dispositivi a blocchi e dove sono montati.
- **Punto di montaggio**: la directory da cui si accede a un filesystem. Quello montato su `/` è la radice da cui parte il sistema in esecuzione.

**Esito.**

| Comando | Cosa si legge | Cosa dimostra |
|---|---|---|
| `lsblk` | `sda1` su `/`, `sda2` come `[SWAP]`, niente `loop0`, `sr0` ancora presente | è partito il sistema sul disco, e il lettore è rimasto (D1) |
| `swapon --show` | `/dev/sda2`, 2,5 GiB, `USED 0B`, `PRIO -1` | la swap è attiva: la riga di `fstab` funziona |
| `ip -br addr` | `enp0s3 UP`, `10.0.2.15/24` | la scheda è accesa e ha un indirizzo dal DHCP di VirtualBox |
| `ping` | 3 pacchetti su 3 | funzionano DNS e uscita verso Internet |

**Perché controllare la swap.** Se manca, il sistema parte lo stesso e nulla lo segnala finché la RAM non finisce. Di solito il primo a farne le spese è un processo chiuso dall'OOM killer. Qui `lsblk` mostrava già `[SWAP]`; `swapon --show` aggiunge uso e priorità. Vedi [[swap|Swap]].

**Leggere `ip -br addr`.** Vedi [[ip-addr|Leggere ip addr]]. L'indirizzo `10.0.2.15` è privato della rete NAT: il Mac non lo raggiunge, ed è il motivo dell'inoltro di porta al passo 3.

**Sintesi.** Con il lettore vuoto il firmware arriva al disco. `sda1` su `/` e l'assenza di `loop0` dicono che gira il sistema installato; swap e rete funzionano, quindi si può scaricare `openssh`.

---

## 2. Preparare SSH nella VM

> **D3.** Che differenza c'è tra `ssh` e `sshd`, e su quale macchina gira ciascuno?
> **R.** `sshd` è il server: gira nella VM e accetta le connessioni. ✅ `ssh` è il client: gira sul Mac e le apre (questa parte l'ho completata con la correzione). `ssh host` apre una shell di login interattiva; `ssh host comando` esegue il comando in una shell non interattiva e non di login. Vedi [[tipi-di-shell|Tipi di shell]].

```sh
pacman -Syu openssh
systemctl enable --now sshd
systemctl is-enabled sshd
systemctl is-active sshd
ss -tln
```

- **`ssh`**: *Secure Shell*, shell remota con il traffico cifrato. Ha sostituito `telnet` e `rsh`, che facevano passare anche le password in chiaro.
- **`sshd`**: *SSH daemon*. Un demone è un processo che resta in background in attesa di lavoro.
- **`openssh`**: l'implementazione nata nel progetto OpenBSD. Il pacchetto contiene sia il client sia il server.
- **`pacman -Syu`**: `S` *sync*, `y` aggiorna gli elenchi dei pacchetti, `u` *upgrade*. Su Arch non si installa da elenchi aggiornati lasciando il sistema indietro: gli aggiornamenti parziali non sono supportati.
- **`systemctl enable --now`**: `enable` avvia il servizio a ogni accensione, `--now` anche subito.
- **`ss -tln`**: *socket statistics*. `t` TCP, `l` solo in ascolto, `n` porte in numeri.

**Esito.** `sshd` risulta `active` ed `enabled`, ed è in ascolto su `0.0.0.0:22` e `[::]:22`. La schermata tagliava la colonna degli indirizzi, quindi l'ho estratta con `ss -tln | awk '{print $1, $4}'`. `enable` crea un collegamento a `sshd.service` in `multi-user.target.wants`. Lettura completa in [[ss-porte|Leggere ss]].

> **D4.** Perché `sshd` rifiuta di default la password di `root`, ma accetta quella di un utente normale?
> **R.** Per entrare servono nome utente e password, e `root` ha il nome già noto: all'attaccante resta da indovinare solo la password. ✅ Inoltre `root` può fare tutto. Prima risposta sbagliata (evitare una shell di `root`): con una chiave `root` può entrare lo stesso, perché `PermitRootLogin prohibit-password` vieta solo la password. Trovata con un indizio.

**Come funziona l'accesso.** Vedi [[ssh|Come funziona SSH]]: SSH chiede nome utente e password come il login davanti alla macchina, ma a distanza.

**Creare l'utente.**

```sh
useradd -m remoto
passwd remoto
getent passwd remoto
passwd -S remoto
```

- **`useradd`**: aggiunge un utente al sistema.
- **`-m`**: *create home*, crea `/home/remoto` copiandoci il contenuto di `/etc/skel`. Senza, l'utente non avrebbe una home dove tenere `~/.ssh`.
- **`passwd`**: imposta la password, necessaria al primo accesso per installare la chiave.
- **`getent`**: *get entries*, legge una voce dai database del sistema, qui `passwd`.
- **`passwd -S`**: *status*, mostra lo stato della password. `P` vuol dire che è impostata e utilizzabile.

**Esito.** `remoto:x:1000:1000::/home/remoto:/usr/bin/bash`: UID e GID 1000, home creata, shell `bash`. `passwd -S` dà `remoto P 2026-11-03 -1 -1 -1 -1`: password utilizzabile, cambiata oggi, nessuna scadenza. In `sshd_config` la riga `#PermitRootLogin prohibit-password` è commentata: mostra il valore predefinito.

**Sintesi.** Nella VM ora ci sono `sshd`, attivo e abilitato, e un utente che può entrare con la password. Si spegne con `poweroff`, perché il passo 3 cambia la configurazione a VM spenta.

---

## 3. Inoltrare la porta e avviare senza interfaccia

> **D5.** Perché la VM raggiunge `archlinux.org`, ma il Mac non raggiunge la VM su `10.0.2.15`?
> **R.** Non lo sapevo, spiegata. Con il NAT VirtualBox fa da intermediario: annota le connessioni in uscita e così sa a chi consegnare le risposte. Una connessione che arriva dall'esterno non ha nessuna voce annotata, e `10.0.2.15` esiste solo nella rete privata della VM.

```sh
VBoxManage modifyvm lab-arch --natpf1 "ssh,tcp,127.0.0.1,2222,,22"
VBoxManage showvminfo lab-arch --machinereadable | grep -E '^VMState=|^Forwarding'
```

- **`--natpf1`**: *NAT port forwarding* sulla scheda di rete 1.
- **`ssh`**: nome della regola, a scelta.
- **`tcp`**: il protocollo.
- **`127.0.0.1,2222`**: indirizzo e porta sul Mac.
- **campo vuoto**: indirizzo nella VM, quando è vuoto vale quello della VM.
- **`22`**: porta nella VM.

Vedi [[nat-port-forwarding|NAT e inoltro di porta]].

**Esito.** `VMState="poweroff"` e `Forwarding(0)="ssh,tcp,127.0.0.1,2222,,22"`: la regola è salvata nella configurazione della VM, e `0` è il suo numero d'ordine.

> **D6.** Avviando senza finestra, dentro la VM cambia qualcosa per Arch e i suoi servizi?
> **R.** No, cambia solo che la finestra non si apre. ✅ La VM ha ancora il suo schermo virtuale e la console: manca solo chi li mostra.

**Avviare senza interfaccia.** Dal Mac:

```sh
VM=lab-arch VMSTART=headless make start
VBoxManage showvminfo lab-arch --machinereadable | grep -E '^VMState=|^SessionName'
nc -w 3 127.0.0.1 2222
```

- **`headless`**: *senza testa*, cioè senza schermo collegato. Si usa per le macchine che si gestiscono solo in remoto.
- **`VMSTART=headless`**: `lab.sh` lo passa a `VBoxManage startvm --type`.
- **`nc`**: *netcat*, apre una connessione e mostra ciò che riceve. Qui prova tutto il percorso fino a `sshd`, che si presenta con una riga come `SSH-2.0-OpenSSH_...`.

**Esito.** `nc` risponde `SSH-2.0-OpenSSH_10.6`: `SSH-2.0` è la versione del protocollo, `OpenSSH_10.6` il programma.

**Sintesi.** La VM gira senza finestra e `sshd` è raggiungibile dal Mac sulla porta 2222. Manca solo l'accesso.

---

## 4. Collegarsi dal Mac

> **D7.** Perché `ssh -p 2222 remoto@127.0.0.1` usa l'indirizzo del Mac e non `10.0.2.15`, e a cosa serve `-p 2222`?
> **R.** Perché la porta 2222 del Mac porta alla 22 della VM. ✅ `-p` indica la porta: senza, `ssh` userebbe la 22. `10.0.2.15` è l'indirizzo letto in `ip -br addr` sulla riga di `enp0s3`, e dal Mac non è raggiungibile.

```sh
ssh -p 2222 remoto@127.0.0.1
```

Nella VM:

```sh
whoami
uname -n
echo "$SSH_CONNECTION"
```

- **`yes` al primo collegamento**: `ssh` non conosce ancora la macchina e mostra la sua impronta (*fingerprint*). Accettandola la salva in `~/.ssh/known_hosts` del Mac e la confronta alle connessioni successive.
- **`whoami`**: *who am I*, l'utente con cui gira la shell.
- **`uname -n`**: *nodename*, il nome della macchina.
- **`SSH_CONNECTION`**: variabile impostata da `sshd`. I quattro valori sono indirizzo e porta del client, indirizzo e porta del server.

**Esito.** Primo accesso riuscito: `whoami` dà `remoto`, `uname -n` dà `arch-lab`, `SSH_CONNECTION` dà `10.0.2.2 51574 10.0.2.15 22`. Per la VM il client è `10.0.2.2`, cioè VirtualBox; `51574` è una porta temporanea scelta per questo collegamento.

> **D8.** Perché la chiave è divisa in due file, e quale si può copiare nella VM?
> **R.** Una è pubblica e una privata, e l'algoritmo le usa insieme. ✅ Si copia la pubblica, `id_ed25519.pub`. La privata firma, la pubblica verifica la firma: la privata non lascia mai il Mac. Vedi [[ssh|Come funziona SSH]].

**Installare la chiave.** Dal Mac, dopo `exit`:

```sh
ssh-copy-id -p 2222 remoto@127.0.0.1
ssh -p 2222 remoto@127.0.0.1
```

Nella VM:

```sh
ls -la ~/.ssh
cat ~/.ssh/authorized_keys
```

- **`ssh-copy-id`**: copia la chiave pubblica nella macchina remota, usando per l'ultima volta la password.
- **`authorized_keys`**: il file con le chiavi autorizzate a entrare con questo utente.

**Esito.** `authorized_keys` contiene una riga con tre parti: l'algoritmo `ssh-ed25519`, la chiave pubblica e un commento. È la stessa di `~/.ssh/id_ed25519.pub` sul Mac.

**Sintesi.** `ssh` sul Mac raggiunge `sshd` nella VM attraverso l'inoltro di porta. La firma fatta con la chiave privata sostituisce la password, e la privata non lascia mai il Mac.

---

## 5. Spegnere la VM senza finestra

> **D9.** Che differenza c'è tra `controlvm acpipowerbutton` e `controlvm poweroff`, e quale è più rischioso?
> **R.** `acpipowerbutton` spegne bene, `poweroff` stacca la corrente ed è più rischioso. ✅ Il primo chiede al sistema di spegnersi; il secondo interrompe la VM, e ciò che è ancora in RAM non arriva sul disco. Da usare solo se la VM non risponde.

```sh
VBoxManage controlvm lab-arch acpipowerbutton
VBoxManage showvminfo lab-arch --machinereadable | grep '^VMState='
```

- **`controlvm`**: *control VM*, agisce su una VM accesa.
- **`acpipowerbutton`**: ACPI (*Advanced Configuration and Power Interface*) è lo standard con cui hardware e sistema gestiscono l'alimentazione. Il comando simula la pressione del pulsante di accensione: il kernel avvisa `systemd-logind`, che avvia lo spegnimento ordinato.
- **Attenzione al nome**: `poweroff` lanciato dentro la VM è uno spegnimento ordinato, mentre `controlvm poweroff` dal Mac è il distacco della corrente.

**Esito.** Dopo `acpipowerbutton`, `VMState="poweroff"`: la VM si è spenta da sola. Qui `poweroff` è il nome dello stato, non il modo in cui è stata spenta.

**Sintesi.** Un'interfaccia grafica non serve per usare una VM: basta un servizio in ascolto, una strada per raggiungerlo e un modo per farsi riconoscere. `sshd` è il servizio, l'inoltro di porta è la strada, la chiave è il riconoscimento.

---

## Per rifarlo

**Una volta sola, per ogni VM**

Nella VM, dalla finestra, come `root` (la ISO va già tolta):

```sh
pacman -Syu openssh
systemctl enable --now sshd
useradd -m remoto
passwd remoto
poweroff
```

Dal Mac, a VM spenta:

```sh
VBoxManage modifyvm lab-arch --natpf1 "ssh,tcp,127.0.0.1,2222,,22"
VM=lab-arch VMSTART=headless make start
ssh-copy-id -p 2222 remoto@127.0.0.1
```

**Ogni giorno**

```sh
VM=lab-arch VMSTART=headless make start
ssh -p 2222 remoto@127.0.0.1
VBoxManage controlvm lab-arch acpipowerbutton
```

Se `ssh-copy-id` o `ssh` rifiutano la connessione subito dopo l'avvio, Arch sta ancora partendo: si aspetta qualche secondo.

Su una VM nuova: `pacman` e `useradd` cambiano a seconda della distribuzione, e ogni VM accesa insieme alle altre deve usare una porta diversa dalla 2222.

---

↑ [[00-home|Home]] · [[laboratorio-installazione-arch|Installazione di Arch]]
