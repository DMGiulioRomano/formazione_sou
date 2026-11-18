---
tags:
  - lezione
  - linux
aliases:
  - Linux 04 — Swap
---
# Linux 04 — Swap

Quando la RAM finisce, un server senza swap non rallenta: perde un processo. Qui aggiungi swap su partizione e su file, senza fermare niente, e la togli quando qualcuno lo chiede, regolando quanto il kernel la usa. Gli appunti di partenza sono [[swap|Swap]] e [[pseudo-filesystem-sys-proc|Pseudo-filesystem /sys e /proc]].

```sh
cd formazione_sou/lab/linux
sudo ./prepara.sh 04        # problema 1; poi sudo ./prepara.sh 04 2, e così via
```

Le swap che il kit crea stanno sui dischi dedicati. Quella del sistema, se la tua VM ne ha una, non si tocca.

## La mappa

| # | Problema | Stato |
|---|---|---|
| 1 | Il database ucciso di notte | — |
| 2 | Swap subito, e non c'è spazio da partizionare | — |
| 3 | Niente swap su file | — |
| P | Pulizia — restituire il disco dati | — |

---

## Problema 1 — Il database ucciso di notte

**Situazione.** Stanotte il database si è fermato, e nel log del kernel c'è «Out of memory: Killed process». La macchina non ha swap. Sul disco del database, dopo la sua partizione, c'è spazio libero.

> [!info] Il contesto
> **Lo scenario.** Quando la memoria finisce, il kernel sceglie un processo e lo uccide. Di solito è il più grande, cioè proprio quello che serve.
> - **OOM killer** (*Out Of Memory killer*, chi uccide a memoria esaurita): la parte del kernel che sceglie il processo da sacrificare.
> - **Swap** (inglese, «scambio»): spazio su disco dove il kernel sposta le pagine di memoria usate di rado.
> - **Pagina**: il blocco di memoria che il kernel gestisce, di solito 4 KiB (`getconf PAGESIZE`).
> - **Priorità**: con più swap, il kernel riempie prima quella con il numero più alto.
>
> **Perché conta.** Un po' di swap trasforma un crollo in un rallentamento, e lascia il tempo di accorgersene prima che il database cada.

**Compito.** Esegui `palestra/l04/ticket-1.txt`:

- una partizione di swap da 512 MiB esatti, subito dopo quella del database, senza fermare `/srv/db`;
- attiva adesso con priorità 10;
- a ogni avvio, cercata per UUID, con la stessa priorità;
- il sistema di avvio usa già la configurazione nuova.

Criteri di accettazione: `sudo ./verifica.sh 04 1` esce con 0, e `swapon --show` la mostra con priorità 10.

**Verifica.** `sudo ./verifica.sh 04 1`

> [!question]- Indizio 1
> Rileggi [[swap|Swap]]: cosa serve perché una partizione diventi swap, oltre al tipo giusto nella tabella?

> [!question]- Indizio 2
> La partizione nuova nasce su un disco in uso. Ricordi il problema 3 della lezione 01?

> [!question]- Indizio 3
> La priorità: come la dai a mano, e dove la scrivi perché valga all'avvio? `man swapon`, e in `man fstab` la parte sulle opzioni.

> [!question]- Indizio 4
> Anche le swap di fstab diventano unità di systemd. Cerca la tua con `systemctl list-units --type=swap --all`: cosa dice il suo stato?

**Dopo.** Cosa dicono adesso `free -h` e `cat /proc/swaps`? Cosa succede con due swap di pari priorità? Perché la swap non ha né filesystem né punto di montaggio? La vecchia regola «il doppio della RAM» vale ancora?

---

## Problema 2 — Swap subito, e non c'è spazio da partizionare

**Situazione.** Un job notturno esaurisce la memoria. Il disco è tutto occupato dalla partizione dei dati, montata su `/srv/dati`, e non si può fermare niente. Serve swap adesso.

> [!info] Il contesto
> **Lo scenario.** Quando serve memoria in fretta e non c'è spazio da partizionare, si crea un file di swap su un filesystem che c'è già. Si fa in un minuto, ma i dettagli contano.
> - **File di swap**: un file normale in cui il kernel scrive direttamente, blocco per blocco, senza passare dal filesystem.
> - **File sparso** (*sparse file*): un file che dichiara una dimensione ma non ha ancora i suoi blocchi sul disco. I «buchi» si riempiono quando ci si scrive.
>
> **Perché conta.** Nella swap finiscono pezzi della memoria dei processi, password comprese: chi può leggere il file può leggere quella memoria. E il kernel deve sapere in anticipo dove stanno tutti i blocchi del file.

**Compito.** Esegui `palestra/l04/ticket-2.txt`:

- un file `/srv/dati/swapfile` da 256 MiB esatti, usato come swap;
- attivo adesso con priorità 5, e a ogni avvio con la stessa priorità;
- solo root lo legge e lo scrive;
- il sistema di avvio usa già la configurazione nuova.

Criteri di accettazione: `sudo ./verifica.sh 04 2` esce con 0, e `swapon --show` lo mostra con priorità 5.

**Verifica.** `sudo ./verifica.sh 04 2`

