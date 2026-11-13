---
tags:
  - lezione
  - scripting
aliases:
  - Scripting 24 — Secondo progetto finale
---
# Scripting 24 — Secondo progetto finale

Tre programmi che in azienda fanno strumenti come Capistrano, Ansible e `logrotate`. Qui li ricostruisci in piccolo, con tutto ciò che hai imparato: operazioni atomiche, idempotenza, prove a secco, segnali, file descriptor. Come nella lezione 11, prima di scrivere codice si discute la struttura, e la discussione va nel diario. Si fa per ultima.

```sh
./prepara.sh 24 && cd palestra/l24
```

## La mappa

| # | Problema | Stato |
|---|---|---|
| 1 | `deploy.sh` — rilasci con ritorno indietro | — |
| 2 | `provisiona.sh` — la macchina come la descrive un file | — |
| 3 | `ruota-log.sh` — il tuo logrotate | — |

---

## Problema 1 — `deploy.sh`

**Situazione.** Il sito si aggiorna copiando i file sopra quelli vecchi. Per qualche secondo il sito è mezzo vecchio e mezzo nuovo, e se la versione nuova è rotta non c'è modo di tornare indietro. Lo schema classico: ogni rilascio nella sua cartella, e un link simbolico `current` che punta a quello attivo.

> [!info] Il contesto
> **Lo scenario.** Un sito si aggiorna più volte alla settimana, mentre i clienti lo usano. Ogni aggiornamento deve essere istantaneo e, se la versione nuova si rivela rotta, annullabile in un attimo.
> - **Deploy** (francese *déployer*, «spiegare», come si schierano le truppe): la messa in servizio di una versione nuova.
> - **Rilascio** (in inglese *release*): una versione completa dell'applicazione, conservata nella sua cartella.
> - **Link simbolico**: un file speciale che contiene solo il percorso di un altro file o cartella, e chi lo apre finisce lì. Qui `current` indica il rilascio attivo.
> - **Tornare indietro** (in inglese *rollback*): rimettere in servizio la versione precedente.
>
> **Perché conta.** Un sito mezzo vecchio e mezzo nuovo dà errori imprevedibili, e senza la versione di prima a portata di mano un rilascio sbagliato diventa una notte di lavoro.

**Compito.** `./deploy.sh BASE PACCHETTO.tar.gz` e `./deploy.sh BASE --indietro`.

```text
BASE/
├── current -> releases/20261103-101500
└── releases/
    ├── 20261103-091200/
    └── 20261103-101500/
```

- Ogni rilascio va in `BASE/releases/AAAAMMGG-HHMMSS`. Se quel nome c'è già, perché due rilasci cadono nello stesso secondo, si aggiunge `-02`, `-03` e così via, sempre con due cifre. Il nome nuovo deve venire, in ordine, dopo tutti quelli già presenti: l'ordine dei nomi è l'ordine dei rilasci. `BASE` e `releases` si creano se mancano.
- Il pacchetto si estrae nel rilascio. Se il pacchetto contiene `controllo.sh`, lo si esegue dentro il rilascio: deve uscire con 0.
- Se estrazione o controllo falliscono: il rilascio nuovo si cancella, `current` non cambia, codice 1.
- Se va tutto bene, `current` passa al rilascio nuovo **in modo atomico**: non c'è mai un istante in cui `current` manca. Il link è relativo, `releases/NOME`, così `BASE` si può spostare.
- Si tengono gli ultimi tre rilasci, in ordine di nome; i più vecchi si cancellano.
- `--indietro` riporta `current` al rilascio precedente, sempre in ordine di nome. Se non ce n'è uno: codice 1.
- Ogni esecuzione riuscita stampa `attiva: releases/NOME`. Argomenti sbagliati: codice 2.

**Verifica.** `../../verifica.sh 24 1`. Mentre fai i rilasci, il correttore controlla di continuo che `current/index.html` esista.

> [!question]- Indizio 1
> `ln -sfn` sostituisce un link in un colpo solo, oppure lo cancella e lo ricrea? Guardalo con `strace -e trace=unlink,symlink,rename ln -sfn a b`. Quale chiamata di sistema è atomica? Ci hai lavorato nella lezione 08.

