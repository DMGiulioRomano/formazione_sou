---
tags:
  - lezione
  - linux
aliases:
  - Linux 07 — fsck ed emergency mode
---
# Linux 07 — fsck ed emergency mode

Prima o poi una macchina si spegne male, un filesystem si rovina, una riga di `/etc/fstab` sbagliata la ferma all'avvio. Qui tieni i log da un avvio all'altro, ripari un ext4 e un XFS senza perdere dati e riporti in servizio una macchina ferma in emergenza, dalla console. Gli appunti di partenza sono [[integrita-fsck|Integrità del filesystem e fsck]], [[journaling|Journaling]], [[journalctl|journalctl]] e [[mount-fstab|Mount e fstab]].

```sh
cd formazione_sou/lab/linux
sudo ./prepara.sh 07        # problema 1; poi sudo ./prepara.sh 07 2, e così via
```

> [!warning] Prima di cominciare
> - **Una fotografia della VM**, a VM spenta: `VBoxManage snapshot lab-rocky take prima-di-07`. Il problema 4 ferma l'avvio, e un errore in emergenza può renderlo più difficile da sistemare.
> - **La password di root**: in emergenza il sistema la chiede. `sudo passwd -S root` deve dire `PS`; se dice `LK` o `NP`, impostala con `sudo passwd root` e annotala. Senza, `prepara.sh 07 4` si rifiuta di partire.
> - **La finestra della VM** aperta in VirtualBox: quando la rete non c'è, è l'unica console.

## La mappa

| # | Problema | Stato |
|---|---|---|
| 1 | I log di ieri non ci sono | — |
| 2 | Structure needs cleaning | — |
| 3 | Il disco tornato dal guasto | — |
| 4 | La macchina non riparte | — |
| P | Pulizia — restituire i dischi dopo il guasto | — |

---

## Problema 1 — I log di ieri non ci sono

**Situazione.** Stanotte un servizio si è fermato e la macchina è stata riavviata. Stamattina il gruppo vuole capire cosa è successo, ma `journalctl` comincia dal riavvio: di prima non c'è niente.

> [!info] Il contesto
> **Lo scenario.** Il primo passo di ogni indagine dopo un guasto è leggere i log dell'avvio precedente. Se il journal vive solo in memoria, il riavvio li cancella proprio quando servono.
> - **journald** (*journal daemon*, il demone del giornale): il servizio di systemd che raccoglie i log di kernel, servizi e programmi.
> - **Volatile** (dal latino *volare*, «che vola via»): tenuto in RAM, in `/run`, e perso allo spegnimento.
> - **Persistente**: scritto su disco, in `/var`, e conservato da un avvio all'altro.
> - **Rotazione**: quando i file dei log superano il limite, journald cancella i più vecchi.
>
> **Perché conta.** Un journal su disco senza limite riempie `/var`, e con `/var` piena si fermano altri servizi. Va scelto il tetto insieme alla persistenza.

**Compito.** Esegui `palestra/l07/ticket-1.txt`:

- il journal si salva su disco e sopravvive ai riavvii;
- su disco occupa al massimo 200 MiB;
- la configurazione nuova è già attiva, senza riavviare.

Criteri di accettazione: `sudo ./verifica.sh 07 1` esce con 0. Dopo il prossimo riavvio, `journalctl --list-boots` mostra anche l'avvio di oggi.

**Verifica.** `sudo ./verifica.sh 07 1`

> [!question]- Indizio 1
> Dove tiene i suoi file journald? Cerca le due cartelle in `man systemd-journald`, sezione FILES, e guarda quale delle due cresce adesso.

> [!question]- Indizio 2
> La configurazione di journald non sta in un file solo. L'inizio di `man journald.conf` dice quali file legge e chi vince fra loro. Cosa trovi sulla tua macchina in quei posti? `systemd-analyze cat-config systemd/journald.conf` li mostra in fila.

