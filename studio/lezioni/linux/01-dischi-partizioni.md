---
tags:
  - lezione
  - linux
aliases:
  - Linux 01 — Dischi e partizioni
---
# Linux 01 — Dischi e partizioni

Un disco nuovo non serve finché qualcuno non lo divide e non descrive come è diviso. Qui impari a riconoscere il disco giusto, a scriverne la tabella e a farla vedere al kernel senza toccare ciò che c'è già. Gli appunti di partenza sono [[disco-settori|Disco e settori]], [[partizioni|Partizioni]], [[mbr-gpt|MBR e GPT]] e [[strumenti-partizionamento|Strumenti di partizionamento]].

```sh
cd formazione_sou/lab/linux
sudo ./prepara.sh 01        # problema 1; poi sudo ./prepara.sh 01 2, e così via
```

Ogni `prepara.sh` azzera i dischi dedicati e costruisce lo scenario di un solo problema: si fanno uno alla volta, come i ticket.

## La mappa

| # | Problema | Stato |
|---|---|---|
| 0 | Previsioni — settori, MiB e tabelle sulla carta | — |
| 1 | Il disco del database — quale disco è quello nuovo? | — |
| 2 | L'apparato che vuole MBR | — |
| 3 | Una partizione in più, a caldo | — |
| 4 | `clona-schema.sh` — lo stesso schema sui dischi gemelli | — |
| P | Pulizia — restituire i dischi | — |

---

## Problema 0 — Previsioni

**Situazione.** Un collega ti incolla la tabella delle partizioni di un disco e ti chiede due conti. Prima di toccare dischi veri, conviene saperli fare sulla carta.

> [!info] Il contesto
> **Lo scenario.** Nei ticket e nelle chat le tabelle delle partizioni girano come testo. Chi le legge deve capire al volo quanto è grande una partizione, dove finisce e cosa resta libero.
> - **Settore** (latino *sector*, «chi taglia», poi «spicchio»): l'unità minima che il disco legge e scrive, qui 512 byte.
> - **LBA** (*Logical Block Addressing*, indirizzamento logico dei blocchi): i settori numerati da 0 in poi, senza più cilindri e testine.
> - **MiB** e **GiB** (*mebibyte*, *gibibyte*): 1024² e 1024³ byte. MB e GB, a rigore, sono 1000² e 1000³.
>
> **Perché conta.** Un errore di un settore non si vede subito: lo scopri quando due partizioni si sovrappongono o un filesystem non entra più.

**Compito.** Per ogni domanda scrivi **prima** la risposta e il conto, poi controlla con Claude.

```text
Disk /dev/sdb: 2 GiB, 2147483648 bytes, 4194304 sectors
Sector size (logical/physical): 512 bytes / 512 bytes
Disklabel type: gpt

Device       Start     End Sectors  Size Type
/dev/sdb1     2048 1050623 1048576  512M Linux filesystem
/dev/sdb2  1050624 3147775 2097152    1G Linux swap
```

1. Quanti byte ci sono prima di `sdb1`? Perché proprio quel numero di settori?
2. Una partizione da 1 GiB che inizia a 1 MiB: quanto valgono `Start` e `End`?
3. Dove inizierebbe una terza partizione? Fin dove può arrivare, al massimo, e perché non fino al settore 4194303?
4. In una tabella MBR, quante partizioni primarie ci stanno? Quanto può essere grande un disco MBR con settori da 512 byte?
5. Cosa c'è nel settore 0 di un disco GPT?
6. Dopo aver creato `sdb1` e `sdb2`, cosa stampa `ls -l /dev/sdb*`, numeri compresi?

**Verifica.** A mano, con Claude. Alcune risposte le ritrovi sul disco vero nel problema 1.

**Dopo.** Quale di queste risposte hai dovuto cercare? Dove l'hai trovata?

---

## Problema 1 — Il disco del database

**Situazione.** Sulla macchina sono arrivati dischi nuovi da 2 GiB, tutti uguali. Uno è per il database, un altro è di una collega che ci ha già messo dei dati. Il ticket li distingue per numero di serie, non per nome.

