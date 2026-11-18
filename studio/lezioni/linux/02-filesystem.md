---
tags:
  - lezione
  - linux
aliases:
  - Linux 02 — Filesystem
---
# Linux 02 — Filesystem

Una partizione è solo un tratto di settori: il filesystem la trasforma in file e cartelle. Qui scegli il filesystem giusto per ogni uso, scopri cosa può finire oltre ai byte, e cambi la dimensione di un filesystem senza perdere niente. Gli appunti di partenza sono [[filesystem|Filesystem]], [[inode|Inode e scrittura dei file]], [[block-group|Block e block group]] e [[journaling|Journaling]].

```sh
cd formazione_sou/lab/linux
sudo ./prepara.sh 02        # problema 1; poi sudo ./prepara.sh 02 2, e così via
```

## La mappa

| # | Problema | Stato |
|---|---|---|
| 1 | Tre filesystem per tre usi | — |
| 2 | La posta non parte, ma il disco è mezzo vuoto | — |
| 3 | Il disco è stato ingrandito | — |
| 4 | Restringere per far posto | — |
| P | Pulizia — dismettere il server applicativo | — |

---

## Problema 1 — Tre filesystem per tre usi

**Situazione.** Un server applicativo nuovo ha il disco dati già partizionato. Ogni partizione ha un uso diverso, e il ticket dice quale filesystem ci va. La prima partizione arriva da un server dismesso.

> [!info] Il contesto
> **Lo scenario.** Su Rocky il filesystem predefinito è XFS, ma ext4 resta comune e FAT serve ancora per parlare con firmware, apparati e altri sistemi operativi.
> - **XFS**: nato nel 1993 alla Silicon Graphics per le sue workstation IRIX, portato su Linux nel 2001, predefinito in Red Hat dal 2014, con RHEL 7.
> - **ext4** (*fourth extended filesystem*): la quarta versione del filesystem «esteso» scritto per Linux nel 1992. È stabile dal 2008.
> - **FAT** (*File Allocation Table*, tabella di allocazione dei file): di Microsoft, dal 1977. **FAT32** è del 1996. **vfat** è il nome che Linux dà al driver che li legge tutti.
> - **Etichetta** (*label*): un nome dentro il filesystem, comodo da leggere e da cercare.
> - **Spazio riservato**: la parte di un ext4 che solo root può usare. Serve perché il sistema respiri anche a disco pieno.
>
> **Perché conta.** Su un volume di dati lo spazio riservato predefinito spreca decine di gigabyte senza servire a nessuno. Un apparato che legge solo FAT32 rifiuta in silenzio un disco formattato diversamente.

**Compito.** Esegui `palestra/l02/ticket-1.txt`: XFS «APPDATI» sulla partizione 1, ext4 «LOG» con l'1% riservato sulla 2, FAT32 «SCAMBIO» sulla 3. Non serve montarli. Prima di scrivere, guarda cosa c'è sulla partizione 1.

Criteri di accettazione: `sudo ./verifica.sh 02 1` esce con 0.

**Verifica.** `sudo ./verifica.sh 02 1`

> [!question]- Indizio 1
> Come scopri cosa contiene una partizione senza montarla? Uno strumento legge le firme e ti dice tipo, etichetta e UUID.

> [!question]- Indizio 2
> I programmi che creano un filesystem hanno un nome in comune. Quale? Prova a completarlo con il tasto Tab.

> [!question]- Indizio 3
> Nella pagina di manuale del programma per ext4, quale opzione parla di blocchi riservati (*reserved*)? Accetta una percentuale o un numero di blocchi?

> [!question]- Indizio 4
> Il programma per FAT sceglie da solo la variante in base alla dimensione. Cosa ha scelto, secondo il campo `VERSION` delle firme? Come lo obblighi a scegliere quella che vuoi tu?

**Dopo.** Il programma per XFS si è rifiutato al primo tentativo? Perché? Cosa fa l'opzione che lo costringe, e perché va usata solo dopo aver guardato? Lo spazio riservato di un ext4 si può cambiare dopo, senza riformattare? Perché il programma per FAT avvisa delle etichette minuscole?

---

## Problema 2 — La posta non parte, ma il disco è mezzo vuoto

**Situazione.** Il servizio di posta si è fermato con «No space left on device», ma `df -h` dice che `/srv/posta` è pieno solo per metà. I messaggi in coda non si possono perdere.

