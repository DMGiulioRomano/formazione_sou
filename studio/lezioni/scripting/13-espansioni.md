---
tags:
  - lezione
  - scripting
aliases:
  - Scripting 13 — Espansioni e virgolette
---
# Scripting 13 — Espansioni e virgolette

Prima di eseguire una riga, la shell la riscrive: allarga graffe, tilde, variabili, comandi e asterischi, poi la spezza in parole e toglie le virgolette. Chi conosce l'ordine di questi passaggi prevede cosa riceve un comando; chi non lo conosce va per tentativi. Si fa dopo la lezione 01. Riferimento: [[variabili-opzioni|Variabili e opzioni della shell]].

```sh
./prepara.sh 13 && cd palestra/l13
```

## La mappa

| # | Problema | Stato |
|---|---|---|
| 0 | Previsioni — carta e penna, poi la prova | — |
| 1 | `crea-struttura.sh` — cento cartelle con una riga | — |
| 2 | `tabella.sh` — un rapporto che si legge | — |
| 3 | `riesegui.sh` — un registro da cui rilanciare | — |

---

## Problema 0 — Previsioni

**Situazione.** Ogni volta che una riga fa una cosa diversa da quella che pensavi, il modello mentale ha un buco. Meglio trovarlo qui che su un server.

> [!info] Il contesto
> **Lo scenario.** Su un server si lavora quasi sempre a distanza, senza interfaccia grafica, spesso con i poteri dell'amministratore: si scrive una riga, si preme Invio e la riga agisce su file veri.
> - **Server** (inglese *to serve*, «servire»): il computer che offre un servizio ad altri computer, come un sito o un database.
> - **Modello mentale**: l'idea che hai in testa di come la shell legge una riga. Se è giusta, prevedi cosa riceve ogni comando.
>
> **Perché conta.** Un nome con uno spazio o un asterisco interpretati in modo diverso da come pensavi possono far toccare a un comando i file sbagliati, e su un server non c'è il tasto «annulla».

**Compito.** Lavora in `palestra/l13/dati/vetrina`, che contiene tre file. Per ogni riga scrivi **prima** cosa stampa e perché, poi lanciala. Dove sbagli, il modello va corretto prima di proseguire.

```sh
echo {a,b}{1,2}
echo {1..10..3} {e..a}
echo {01..10}
n=3; echo {1..$n}
x='{1..3}'; echo $x
echo ~ ~root ~nessuno
v='~'; echo $v
a='*'; echo "$a"; echo $a
echo '$HOME' "$HOME" \$HOME
echo $'a\tb' 'a\tb' "a\tb"
printf '%s\n' "a b" c
printf '%s-%s\n' 1 2 3
printf '%5s|%-5s|%05d\n' ab ab 42
set -- "a b" c; printf '[%s]' $@; echo; printf '[%s]' "$@"; echo; printf '[%s]' "$*"; echo
echo "data: $(date +%Y) e $((2 + 3)) e ${HOME##*/}"
f='file con spazi.txt'; ls $f; ls "$f"
```

**Verifica.** Si controlla a mano, con Claude: spiega ogni errore di previsione.

**Dopo.** In quale ordine avvengono le sette espansioni del manuale (sezione *EXPANSION*)? Perché la riga 4 non funziona e la 5 nemmeno? Quali espansioni avvengono anche fra virgolette doppie e quali no? Perché `echo -e` e `echo -n` sono una cattiva idea in uno script che deve girare anche sotto `sh`?

---

## Problema 1 — `crea-struttura.sh`

**Situazione.** Un'applicazione gira su più nodi, in produzione e in collaudo. Ogni nodo vuole le sue cartelle `bin`, `conf` e `log`. Crearle a mano significa sbagliarne una, e accorgersene al primo avvio.