> [!info] Il contesto
> **Lo scenario.** In un centro dati i dischi arrivano a gruppi e si somigliano tutti. Chi li ordina conosce il seriale stampato sull'etichetta, o mostrato dall'hypervisor, non il nome che gli darà Linux.
> - **Seriale** (*serial number*, numero di serie): il codice che il produttore, o VirtualBox, assegna a ogni disco. Non cambia.
> - **`sdb`** (*SCSI disk*, secondo disco): il nome che il kernel assegna in ordine di scoperta, a ogni avvio. Può cambiare.
> - **GPT** (*GUID Partition Table*): la tabella delle partizioni moderna, nata con l'EFI di Intel. Ogni disco e ogni partizione hanno un **GUID** (*Globally Unique Identifier*, identificatore unico al mondo).
> - **Tipo di partizione**: un altro GUID, che dice a cosa serve la partizione (dati Linux, swap, sistema EFI). Non è il filesystem.
>
> **Perché conta.** Scrivere sul disco sbagliato è l'errore più costoso del mestiere: basta un comando, senza conferma, e i dati di un altro sono persi. Su un disco si scrive solo dopo averlo riconosciuto da qualcosa che non cambia.

**Compito.** Esegui il ticket che `prepara.sh` stampa e salva in `palestra/l01/ticket-1.txt`: una GPT, una sola partizione da 1 GiB esatto che inizia a 1 MiB, con nome «dati-db» e tipo «Linux filesystem», sul disco del seriale indicato. Il disco della collega non va toccato.

Criteri di accettazione: `sudo ./verifica.sh 01 1` esce con 0. Il correttore guarda la tabella scritta sul disco, quella che vede il kernel e il filesystem della collega con i suoi file.

**Verifica.** `sudo ./verifica.sh 01 1`

> [!question]- Indizio 1
> Prima di scrivere: come chiedi al sistema l'elenco dei dischi con il loro seriale? Lo strumento che disegna l'albero dei dischi accetta colonne a scelta: quali conosce, secondo il suo `--help`?

> [!question]- Indizio 2
> Il disco con il nome più basso non mostra partizioni. Vuol dire che è vuoto? Che cosa può esserci su un disco senza tabella? Guarda la colonna del tipo di filesystem.

> [!question]- Indizio 3
> Quali strumenti elenca [[strumenti-partizionamento|Strumenti di partizionamento]]? Quale lavora con GPT? Come gli dici «1 MiB» e «1 GiB» senza calcolare i settori a mano?

> [!question]- Indizio 4
> Il nome GPT è una proprietà della partizione, non del filesystem. Nella pagina di manuale dello strumento che hai scelto, cerca la parola *name*.

**Dopo.** Perché la partizione inizia al settore 2048 e non al 34? Che avviso ti avrebbe dato lo strumento sul disco della collega, se l'avessi scelto? Che differenza c'è fra il nome GPT (`PARTLABEL`) e l'etichetta di un filesystem (`LABEL`)? Riavvia la VM: i nomi `sdb` e `sdc` sono rimasti gli stessi? Cosa li decide?

---

## Problema 2 — L'apparato che vuole MBR

**Situazione.** Un vecchio apparato di misura parte da BIOS e legge solo tabelle MBR. Il fornitore chiede sei partizioni, in un ordine preciso.

> [!info] Il contesto
> **Lo scenario.** Nell'industria, nei laboratori e negli ospedali girano macchine di vent'anni fa che nessuno può aggiornare. Il disco che gli consegni deve parlare la loro lingua.
> - **MBR** (*Master Boot Record*, registro principale di avvio): il primo settore del disco nei PC IBM dal 1983 (PC DOS 2.0). Contiene il codice di avvio e una tabella con quattro posti.
> - **Primaria, estesa, logica**: per superare i quattro posti, una primaria diventa **estesa**, un contenitore in cui si mettono partizioni **logiche** a catena.
> - **Tipo** MBR: un solo byte esadecimale, per esempio `83` (Linux), `82` (Linux swap), `8e` (Linux LVM).
> - **Flag di avvio** (partizione **attiva**): il segno che dice al vecchio codice di avvio da quale partizione partire.
>
> **Perché conta.** Un apparato che non trova ciò che si aspetta non dà errori chiari: semplicemente non parte, magari in un reparto dove serve.

**Compito.** Esegui `palestra/l01/ticket-2.txt`: sei partizioni con dimensioni, tipi e flag del fornitore, nell'ordine indicato. La quarta contiene la quinta e la sesta.

Criteri di accettazione: `sudo ./verifica.sh 01 2` esce con 0, e il kernel vede tutte le partizioni.

**Verifica.** `sudo ./verifica.sh 01 2`

