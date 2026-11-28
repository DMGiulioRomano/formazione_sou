---
tags:
  - lezione
  - linux
aliases:
  - Linux 05 — LVM
---
# Linux 05 — LVM

Con le partizioni lo spazio è legato al disco: per ingrandire bisogna spostare, ricreare, riavviare. LVM mette i dischi in un unico serbatoio da cui ricavare volumi che crescono, cambiano disco e sopravvivono ai guasti senza fermare niente. L'appunto di partenza è [[lvm|LVM]], con [[partizioni|Partizioni]].

```sh
cd formazione_sou/lab/linux
sudo ./prepara.sh 05        # problema 1; poi sudo ./prepara.sh 05 2, e così via
```

I VG del kit stanno solo sui dischi dedicati: `prepara.sh` li toglie con tutti i loro volumi, e toglie anche i dischi dedicati dal file dei dispositivi di LVM. Il VG di sistema (`rl`) non si tocca.

## La mappa

| # | Problema | Stato |
|---|---|---|
| 0 | Previsioni — extent, PV e volumi sulla carta | — |
| 1 | Un volume da 2,5 GiB per il database | — |
| 2 | `/srv/db` non basterà | — |
| 3 | Il disco che sta per rompersi | — |
| 4 | Il disco del vecchio server di archivio | — |
| P | Pulizia — restituire i dischi del volume | — |

---

## Problema 0 — Previsioni

**Situazione.** Prima di creare volumi conviene sapere come LVM divide lo spazio. Due PV: una partizione da 2047 MiB e un disco intero da 2048 MiB, in un VG con extent da 8 MiB.

> [!info] Il contesto
> **Lo scenario.** Chi progetta un VG fa i conti prima: quanto spazio c'è davvero, quanto ne resta, quanto si perde.
> - **Extent** (inglese, «estensione»): il mattone con cui LVM assegna lo spazio. Si chiama **PE** (*physical extent*) sul PV e **LE** (*logical extent*) sul LV.
>
> **Perché conta.** Un LV si misura in extent interi: chiedere «2,5 GiB» o «il 100% del libero» dà risultati diversi a seconda di come è fatto il VG.

**Compito.** Rispondi sulla carta, poi controlla con Claude:

1. Quanti extent ha più o meno ciascun PV? Perché non 256 esatti?
2. Quanti extent occupa un LV da 2,5 GiB? Può stare su un solo PV?
3. Cosa vogliono dire `100%FREE` e `50%VG`?
4. Con extent da 4 MiB, cambierebbe la dimensione massima di un LV?
5. Cosa c'è nei primi settori di un PV? Guarda l'immagine in [[lvm|LVM]].
6. Cosa sono `/dev/mapper/vgdati-lvdb` e `/dev/dm-0`, e chi li crea?

**Verifica.** A mano, con Claude.

**Dopo.** Quale risposta hai ritrovato nel problema 1, guardando `vgs` e `pvs`?

---

## Problema 1 — Un volume da 2,5 GiB per il database

**Situazione.** Il database nuovo vuole 2,5 GiB in un solo filesystem, ma i dischi sono da 2 GiB. Uno dei due arriva da un server dismesso.

> [!info] Il contesto
> **Lo scenario.** Un filesystem più grande di qualsiasi disco, o che cresca nel tempo: è il motivo per cui quasi ogni server Red Hat usa LVM fin dall'installazione.
> - **LVM** (*Logical Volume Manager*, gestore dei volumi logici): ispirato a quello di HP-UX, scritto per Linux da Heinz Mauelshagen nel 1998.
> - **PV, VG, LV** (*physical volume*, *volume group*, *logical volume*): il disco o la partizione dato a LVM, il serbatoio che li unisce, il volume che se ne ricava. Vedi [[lvm|LVM]].
> - **device-mapper** (mappatore di dispositivi): la parte del kernel che costruisce i volumi in `/dev/mapper`.
>
> **Perché conta.** Un PV su un disco che ha ancora vecchie firme confonde chiunque lo guardi dopo. Per questo LVM rifiuta i dischi che sembrano in uso, e tocca a te guardare e decidere.

**Compito.** Esegui `palestra/l05/ticket-1.txt`:

- una partizione «Linux LVM» su tutto il primo disco, e il secondo intero, come PV;
- il VG `vgdati` con extent da 8 MiB;
- il LV `lvdb` da 2,5 GiB esatti, con un XFS etichettato DB;
- montato su `/srv/db` a ogni avvio e adesso.

Criteri di accettazione: `sudo ./verifica.sh 05 1` esce con 0, `sudo vgs vgdati` mostra 2 PV.

