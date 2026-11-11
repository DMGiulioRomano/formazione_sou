---
tags:
  - lezione
  - scripting
aliases:
  - Scripting 08 — Backup e rotazione
---
# Scripting 08 — Backup e rotazione

Il manuale Bash fa crescere uno script di backup che copia quattro file. Qui lo porti al livello di uno vero: dati integri, spazio sotto controllo, ripristino provato. Riferimento: *Admin Guide*, capitolo 10.

```sh
./prepara.sh 08 && cd palestra/l08
```

## La mappa

| # | Problema | Stato |
|---|---|---|
| 1 | `backup.sh` — un archivio di cui fidarsi | — |
| 2 | `ruota.sh` — non riempire il disco | — |
| 3 | `prova-ripristino.sh` — il backup funziona? | — |
| 4 | `incrementale.sh` — copiare solo ciò che è cambiato | — |

---

## Problema 1 — `backup.sh`

**Situazione.** Di notte il backup si interrompe a metà per il disco pieno. La mattina dopo c'è un file `.tar.gz` col nome giusto, ma è rotto. Nessuno se ne accorge finché non serve.

**Compito.** `./backup.sh SORGENTE DESTINAZIONE`

- Crea la destinazione se manca.
- Produce `DESTINAZIONE/<nome>_AAAAMMGG-HHMMSS.tar.gz` e, accanto, lo stesso nome con `.sha256` in più.
- Stampa su stdout solo il percorso dell'archivio.
- Dentro l'archivio i percorsi iniziano col nome della cartella, come `sito web/index.html`, non con il percorso assoluto.
- La somma si controlla entrando nella cartella dei backup, quindi nel file `.sha256` non ci sono percorsi.
- `SORGENTE` con la barra finale dà lo stesso nome.
- Se qualcosa fallisce: codice diverso da 0, niente su stdout, nessun archivio con un nome da backup valido. Nemmeno un file temporaneo deve restare, quando finisce bene.
- Numero di argomenti sbagliato: codice 2.

**Verifica.** `../../verifica.sh 08 1`

> [!question]- Indizio 1
> Se scrivi direttamente sul nome definitivo e il disco si riempie, cosa resta? Quale operazione del filesystem fa comparire un file col nuovo nome tutta in una volta? Cosa hai letto in [[inode|inode]] su cosa cambia davvero?

> [!question]- Indizio 2
> Il manuale spiega che `tar` lavora in modalità relativa, con percorsi relativi al punto da cui parte. Come dici a `tar` di partire da un'altra cartella, senza usare `cd`?

> [!question]- Indizio 3
> `sha256sum dest/file` scrive nel risultato anche `dest/`. Da quale cartella dovresti lanciarlo? Si può fare senza spostare tutto lo script?

**Dopo.** `tar` crea l'archivio mentre i file cambiano: un database copiato così è coerente? Chi legge il backup? I permessi del file creato sono quelli giusti per un archivio di `/etc`? Controlla `umask` nell'*Admin Guide* 8.7.

---

## Problema 2 — `ruota.sh`

**Situazione.** Il backup va, ma dopo un mese il disco è pieno di backup. Devi tenere solo gli ultimi. Questa è la parte più pericolosa di tutto il sistema, perché cancella proprio ciò che dovrebbe salvarti.

**Compito.** `./ruota.sh CARTELLA PREFISSO N [--cancella]`

- I backup sono i file `<PREFISSO>_*.tar.gz`. Si tengono gli `N` più recenti e si elencano gli altri, ciascuno seguito dal suo `.sha256` se c'è, dal più vecchio.
- «Recente» si decide dalla data nel nome, non dalla data del file.
- Solo con `--cancella` li rimuove.
- `web` non deve toccare `web2_...`.
- Prefissi con spazi devono funzionare.
- `N` è un intero da 1 in su, altrimenti codice 2: tenere zero backup non è una rotazione. Cartella mancante: codice 1.

**Verifica.** `../../verifica.sh 08 2`. Prova su `dati/backup`, prima senza `--cancella`.

> [!question]- Indizio 1
> Una copia con `cp` senza `-p` o un ripristino cambiano la data di un file. Che fine fa, in quel caso, un `ls -t`? Per questo il nome è più affidabile.

> [!question]- Indizio 2
> Se ordini i nomi `AAAAMMGG-HHMMSS` come testo, l'ordine coincide con quello del tempo? Chi te lo dà già ordinato in shell, senza lanciare `ls`?

> [!question]- Indizio 3
> Come costruisci il pattern perché `web` non prenda `web2`? Quale parte deve restare fra virgolette perché sia presa alla lettera, e quale fuori?

> [!question]- Indizio 4
> Con i nomi in un array, come calcoli quanti sono e come prendi solo i primi k? `man bash`, *Arrays* e *Parameter Expansion*.