> [!question]- Indizio 3
> Hai cambiato la configurazione: il journald che gira l'ha letta? Da quando è attivo, secondo `systemctl status systemd-journald`?

**Dopo.** Che fine fanno i log che erano solo in memoria quando passi al disco? Cerca *flush* in `man journalctl`. Come leggi l'avvio precedente, e come gli errori di quell'avvio soltanto? Su Rocky gira anche rsyslog, che scrive `/var/log/messages`: a cosa serve ancora? Cosa fanno `SystemKeepFree` e `MaxRetentionSec`?

---

## Problema 2 — Structure needs cleaning

**Situazione.** L'applicazione dell'archivio riceve «Structure needs cleaning» quando legge le fatture, e da stamattina non scrive più niente in `/srv/archivio`. Il disco è sano: si è rovinata una struttura del filesystem.

> [!info] Il contesto
> **Lo scenario.** Una scrittura interrotta, un blocco del disco che restituisce dati sbagliati, un bug: i metadati di un filesystem smettono di tornare. Il kernel se ne accorge solo quando ci passa sopra.
> - **Structure needs cleaning** («la struttura va ripulita»): il messaggio dell'errore `EUCLEAN`, che il kernel restituisce quando trova metadati incoerenti.
> - **Inode**: la scheda di un file o di una cartella, con proprietario, permessi e blocchi, ma senza il nome ([[inode|Inode e scrittura dei file]]).
> - **errors=remount-ro**: un'opzione di montaggio di ext4. Al primo errore il filesystem si rimonta in sola lettura, per non scrivere sopra una struttura rotta.
> - **lost+found** («perduto e ritrovato»): la cartella in cui il controllo del filesystem raccoglie ciò che ritrova senza più una cartella che lo contenga.
>
> **Perché conta.** Un controllo fatto con il filesystem montato può peggiorare il danno. Quando invece lo fai nel modo giusto, i file tornano, ma non da soli al loro posto: rimetterli a posto è lavoro tuo.

**Compito.** `sudo ./prepara.sh 07 2`, poi esegui `palestra/l07/ticket-2.txt`:

- il filesystem riparato, e di nuovo montato in lettura e scrittura come da `/etc/fstab`;
- nessuna fattura persa: tutte in `/srv/archivio/fatture`, ognuna con il suo nome, cioè il numero scritto nella prima riga più `.txt`;
- la cartella `fatture` com'era: di root, gruppo `amministrazione`, permessi 2770;
- contratti e verbali intatti. Il servizio `lab-occupa-archivio` si può fermare.

Criteri di accettazione: `sudo ./verifica.sh 07 2` esce con 0, e `ls /srv/archivio/lost+found` non mostra niente.

**Verifica.** `sudo ./verifica.sh 07 2`

> [!question]- Indizio 1
> Rileggi [[integrita-fsck|Integrità del filesystem e fsck]]: quale programma controlla un ext4, e in che stato deve essere il filesystem quando lo lanci?

> [!question]- Indizio 2
> Prova il controllo così com'è e leggi la prima riga della risposta. Poi chiedi chi usa il filesystem: `fuser -vm /srv/archivio`.

> [!question]- Indizio 3
> Il controllo è finito: cosa c'è in `/srv/archivio/lost+found`? Cosa sono quei nomi, e cosa dice la prima riga di ciascun file?

> [!question]- Indizio 4
> Il 2 davanti a 770: ricordi la cartella del gruppo, nella lezione 03?

**Dopo.** All'avvio il controllo gira in modalità automatica (*preen*, «ripulire», l'opzione `-p`): su questo danno avrebbe finito da solo? Perché? I file ritrovati hanno conservato proprietario e permessi ma non il nome: dove sta scritto il nome di un file? Cosa dice `dumpe2fs -h` del filesystem prima e dopo la riparazione? Cosa dice la sesta colonna di `/etc/fstab` per `/srv/archivio`, e cosa succede a ogni avvio per colpa sua? È la frase da controllare in [[integrita-fsck|Integrità e fsck]].