> [!question]- Indizio 2
> Per `--indietro` ti serve sapere qual è il rilascio attivo. Come leggi dove punta un link?

> [!question]- Indizio 3
> Un rilascio fallito a metà lascia una cartella mezza piena. Quale comando della lezione 08 fa pulizia in qualunque modo finisca lo script?

**Dopo.** Cosa succede ai processi che hanno già aperto file del rilascio vecchio quando `current` cambia? Perché un web server va comunque ricaricato? Cosa fa `rsync --link-dest` e come lo useresti per non copiare ogni volta tutto?

---

## Problema 2 — `provisiona.sh`

**Situazione.** Ogni nuova VM va preparata allo stesso modo: gruppi, utenti, pacchetti, righe di configurazione, cartelle con i permessi giusti. Farlo a mano significa VM tutte un po' diverse. Ansible descrive lo stato voluto e cambia solo ciò che non corrisponde. Ne scrivi la versione minima.

> [!info] Il contesto
> **Lo scenario.** In un laboratorio, o in un'azienda che cresce, le macchine nuove arrivano ogni settimana e devono essere tutte uguali: stessi gruppi, stessi utenti, stessi pacchetti, stesse impostazioni.
> - **Provisioning** (inglese *to provision*, «rifornire di provviste»): preparare una macchina nuova perché sia pronta all'uso.
> - **Stato voluto**: la descrizione di come deve essere la macchina alla fine, invece della lista dei comandi per arrivarci.
> - **Ansible**: lo strumento più diffuso che lavora così, su molte macchine insieme.
>
> **Perché conta.** Macchine preparate a mano sono tutte un po' diverse, e un difetto che compare su una sola è difficile da spiegare. Uno script che rifà sempre tutto, invece, cambia cose che andavano già bene.

**Compito.** `./provisiona.sh RADICE CONFIG` porta il sistema montato in `RADICE` allo stato descritto da `CONFIG`. Righe vuote e `#` si ignorano.

| Riga | Stato voluto | Come si cambia |
|---|---|---|
| `gruppo NOME` | Il gruppo è in `RADICE/etc/group` | `groupadd -R RADICE NOME` |
| `utente NOME GRUPPO` | L'utente è in `RADICE/etc/passwd` con quel gruppo primario | `useradd -R RADICE -m -g GRUPPO NOME`, oppure `usermod -R RADICE -g GRUPPO NOME` se c'è con un altro gruppo |
| `pacchetto NOME` | `rpm -q --root RADICE NOME` riesce | `dnf -y --installroot RADICE install NOME` |
| `riga FILE TESTO...` | `RADICE/FILE` contiene esattamente la riga `TESTO` | Si aggiunge in fondo; il file e le sue cartelle si creano se mancano |
| `cartella PERCORSO MODO` | `RADICE/PERCORSO` è una cartella con i permessi `MODO` in ottale | `mkdir -p`, poi `chmod` |

- Per ogni riga stampa `cambiato: RIGA` o `invariato: RIGA`, poi in fondo `cambiati: N`.
- **Prima** di cambiare qualsiasi cosa, controlla tutto il file: un tipo sconosciuto o un numero di parametri sbagliato dà `riga N: ...` su stderr e codice 2, senza toccare nulla.
- Se un comando fallisce: `errore: RIGA` su stderr, si prosegue con le altre righe, e alla fine codice 1. Altrimenti 0.
- Rilanciato subito dopo, stampa solo `invariato` e non esegue nessun comando che cambia qualcosa.

In `dati/bin` trovi `groupadd`, `useradd`, `usermod`, `rpm` e `dnf` finti, che lavorano sotto `RADICE` e registrano ogni chiamata in `RADICE/comandi.log`. In `dati/radice` c'è un sistema di partenza, e `dati/config.txt` è un esempio.

**Verifica.** `../../verifica.sh 24 2`

> [!question]- Indizio 1
> Quante volte devi leggere `CONFIG` per rispettare la regola «prima controlla tutto»? Una funzione per tipo di riga, con due modi, «controlla» e «applica», è un'idea.

