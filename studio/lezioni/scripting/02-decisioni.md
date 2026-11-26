---
tags:
  - lezione
  - scripting
aliases:
  - Scripting 02 — Decidere
---
# Scripting 02 — Decidere

Uno script che non decide è solo una lista di comandi. In shell ogni decisione si basa su una cosa sola: il codice di uscita di un comando.

```sh
./prepara.sh 02 && cd palestra/l02
```

## La mappa

| # | Problema | Stato |
|---|---|---|
| 0 | Previsioni — i test che sembrano giusti | ✅ |
| 1 | `utente-esiste.sh` — una domanda con risposta sì o no | ✅ |
| 2 | `soglia-disco.sh` — l'allarme del disco pieno | ⏳ |
| 3 | `estrai.sh` — scegliere in base al nome | — |

---

## Problema 0 — Previsioni

**Situazione.** Un `if` sbagliato non dà quasi mai errore: prende la strada sbagliata in silenzio.

> [!info] Il contesto
> **Lo scenario.** Gli script di manutenzione decidono da soli: cancellare o no, avvisare o no, procedere o fermarsi. Nessuno li guarda mentre lo fanno.
> - **Condizione**: la domanda da cui dipende la scelta. In shell la risposta è sempre «riuscito» o «non riuscito».
> - **Ramo** (in inglese *branch*): ciascuna delle strade che lo script può prendere dopo la domanda.
>
> **Perché conta.** Una condizione scritta male non dà errori: fa prendere sempre la stessa strada. Lo scopri quando la pulizia ha cancellato ciò che doveva tenere.

**Compito.** Per ogni riga scrivi **prima** cosa stampa e perché, poi lanciala. `vuota` non è mai stata assegnata.

```sh
x=; [ $x = ciao ] && echo si
x=; [ "$x" = ciao ] || echo no
[ -n $vuota ] && echo pieno
[ -n "$vuota" ] || echo vuoto
[ 10 -lt 9 ]; echo $?
[ 10 \< 9 ]; echo $?
[[ 10 < 9 ]]; echo $?
[ 010 -eq 8 ]; echo $?
(( 010 == 8 )); echo $?
f=mario.txt; [[ $f == *.txt ]] && echo testo
p='*.txt'; [[ $f == $p ]] && echo a; [[ $f == "$p" ]] && echo b
[[ ciao =~ ^c.a ]] && echo regex
[ -f /etc ]; echo $?; [ -d /etc ]; echo $?
true && false || echo terzo
if grep -q root /etc/passwd; then echo trovato; fi
if [ grep -q root /etc/passwd ]; then echo trovato; fi
```

**Verifica.** Si controlla a mano, con Claude.

**Dopo.** `[` è un programma o un comando interno? Guarda `type [` e `ls -l /usr/bin/[`. Perché dentro `[[ ]]` le variabili non vanno per forza fra virgolette, e a destra di `==` invece sì? Cosa fa `true && false || echo terzo`, ed è davvero un `if`?

---

## Problema 1 — `utente-esiste.sh`

**Situazione.** Prima di creare un account o una cartella vuoi sapere se l'utente c'è. La risposta serve ad altri script, quindi non deve stampare nulla: conta il codice di uscita.

> [!info] Il contesto
> **Lo scenario.** Uno script crea gli account per i nuovi assunti, un altro prepara le cartelle condivise, un terzo disattiva chi se ne va. Tutti devono prima sapere se un utente esiste già, e lo chiedono a un piccolo script comune.
> - **Account** (inglese, «conto», come quello in banca): l'identità con cui una persona o un programma entra nel sistema.
> - **`/etc/passwd`**: il file con l'elenco degli utenti, una riga per account. Il nome viene dai primi Unix, quando conteneva anche le password cifrate; oggi stanno in `/etc/shadow`.
> - **Codice di uscita**: il numero da 0 a 255 che un programma lascia a chi l'ha lanciato quando finisce. 0 vuol dire successo.
>
> **Perché conta.** Se il controllo dice «esiste» per un nome solo simile, lo script dei nuovi assunti salta una persona, o tocca l'account di un'altra.

**Compito.** `./utente-esiste.sh NOME [FILE]`. `FILE` ha il formato di `/etc/passwd`, che è anche il valore predefinito.

| Codice | Significato |
|---|---|
| 0 | L'utente esiste |
| 1 | Non esiste |
| 2 | Uso sbagliato (argomento mancante, file illeggibile): spiegazione su stderr, niente su stdout |

`mar` non deve trovare `mario`, `bash` e `1000` non sono nomi, `m.rio` non è `mario`.

**Verifica.** `../../verifica.sh 02 1`

> [!question]- Indizio 1
> Guarda una riga di `dati/passwd`. Su quale pezzo della riga vuoi cercare? Su tutta la riga, cosa può trovare per sbaglio?