> [!info] Il contesto
> **Lo scenario.** Code di posta, sessioni web, cache e miniature producono milioni di file minuscoli. Su questi volumi la prima cosa a finire spesso non sono i byte.
> - **Inode** (*index node*, nodo indice): la scheda di un file con i suoi metadati, uno per file. Dennis Ritchie, uno dei padri di Unix, disse che la «i» stava probabilmente per *index*.
> - **ENOSPC** (*Error NO SPaCe*): il codice d'errore dietro «No space left on device». Lo stesso codice vale per lo spazio e per gli inode.
> - **Coda** (*queue*): la cartella in cui i messaggi aspettano di essere spediti.
>
> **Perché conta.** Un controllo che guarda solo la percentuale di spazio dice «tutto bene» mentre il servizio è fermo. Cancellare i file per far posto risolve oggi e perde dati, e domani il problema torna.

**Compito.** Esegui `palestra/l02/ticket-2.txt`: `/srv/posta` deve poter contenere almeno 50.000 messaggi come quelli presenti, con almeno 45.000 posti liberi. Tutti i messaggi restano, identici e nella stessa cartella, con lo stesso punto di montaggio e l'etichetta POSTA. Il disco non si può ingrandire.

Criteri di accettazione: `sudo ./verifica.sh 02 2` esce con 0.

**Verifica.** `sudo ./verifica.sh 02 2`

> [!question]- Indizio 1
> In un filesystem, cosa può finire oltre ai byte? Rileggi [[inode|Inode e scrittura dei file]].

> [!question]- Indizio 2
> `df` misura anche quell'altra cosa. Quale opzione lo dice, nella sua pagina di manuale?

> [!question]- Indizio 3
> Il numero di inode di un ext4 si decide una volta sola: quando? Si può cambiare dopo? Cerca «inode» nella pagina del programma che crea ext4. Esistono filesystem che decidono man mano?

> [!question]- Indizio 4
> Prima di ricreare il filesystem, i messaggi vanno messi al sicuro: dove, e con quale comando li copi conservando proprietari, permessi e date?

**Dopo.** Quanti inode ha ora `/srv/posta`, e quanto spazio occupano le loro tabelle? Perché ingrandire la partizione non sarebbe bastato, nemmeno se si fosse potuto? Come cambieresti la sentinella della lezione 11 di scripting perché se ne accorga in tempo?

---

## Problema 3 — Il disco è stato ingrandito

**Situazione.** Il gruppo virtualizzazione ha portato il disco di `/srv/app` da 1 a 2 GiB dalla console, a macchina accesa. Dentro la VM `/srv/app` vede ancora 1 GiB, e il servizio non si può fermare.

> [!info] Il contesto
> **Lo scenario.** Nel cloud e con gli hypervisor un disco si ingrandisce con un clic. Il sistema dentro la macchina però non se ne accorge da solo: tocca a chi la amministra.
> - **Hypervisor** (da *supervisor*, «sovrintendente», con *hyper*, «sopra»): il programma che fa girare le VM, come VirtualBox.
> - **Online** e **offline**: un'operazione è online se il filesystem resta montato e in uso mentre la fai.
> - **Header di riserva**: la GPT tiene una seconda copia di sé nell'ultimo settore del disco. Se il disco cresce, la copia resta dov'era, a metà.
>
> **Perché conta.** Ingrandire il disco non basta: lo spazio nuovo resta inutilizzato finché partizione e filesystem non lo raggiungono. Se ne serve uno solo dei due, il ticket resta aperto e il disco si riempie lo stesso.

**Compito.** Esegui `palestra/l02/ticket-3.txt`: `/srv/app` deve usare tutto il disco, online. La partizione mantiene il primo settore e il PARTUUID, il servizio `lab-occupa-app` non si ferma e non si perde nessun dato.

Criteri di accettazione: `sudo ./verifica.sh 02 3` esce con 0.

**Verifica.** `sudo ./verifica.sh 02 3`

> [!question]- Indizio 1
> Leggi i messaggi del kernel di questo avvio, quelli che parlano di GPT. Cosa dicono di questo disco?

> [!question]- Indizio 2
> Gli strati sono tre: disco, partizione, filesystem. Misurali uno per uno, ciascuno con lo strumento che lo conosce. Quale è già cresciuto?

> [!question]- Indizio 3
> C'è uno strumento nato per le immagini cloud che allarga l'ultima partizione fino in fondo al disco. Il suo pacchetto ha un nome che ricorda la crescita: cercalo con `dnf search`.

> [!question]- Indizio 4
> Ogni filesystem ha il suo programma per crescere. Per XFS, la pagina di manuale di `xfs` elenca i programmi `xfs_*`: quale fa al caso tuo, e vuole il filesystem montato o smontato?