> [!info] Il contesto
> **Lo scenario.** Un sito con molte visite non gira su un solo computer: più copie identiche dell'applicazione si dividono il lavoro. Prima del rilascio, chi gestisce le macchine deve preparare su ognuna la stessa struttura di cartelle.
> - **Nodo** (latino *nodus*, il nodo di una rete): ciascuna macchina che fa girare una copia dell'applicazione. `web01`, `web02`… sono i loro nomi.
> - **Produzione**: l'ambiente che usano i clienti veri. **Collaudo**, in inglese **staging** (*stage*, il palcoscenico dove si allestisce lo spettacolo prima del debutto), è la sua copia in cui si prova un rilascio prima di farlo sul serio.
> - **`bin`, `conf`, `log`**: i programmi eseguibili (*binaries*), la configurazione e i diari degli eventi, dal *logbook*, il giornale di bordo delle navi.
>
> **Perché conta.** Fatte a mano, cento cartelle hanno sempre un refuso. Se a `web07` manca `log`, l'applicazione si ferma al primo avvio, magari di notte.

**Compito.** `./crea-struttura.sh RADICE N` crea, per `AMBIENTE` in `prod` e `staging` e per ogni nodo da `web01` a `webN` (sempre con due cifre):

```text
RADICE/AMBIENTE/webNN/bin
RADICE/AMBIENTE/webNN/conf
RADICE/AMBIENTE/webNN/log
```

- `N` va da 1 a 99, altrimenti codice 2. Anche un numero di argomenti sbagliato dà 2.
- Rilanciato, non dà errori e non cambia nulla.
- `RADICE` può contenere spazi.
- Non stampa nulla e, se tutto va bene, esce con 0.

**Verifica.** `../../verifica.sh 13 1`

> [!question]- Indizio 1
> Prova la riga 3 del problema 0. Quante cartelle servono con `N=12`? Riesci a scrivere tutta la struttura con un solo `mkdir`, per un `N` fisso?

> [!question]- Indizio 2
> Ora metti `N` in una variabile. Cosa è successo? Rileggi in che ordine vengono le espansioni: quando si allargano le graffe, la variabile ha già un valore?

> [!question]- Indizio 3
> Se le graffe non possono contare fino a un valore che conosci solo durante l'esecuzione, chi sa farlo? Ti servono anche gli zeri davanti: quale comando interno formatta un numero con una larghezza fissa?

**Dopo.** Quante cartelle crea `mkdir` con `N=99`, e quanti argomenti riceve in tutto se scrivi tutto in una riga? Esiste un limite alla lunghezza di una riga di comando? Cerca `getconf ARG_MAX`. Cosa fa `mkdir -p` su una cartella che c'è già, e su un *file* con quel nome?

---

## Problema 2 — `tabella.sh`

**Situazione.** Il responsabile vuole sapere chi occupa spazio nelle home. Gli mandi un rapporto: se le colonne non sono allineate, non lo legge.

> [!info] Il contesto
> **Lo scenario.** Le cartelle personali degli utenti stanno di solito sullo stesso disco. Quando si riempie, il responsabile chiede chi occupa spazio, e il rapporto gli arriva per posta o in una chat.
> - **Home** (inglese, «casa»): la cartella personale di ogni utente, di solito `/home/nome`.
> - **Quota** (latino *quota pars*, «quale parte»): lo spazio massimo che un utente può occupare. Qui è la percentuale di quel limite già usata.
> - **Megabyte** (greco *mégas*, «grande»): circa un milione di byte, l'unità in cui il rapporto misura lo spazio.
>
> **Perché conta.** Un rapporto con le colonne sfalsate si legge male e porta a decisioni sbagliate, come scrivere all'utente sbagliato.

**Compito.** `./tabella.sh FILE`, dove ogni riga di `FILE` è `utente;home;megabyte;quota`, e la quota è una percentuale che può avere decimali. Righe vuote e righe che iniziano con `#` si ignorano. Per `dati/spazio.txt` stampa esattamente:

```text
UTENTE       HOME                        MB   QUOTA
anna         /home/anna                 512   12.5%
mario        /home/mario              20480   85.0%
utentelungon /home/utente prova           7    0.3%
TOTALE                                20999
```

| Colonna | Larghezza | Allineamento |
|---|---|---|
| Utente | 12 caratteri; i nomi più lunghi si tagliano | Sinistra |
| Home | 20 caratteri | Sinistra |
| Megabyte | 9 caratteri, preceduti da uno spazio | Destra |
| Quota | 7 caratteri, preceduti da uno spazio, un decimale e `%` | Destra |