> [!question]- Indizio 2
> Se il comando che usi per cercare trova o non trova, quale codice restituisce? Serve davvero confrontare il suo output?

> [!question]- Indizio 3
> `m.rio` trova `mario`: per il tuo comando di ricerca, cosa significa il punto? `man grep`: quali opzioni cambiano *cosa conta come corrispondenza*?

**Dopo.** `/etc/passwd` è l'unica fonte degli utenti di un sistema? Cosa fa `getent passwd`, e perché su una macchina aziendale la tua soluzione potrebbe rispondere in modo sbagliato?

---

## Problema 2 — `soglia-disco.sh`

**Situazione.** Un disco pieno ferma database e log. I sistemi di monitoraggio come Nagios usano una convenzione semplice: una riga di testo per l'umano e il codice per la macchina.

> [!info] Il contesto
> **Lo scenario.** In un centro di calcolo un programma di monitoraggio controlla ogni pochi minuti centinaia di macchine, lanciando piccoli script chiamati *plugin*. Se uno segnala un problema, qualcuno riceve un avviso, anche di notte.
> - **Nagios**: uno dei sistemi di monitoraggio più diffusi, nato nel 1999. Il suo modo di leggere i plugin (codici 0, 1, 2, 3 per OK, WARNING, CRITICAL, UNKNOWN) è stato adottato da quasi tutti gli strumenti venuti dopo.
> - **Mount** (inglese *to mount*, «montare»): la cartella da cui si raggiunge un disco o una partizione, come `/var`.
> - **Soglia** di avviso e soglia critica: le percentuali oltre le quali il problema diventa da guardare, e poi urgente.
>
> **Perché conta.** Un disco pieno ferma un database e fa perdere i log proprio quando servono. Un allarme che sbaglia la soglia sveglia per niente, o tace quando conta.

**Compito.** `df -P | ./soglia-disco.sh AVVISO CRITICO [MOUNT]`. Legge da stdin; il mount predefinito è `/`. Per provare: `./soglia-disco.sh 80 90 /var < dati/df.txt`.

| Uso del disco | Stampa | Codice |
|---|---|---|
| Sotto `AVVISO` | `OK /var 42%` | 0 |
| Da `AVVISO` in su | `WARNING /var 85%` | 1 |
| Da `CRITICO` in su | `CRITICAL /var 96%` | 2 |
| Mount inesistente, soglie non numeriche o mancanti, `AVVISO` ≥ `CRITICO` | spiegazione su stderr | 3 |

**Verifica.** `../../verifica.sh 02 2`

> [!question]- Indizio 1
> Guarda `dati/df.txt`: `/var` e `/var/log` iniziano allo stesso modo. Come distingui una colonna intera da un pezzo di testo?

> [!question]- Indizio 2
> `/boot` è al 9% ma il tuo script grida? Quale ordine usa il confronto che hai scritto, e cosa viene prima fra `"9"` e `"80"` in un dizionario?

> [!question]- Indizio 3
> `85%` non è un numero. Come togli un carattere dalla fine di una variabile senza lanciare altri comandi? Cerca in `man bash` la sezione *Parameter Expansion*.

> [!question]- Indizio 4
> Come riconosci che una stringa è fatta solo di cifre? Cosa accetta `[[ ]]` a destra di `=~`?

**Dopo.** Prova `./soglia-disco.sh 80 90 "/var/log"` e poi un mount con uno spazio nel nome: cosa fa il tuo script? Perché `df -P` e non `df -h`? Cosa fa la `P`?

---

## Problema 3 — `estrai.sh`

**Situazione.** Arrivano archivi in formati diversi e ricordare ogni volta le opzioni è una perdita di tempo. Vuoi un comando solo. Il manuale Rocky elenca i formati nel capitolo sui backup.

> [!info] Il contesto
> **Lo scenario.** Fornitori, colleghi e sistemi di backup mandano pacchetti di file in formati diversi: log da analizzare, programmi da installare, copie da ripristinare.
> - **Archivio**: un file che ne contiene molti, con le loro cartelle, per spostarli come un pezzo solo.
> - **Compressione**: la riscrittura di un file in meno byte, togliendo le ripetizioni. Archivio e compressione sono due cose diverse, e spesso si combinano.
> - **Estensione** (latino *extendere*, «allungare»): la parte finale del nome, dopo il punto. Per Linux è solo una convenzione, non una garanzia.
>
> **Perché conta.** Ricordare a memoria le opzioni giuste per ogni formato porta a estrarre nella cartella sbagliata, o a perdere l'originale che volevi conservare.

**Compito.** `./estrai.sh ARCHIVIO CARTELLA` crea la cartella ed estrae lì dentro.

