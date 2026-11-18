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
| 0 | Previsioni — carta e penna, poi la prova | ✅ |
| 1 | `crea-struttura.sh` — cento cartelle con una riga | ✅ |
| 2 | `tabella.sh` — un rapporto che si legge | ✅ |
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
> **Lo scenario.** Un sito con molte visite non gira su un solo computer: più copie identiche dell'applicazione si dividono il lavoro. Un *bilanciatore di carico* smista le richieste fra loro: se una macchina si guasta, le altre reggono. Prima del rilascio, chi gestisce le macchine deve preparare su ognuna la stessa struttura di cartelle.
> - **Nodo** (latino *nodus*, il nodo di una rete): ciascuna macchina che fa girare una copia dell'applicazione. `web01`, `web02`… sono i loro nomi.
> - **Produzione** (`prod`): l'ambiente che usano i clienti veri. **Collaudo**, in inglese **staging** (*stage*, il palcoscenico dove si allestisce lo spettacolo prima del debutto), è la sua copia in cui si prova un rilascio prima di farlo sul serio.
> - **`bin`, `conf`, `log`**: i programmi eseguibili (*binaries*), la configurazione e i diari degli eventi, dal *logbook*, il giornale di bordo delle navi.
>
> **Perché conta.** Fatte a mano, cento cartelle hanno sempre un refuso. Se a `web07` manca `log`, l'applicazione si ferma al primo avvio, magari di notte. Per questo la struttura si genera con uno script, che fa sempre la stessa cosa.

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

### Problema 1 — `crea-struttura.sh`

`verifica.sh 13 1`: 17 su 17. Versioni scritte: `eval` con le graffe; `for` su `seq` + `printf -v`; `for` su `seq -f '%02g'`; `for (( ; ; ))`; `while (( ))` con incremento; `while` con `declare -i` e `n+=1`. Gli array sono rimandati alla lezione 16.

Errori e ciò che li ha fatti capire:

- Condizione `<` invece di `<=`: con `N=3` mancava `web03`. L'ha mostrato la previsione delle cartelle create.
- `n+=1` dava `11`: fuori da `(( ))` `+=` accoda una stringa; somma solo nel contesto aritmetico o con `declare -i`.
- `++n` da solo: «comando non trovato». `++` esiste solo nei contesti aritmetici; una riga senza `=` è un comando semplice.
- `$(( ++n ))` da solo: «2: comando non trovato». L'espansione lascia il testo `2`, che diventa il nome del comando; `(( ))` invece non lascia testo.
- `n= $(( n + 1 ))`: lo spazio dopo `=` rende `n=` un'assegnazione temporanea per il comando `2`.
- `while` non accetta le tre parti del `for (( ; ; ))`: è una sintassi solo di `for`.
- `xargs` senza opzioni raggruppa più argomenti in un solo comando; `-I` (non `-i`, deprecato) lo lancia una volta per riga. Le graffe le espande la shell prima che `xargs` parta.
- `xargs a=( ... )`: un'assegnazione è sintassi della shell, riconosciuta solo all'inizio del comando.

> **D1.** Cosa riceve la shell dopo l'espansione di `$(( ++n ))` su una riga da sola?
> **R.** Il numero, per esempio `2`, che viene eseguito come nome di comando. ✅

> **D2.** Chi espande le graffe in `seq ... | xargs -I X mkdir -p "$1"/{prod,staging}/webX/{bin,conf,log}`?
> **R.** La shell, prima di avviare `xargs`, che riceve 6 percorsi con la `X`. ✅

> **D3.** Cosa diventa `$argms[]` su un array?
> **R.** Il primo elemento seguito da `[]` letterale: senza graffe le quadre non fanno parte del riferimento. ✅

> **D4.** Cosa stampa `printf '[%s]\n' x/web"${a[@]}"/bin` con `a=(01 02 03)`?
> **R.** `[x/web01] [02] [03/bin]`: il testo attaccato si unisce solo al primo e all'ultimo elemento. ✅

> **D5.** Con `N=99`, quante cartelle foglia crea lo script, e quanti argomenti riceverebbe un solo `mkdir`?
> **R.** 2 × 99 × 3 = 594 cartelle, quindi 594 percorsi (595 argomenti con `-p`). ✅

> **D6.** Esiste un limite alla lunghezza degli argomenti? I 594 percorsi ci stanno?
> **R.** `getconf ARG_MAX` sulla VM: 2097152 byte (2 MiB). Ci stanno abbondantemente: circa 30 byte a percorso, quindi circa 18 KB. Il limite comprende anche l'ambiente; oltre, `execve` fallisce con *Argument list too long* (`E2BIG`), ed è il problema che `xargs` risolve. ✅

> **D7.** Cosa fa `mkdir -p` su una cartella che esiste già, e su un file con quel nome?
> **R.** Sulla cartella non fa niente ed esce con 0: per questo lo script si può rilanciare (idempotenza). Su un file fallisce (*File exists*), e dentro un file non si creano sottocartelle (*Not a directory*). ✅