**Verifica.** `sudo ./verifica.sh 05 1`

> [!question]- Indizio 1
> I comandi di LVM hanno un prefisso per ogni livello. Scrivi `pv`, `vg` o `lv` e premi Tab due volte: cosa trovi?

> [!question]- Indizio 2
> Il secondo disco viene rifiutato? Leggi il messaggio. Cosa c'è sopra, e come lo togli dopo averlo guardato? Ricordi la pulizia della lezione 01.

> [!question]- Indizio 3
> La dimensione degli extent si decide una volta sola: quando? Cercala in `man vgcreate`.

> [!question]- Indizio 4
> Il tipo di partizione «Linux LVM»: come lo chiama lo strumento di partizionamento che preferisci?

**Dopo.** Cosa mostra `lsblk` sotto i due dischi? Cosa c'è in `/etc/lvm/backup/vgdati`? Perché in fstab `/dev/mapper/vgdati-lvdb` va bene e `/dev/sdb1` no? Per un PV, meglio una partizione o il disco intero?

---

## Problema 2 — `/srv/db` non basterà

**Situazione.** Il database cresce più del previsto: `lvdb` deve arrivare a 3 GiB oggi, ma in `vgdati` non c'è abbastanza spazio. È arrivato un disco nuovo.

> [!info] Il contesto
> **Lo scenario.** Lo spazio finisce sempre prima del previsto. Con LVM si aggiunge a caldo, senza fermare chi lo usa.
> - **Estendere** (*extend*): dare a un LV extent liberi del suo VG, o dare a un VG un PV nuovo.
>
> **Perché conta.** Se il volume cresce e il filesystem no, `df` non cambia e il ticket si riapre domani. È lo stesso errore della lezione 02, con un livello in più.

**Compito.** Esegui `palestra/l05/ticket-2.txt`: `lvdb` a 3 GiB esatti usando il disco nuovo intero, il filesystem che vede tutto lo spazio, a caldo e senza perdere dati.

Criteri di accettazione: `sudo ./verifica.sh 05 2` esce con 0, `df -h /srv/db` mostra circa 3 GiB.

**Verifica.** `sudo ./verifica.sh 05 2`

> [!question]- Indizio 1
> Quanto spazio libero ha `vgdati`? Quanto te ne serve?

> [!question]- Indizio 2
> Come entra un disco nuovo in un VG che esiste già? Il comando ha il prefisso del VG.

> [!question]- Indizio 3
> Dopo aver allargato il LV, cosa dice `df -h /srv/db`? LVM sa fare anche il secondo passo: cerca *resizefs* in `man lvextend`.

**Dopo.** Prova a ridurre `lvdb` di 100 MiB: cosa dice LVM, e perché? Cosa avrebbe detto con un ext4? Cos'è il *thin provisioning*, e perché è comodo e pericoloso insieme?

---

## Problema 3 — Il disco che sta per rompersi

**Situazione.** Stanotte il monitoraggio ha segnalato settori illeggibili su uno dei dischi di `vgdati`. Domani lo sostituiscono: prima va svuotato, senza fermare il database.

> [!info] Il contesto
> **Lo scenario.** I dischi avvisano prima di morire. Con LVM il disco malato si svuota e si toglie a caldo, e nessuno se ne accorge.
> - **SMART** (*Self-Monitoring, Analysis and Reporting Technology*): l'autodiagnosi dei dischi. **smartd** è il servizio che la legge e scrive gli avvisi.
> - **Settore pendente** (*pending sector*): un settore che il disco non riesce più a leggere e aspetta di sostituire.
>
> **Perché conta.** L'ordine conta: prima si sposta, poi si toglie. Le opzioni che costringono LVM a togliere un disco ancora in uso tolgono anche i dati che ci stanno sopra.

**Compito.** Esegui `palestra/l05/ticket-3.txt`: tutto ciò che sta sul disco guasto passa sul disco nuovo, a caldo. Poi il disco guasto esce da `vgdati` e perde l'etichetta LVM. `lvdb` non cambia dimensione e nessun dato si perde.

Criteri di accettazione: `sudo ./verifica.sh 05 3` esce con 0, `sudo pvs` non mostra più il disco guasto.

**Verifica.** `sudo ./verifica.sh 05 3`

> [!question]- Indizio 1
> Su quali PV sta `lvdb`? `lvs` mostra anche i dispositivi, se glielo chiedi: cerca la colonna in `lvs -o help`.

> [!question]- Indizio 2
> Fra i comandi con il prefisso dei PV ce n'è uno che sposta gli extent da un PV all'altro. Quale?