---

## Problema 3 — Il disco tornato dal guasto

**Situazione.** Durante l'indicizzazione la macchina si è spenta di colpo. Il collega di turno ha smontato `/srv/indici` e lanciato il controllo del filesystem: si è fermato con un errore e gli ha suggerito un'opzione per forzarlo. Non l'ha usata, e ti passa il ticket.

> [!info] Il contesto
> **Lo scenario.** Dopo uno spegnimento brusco, un filesystem con journal non è rotto: ha del lavoro in sospeso. Le ultime modifiche ai metadati sono scritte nel log ma non ancora al loro posto.
> - **Log** (in inglese «giornale di bordo»): il journal di XFS, l'area in cui il filesystem scrive le transazioni prima di applicarle ([[journaling|Journaling]]).
> - **Checkpoint** («punto di controllo»): il momento in cui le transazioni del log vengono copiate nei metadati veri.
> - **Replay** («rigiocare»): applicare le transazioni rimaste nel log, come se lo spegnimento non ci fosse stato.
> - **Spegnimento sporco** (*unclean shutdown*): uno spegnimento senza smontare, per esempio per mancanza di corrente.
>
> **Perché conta.** L'opzione che forza un controllo spesso butta via proprio ciò che serviva. Qui sono le ultime ore di lavoro.

**Compito.** `sudo ./prepara.sh 07 3`, poi esegui `palestra/l07/ticket-3.txt`:

- `/srv/indici` di nuovo montato come da `/etc/fstab`, con lo stesso filesystem;
- non si perde niente, né lo storico né gli indici scritti stanotte in `/srv/indici/stanotte`.

Criteri di accettazione: `sudo ./verifica.sh 07 3` esce con 0.

**Verifica.** `sudo ./verifica.sh 07 3`

> [!question]- Indizio 1
> Lancia lo stesso controllo del collega e leggi il messaggio fino all'ultima riga. Cosa ti chiede di fare, prima di forzare?

> [!question]- Indizio 2
> Rileggi le fasi in [[journaling|Journaling]]: dove stanno le ultime modifiche se il checkpoint non è arrivato? E cosa succede loro se il log si cancella?

> [!question]- Indizio 3
> Dopo aver fatto ciò che il messaggio chiede, il controllo si può ripetere senza toccare niente: cerca in `man xfs_repair` l'opzione che si limita a guardare.

**Dopo.** Cosa ha scritto il kernel quando il log è stato rigiocato (`journalctl -k`)? Cosa avrebbe perso l'opzione suggerita, e perché proprio i file di stanotte? Perché XFS non ha un controllo all'avvio come ext4 (guarda `/usr/sbin/fsck.xfs`)? In quale caso l'opzione che cancella il log è l'unica strada?

---

## Problema 4 — La macchina non riparte

**Situazione.** Venerdì un collega ha spostato i dati del database su un disco dedicato: l'ha montato a mano e ha aggiunto la riga in `/etc/fstab`, scrivendo l'UUID a mano. Stanotte la macchina si è riavviata per gli aggiornamenti e non è più tornata in rete.

> [!info] Il contesto
> **Lo scenario.** Una riga di `/etc/fstab` può restare sbagliata per mesi: finché nessuno riavvia, il disco resta montato e tutto funziona. Il guasto si vede al primo riavvio, spesso di notte, e senza rete.
> - **Emergency mode** (modalità di emergenza): systemd si ferma prima di quasi tutto e offre una shell di root sulla console.
> - **local-fs.target**: il punto dell'avvio in cui i filesystem locali di `/etc/fstab` sono montati. Se uno non arriva, systemd non va oltre.
> - **Timeout del dispositivo**: quanto systemd aspetta un disco prima di arrendersi, di solito 90 secondi.
> - **Console** (dal francese, «mensola», poi il quadro dei comandi): lo schermo e la tastiera della macchina. Nei datacenter è remota: iLO, iDRAC, la console della VM.
>
> **Perché conta.** Far partire la macchina «comunque» nasconde il guasto: il database partirebbe scrivendo nella cartella vuota sul disco di sistema.

