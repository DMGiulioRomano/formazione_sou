---
tags:
  - lezione
  - linux
aliases:
  - Linux 03 — Mount, fstab e UUID
---
# Linux 03 — Mount, fstab e UUID

Un filesystem montato a mano dura fino al prossimo riavvio. Perché resti, il sistema deve sapere cosa montare, dove e come trovarlo, anche quando i dischi cambiano nome o mancano. Qui impari a scriverlo in modo che regga. L'appunto di partenza è [[mount-fstab|Mount e fstab]], con [[fhs|FHS]] e [[systemd|systemd]].

```sh
cd formazione_sou/lab/linux
sudo ./prepara.sh 03        # problema 1; poi sudo ./prepara.sh 03 2, e così via
```

Da questa lezione gli scenari scrivono anche in `/etc/fstab`. `prepara.sh` toglie da lì solo le righe che riguardano i dischi dedicati o i punti del kit, e avvisa se il file è diverso da quello fotografato nell'inventario.

## La mappa

| # | Problema | Stato |
|---|---|---|
| 1 | Montato a mano, sparito al riavvio | — |
| 2 | `/srv/dati` mostra fatture vecchie di mesi | — |
| 3 | Il disco di backup che va e viene | — |
| 4 | La cartella condivisa del gruppo | — |
| P | Pulizia — restituire i dischi, e che la macchina riparta | — |

---

## Problema 1 — Montato a mano, sparito al riavvio

**Situazione.** Mesi fa qualcuno ha montato `/srv/archivio` a mano. Al riavvio di stanotte l'applicazione ha trovato una cartella vuota. Il filesystem ora è rimontato, sempre a mano: va reso permanente.

> [!info] Il contesto
> **Lo scenario.** Si monta a mano «per provare» e ci si dimentica. Al primo riavvio l'applicazione trova una cartella vuota, e magari ci scrive dentro dati che poi spariscono sotto il montaggio.
> - **fstab** (*filesystem table*, tabella dei filesystem): il file, nato negli Unix di Berkeley, che dice al sistema cosa montare a ogni avvio.
> - **UUID** (*Universally Unique Identifier*): 128 bit scritti nel superblocco quando il filesystem viene creato.
> - **atime** (*access time*): l'ora dell'ultimo accesso a un file, che il kernel aggiorna anche quando lo legge soltanto.
> - **Generatore** (*generator*): un programma che systemd lancia all'avvio, e ogni volta che rilegge la configurazione, per trasformare le righe di fstab in unità di montaggio.
>
> **Perché conta.** La configurazione che scrivi e quella che il sistema usa possono essere diverse, senza che nessuno se ne accorga fino al riavvio.

**Compito.** Esegui `palestra/l03/ticket-1.txt`:

- `/srv/archivio` montato a ogni avvio, cercato per UUID;
- l'opzione `noatime`, attiva già adesso;
- il sistema di avvio usa già la configurazione nuova;
- nessun dato perso.

Criteri di accettazione: `sudo ./verifica.sh 03 1` esce con 0, `findmnt --verify` esce con 0.

**Verifica.** `sudo ./verifica.sh 03 1`

> [!question]- Indizio 1
> Rileggi in [[mount-fstab|Mount e fstab]] le sei colonne. Quale dice come cercare il filesystem? Quali forme accetta, secondo `man fstab`?

> [!question]- Indizio 2
> Dove leggi l'UUID di un filesystem senza montarlo?

> [!question]- Indizio 3
> L'opzione è nella riga: è anche attiva? Confronta le opzioni della riga con quelle che mostra `findmnt /srv/archivio`. Come si cambiano le opzioni di un filesystem montato senza smontarlo? Cerca in `man mount`.

> [!question]- Indizio 4
> systemd sa della riga nuova? Leggi le prime righe di `systemctl status srv-archivio.mount`.

**Dopo.** Cosa succede ai file scritti in `/srv/archivio` mentre il filesystem non è montato? Cosa fa davvero la sesta colonna con XFS? Rileggi [[integrita-fsck|Integrità e fsck]] e prova `man fsck.xfs`. Cos'è `relatime`, il valore predefinito? Trova in `/run/systemd/generator/` il file che il generatore ha scritto per `/srv/archivio`.

---

## Problema 2 — `/srv/dati` mostra fatture vecchie di mesi

**Situazione.** Stanotte è stato aggiunto un disco e la macchina è stata riavviata. Da allora `/srv/dati` mostra le fatture di maggio, e quelle di novembre sembrano sparite. Il filesystem buono, DATI, è ancora sulla macchina.

