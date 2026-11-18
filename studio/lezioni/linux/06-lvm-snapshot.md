---
tags:
  - lezione
  - linux
aliases:
  - Linux 06 — Snapshot LVM
---
# Linux 06 — Snapshot LVM

Prima di un'operazione rischiosa serve un punto a cui tornare. LVM lo dà con gli snapshot, e tiene copie dei propri metadati per quando qualcuno sbaglia disco. Qui fai una fotografia, ci torni dopo un aggiornamento andato male e recuperi un VG a cui è stata cancellata un'etichetta. Gli appunti di partenza sono [[lvm|LVM]] e la lezione [[05-lvm|05]].

```sh
cd formazione_sou/lab/linux
sudo ./prepara.sh 06        # problema 1; poi sudo ./prepara.sh 06 2, e così via
```

## La mappa

| # | Problema | Stato |
|---|---|---|
| 1 | La fotografia prima dell'aggiornamento | — |
| 2 | L'aggiornamento è andato male | — |
| 3 | Il collega ha cancellato il disco sbagliato | — |
| P | Pulizia — restituire i dischi dell'applicazione | — |

---

## Problema 1 — La fotografia prima dell'aggiornamento

**Situazione.** Stasera l'applicazione si aggiorna e riscrive i suoi dati in `/srv/app`. Prima serve una fotografia del volume, da tenere fino a domani e da poter consultare.

> [!info] Il contesto
> **Lo scenario.** Prima di un aggiornamento, di una migrazione o di uno script che tocca molti file, si fotografa il volume. Ci vuole un secondo e costa poco, se la fotografia non si tiene per mesi.
> - **Snapshot** (inglese, «istantanea»): un LV che mostra un altro LV com'era in un istante preciso.
> - **Origine** (*origin*): il LV fotografato.
> - **COW** (*Copy On Write*, copia quando si scrive): all'inizio lo snapshot non contiene niente. Prima che un blocco dell'origine cambi, il blocco vecchio viene copiato nello spazio dello snapshot.
>
> **Perché conta.** Lo spazio per le copie deve bastare per tutte le modifiche fino a quando lo snapshot serve. Se si riempie, lo snapshot diventa inutilizzabile proprio quando serviva.

**Compito.** Esegui `palestra/l06/ticket-1.txt`:

- uno snapshot di `lvapp` che si chiami `lvapp-prima`, con almeno 300 MiB per le modifiche;
- montato in sola lettura su `/srv/app-prima`, ma non all'avvio, perché è temporaneo;
- `lvapp` resta montato e `lab-occupa-app` non si ferma.

Criteri di accettazione: `sudo ./verifica.sh 06 1` esce con 0, `sudo lvs vgapp` mostra `lvapp-prima` con origine `lvapp`.

**Verifica.** `sudo ./verifica.sh 06 1`

> [!question]- Indizio 1
> Gli snapshot si creano con lo stesso comando che crea i LV. Quale opzione, secondo `man lvcreate`?

> [!question]- Indizio 2
> Il montaggio fallisce? Leggi gli ultimi messaggi del kernel (`journalctl -k | tail`): cosa dice di quel filesystem?

> [!question]- Indizio 3
> Fra le opzioni di montaggio di XFS, in `man 5 xfs`, ce n'è una pensata proprio per quel caso.

**Dopo.** Scrivi qualcosa in `/srv/app` e guarda la colonna Data% di `lvs`: perché sale? Cosa succede quando arriva al 100%? Come si allarga uno snapshot, e cosa fanno `snapshot_autoextend_threshold` e `snapshot_autoextend_percent` in `/etc/lvm/lvm.conf`? Con un ext4 il montaggio sarebbe fallito? Perché?

---

## Problema 2 — L'aggiornamento è andato male

**Situazione.** L'aggiornamento ha rovinato i dati: schede sparite, configurazioni riscritte, un catalogo illeggibile. Prima di cominciare era stato fatto lo snapshot `lvapp-prima`.

> [!info] Il contesto
> **Lo scenario.** Tornare indietro con uno snapshot richiede minuti; ripristinare un backup può richiedere ore. È il motivo per cui lo snapshot si fa.
> - **Merge** (inglese, «fondere»): riversare lo snapshot nella sua origine, che torna com'era. Lo snapshot poi sparisce.
> - **Aperto** (*open*): un dispositivo che qualcuno sta usando, per esempio perché è montato.
>
> **Perché conta.** Un ritorno indietro che resta in sospeso è peggio di nessuno: tutti credono di essere tornati alla versione buona e ci lavorano sopra.

**Compito.** Esegui `palestra/l06/ticket-2.txt`: `lvapp` torna esattamente com'era al momento dello snapshot. Il servizio si può fermare (`sudo systemctl stop lab-occupa-app`). Alla fine `/srv/app` è montato come prima e lo snapshot non esiste più.

Criteri di accettazione: `sudo ./verifica.sh 06 2` esce con 0, `sudo lvs vgapp` non mostra più `lvapp-prima`.