> [!question]- Indizio 3
> Un PV esce da un VG con un comando dei VG, e perde l'etichetta con uno dei PV. In che ordine, e cosa succede se li inverti?

**Dopo.** Quanto ci ha messo lo spostamento, e cosa succede se lo interrompi a metà? Come fa LVM a spostare dati in uso, con il database che scrive? Il disco tolto è ancora nel file dei dispositivi?

---

## Problema 4 — Il disco del vecchio server di archivio

**Situazione.** Su questa macchina è arrivato il disco del vecchio server di archivio, con dentro un VG e dieci anni di pratiche. LVM non lo vede.

> [!info] Il contesto
> **Lo scenario.** Dischi spostati fra macchine, VM clonate, volumi di una SAN visti da più server. Su Rocky 9 LVM usa solo i dischi che conosce.
> - **SAN** (*Storage Area Network*): una rete di dischi condivisi fra molti server.
> - **File dei dispositivi** (*devices file*): `/etc/lvm/devices/system.devices`, l'elenco dei dischi che LVM di questa macchina considera suoi. Lo crea l'installatore di Rocky.
> - **Attivare** (*activate*): rendere utilizzabile un LV, creandone il dispositivo in `/dev/mapper`.
>
> **Perché conta.** Senza l'elenco, LVM potrebbe usare i dischi di un'altra macchina e rovinarli. Con l'elenco, un disco legittimo resta invisibile finché qualcuno non lo aggiunge, e se la soluzione è provvisoria il problema torna al primo riavvio.

Nota: se la tua VM non ha `/etc/lvm/devices/system.devices`, `prepara.sh` si ferma e il problema si salta. Le installazioni dalla ISO di Rocky 9 quel file lo hanno.

**Compito.** Esegui `palestra/l05/ticket-4.txt`:

- `vgvecchio` visibile e attivo, senza toccarne il contenuto;
- `lvdati` montato su `/srv/archivio` a ogni avvio e adesso;
- anche dopo un riavvio LVM lo trova da solo.

Criteri di accettazione: `sudo ./verifica.sh 05 4` esce con 0, `sudo vgs vgvecchio` esce con 0.

**Verifica.** `sudo ./verifica.sh 05 4`

> [!question]- Indizio 1
> Prova `sudo vgs`, poi `sudo vgs --devicesfile ""`. Cosa cambia, e perché?

> [!question]- Indizio 2
> `man lvmdevices`: cosa contiene quel file, e quali comandi lo modificano?

> [!question]- Indizio 3
> Un VG visibile non è ancora attivo. Cosa dice `lvs` nella colonna Attr, e quale comando dei VG attiva i suoi volumi?

**Dopo.** Cosa succederebbe se il disco arrivato avesse un VG con lo stesso nome di uno di questa macchina, per esempio `rl`? Perché il file dei dispositivi protegge le SAN? Riavvia la VM: `vgvecchio` si attiva da solo?

---

## Pulizia — Restituire i dischi del volume

**Situazione.** I tre dischi dedicati tornano in magazzino. Sopra ci sono due VG, con i loro volumi montati e scritti in `/etc/fstab`.

> [!info] Il contesto
> **Lo scenario.** Si smonta in ordine inverso a come si è costruito: chi usa il filesystem, il montaggio, il LV, il VG, il PV, poi l'elenco dei dischi che LVM cerca.
>
> **Perché conta.** Un PV cancellato ma rimasto nel file dei dispositivi lascia avvisi a ogni comando LVM. E un VG tolto con i volumi ancora attivi lascia il kernel a usare dischi che non esistono più.

**Compito.** `sudo ./prepara.sh 05 pulizia`, poi esegui `palestra/l05/ticket-pulizia.txt`:

- niente di montato, nessun VG, nessun PV e nessuna firma sui dischi dedicati;
- LVM non li cerca più all'avvio;
- `/etc/fstab` com'era prima della lezione.

Criteri di accettazione: `sudo ./verifica.sh 05 pulizia` esce con 0.

**Verifica.** `sudo ./verifica.sh 05 pulizia`

> [!question]- Indizio 1
> Disegna la pila, dal filesystem al disco. Da quale piano parti, e quale comando toglie ogni piano?

**Dopo.** Cosa c'è ancora in `/etc/lvm/archive/`? Va pulito anche quello?

---

## Diario

Domande numerate, risposte, correzioni ed errori di questa lezione, problema per problema.

## Sintesi

Da scrivere insieme a lezione finita, partendo dalle mie parole.

---

↑ [[00-percorso-linux|Il percorso]] · ← [[04-swap|Lezione 04]] · → [[06-lvm-snapshot|Lezione 06]]
