---
tags:
  - lezione
  - scripting
aliases:
  - Scripting 06 — Funzioni e robustezza
---
# Scripting 06 — Funzioni e robustezza

Uno script di dieci righe può cancellare un disco. Qui si impara a far fallire gli script in modo controllato e a dargli la forma di un vero comando: opzioni, funzioni, messaggi.

```sh
./prepara.sh 06 && cd palestra/l06
```

## La mappa

| # | Problema | Stato |
|---|---|---|
| 1 | `pulisci.sh` — il bug che cancella tutto | — |
| 2 | `chiavi.sh` — opzioni come un vero comando | — |
| 3 | `mycd.sh` — ciò che uno script non può fare | — |
| 4 | `lib-log.sh` — una libreria tutta tua | — |
| 5 | `rilascia.sh` — opzioni lunghe come i comandi GNU | — |

---

## Problema 1 — `pulisci.sh`

> [!danger] Non lanciare `pulisci-rotto.sh`
> Si studia leggendolo. Mentre scrivi la tua versione, metti `echo` davanti a `rm` finché non hai provato ogni caso, e non lavorare come root. Il correttore ha guardie su `rm` e `find`, ma le tue prove a mano no.

**Situazione.** `palestra/l06/pulisci-rotto.sh` sembra innocuo: tre righe per svuotare una cartella. Errori di questa famiglia hanno davvero cancellato dati di utenti, in prodotti molto diffusi.

> [!info] Il contesto
> **Lo scenario.** Script di pulizia come questo si trovano ovunque: svuotano cartelle temporanee, cache, vecchie installazioni. Scritti in fretta, girano per anni senza problemi, finché un giorno ricevono un caso che nessuno aveva previsto.
> - **Svuotare** una cartella: togliere tutto ciò che contiene, lasciando la cartella al suo posto.
> - **Prodotti molto diffusi**: nel 2015 lo script di installazione di Steam, il negozio di videogiochi di Valve, su Linux ha cancellato tutti i file di alcuni utenti.
>
> **Perché conta.** Una riga di pulizia sbagliata non cancella la cartella giusta: cancella la home, o il disco. Non c'è un cestino da cui recuperare.

**Compito, prima parte: leggere.** Senza eseguirlo, rispondi: cosa fa lo script se lo lanci senza argomenti? Con una cartella inesistente? Con `"mia cartella"`? Dove si trova quando arriva a `rm`?

**Compito, seconda parte: scrivere.** `./pulisci.sh CARTELLA` svuota la cartella, che resta al suo posto vuota, nascosti compresi.

| Caso | Codice |
|---|---|
| Svuotata | 0 |
| Cartella inesistente | 1 |
| Nessun argomento o stringa vuota | 2 |
| La cartella è `/` o la home, anche se scritta in altro modo (`~/`, `/home/../home/io`) | 3 |

In nessun caso di errore può sparire qualcosa.

**Verifica.** `../../verifica.sh 06 1`. Il rifiuto di `/` non viene provato di proposito: controllalo tu, con `echo` al posto di `rm`.

> [!question]- Indizio 1
> `cd` senza argomenti dove porta? E quale comando viene eseguito se `cd` fallisce? Cosa impedisce a uno script di proseguire dopo un errore?

> [!question]- Indizio 2
> Se scrivi `rm -rf "$1"/*` e `$1` è vuota, che percorso resta? Quali opzioni di `set` cita il manuale per le variabili non definite, e quali altre ne trovi in `man bash` sotto *set*?

> [!question]- Indizio 3
> `/home/../home/io` e `/home/io/` sono la stessa cartella scritta in modi diversi. Come ottieni la forma canonica? Chi lo sa sicuramente, se ci entri?

> [!question]- Indizio 4
> `*` non prende i file col punto. Conosci già un comando che scende in una cartella, sa da che profondità partire e sa cancellare? In alternativa, quale opzione di shell cambia il glob?

**Dopo.** `set -e` copre tutti i casi? Prova `false | true`, poi `if false; then ...`, poi `locale=$(false)` dichiarato con `local` in una funzione. Cosa aggiunge `pipefail`? Perché qualcuno sconsiglia di fidarsi solo di `set -e`?

---

## Problema 2 — `chiavi.sh`

**Situazione.** In `dati/consumi.txt` ci sono i megabyte usati da ogni servizio. Vuoi interrogarlo con le opzioni a cui sei abituato, compresa la forma compatta `-an2` di `ls -la` e `tar -xzf`.

> [!info] Il contesto
> **Lo scenario.** Uno script nato per te finisce nelle mani dei colleghi, che si aspettano di usarlo come tutti gli altri comandi, con le opzioni nel modo solito.
> - **Opzione** (latino *optio*, «scelta»): un argomento che inizia con `-` e cambia il comportamento del comando, come `-l` di `ls`.
> - **Forma compatta**: più opzioni brevi unite dietro un solo trattino. È una convenzione che risale ai primi Unix ed è fissata nello standard POSIX.
>
> **Perché conta.** Uno script che non segue le convenzioni costringe chi lo usa a ricordarne le regole. Chi sbaglia un'opzione senza ricevere un messaggio chiaro prende un risultato sbagliato per buono.