> [!info] Il contesto
> **Lo scenario.** Aggiungere un disco o un controller cambia l'ordine in cui il kernel trova i dischi, e quindi i loro nomi. Succede anche nel cloud, quando si collega un volume.
> - **Nome del kernel** (`sdb`, `sdc`): assegnato in ordine di scoperta, a ogni avvio.
> - **LABEL, UUID, PARTUUID**: scritti sul disco, quindi lo seguono ovunque. udev li mostra come collegamenti nelle cartelle di `/dev/disk/`.
> - **udev** (*userspace /dev*): il servizio che crea i nomi aggiuntivi dei dispositivi, come visto in [[partizioni|Partizioni]].
>
> **Perché conta.** Con i nomi del kernel, fstab monta in silenzio il filesystem sbagliato. Non c'è nessun errore: i dati sembrano spariti, e quelli nuovi finiscono nel posto sbagliato.

**Compito.** Esegui `palestra/l03/ticket-2.txt`:

- `/srv/dati` mostra di nuovo il filesystem DATI;
- la riga di fstab lo trova da qualcosa scritto sul disco stesso;
- il filesystem VECCHI non viene modificato né lasciato montato;
- il sistema di avvio usa già la configurazione nuova.

Criteri di accettazione: `sudo ./verifica.sh 03 2` esce con 0, `findmnt --verify` esce con 0.

**Verifica.** `sudo ./verifica.sh 03 2`

> [!question]- Indizio 1
> Quale filesystem è montato ora su `/srv/dati`, e dove sta quello che si chiama DATI? Uno strumento mostra i filesystem di ogni disco con etichetta e UUID.

> [!question]- Indizio 2
> Guarda le cartelle in `/dev/disk/`: ognuna chiama gli stessi dischi in un modo diverso. Quali nomi cambierebbero se cambiasse l'ordine dei dischi?

> [!question]- Indizio 3
> Prima di correggere la riga, cosa va fatto di ciò che è montato ora? E dopo averla corretta?

**Dopo.** Hai usato l'UUID o l'etichetta? Quale dei due è più comodo, e quale regge se un giorno cloni il disco byte per byte? Cosa fa XFS se due filesystem hanno lo stesso UUID? Che differenza c'è fra `by-id` e `by-path`?

---

## Problema 3 — Il disco di backup che va e viene

**Situazione.** Il disco di backup è esterno: il venerdì si scollega e va fuori sede, il lunedì torna. Va montato quando c'è, ma la macchina deve avviarsi anche quando manca.

> [!info] Il contesto
> **Lo scenario.** Dischi esterni, volumi iSCSI e di rete, dischi rimovibili: il sistema deve sapere che può farne a meno.
> - **Requires** e **Wants** (inglese, «richiede» e «vuole»): le due dipendenze di systemd. Con la prima, se manca ciò che serve, fallisce anche chi lo richiede; con la seconda si prova, ma si va avanti.
> - **local-fs.target** (*target*, «obiettivo»): il punto dell'avvio in cui i filesystem locali devono essere montati.
> - **Timeout** (*time out*, «tempo scaduto»): quanto si aspetta prima di rinunciare. Per un disco, systemd aspetta 90 secondi.
>
> **Perché conta.** Per systemd, un disco che manca è un filesystem obbligatorio che non arriva. Dopo un minuto e mezzo d'attesa la macchina si ferma in emergency mode, e via SSH non entra più nessuno.

**Compito.** Esegui `palestra/l03/ticket-3.txt`:

- `/srv/backup` montato a ogni avvio quando il disco c'è, cercato per UUID;
- se manca, l'avvio prosegue, con al massimo 10 secondi di attesa;
- montato adesso, con la configurazione nuova già in uso.

Criteri di accettazione: `sudo ./verifica.sh 03 3` esce con 0, `findmnt --verify` esce con 0.

**Verifica.** `sudo ./verifica.sh 03 3`

> [!question]- Indizio 1
> Fra le opzioni in `man fstab`, quale dice di non considerare un errore la mancanza del dispositivo?

> [!question]- Indizio 2
> Le opzioni che riguardano solo systemd hanno un prefisso comune: lo trovi in `man systemd.mount`, sezione FSTAB. Quale parla dell'attesa per il dispositivo?

> [!question]- Indizio 3
> Cosa ne ha capito systemd? Dopo avergli fatto rileggere la configurazione, guarda `systemctl show local-fs.target -p Wants -p Requires`.

**Dopo.** A VM spenta stacca il disco di backup, poi riavvia. Trova la sua porta SATA con `VBoxManage showvminfo lab-rocky | grep SATA` e il seriale del ticket, poi staccalo con `VBoxManage storageattach lab-rocky --storagectl SATA --port N --medium none`. Quanto ci mette, e cosa dice `systemctl --failed`? Poi rimettilo. Cosa farebbe `x-systemd.automount`? Perché per i filesystem di rete si usa `_netdev`?

---

## Problema 4 — La cartella condivisa del gruppo