| Nome | Azione |
|---|---|
| `.tar` | Estrae |
| `.tar.gz`, `.tgz` | Estrae |
| `.gz` | Decomprime nella cartella, togliendo `.gz`, e lascia l'originale al suo posto |

Codici: 1 numero di argomenti sbagliato, 2 formato non supportato, 3 archivio inesistente.

**Verifica.** `../../verifica.sh 02 3`

> [!question]- Indizio 1
> Con una catena di `if` dovresti ripetere molte volte lo stesso test. Il quiz del manuale cita una struttura pensata per scegliere fra tanti valori: quale?

> [!question]- Indizio 2
> `.tar.gz` finisce anche con `.gz`. Se metti le regole in un certo ordine, quale scatta per prima?

> [!question]- Indizio 3
> `gzip` di solito sostituisce il file che gli dai. `man gzip`: c'è un modo per mandare il risultato altrove?

**Dopo.** Il nome di un file garantisce cosa contiene? Prova `file dati/strano.rar`. Come cambierebbe lo script se decidesse guardando il contenuto?

---

## Diario

Domande numerate, risposte e correzioni di questa lezione. Il concetto è in [[condizioni-modelli|Condizioni, modelli e trappole]]; le fonti degli utenti in [[nss-utenti|Da dove vengono gli utenti]].

### Problema 0 — Previsioni

Previste bene: `[ -n "$vuota" ]`, `[ 10 -lt 9 ]`, il glob `*.txt` in `[[ ]]`, la regex `^c.a`, `-f`/`-d` su `/etc`, `true && false || echo terzo`, `if grep -q`.

Errori e cosa me li ha fatti capire:

- `x=; [ $x = ciao ]`: mi aspettavo silenzio, invece «atteso operatore unario». `printf '<%s>\n' [ $x = ciao ]` ha mostrato che `$x` sparisce; il paragrafo *Word Splitting* di `man bash` spiega che gli argomenti nulli impliciti vengono tolti.
- `[ -n $vuota ]` dice «pieno»: resta un solo argomento, `-n`, che è una stringa non vuota.
- `[ 10 \< 9 ]` e `[[ 10 < 9 ]]` danno 0: pensavo che `<` non esistesse in `test` (lo cercavo con la barra). È un confronto lessicografico.
- `[ 010 -eq 8 ]` dà 1: pensavo che `test` leggesse l'ottale, invece legge in decimale. L'ottale è di `(( ))`.
- Riga 11: esito giusto, ma pensavo che le virgolette impedissero «l'espansione dell'asterisco». In `[[ ]]` non c'è espansione dei nomi di file: le virgolette decidono fra modello e stringa letterale. Chiarito con `[[ ciao.txt == $p ]]` contro `"$p"`.
- `if [ grep -q … ]`: pensavo non cambiasse niente. `[` riceve `grep` come stringa e si lamenta di `-q`.

> **D1.** Perché `$x` vuota sparisce e `"$x"` no?
> **R.** Senza virgolette è un argomento nullo implicito, e la divisione in parole lo toglie; fra virgolette diventa un argomento vuoto che resta. ✅

> **D2.** Con `[ = ciao ]`, perché «atteso operatore unario»?
> **R.** `test` sceglie le regole in base al numero di argomenti: con due, il primo deve essere un operatore unario (`-f`, `-n`), e `=` è binario. ✅

> **D3.** Perché `[ -n $vuota ]` dà «pieno»?
> **R.** Resta un solo argomento, `-n`, letto come stringa: non vuota, quindi vero. ✅

> **D4.** Quando vanno le virgolette sulle variabili dentro `[ ]`?
> **R.** Sempre: così ogni variabile resta un argomento e `test` riceve il numero di argomenti previsto. ✅

> **D5.** Perché `10` viene prima di `9`, perché in `[ ]` serve `\<` e in `[[ ]]` no?
> **R.** Confronto lessicografico sul primo carattere. Senza barra `<` è una redirezione dal file `9`; `[[` è una parola riservata, la legge la shell e `<` non è redirezione. ✅

> **D6.** Che numero è `010` per `-eq` e per `(( ))`? Cosa fa `10#`? Perché `(( 08 + 1 ))` fallisce?
> **R.** `-eq` legge in decimale (10), `(( ))` in ottale (8); `10#` forza la base 10. In ottale l'8 non esiste. ✅

> **D7.** Cosa diventa `$p='*.txt'` in `[[ $f == $p ]]` e in `[[ $f == "$p" ]]`?
> **R.** Senza virgolette un modello, fra virgolette una stringa letterale. ❓ → scoperta con un esperimento.

> **D8.** In `if [ grep -q root /etc/passwd ]` cosa esegue `if`?
> **R.** `[`, che riceve `grep -q root /etc/passwd` come stringhe: `grep` non parte. ✅