> [!question]- Indizio 1
> Quante voci ha la tabella MBR, e perché proprio quelle? Rileggi [[mbr-gpt|MBR e GPT]]. Se ne servono sei, cosa deve diventare la quarta?

> [!question]- Indizio 2
> Lo strumento interattivo ha un menu di comandi a una lettera. Quale lettera ti mostra il menu? Quale crea una tabella MBR (detta anche «DOS») nuova e vuota?

> [!question]- Indizio 3
> Tipo e flag di avvio si cambiano dopo aver creato le partizioni. Fra le lettere del menu, quali parlano di *type* e di *bootable*?

**Dopo.** Perché le logiche iniziano dal numero 5 anche se esiste la 4? Perché fra una logica e l'altra c'è 1 MiB vuoto? Da dove viene il limite di 2 TiB di MBR? Chi legge ancora il flag di avvio, su una macchina UEFI?

---

## Problema 3 — Una partizione in più, a caldo

**Situazione.** L'archivio è montato e un servizio lo usa giorno e notte. Sullo stesso disco serve una seconda partizione, subito, senza fermare niente.

> [!info] Il contesto
> **Lo scenario.** In produzione le modifiche si fanno **a caldo** (*hot*, con il sistema acceso e in uso). Fermare un servizio richiede una **finestra di manutenzione**, cioè un orario concordato con chi lo usa.
> - **Tabella sul disco e tabella del kernel**: la prima sta nei primi settori, la seconda è la copia che il kernel tiene in memoria e da cui nascono `sdc1`, `sdc2`. Possono essere diverse.
> - **PARTUUID**: il GUID di una partizione GPT. Le applicazioni e i file di configurazione lo usano per ritrovarla qualunque nome abbia.
>
> **Perché conta.** Se il kernel non conosce una partizione, per il sistema non esiste: non la puoi formattare né montare. Se per aggiungerla riscrivi tutta la tabella, cambi identità anche a ciò che c'era, e chi la cercava non la trova più.

**Compito.** Esegui `palestra/l01/ticket-3.txt`: una seconda partizione da 1 GiB esatto, subito dopo la prima, con nome «indici». `/srv/archivio` resta montato, il servizio `lab-occupa-archivio` non si ferma e non riparte, la prima partizione e il disco non cambiano identità. Il kernel deve vedere la nuova partizione.

Criteri di accettazione: `sudo ./verifica.sh 01 3` esce con 0.

**Verifica.** `sudo ./verifica.sh 01 3`

> [!question]- Indizio 1
> Dove guardi la tabella che il kernel sta usando? Rileggi in [[partizioni|Partizioni]] la parte su `/sys/block`. E come leggi invece quella scritta sul disco?

> [!question]- Indizio 2
> Dopo aver scritto, lo strumento ti ha detto qualcosa sul kernel? Leggi le sue ultime righe. Cosa succede se provi a creare un filesystem sulla partizione nuova?

> [!question]- Indizio 3
> Esistono comandi che chiedono al kernel di aggiornare le partizioni di un disco occupato, una alla volta. Cercali nella sezione SEE ALSO della pagina di manuale dello strumento che hai usato.

**Dopo.** Prova a smontare `/srv/archivio`: cosa dice e perché? Chi lo tiene occupato, secondo `fuser -vm`? Quali strumenti aggiornano da soli il kernel anche su un disco occupato, e quali no? Prova con un altro. Perché il kernel rifiuta di rileggere tutta la tabella di un disco in uso? Cosa sono le richieste BLKRRPART e BLKPG?

---

## Problema 4 — `clona-schema.sh`

**Situazione.** Su ogni server nuovo prepari dischi gemelli con lo stesso schema, per esempio due dischi in mirror. Farlo a mano porta prima o poi a un errore: serve uno script.

> [!info] Il contesto
> **Lo scenario.** Chi gestisce decine di macchine scrive una volta e ripete. Lo schema di partizioni viene da un disco già pronto e va copiato su quello nuovo, senza i dati.
> - **Mirror** (inglese, «specchio»; il RAID 1): due dischi che contengono le stesse cose, così se uno si guasta resta l'altro.
> - **Identificatore univoco**: il GUID del disco e delle partizioni, o l'identificativo MBR. Due dischi nella stessa macchina non devono averne uno uguale.
> - **Firma** (*signature*): i byte con cui una tabella o un filesystem si riconoscono sul disco, per esempio `EFI PART` all'inizio di un header GPT.
>
> **Perché conta.** Identificatori duplicati confondono tutto ciò che cerca le partizioni per GUID: montaggi, RAID, avvio. E uno script che scrive su un disco non vuoto cancella in silenzio i dati di qualcuno.