**Situazione.** Il gruppo sviluppo avrà una cartella condivisa su un disco suo. Un collega ha cominciato il lavoro e ha già «sistemato i permessi». Il resto tocca a te.

> [!info] Il contesto
> **Lo scenario.** Un gruppo di lavoro condivide una cartella. Con i permessi di base ognuno crea file con il proprio gruppo, e chi può scrivere nella cartella può anche cancellare il lavoro degli altri.
> - **Proprietario, gruppo, altri** (*user*, *group*, *others*): le tre classi dei permessi Unix, ognuna con lettura, scrittura ed esecuzione (*rwx*).
> - **setgid** (*set group ID*, imposta l'identificativo di gruppo): su una cartella, fa sì che i file nuovi prendano il gruppo della cartella invece di quello di chi li crea.
> - **File di dispositivo** e **setuid** (*set user ID*): un file che dà accesso diretto a un disco, e un programma che gira con i poteri del suo proprietario. Su un volume di dati non servono e sono un rischio.
>
> **Perché conta.** Con permessi sbagliati sulla cartella condivisa succede una di due cose: nessuno riesce a lavorare, oppure un errore di uno cancella il lavoro di tutti. E il lavoro di un collega va controllato sulla cartella che si usa davvero.

**Compito.** Esegui `palestra/l03/ticket-4.txt`:

- `/srv/progetti` montato a ogni avvio per UUID, e adesso, senza effetto per file di dispositivo e setuid;
- anna e luca creano file e cartelle e vedono quelli dell'altro;
- tutto ciò che nasce lì appartiene al gruppo sviluppo, anche nelle sottocartelle;
- nessuno cancella o rinomina i file degli altri;
- marco, che non è del gruppo, non può nemmeno elencare la cartella.

Criteri di accettazione: `sudo ./verifica.sh 03 4` esce con 0, `findmnt --verify` esce con 0. Il correttore crea e prova a cancellare file come anna, luca e marco, poi li toglie.

**Verifica.** `sudo ./verifica.sh 03 4`

> [!question]- Indizio 1
> Monta il filesystem e guarda `ls -ld /srv/progetti`: sono i permessi del collega? Smonta e guarda di nuovo. Dove li aveva messi?

> [!question]- Indizio 2
> Prova come anna: `sudo runuser -u anna -- touch /srv/progetti/prova`. Cosa manca, fra i permessi del proprietario, del gruppo e degli altri?

> [!question]- Indizio 3
> Crea un file come anna e guarda a che gruppo appartiene. Quale bit speciale della cartella cambia questo comportamento? `man chmod`, sezione SETUID AND SETGID BITS.

> [!question]- Indizio 4
> In `/tmp` tutti scrivono, ma nessuno cancella i file degli altri. Guarda `ls -ld /tmp`: cosa c'è di diverso dalle altre cartelle?

**Dopo.** Cosa vogliono dire la `s` nella colonna del gruppo e la `t` in fondo, e cosa cambierebbe se fossero maiuscole? Perché luca legge il file di anna ma non lo può modificare, e come lo permetteresti con `umask` o con le ACL (`setfacl -d`)? Cosa impediscono in concreto le due opzioni di montaggio?

---

## Pulizia — Restituire i dischi, e che la macchina riparta

**Situazione.** I tre dischi dedicati tornano in magazzino. Sono montati, e `/etc/fstab` li cita tutti.

> [!info] Il contesto
> **Lo scenario.** Dismettere un disco non finisce quando lo si cancella: la macchina deve ripartire senza di lui.
> - **Riga orfana**: una riga di fstab che cita un disco che non c'è più.
>
> **Perché conta.** Un disco tolto con la sua riga ancora in fstab è il modo più comune di finire in emergency mode al riavvio. Lo vedrai nella lezione 07.

**Compito.** `sudo ./prepara.sh 03 pulizia`, poi esegui `palestra/l03/ticket-pulizia.txt`:

- niente di montato e nessuna firma sui dischi dedicati;
- `/etc/fstab` com'era prima della lezione, già riletto dal sistema di avvio;
- il disco di sistema non si tocca.

Criteri di accettazione: `sudo ./verifica.sh 03 pulizia` esce con 0.

**Verifica.** `sudo ./verifica.sh 03 pulizia`

> [!question]- Indizio 1
> In che ordine lavori? Cosa succede se cancelli la riga di fstab prima di smontare, e cosa se la cancelli dopo?

**Dopo.** Quale delle tre righe, lasciata lì, avrebbe fermato il prossimo avvio, e quale no? Perché?

---

## Diario

Domande numerate, risposte, correzioni ed errori di questa lezione, problema per problema.

## Sintesi

Da scrivere insieme a lezione finita, partendo dalle mie parole.

---

↑ [[00-percorso-linux|Il percorso]] · ← [[02-filesystem|Lezione 02]] · → [[04-swap|Lezione 04]]