> [!question]- Indizio 1
> Quali comandi conosci per creare un file di una dimensione data? Sul file che hai creato prova `ls -lsh`: la prima colonna e la dimensione coincidono?

> [!question]- Indizio 2
> Leggi fino in fondo cosa risponde il programma che attiva la swap. Cosa non gli piace?

> [!question]- Indizio 3
> In una riga di fstab per un file, cosa va nella prima colonna e cosa nella seconda?

**Dopo.** Perché il kernel non accetta buchi in un file di swap? Cosa succederebbe all'avvio se `/srv/dati` non fosse ancora montato quando systemd attiva il file? Guarda `systemctl show srv-dati-swapfile.swap -p RequiresMountsFor -p After`. Fra swap su file e su partizione, cosa cambia per le prestazioni?

---

## Problema 3 — Niente swap su file

**Situazione.** Il fornitore del database chiede due cose: niente swap su file, solo quella sulla partizione, e un kernel che ricorra alla swap il meno possibile. Senza riavviare.

> [!info] Il contesto
> **Lo scenario.** I fornitori di software chiedono spesso configurazioni precise della memoria, e il loro supporto le controlla prima di rispondere.
> - **swappiness** (da *swap*, con il suffisso *-iness*, «propensione allo scambio»): il parametro che dice al kernel quanto preferire la swap rispetto a liberare la cache dei file. Va da 0 a 200; su Rocky vale 60.
> - **Parametri del kernel**: valori che cambiano il comportamento del kernel mentre gira, visibili come file in `/proc/sys`.
>
> **Perché conta.** Un parametro cambiato solo a caldo sparisce al riavvio, e il supporto lo trova sbagliato proprio dopo una manutenzione. Lo stesso vale per una swap tolta a caldo ma ancora scritta nella configurazione.

**Compito.** Esegui `palestra/l04/ticket-3.txt`:

- il file di swap va tolto, adesso e per sempre, e il suo spazio torna libero su `/srv/dati`;
- la swap sulla partizione resta com'è, con priorità 10;
- `vm.swappiness` vale 10, adesso e a ogni avvio;
- niente riavvio, e il sistema di avvio usa già la configurazione nuova.

Criteri di accettazione: `sudo ./verifica.sh 04 3` esce con 0, `cat /proc/sys/vm/swappiness` stampa 10.

**Verifica.** `sudo ./verifica.sh 04 3`

> [!question]- Indizio 1
> Prova a cancellare il file prima di tutto il resto. Cosa risponde il sistema, e perché?

> [!question]- Indizio 2
> `vm.swappiness` vive come file sotto `/proc/sys`. Scriverci dentro vale per sempre? Rileggi [[pseudo-filesystem-sys-proc|Pseudo-filesystem /sys e /proc]]: quei file stanno sul disco?

> [!question]- Indizio 3
> All'avvio qualcuno applica i parametri del kernel scritti nella configurazione. Cerca fra le unità di systemd quella che ha `sysctl` nel nome: quali cartelle legge, secondo la sua pagina di manuale?

**Dopo.** Quale file hai scelto, e in che ordine si leggono i file di configurazione? Se sulla tua VM è attivo `tuned` (`systemctl status tuned`), cosa fa con la swappiness, e chi vince? Cosa vuol dire swappiness 0?

---

## Pulizia — Restituire il disco dati

**Situazione.** Il disco dati torna in magazzino. Sopra ci sono una partizione montata, una partizione di swap e un file di swap, tutti attivi e tutti in `/etc/fstab`.

> [!info] Il contesto
> **Lo scenario.** Anche la swap si dismette: una swap attiva tiene occupato il suo disco, o il filesystem che contiene il file.
> - **Dismettere** (*decommission*): ritirare dal servizio, in ordine inverso a come si è costruito.
>
> **Perché conta.** Una riga di swap che cita un disco tolto non ferma l'avvio come un filesystem, ma lascia un'unità fallita a ogni riavvio. E spegnere tutte le swap insieme spegne anche quella del sistema.

**Compito.** `sudo ./prepara.sh 04 pulizia`, poi esegui `palestra/l04/ticket-pulizia.txt`:

- niente di montato, nessuna swap attiva dal disco dedicato, nessuna firma;
- `/etc/fstab` com'era prima della lezione, già riletto dal sistema di avvio;
- il disco di sistema, e la sua swap se c'è, non si toccano.

Criteri di accettazione: `sudo ./verifica.sh 04 pulizia` esce con 0.

**Verifica.** `sudo ./verifica.sh 04 pulizia`

> [!question]- Indizio 1
> Chi sta usando `/srv/dati`, oltre ai processi? Prova a smontarlo per primo e leggi l'errore.

**Dopo.** Cosa avrebbe fatto `swapoff -a` su una macchina con la swap di sistema? Cosa resta in `/etc/fstab` se togli la swap a caldo e basta?

---

## Diario

Domande numerate, risposte, correzioni ed errori di questa lezione, problema per problema.

## Sintesi

Da scrivere insieme a lezione finita, partendo dalle mie parole.

---

↑ [[00-percorso-linux|Il percorso]] · ← [[03-mount-fstab-uuid|Lezione 03]] · → [[05-lvm|Lezione 05]]