**Dopo.** Perché XFS cresce solo montato, mentre ext4 cresce anche smontato? Che fine ha fatto l'header di riserva della GPT? Prova a ingrandire davvero un disco della VM: a VM spenta, con `VBoxManage modifymedium --resize`.

---

## Problema 4 — Restringere per far posto

**Situazione.** Sul disco dei log servono 400 MiB per una partizione nuova. Le due partizioni esistenti sono grandi e quasi vuote: vanno ristrette, una ext4 e una XFS, senza perdere dati.

> [!info] Il contesto
> **Lo scenario.** Lo spazio si chiede sempre in abbondanza, e prima o poi va restituito. Restringere è l'operazione più rischiosa sui dischi, perché il filesystem deve stare tutto dentro il contenitore più piccolo.
> - **Restringere** (*shrink*): ridurre la dimensione. L'opposto, *grow*, è crescere.
> - **Offline**: con il filesystem smontato. È l'unico modo in cui ext4 si lascia ridurre.
> - **Copia di sicurezza** (*backup*): prima di un'operazione che può perdere dati, una copia da cui ripartire.
>
> **Perché conta.** Se riduci il contenitore prima del contenuto, la coda del filesystem resta fuori e i file che ci stavano sono persi. E non tutti i filesystem si possono restringere: con qualcuno l'unica strada è copiare, ricreare e rimettere.

**Compito.** Esegui `palestra/l02/ticket-4.txt`: la partizione 1 scende a 600 MiB esatti e la 2 a 500 MiB esatti, ognuna con lo stesso primo settore e lo stesso PARTUUID. Ogni filesystem riempie la sua partizione al MiB e mantiene tipo ed etichetta, e nessun dato si perde. Alla fine entrambi sono montati dov'erano, e resta un tratto libero contiguo di almeno 400 MiB.

Criteri di accettazione: `sudo ./verifica.sh 02 4` esce con 0.

**Verifica.** `sudo ./verifica.sh 02 4`

> [!question]- Indizio 1
> Disegna partizione e filesystem come due segmenti, uno dentro l'altro. Se accorci prima quello esterno, cosa resta fuori? E nell'ordine opposto?

> [!question]- Indizio 2
> Lo strumento che ridimensiona ext4 si rifiuta finché il filesystem non è stato controllato da poco. Cosa chiede di fare prima? Leggi il suo messaggio fino in fondo.

> [!question]- Indizio 3
> Cosa dice la pagina di manuale del programma che fa crescere XFS a proposito di ridurlo? Se non si può, quali passi ti servono per conservare i dati?

> [!question]- Indizio 4
> Una partizione si può accorciare senza cancellarla e senza spostarne l'inizio. Gli strumenti che hai usato nella lezione 01 come lo chiamano?

**Dopo.** Perché il ticket chiede lo stesso PARTUUID? Cosa sarebbe cambiato se `/srv/indici` fosse stato un ext4? Con LVM, nella lezione 05, quali di questi passi spariranno e quali no?

---

## Pulizia — Dismettere il server applicativo

**Situazione.** Il server applicativo si spegne per sempre. Il suo disco dati va restituito pulito, mentre qualcosa lo usa ancora.

> [!info] Il contesto
> **Lo scenario.** La dismissione è l'ultimo passo di ogni servizio: si toglie ciò che sta sopra prima di ciò che sta sotto, e si lascia scritto cosa si è cancellato.
> - **Dismettere** (*decommission*): ritirare dal servizio.
>
> **Perché conta.** Un filesystem ancora montato su un disco senza firme è un fantasma: il kernel ci scrive, ma al prossimo avvio non c'è più niente.

**Compito.** `sudo ./prepara.sh 02 pulizia`, poi esegui `palestra/l02/ticket-pulizia.txt`: niente di montato dai dischi dedicati, nessun servizio `lab-occupa-*` attivo, nessuna firma. Il disco di sistema non si tocca.

Criteri di accettazione: `sudo ./verifica.sh 02 pulizia` esce con 0.

**Verifica.** `sudo ./verifica.sh 02 pulizia`

> [!question]- Indizio 1
> Quali punti di montaggio vengono dai dischi dedicati? Lo strumento che elenca i filesystem montati sa filtrare per dispositivo di origine.

**Dopo.** In che ordine hai smontato, e perché? Cosa avrebbe fatto `umount -l`, e perché è una scorciatoia pericolosa?

---

## Diario

Domande numerate, risposte, correzioni ed errori di questa lezione, problema per problema.

## Sintesi

Da scrivere insieme a lezione finita, partendo dalle mie parole.

---

↑ [[00-percorso-linux|Il percorso]] · ← [[01-dischi-partizioni|Lezione 01]] · → [[03-mount-fstab-uuid|Lezione 03]]