### Problema 2 — `tabella.sh`

Errori e ciò che li ha fatti capire:

- Filtro «righe che contengono `;`»: il commento in testa al file contiene `;`. L'ha mostrato `cat -A dati/spazio.txt`.
- Filtro «contiene `#`»: scarterebbe una home come `/home/luca#vecchia`; il `#` conta solo come primo carattere.
- Il `$` di `cat -A` non è nel file: `od -c` mostra che una riga vuota è solo `\n`.
- `tr ';' ' ' | xargs printf`: lo spazio in `/home/utente prova` diventa un separatore, `printf` riceve cinque argomenti.
- `read -d` cambia il terminatore della riga, non il separatore dei campi.
- `tr ' ' '_'` per proteggere lo spazio: la home esce `/home/utente_prova`, il rapporto altera il dato.
- `while read -d ';'` perde l'ultimo pezzo: `w\n` finisce con EOF, `read` lo legge ma esce con 1 e il ciclo si ferma.
- `IFS=;` nella cronologia: il `;` non citato è un separatore di comandi, quindi `IFS` diventa vuoto per tutta la sessione. `printf '%q' "$IFS"` non distingue vuoto da non impostato; `declare -p IFS` e `${IFS+impostata}` sì.
- `IFS=';' | echo $IFS` non cambia nulla: ogni pezzo della pipeline è una subshell.
- Variabili non citate in `printf`: la home con lo spazio diventa due argomenti, le colonne slittano.
- `%s` sulla quota stampa `85` invece di `85.0`; `%7.1f%%` occupa 8 caratteri, ne servono 7: `%6.1f%%`.
- `\%` non è una sequenza di `printf`; il `%` letterale è `%%`. Il flag `#` non vale per `%d`.
- `printf '%.1f' 85.5` dà «numero non valido» e `85,0`: con `LC_NUMERIC=it_IT.UTF-8` il separatore dei decimali è la virgola.

> **D4.** Che differenza c'è fra `X=ciao comando` e `X=ciao; comando`?
> **R.** La prima è un'assegnazione temporanea: il comando la vede, la shell dopo non ce l'ha. La seconda resta nella shell, ma un processo figlio non la vede senza `export`. ✅ (la seconda metà al secondo tentativo)

> **D5.** Come si fa valere `IFS=';'` solo per `read`?
> **R.** Con l'assegnazione temporanea davanti al comando, nel `while`. ✅

> **D6.** Quale locale garantisce il punto decimale, e come lo si applica solo a `printf`?
> **R.** `C` (sinonimo `POSIX`), con `LC_NUMERIC=C` come assegnazione temporanea. ✅

> **D1.** Le regole «contiene `;`» e «non inizia con `#`» scelgono le stesse righe?
> **R.** No: un commento può contenere `;`. Va filtrato il `#` iniziale. ✅

> **D2.** Com'è fatta in byte una riga vuota?
> **R.** È solo `\n`; il `$` lo disegna `cat -A`. In regex è `^$`. ✅

> **D3.** Quali valori non escono come sono nel file?
> **R.** Il nome lungo va tagliato a 12, la quota va con un decimale (`85` → `85.0`), il `%` va aggiunto. ✅ (il decimale trovato al secondo tentativo)

- Pipeline `tr ' ' '_' | tr ';' ' ' | while read n; ... printf ... $n`: la home esce `/home/utente_prova`. Proteggere lo spazio cambiando il dato altera il rapporto.
- `while read -d ';'` perdeva l'ultimo campo `w`: dopo non c'è `;` ma EOF, `read` riempie la variabile ma esce con 1, e `while` non esegue il corpo.
- `IFS=;` (cronologia, riga 1034) aveva svuotato `IFS` per tutta la sessione: il `;` senza virgolette chiude il comando. `IFS=';' | echo $IFS` invece non cambia nulla, perché la pipeline gira in subshell.
- Previsione sbagliata: `X=ciao; bash -c 'echo $X'` non stampa `ciao`, perché senza `export` il figlio non vede la variabile.

> **D4.** Cosa decide dove finisce un campo per `read`, e cosa fa `-d`?
> **R.** `IFS` separa i campi della riga letta; `-d` cambia il terminatore della riga; `-n` limita i caratteri letti in tutto. ✅

> **D5.** Cosa stampano `X=ciao bash -c 'echo "[$X]"'; echo "[$X]"` e la stessa con `X=ciao;`?
> **R.** Prima: dentro `ciao`, fuori vuoto. Seconda: dentro vuoto, fuori `ciao`. ✅ la prima, ❌ poi ✅ la seconda (serve `export`).

> **D6.** Perché `X=pino echo $X` stampa vuoto?
> **R.** `$X` lo espande la shell corrente prima di eseguire, e lì `X` non c'è; l'assegnazione vale solo per l'ambiente di `echo`. ✅ (spiegata)

Studiato: la sintassi del comando semplice e l'assegnazione temporanea prima di un comando, in [[variabili-opzioni|Variabili e opzioni della shell]].