**Compito.** `sudo ./prepara.sh 07 4`, poi esegui `palestra/l07/ticket-4.txt`. Il ticket ti fa riavviare la macchina con la console aperta. Alla fine:

- la macchina si avvia da sola fino in fondo, con `/srv/dati` montato come da `/etc/fstab` e i dati intatti;
- senza `nofail`: se il disco mancasse, la macchina se ne deve accorgere;
- l'ultimo avvio è un riavvio pulito, che non passa dalla modalità di emergenza.

Criteri di accettazione: dopo il riavvio finale `sudo ./verifica.sh 07 4` esce con 0, e `systemctl --failed --type=mount` non elenca niente.

**Verifica.** `sudo ./verifica.sh 07 4`

> [!question]- Indizio 1
> Prima di scrivere la password, leggi lo schermo: cosa ha aspettato systemd, e per quanto tempo?

> [!question]- Indizio 2
> Dentro la modalità di emergenza: `journalctl -xb -p err`. Quale unità è fallita per prima, e quali sono cadute per colpa sua?

> [!question]- Indizio 3
> Confronta ciò che `/etc/fstab` cerca con ciò che il disco dice di sé: `blkid`.

> [!question]- Indizio 4
> Corretto il file, systemd lo sa già? E come provi che la macchina riparte da sola, senza aiuto?

**Dopo.** Perché la macchina si è fermata invece di partire senza `/srv/dati`? Cosa avrebbe cambiato `nofail`, e perché il ticket lo vieta? Che differenza c'è tra `emergency.target` e `rescue.target` (`man systemd.special`)? Cosa sarebbe successo con `systemctl default` dalla shell di emergenza, e perché il correttore voleva un riavvio vero? Cosa mostra `journalctl -b -1 -p err` adesso?

---

## Pulizia — Restituire i dischi dopo il guasto

**Situazione.** Archivio, indici e database sono passati su un'altra macchina. I tre dischi dedicati tornano in magazzino: sopra ci sono `/srv/archivio` (ext4), `/srv/indici` e `/srv/dati` (XFS), montati e scritti in `/etc/fstab`, e l'archivio è ancora in uso.

> [!info] Il contesto
> **Lo scenario.** Si dismette in ordine inverso a come si è costruito: chi usa, cosa è montato, cosa lo monta all'avvio, cosa c'è sul disco.
>
> **Perché conta.** Una riga di `/etc/fstab` che cita un disco tolto è proprio il guasto del problema 4, rimandato al prossimo riavvio.

**Compito.** `sudo ./prepara.sh 07 pulizia`, poi esegui `palestra/l07/ticket-pulizia.txt`:

- niente di montato e nessuna firma sui dischi dedicati;
- `/etc/fstab` com'era prima della lezione, già riletto dal sistema di avvio;
- il disco di sistema non si tocca.

Criteri di accettazione: `sudo ./verifica.sh 07 pulizia` esce con 0.

**Verifica.** `sudo ./verifica.sh 07 pulizia`

> [!question]- Indizio 1
> Uno dei tre non si smonta? Chi lo sta usando?

**Dopo.** Cosa avresti visto al prossimo avvio se avessi cancellato i dischi senza toccare `/etc/fstab`? Il prossimo `prepara.sh` riporta la configurazione di journald a com'era prima della lezione: i log già scritti in `/var/log/journal` restano? Controlla con `journalctl --list-boots`.

---

## Diario

Domande numerate, risposte, correzioni ed errori di questa lezione, problema per problema.

## Sintesi

Da scrivere insieme a lezione finita, partendo dalle mie parole.

---

↑ [[00-percorso-linux|Il percorso]] · ← [[06-lvm-snapshot|Lezione 06]] · → [[08-avvio-grub|Lezione 08]]