**Dopo.** Se i backup falliscono per una settimana e la rotazione continua, cosa rischi? La politica nonno-padre-figlio tiene giornalieri, settimanali e mensili: come la costruiresti sopra questo script?

---

## Problema 3 — `prova-ripristino.sh`

**Situazione.** Un backup che non hai mai ripristinato è una speranza. Vuoi provarlo automaticamente, senza toccare i dati veri e senza lasciare residui, nemmeno quando la prova fallisce.

**Compito.** `./prova-ripristino.sh ARCHIVIO SORGENTE`. Il file `ARCHIVIO.sha256` sta accanto all'archivio; dentro c'è una cartella col nome della sorgente.

| Esito | Codice |
|---|---|
| Somma corretta e contenuto identico alla sorgente | 0 |
| Somma sbagliata o archivio illeggibile | 1 |
| Archivio integro, ma contenuto diverso dalla sorgente | 2 |
| Archivio mancante o argomenti sbagliati | 3 |

Estrae in una cartella temporanea creata apposta, che sparisce in ogni caso. Deve funzionare da qualsiasi cartella corrente.

**Verifica.** `../../verifica.sh 08 3`

> [!question]- Indizio 1
> Perché non `mkdir /tmp/prova`? Cosa succede se due copie girano insieme, o se quella cartella c'è già e appartiene a un altro utente? Quale comando risolve il problema?

> [!question]- Indizio 2
> Le uscite dallo script sono molte. Vuoi scrivere la pulizia prima di ogni `exit`? In `help` c'è un comando che registra cosa fare all'uscita, qualunque sia il motivo: ha un nome legato alla caccia.

> [!question]- Indizio 3
> `sha256sum -c` cerca i file a partire dalla cartella corrente. Quindi da dove va lanciato? Quale forma evita di cambiare cartella per il resto dello script?

> [!question]- Indizio 4
> Quale comando confronta due alberi interi e risponde anche col codice di uscita?

**Dopo.** Una somma salvata accanto all'archivio protegge da un disco che si guasta. Protegge da un attaccante? Cosa servirebbe per difendersi? Cosa non confronta il tuo `diff`, per esempio riguardo a proprietari e permessi?

---

## Problema 4 — `incrementale.sh`

**Situazione.** Il backup completo di ogni notte occupa 40 GB e ci mette due ore, ma ogni giorno cambiano pochi file. GNU tar sa fare backup *incrementali*: registra lo stato dei file e la volta dopo archivia solo le differenze, comprese le cancellazioni.

**Compito.** `./incrementale.sh SORGENTE DEST [--completo]`

- Lo stato sta in `DEST/stato.snar`. Se manca, o con `--completo`, si fa un backup completo e lo stato riparte da zero; altrimenti uno incrementale.
- Gli archivi si chiamano `DEST/NNN-completo.tar.gz` o `DEST/NNN-incr.tar.gz`, con `NNN` che conta da `001`, uno più dell'ultimo archivio presente. Dentro, i percorsi iniziano col nome della sorgente, come in `backup.sh`.
- Stampa il percorso dell'archivio creato.
- Se qualcosa fallisce: codice 1, nessun archivio nuovo e `stato.snar` com'era prima. Argomenti sbagliati: codice 2.

Per ripristinare si estraggono in ordine l'ultimo completo e tutti gli incrementali successivi, ciascuno con `tar --listed-incremental=/dev/null -xzf`.

**Verifica.** `../../verifica.sh 08 4`. Il correttore cambia, aggiunge e cancella file fra un backup e l'altro, poi ripristina e confronta.

> [!question]- Indizio 1
> `man tar` e la sezione *Incremental dumps* di `info tar`: cosa fa `--listed-incremental`, e cosa cambia nel file di stato dopo ogni esecuzione?

> [!question]- Indizio 2
> Se `tar` fallisce a metà, il file di stato è già stato aggiornato? Come lo proteggi? Pensa a lavorare su una copia e a sostituire l'originale solo alla fine.

> [!question]- Indizio 3
> Come trovi il numero più alto fra i nomi già presenti, con lo zero davanti, e come scrivi il successivo con tre cifre? Attenzione a `08` e `09`.

**Dopo.** Che differenza c'è fra backup incrementale e differenziale? Cosa succede se perdi l'incrementale numero 3 su 7? Come sceglieresti quando fare un nuovo completo? Cosa fa `rsync --link-dest`, e perché molti lo preferiscono?

---

## Diario

Domande numerate, risposte e correzioni di questa lezione.

## Sintesi

Da scrivere a lezione finita, con le tue parole.

---

← [[07-utenti-permessi|Lezione 07]] · ↑ [[00-percorso|Il percorso]] · → [[09-processi-segnali|Lezione 09]]