**Compito.** Scrivi `palestra/l01/clona-schema.sh SORGENTE DESTINAZIONE`. Copia su DESTINAZIONE lo schema di SORGENTE, GPT o MBR: stessi inizi, dimensioni, tipi, nomi e flag, ma identificatori nuovi. Su un disco più grande, l'area utilizzabile arriva fino in fondo.

| Caso | Codice |
|---|---|
| Schema copiato | 0 |
| Argomenti mancanti o in più, non dispositivi a blocchi, sorgente uguale alla destinazione, sorgente senza tabella | 2 |
| Destinazione con una tabella, un filesystem o qualcosa di montato: non si scrive niente | 3 |
| Destinazione troppo piccola per l'ultima partizione: non si scrive niente | 4 |
| Qualsiasi altro errore | 1 |

Il correttore lancia lo script solo su dispositivi loop, in una gabbia con un `/dev` che contiene soltanto quei dischi di prova. Per provarlo anche tu senza rischi:

```sh
truncate -s 512M /tmp/a.img /tmp/b.img
sudo losetup -f --show -P /tmp/a.img    # stampa il nome, per esempio /dev/loop0
sudo losetup -d /dev/loop0              # a fine prova
```

**Verifica.** `sudo ./verifica.sh 01 4`

> [!question]- Indizio 1
> Fra gli strumenti di util-linux ce n'è uno pensato per gli script, che non fa domande. `man -k partition` ti aiuta a trovarlo. Sa stampare lo schema di un disco in una forma che si può rileggere?

> [!question]- Indizio 2
> Prova la copia più semplice su due loop e confronta gli identificatori della sorgente e della copia. Sono diversi? Dove compaiono nella forma stampata?

> [!question]- Indizio 3
> Come scopri se un disco contiene già qualcosa senza scriverci? C'è uno strumento che elenca le firme senza toccarle: lo trovi nella pagina che parla di cancellarle.

> [!question]- Indizio 4
> Con una destinazione più grande, guarda le righe d'intestazione della forma stampata. Quale dice fin dove arriva l'area utilizzabile, e di quale disco parla?

**Dopo.** Chi cerca le partizioni per PARTUUID, su questa VM? Prova `ls -l /dev/disk/by-partuuid/`. Perché lo script non copia i dati, e con cosa li copieresti? Cosa fa se la destinazione è un disco intero con dentro un PV di LVM? Cosa succede se lo interrompi a metà?

---

## Pulizia — Restituire i dischi

**Situazione.** La lezione è finita e i dischi dedicati tornano in magazzino. Devono uscire come nuovi, ma sulla macchina qualcuno li sta ancora usando.

> [!info] Il contesto
> **Lo scenario.** Quando un disco o un server si **dismette** (*decommission*, ritiro dal servizio), si toglie ciò che c'è sopra in ordine inverso a come lo si è costruito: prima chi usa, poi chi è usato.
> - **Dismettere**: ritirare dal servizio, documentando cosa si spegne e cosa si cancella.
>
> **Perché conta.** Un disco cancellato mentre è montato lascia il kernel a lavorare su una tabella che non c'è più. E un disco restituito con le vecchie firme confonde la macchina che lo riceve.

**Compito.** `sudo ./prepara.sh 01 pulizia` ricostruisce la macchina come la lascia la lezione. Esegui `palestra/l01/ticket-pulizia.txt`: niente di montato dai dischi dedicati, nessun servizio del kit attivo (si chiamano `lab-occupa-*`), nessuna firma. Il disco di sistema non si tocca.

Criteri di accettazione: `sudo ./verifica.sh 01 pulizia` esce con 0.

**Verifica.** `sudo ./verifica.sh 01 pulizia`

> [!question]- Indizio 1
> Disegna la pila: disco, partizione, filesystem, montaggio, processo. Da quale piano si comincia a togliere?

**Dopo.** Lo strumento che cancella le firme si è rifiutato di lavorare su un disco in uso? Con quale opzione l'avresti costretto, e cosa sarebbe successo al kernel?

---

## Diario

Domande numerate, risposte, correzioni ed errori di questa lezione, problema per problema.

## Sintesi

Da scrivere insieme a lezione finita, partendo dalle mie parole.

---

↑ [[00-percorso-linux|Il percorso]] · → [[02-filesystem|Lezione 02]]