> [!question]- Indizio 2
> Per ogni tipo, come scopri lo stato attuale senza cambiare nulla? Per i gruppi e gli utenti hai già scritto le ricerche nelle lezioni 02 e 04.

> [!question]- Indizio 3
> `riga etc/motd Benvenuto  in lab` con due spazi: quanti spazi ha la riga voluta? Come leggi «tutto il resto della riga» con `read`?

**Dopo.** Che differenza c'è fra *idempotente* e *dichiarativo*? Cosa dovrebbe fare il tuo script con una riga `utente` che *non* è più nel file: cancellare l'utente? Perché Ansible non lo fa da solo? Come aggiungeresti una modalità `--prova` che dice cosa cambierebbe senza cambiarlo?

---

## Problema 3 — `ruota-log.sh`

**Situazione.** Il log di un servizio cresce di un gigabyte al giorno. Va ruotato: il file attuale diventa `.1`, i vecchi si comprimono, i più vecchi si cancellano. Ma il servizio ha il file aperto, e scrive attraverso il suo descrittore, non attraverso il nome.

> [!info] Il contesto
> **Lo scenario.** Un servizio molto usato scrive un gigabyte di log al giorno. Senza intervento il disco si riempie in qualche settimana. Ma il servizio non può essere fermato ogni notte per sistemare i suoi file.
> - **Ruotare** un log: mettere da parte il file attuale con un numero, comprimere i vecchi e cancellare i più vecchi, come una ruota che gira.
> - **Descrittore di file** (in inglese *file descriptor*): il numero con cui un processo si riferisce a un file che ha aperto. Una volta aperto il file, il processo usa quello, non il nome.
> - **Gigabyte** (greco *gígas*, «gigante»): circa un miliardo di byte.
>
> **Perché conta.** Una rotazione fatta male perde righe di log, o lascia il servizio a scrivere in un file che nessuno guarda più, mentre il disco continua a riempirsi.

**Compito.** `./ruota-log.sh FILE N [--copia | --segnala PIDFILE]`, con `N` da 1 in su:

- I file ruotati sono `FILE.1`, non compresso, poi `FILE.2.gz`, `FILE.3.gz`, fino a `FILE.N.gz`. Ogni rotazione sposta tutti di un posto, comprime quello che passa da `.1` a `.2`, e cancella ciò che andrebbe oltre `N`.
- Modo normale: `FILE` diventa `FILE.1` e si crea un `FILE` nuovo vuoto con gli stessi permessi. Con `--segnala PIDFILE` si manda poi `SIGHUP` al processo il cui PID sta in `PIDFILE`, perché riapra il file.
- Con `--copia`: `FILE` si copia in `FILE.1` e poi si svuota sul posto, per i programmi che non sanno riaprire il log.
- Un `FILE` vuoto non si ruota. File mancante, `N` non valido, argomenti sbagliati: codice 2.

**Verifica.** `../../verifica.sh 24 3`. Il correttore tiene un processo che scrive nel log mentre lo ruoti.

> [!question]- Indizio 1
> Sposta prima il più vecchio o il più nuovo? Prova su carta con `N=3` e quattro file: cosa sovrascrivi se parti dal lato sbagliato?

> [!question]- Indizio 2
> Dopo `mv FILE FILE.1`, dove scrive il processo? Rileggi il problema 3 della lezione 20. Cosa cambia con un `SIGHUP`, se il processo lo gestisce?

> [!question]- Indizio 3
> Svuotare un file sul posto: `: > FILE` o `truncate -s 0`? Che cosa succede alle righe scritte fra la copia e lo svuotamento?

**Dopo.** Cosa fanno `delaycompress`, `postrotate` e `sharedscripts` in `/etc/logrotate.d/` su Rocky? Perché `copytruncate` può perdere righe? Perché un programma che apre il log senza `O_APPEND` lascia, dopo lo svuotamento, un file pieno di zeri? Come lo vedi con `ls -ls`?

---

## Diario

Domande numerate, risposte e correzioni di questa lezione.

## Sintesi

Da scrivere a lezione finita, con le tue parole.

---

← [[11-progetto-finale|Lezione 11]] · ↑ [[00-percorso|Il percorso]]