**Compito.** `./chiavi.sh [-a] [-n N] [-x TESTO] FILE` stampa, una per riga, le `N` chiavi col valore più basso.

| Opzione | Effetto |
|---|---|
| `-a` | Parte dai valori più alti |
| `-n N` | Quante, predefinito 1 |
| `-x TESTO` | Ignora le righe che contengono `TESTO` |
| `--` | Finisce le opzioni |

Opzione sconosciuta, `N` non numerico o file assente dagli argomenti: uso su stderr e codice 2. File inesistente: codice 1.

**Verifica.** `../../verifica.sh 06 2`

> [!question]- Indizio 1
> Scrivere a mano un `case` su `$1` non regge `-an2`. Esiste un comando interno pensato per questo: come si chiama? Prova `help` seguito dal nome, una volta scoperto: `help -d` su qualche candidato, o `man bash` cercando *optstring*.

> [!question]- Indizio 2
> Dopo aver letto le opzioni, `$1` è ancora la prima opzione. Quale variabile dice a che punto sei arrivato, e con quale comando butti ciò che hai già letto?

> [!question]- Indizio 3
> `-a` cambia un'opzione di `sort`. Come costruisci una riga di comando con parti opzionali senza rompere le virgolette? Cosa offre un array?

**Dopo.** Cosa cambia se metti `:` all'inizio della stringa delle opzioni? `getopts` gestisce `--help`? Quando serve `getopt` esterno, e perché ha una cattiva fama?

---

## Problema 3 — `mycd.sh`

**Situazione.** Lavori fra `/srv/prod/app` e `/srv/dev/app`. Vuoi un comando che ti sposti da uno all'altro cambiando solo un pezzo del percorso. Prova a farlo con uno script normale, e guarda dove ti trovi dopo averlo lanciato.

> [!info] Il contesto
> **Lo scenario.** Sullo stesso server convivono due copie dell'applicazione, quella vera e quella di prova, in alberi di cartelle identici. Ci si passa da una all'altra decine di volte al giorno.
> - **`/srv`** (da *service*, «servizio»): la cartella che lo standard sulle cartelle di Linux, l'FHS, riserva ai dati dei servizi offerti dalla macchina.
> - **`prod` e `dev`**: produzione, cioè l'ambiente vero, e sviluppo (*development*), quello in cui si lavora alle modifiche.
>
> **Perché conta.** Scrivere ogni volta il percorso lungo porta prima o poi a modificare la produzione credendo di essere in sviluppo. Un comando che cambia solo il pezzo giusto riduce l'errore.

**Compito.** Il file `mycd.sh` definisce una funzione `mycd`. Lo si usa così: `source mycd.sh`, poi `mycd`.

| Chiamata | Comportamento |
|---|---|
| `mycd` | Va nella home |
| `mycd DIR` | Va in `DIR` |
| `mycd VECCHIO NUOVO` | Sostituisce il testo `VECCHIO` con `NUOVO` nel percorso corrente e ci va |
| Più di 2 argomenti | Codice 2 |

Se riesce stampa `da: <prima>` e `a: <dopo>`. Se fallisce non si sposta, stampa l'errore su stderr e restituisce un codice diverso da 0. Il file va reso eseguibile per il correttore, anche se poi si carica con `source`.

**Verifica.** `../../verifica.sh 06 3`

> [!question]- Indizio 1
> Uno script gira in un processo figlio. Il figlio può cambiare la cartella corrente del padre? Dove viene conservata quella cartella? Perché `cd` è un comando interno della shell?

> [!question]- Indizio 2
> In una funzione, cosa significano `$1` e `$#`? Differenza fra `exit` e `return`: cosa accadrebbe alla tua shell con `exit`?

> [!question]- Indizio 3
> Hai già visto una forma di sostituzione dentro le variabili. Cerca in *Parameter Expansion* quella con le barre.

**Dopo.** Se chiamassi la funzione `cd` invece di `mycd`, cosa userebbe al suo interno, e perché ricorsione infinita? Quale parola la evita? Perché le variabili di una funzione vanno dichiarate `local`?

---

## Problema 4 — `lib-log.sh`

**Situazione.** Da qui in poi gli script parleranno sui log. Copiare le stesse funzioni ovunque è un errore: te ne fai una libreria.

> [!info] Il contesto
> **Lo scenario.** Quando uno script gira di notte nessuno lo guarda. Il mattino dopo, l'unica cosa che racconta cosa è successo sono i messaggi che ha lasciato.
> - **Log**: il diario degli eventi di un programma, una riga per evento, con ora e gravità.
> - **Libreria**: un file di funzioni che gli script caricano invece di ricopiarle. Si corregge un errore una volta e vale per tutti.
> - **Livello** (`INFO`, `ERRORE`…): la gravità di un messaggio, che permette di tacere quelli poco importanti.
>
> **Perché conta.** Messaggi scritti in modi diversi in ogni script non si possono cercare insieme. E se i messaggi si perdono, il mattino dopo nessuno sa cosa è successo.