- Nome non tagliato: la larghezza di `%-12s` è un minimo; il taglio lo fa la precisione, `%-12.12s`.
- `read utente HOME ...`: sovrascrive la variabile d'ambiente, e dentro il ciclo `~` diventa `/home/anna`. Le variabili dello script vanno in minuscolo.
- `grep | while` con la somma: dentro il ciclo `totale` cresce, fuori resta 0, perché il `while` in pipeline è una subshell. L'ha mostrato un `echo` dentro e uno fuori.
- `done <($linee)`: `<( )` vuole un comando, non un testo, e diventa un nome di file (`/dev/fd/63`), quindi va preceduto da `<`. Per dare il contenuto di una variabile serve la here-string `<<<`.
- Riga `TOTALE` spostata di una colonna: `%-32s` più lo spazio fanno 33 caratteri, ma prima dei MB ce ne sono 34 (12 + 1 + 20 + 1). Soluzione chiesta e data: `%-33s %9s`.

> **D7.** Perché la somma fatta in `grep | while` fuori dal ciclo vale 0?
> **R.** Ogni pezzo della pipeline gira in una subshell: la copia di `totale` muore con lei. ✅

> **D8.** Perché `~` dentro il ciclo diventava `/home/anna`?
> **R.** La tilde si espande a `$HOME`, e `read` aveva sovrascritto `HOME`. ✅

`verifica.sh 13 2`: 4 su 4 (18 novembre).

- File mancante: `grep` falliva, ma intestazione e `TOTALE` uscivano lo stesso, con codice 0. `$?` è il codice dell'ultimo comando, il `printf` del totale.
- `set -e` non vede il `grep` fallito: sta in una `$( )` dentro una redirezione `<<<`. E comunque l'intestazione era già stampata: il controllo va fatto prima.
- `[ -f "$2" ]`: distrazione, falliva anche con il file giusto. L'ha mostrato la prova sul caso buono.
- `-r` lascia passare una cartella: per Unix anche la cartella è un file, e leggibile. `-f` vuole un *regular file* (tipo `-` in `ls -l`).
- `[ -rf f ]`: «atteso operatore unario». Le prove di `test` non si accorpano come le opzioni di `ls`.
- `[ -r f ] && [ -f f ]` con `set -e`: con `nonce.txt` lo script andava avanti. `set -e` ignora i fallimenti nelle liste `&&`/`||` tranne l'ultimo comando. L'ha mostrato `man bash`, paragrafo di `errexit`.
- `! [ -r f ] && [ -f f ]`: il `!` vale solo per il primo comando. Serve raggruppare, `! ( … )` o `! { …; }`.
- `{ … }` senza `;` prima di `}`: errore di sintassi, visto con `bash -n`.
- Messaggio «non esiste» anche per una cartella, che esiste: il messaggio deve dire il vero a chi lo legge.
- Shellcheck: SC2162, `read` senza `-r` mangia i `\`; SC2046, `$( )` non citato. Dopo `<<<` bash non spezza in parole, ma le virgolette restano la buona abitudine.

> **D9.** Perché `set -e` non ferma `[ -r f ] && [ -f f ]` quando fallisce il primo?
> **R.** In una lista `&&`/`||` un fallimento può essere voluto, è una decisione: `set -e` considera solo l'ultimo comando. Lo stesso vale per le condizioni di `if`/`while`, i comandi con `!`, le pipeline tranne l'ultimo pezzo e le funzioni chiamate in un contesto condizionale. ✅

> **D10.** Perché il messaggio d'errore va sullo stderr?
> **R.** La pipe e `>` prendono solo lo stdout: i dati vanno avanti, il messaggio resta sul terminale per la persona. ✅

> **D11.** Cosa stampa `LC_NUMERIC=it_IT.UTF-8 printf '%.1f\n' 12.5`, e perché?
> **R.** «numero non valido» e `12,0`: il locale vale anche per l'input, `strtod` si ferma al punto e legge `12`. ❌ (prevista solo la virgola) → spiegata.

> **D12.** Da cosa dipende il separatore decimale se lo script non lo fissa?
> **R.** Dall'ambiente di chi lo lancia: `LC_ALL`, poi `LC_NUMERIC`, poi `LANG`, se no `C`. Arrivano da sistema, utente, ssh (`SendEnv`/`AcceptEnv`); cron non ne ha. Lo script fissa da sé ciò da cui dipende. ❓ → spiegata.

> **D13.** Perché `niccolò` sfasa le colonne?
> **R.** `printf` conta byte, non caratteri: `ò` in UTF-8 sono due byte, `%-12s` mette uno spazio in meno, e `%.12s` può spezzare un carattere. `${#var}` conta i caratteri. ❓ → spiegata.

Da riprendere: la riga `0.0%` con un file vuoto; la versione senza `grep`, con il filtro dentro il ciclo e la redirezione dal file.

## Sintesi

Da scrivere a lezione finita, con le tue parole.

---

← [[01-primo-script|Lezione 01]] · ↑ [[00-percorso|Il percorso]] · → [[02-decisioni|Lezione 02]]