**Verifica.** `sudo ./verifica.sh 06 2`

> [!question]- Indizio 1
> Fra le operazioni di `lvconvert` ce n'è una che riguarda gli snapshot e la loro origine. Quale?

> [!question]- Indizio 2
> Leggi il messaggio che dà, parola per parola. Quando avverrà davvero il ritorno indietro?

> [!question]- Indizio 3
> Cosa vuol dire una lettera maiuscola all'inizio della colonna Attr di `lvs`? Cercalo nella sezione su `lv_attr` di `man lvs`.

**Dopo.** Perché il merge vuole l'origine chiusa? Quanto ci ha messo? Si poteva fare senza fermare il servizio, e a quale prezzo? Come si fa lo stesso con un filesystem che ha gli snapshot incorporati, come Btrfs, o con Stratis?

---

## Problema 3 — Il collega ha cancellato il disco sbagliato

**Situazione.** Un collega doveva cancellare le firme di un disco vuoto e l'ha fatto su un disco di `vgdati`. Il disco è sano, ma ha perso l'etichetta LVM: il VG è incompleto, `lvdb` non si attiva e `/srv/db` non è montato.

> [!info] Il contesto
> **Lo scenario.** Un comando giusto sul disco sbagliato. Succede, e LVM tiene copie dei propri metadati proprio per questi momenti.
> - **Metadati** (*metadata*, «dati sui dati»): la descrizione del VG (quali PV, quali LV, quali extent). Sta su ogni PV ed è copiata in `/etc/lvm/backup` e `/etc/lvm/archive` a ogni modifica.
> - **Etichetta del PV** (*label*): il settore che dice «questo disco è il PV con questo UUID».
> - **Parziale** (*partial*): un VG a cui manca un PV.
>
> **Perché conta.** Con un VG parziale, le opzioni che «riparano» togliendo ciò che manca cancellano anche i LV che ci stavano sopra. Il recupero va fatto prima, con calma e leggendo.

**Compito.** Esegui `palestra/l06/ticket-3.txt`: `vgdati` torna com'era, con i suoi due PV, senza perdere niente; `lvdb` è attivo e `/srv/db` montato come da `/etc/fstab`.

Criteri di accettazione: `sudo ./verifica.sh 06 3` esce con 0, `sudo vgs vgdati` non dà avvisi su dispositivi mancanti.

**Verifica.** `sudo ./verifica.sh 06 3`

> [!question]- Indizio 1
> Cosa dice `sudo vgs vgdati`, parola per parola? Di quale UUID parla?

> [!question]- Indizio 2
> Dove tiene LVM le copie dei metadati? Guarda in `/etc/lvm/` il file di `vgdati`: cosa c'è scritto del PV che manca?

> [!question]- Indizio 3
> Un PV si può ricreare con un UUID scelto da te: cerca *uuid* e *restorefile* in `man pvcreate`. Poi i metadati del VG si rimettono a posto con un comando che inizia con `vgcfg`.

**Dopo.** Cosa avrebbe fatto l'opzione che toglie i PV mancanti? Che differenza c'è fra `backup` e `archive`? Perché il comando del collega ha cancellato solo 8 byte, e cosa sarebbe successo se avesse azzerato tutto il primo MiB?

---

## Pulizia — Restituire i dischi dell'applicazione

**Situazione.** L'applicazione è stata migrata altrove. `vgapp` occupa due dischi dedicati, con `lvapp` montato e il suo snapshot montato accanto.

> [!info] Il contesto
> **Lo scenario.** Uno snapshot dipende dalla sua origine: si toglie prima lui.
>
> **Perché conta.** Togliere l'origine con lo snapshot ancora attivo, o cancellare i dischi con i volumi accesi, lascia il device-mapper a lavorare su dischi che non hanno più niente.

**Compito.** `sudo ./prepara.sh 06 pulizia`, poi esegui `palestra/l06/ticket-pulizia.txt`:

- niente di montato, nessun VG, nessun PV e nessuna firma sui dischi dedicati;
- LVM non li cerca più all'avvio;
- `/etc/fstab` com'era prima della lezione.

Criteri di accettazione: `sudo ./verifica.sh 06 pulizia` esce con 0.

**Verifica.** `sudo ./verifica.sh 06 pulizia`

> [!question]- Indizio 1
> Cosa mostra `lsblk` sotto i due dischi dopo che hai smontato tutto? Sono ancora lì?

**Dopo.** Cosa fa `dmsetup ls`, e cosa mostrerebbe se avessi cancellato i dischi con i volumi ancora attivi?

---

## Diario

Domande numerate, risposte, correzioni ed errori di questa lezione, problema per problema.

## Sintesi

Da scrivere insieme a lezione finita, partendo dalle mie parole.

---

↑ [[00-percorso-linux|Il percorso]] · ← [[05-lvm|Lezione 05]] · → [[07-fsck-emergency|Lezione 07]]