Le colonne sono separate da uno spazio. La riga `TOTALE` somma i megabyte e non ha la quota. File mancante: codice 1.

**Verifica.** `../../verifica.sh 13 2`

> [!question]- Indizio 1
> Con `echo` e le tabulazioni le colonne si allineano? Prova con due nomi di lunghezza molto diversa.

> [!question]- Indizio 2
> `help printf`, poi `man 3 printf`: cosa sono *larghezza* e *precisione* in `%-12s`? Cosa fa la precisione applicata a una stringa?

> [!question]- Indizio 3
> La home di `utentelungon` contiene uno spazio. Cosa riceve `printf` se la variabile non è fra virgolette?

**Dopo.** Prova `LC_NUMERIC=it_IT.UTF-8 printf '%.1f\n' 12.5`: cosa succede, e perché? Cosa significa per uno script che gira sotto un altro utente? Il tuo script allinea bene un nome come `niccolò`? Cosa conta `printf`: caratteri o byte?

---

## Problema 3 — `riesegui.sh`

**Situazione.** Durante un intervento lanci decine di comandi. Il giorno dopo ti chiedono cosa hai fatto, e vuoi poter rilanciare esattamente lo stesso comando, anche se aveva argomenti con spazi, virgolette o `$`.

> [!info] Il contesto
> **Lo scenario.** Un guasto o una manutenzione si risolvono con decine di comandi lanciati in fretta. Il giorno dopo il responsabile, o un collega del turno successivo, chiede cosa è stato fatto, e spesso bisogna rifare la stessa operazione su un'altra macchina.
> - **Intervento**: il lavoro fatto su un sistema in un certo momento, spesso in una finestra di tempo concordata.
> - **Registro**, in inglese **log**: il file in cui si annota, riga dopo riga, cosa è successo e quando.
>
> **Perché conta.** Ricostruire a memoria un comando con spazi, virgolette o `$` produce quasi sempre un comando diverso. Rilanciato, fa un'altra cosa, e lo fa con la sicurezza di chi crede di ripetere.

**Compito.** `./riesegui.sh COMANDO [ARG...]` esegue il comando, poi aggiunge una riga al file indicato da `REGISTRO` (predefinito `~/.riesegui.log`):

```text
2026-11-03T10:00:00 0 COMANDO ARGOMENTI
```

- Data e ora nel formato `AAAA-MM-GGTHH:MM:SS`, poi il codice di uscita del comando, poi il comando.
- La parte del comando, incollata in una shell, deve ricreare **esattamente** gli stessi argomenti, anche vuoti, con spazi, virgolette, `$`, `*` o un a capo, ma sempre su una sola riga.
- L'output del comando passa inalterato e lo script esce con il codice del comando.
- Senza argomenti: codice 2.

**Verifica.** `../../verifica.sh 13 3`

> [!question]- Indizio 1
> Prova a registrare `"$*"` e poi a rilanciare la riga per `./riesegui.sh printf '%s\n' "a b"`. Quanti argomenti riceve `printf` la seconda volta?

> [!question]- Indizio 2
> Ti serve trasformare ogni argomento in un testo che la shell rilegga come l'originale. `help printf`: c'è un formato che fa proprio questo? In *Parameter Expansion* cerca le trasformazioni con `@`.

> [!question]- Indizio 3
> Il codice di uscita lo leggi dopo il comando, ma prima di scrivere la riga devi chiamare `date`. In che ordine fai le cose?

**Dopo.** Perché un registro così è anche un rischio? Pensa a `mysql -p segreta`. Dove salva bash la sua cronologia, e quando la scrive? Cosa fanno `HISTTIMEFORMAT` e `HISTCONTROL=ignorespace`?

---

## Diario

Domande numerate, risposte e correzioni di questa lezione.

## Sintesi

Da scrivere a lezione finita, con le tue parole.

---

← [[01-primo-script|Lezione 01]] · ↑ [[00-percorso|Il percorso]] · → [[02-decisioni|Lezione 02]]