> **D9.** `[` è un programma o un comando interno? Perché esiste `/usr/bin/[`?
> **R.** È interno; il file serve a chi lancia comandi senza shell, come `find -exec`, che altrimenti fallirebbe. ✅ (con un indizio)

> **D10.** `true && false || echo terzo` è un `if`?
> **R.** No: `||` guarda l'ultimo comando eseguito, quindi se il ramo «sì» fallisce parte anche il «no». ✅

### Problema 1 — `utente-esiste.sh`

Verifica superata (13/13), poi riscritto con `if`/`elif` e un messaggio per ogni causa.

Errori e cosa me li ha fatti capire:

- `${"$1":?…}` dà «sostituzione errata»: dopo `${` va il nome del parametro, non la sua espansione. `echo ${HOME}` contro `echo ${"HOME"}`.
- `${2:=…}` non si può: `:=` assegna, e a un parametro posizionale non si assegna così. Copiato in una variabile; poi visto che `:-` basta.
- `:?` scrive su stderr ma esce con 1, e la tabella vuole 2: il codice lo decide uno `exit` mio.
- `echo … 2>&1` lasciava il messaggio su stdout: sposta il canale 2, che `echo` non usa. Capito con `2> /dev/null` e `> /dev/null`, e la regola «a sinistra il canale che sposti, a destra dove lo mandi».
- Il file illeggibile (`chmod 000`) passava i controlli: mancava la prova sulla leggibilità.
- Il ciclo `while read` con `break`: il `$?` era quello del `while`, cioè dell'ultimo comando del corpo, o 0 se il corpo non gira mai. Con un file vuoto rispondeva «esiste». Sostituito da `grep`, che risponde già con il codice.
- `grep` da solo: `mar` trovava `mario` e `m.rio` trovava `mario`; poi la ricerca per parola si faceva ingannare da `mario.rossi`. Capito con `printf … | grep` e la sezione *Matching Control* di `man grep`.
- `cut … $file` senza virgolette: un percorso con uno spazio diventa due argomenti.
- Prima versione con `if`: `elif [ -f "$file" ]` usciva con 2 proprio sui file buoni. Il ramo parte quando il test riesce, mentre nella catena l'errore stava dopo `||`: il test andava rovesciato.

> **D11.** La stringa vuota è ridondante, se ci sono già `-f` e `-r`?
> **R.** No: `-f` e `-r` guardano il file, non il nome. Senza `-z` lo script senza argomenti esce con 1, non con 2. ❓ → spiegato; il controllo è rimasto.

> **D12.** `&& { … } ||` o `if`?
> **R.** La catena va bene per un controllo su una riga che finisce con `exit`; con rami di più righe si usa `if`, perché `a && b || c` non è un `if`. `case` serve a scegliere fra i valori di una stessa stringa, non a interrogare il file system. (domanda mia) → spiegato.

> **D13.** `/etc/passwd` è l'unica fonte degli utenti? Cosa risponde lo script per un collega con account LDAP?
> **R.** No: `nsswitch.conf` dice di chiedere prima a SSSD (`sss`), poi ai file. Lo script legge solo il file, quindi esce con 1, «non esiste»: un falso negativo, non un errore. Per l'uso reale, `getent passwd`, che per «non trovato» esce con 2. ❓ → spiegato.

### Problema 2 — `soglia-disco.sh` (in corso)

Scomposizione: prima i controlli sugli argomenti (soglia mancante, non numerica, avviso ≥ critico), poi la ricerca del mount nei dati, l'estrazione della percentuale e il confronto.

Errori e cosa me li ha fatti capire:

- Numero o no: `[[ 8a0 == [0-9]* ]]` e `[[ 8a0 =~ [0-9] ]]` riescono entrambi. Con `a8` riesce solo la regex: il modello descrive tutta la stringa ma `*` lascia passare il resto, la regex cerca in un punto qualsiasi. Letta `man 7 regex`.
- Pensavo che `dati/df.txt` fosse l'ultimo argomento: la shell apre il file sullo stdin e toglie `<` dalla riga.
- `grep -Fw /var` trova anche `/var/log`: per `-w` lo `/` non è un carattere di parola (`man grep`, *Matching Control*).
- `grep /log$` trova `/var/log`; `grep '^/var$'` non trova niente, perché `^` lega all'inizio della riga, non della colonna. Il confine a sinistra è lo spazio: `" /var$"`.
- `${percentuale:=tail … | …}` assegna il testo, non esegue: visto con `echo "${x:=date}"`.

## Sintesi

Da scrivere a lezione finita, con le tue parole.

---

← [[13-espansioni|Lezione 13]] · ↑ [[00-percorso|Il percorso]] · → [[14-aritmetica|Lezione 14]]