**Compito.** Il file, caricato con `source`, definisce:

| Funzione | Comportamento |
|---|---|
| `log_info MESSAGGIO...` | Scrive `2026-11-03T10:00:00 INFO messaggio` |
| `log_errore MESSAGGIO...` | Scrive `2026-11-03T10:00:00 ERRORE messaggio` |
| `muori CODICE MESSAGGIO...` | Registra l'errore ed esce dallo script con `CODICE` |

- Tutto va su stderr, mai su stdout. Perché? Rispondi prima di scrivere.
- Se `LOG_FILE` è impostata, la riga va anche in quel file, in aggiunta.
- Se `LOG_LIVELLO=ERRORE`, `log_info` tace.
- Caricarla non stampa nulla e non cambia le opzioni della shell di chi la carica.

**Verifica.** `../../verifica.sh 06 4`

> [!question]- Indizio 1
> Immagina `risultato=$(mio_script)`. Se il log finisse su stdout, cosa conterrebbe `risultato`?

> [!question]- Indizio 2
> `LOG_FILE` può non esistere se chi carica la libreria usa `set -u`. Come si legge una variabile forse assente senza errore? Il quiz del manuale ne mostra un parente.

**Dopo.** Il tuo `log_info` come esce quando il livello lo nasconde? Se scrivi l'ultima riga con `[[ ... ]] && ...` e il test è falso, cosa vede uno script con `set -e`? Prova.

---

## Problema 5 — `rilascia.sh`

**Situazione.** `getopts` capisce solo opzioni di una lettera. Gli script veri accettano anche `--prova`, `--ambiente prod` e `--ambiente=prod`, come `tar`, `rsync` e `curl`. Lo schema per farlo a mano è sempre lo stesso, e conviene saperlo scrivere a occhi chiusi.

> [!info] Il contesto
> **Lo scenario.** Un rilascio porta una versione nuova di un'applicazione su un ambiente. Lo script che lo fa lo usano in tanti, e deve capire opzioni scritte come le scrive ognuno.
> - **Rilascio** (in inglese *release*): la consegna di una versione nuova in un ambiente, come la produzione.
> - **Opzioni lunghe**: opzioni con due trattini e un nome intero, come `--ambiente`. Le ha introdotte il progetto GNU, perché si leggono senza aprire il manuale.
> - **Prova** (in inglese *dry run*): fare tutto tranne il passo vero, per vedere cosa succederebbe. **Verboso** (latino *verbosus*, «ricco di parole»): che racconta di più.
>
> **Perché conta.** Uno script di rilascio che fraintende un'opzione rilascia nell'ambiente sbagliato. Per questo, davanti a un dubbio, deve fermarsi invece di indovinare.

**Compito.** `./rilascia.sh [OPZIONI] [--] VERSIONE` non rilascia nulla: stampa la configurazione che ha capito.

| Opzione | Effetto | Predefinito |
|---|---|---|
| `-n`, `--prova` | Prova a secco | `no` |
| `-v`, `--verboso` | Più dettagli; si può ripetere: `-vv` vale 2 | `0` |
| `-e AMB`, `--ambiente AMB`, `--ambiente=AMB` | `prod`, `staging` o `test` | `staging` |
| `-h`, `--help` | Stampa l'uso su stdout ed esce con 0 | |

```text
$ ./rilascia.sh -nv --ambiente=prod -v 1.2.3
ambiente: prod
prova: si
verboso: 2
versione: 1.2.3
```

- Le opzioni brevi si possono unire (`-nv`, `-vv`); `-e` vuole un valore, anche attaccato (`-eprod`).
- `--` chiude le opzioni: dopo, anche `-strana` è una versione.
- Opzione sconosciuta, valore mancante o non ammesso, nessuna versione o più di una: messaggio su stderr e codice 2.

**Verifica.** `../../verifica.sh 06 5`

> [!question]- Indizio 1
> Il ciclo classico è `while (( $# )); do case $1 in ... esac; shift; done`. Cosa fa ogni ramo, e quando esci dal ciclo?

> [!question]- Indizio 2
> `-nv` è un argomento solo. Come lo trasformi in `-n -v` e lo rimetti in testa alla lista degli argomenti? `set --` riscrive i parametri posizionali.

> [!question]- Indizio 3
> `--ambiente=prod` e `--ambiente prod`: in un caso il valore è nello stesso argomento, nell'altro nel successivo. Quale *Parameter Expansion* separa la parte dopo l'`=`?

**Dopo.** Cosa fa `getopt` (senza la `s`) di `util-linux`, e perché quello di altri sistemi non gestisce le opzioni lunghe? Come mostra `git` l'aiuto, e cosa si aspetta un utente da `--help`?

---

## Diario

Domande numerate, risposte e correzioni di questa lezione.

## Sintesi

Da scrivere a lezione finita, con le tue parole.

---

← [[05-sed-awk|Lezione 05]] · ↑ [[00-percorso|Il percorso]] · → [[18-redirezioni|Lezione 18]]
