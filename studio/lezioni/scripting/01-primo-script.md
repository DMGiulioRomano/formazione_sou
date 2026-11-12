---
tags:
  - lezione
  - scripting
aliases:
  - Scripting 01 — Il primo script
---
# Scripting 01 — Il primo script

Prima di programmare serve capire cosa la shell fa di ciò che scrivi: dove finisce un argomento, quando una variabile si spezza, cosa significa «eseguibile».

```sh
./prepara.sh 01 && cd palestra/l01
```

## La mappa

| #   | Problema                                     | Stato |
| --- | -------------------------------------------- | ----- |
| 0   | Previsioni — carta e penna, poi la prova     | ✅    |
| 1   | `scheda.sh` — inquadrare una macchina        | ✅    |
| 2   | `argomenti.sh` — cosa riceve uno script      | ✅    |
| 3   | `salva-conf.sh` — copia prima di toccare     | ✅    |
| 4   | `conta-righe.sh` — riparare uno script rotto | ✅    |

---

## Problema 0 — Previsioni

**Situazione.** Prima di scrivere script conviene sapere cosa fa la shell con una riga sola. Ogni previsione sbagliata è una regola che ancora non conosci.

**Compito.** Per ogni riga scrivi **prima** cosa stampa e perché, poi lanciala.

```sh
echo ciao      mondo
echo "ciao      mondo"
echo 'ciao $HOME' "ciao $HOME"
nome=mario; echo "ciao $nome"; echo "ciao $nomeX"; echo "ciao ${nome}X"
nome = mario
x=5 echo "[$x]"
x=5; echo "[$x]"
ls /nessuno; echo $?
true; echo $?; false; echo $?
echo $0 $$ $#
type echo cd ls
cat /etc/hostname | wc -c
echo uno; echo due > /dev/null; echo tre
echo "$(date +%Y)" e `date +%Y`
```

**Verifica.** Si controlla a mano, con Claude: spiega ogni errore di previsione.

**Dopo.** Perché `nome = mario` dà errore e `nome=mario` no? Cosa vuol dire che in shell una variabile è sempre una stringa? Che differenza c'è fra un comando interno e un programma su disco, secondo `type`?

---

## Problema 1 — `scheda.sh`

**Situazione.** Ti danno l'accesso a un server che non hai mai visto. Prima di toccare qualsiasi cosa vuoi sapere dove sei, e lo vuoi sapere con un solo comando su ogni macchina.

**Compito.** Lo script stampa esattamente queste sei righe, senza argomenti:

```text
host: <nome della macchina>
kernel: <versione del kernel>
utente: <chi sta eseguendo lo script>
core: <numero di CPU>
ram_mib: <RAM totale in MiB, solo il numero>
disco_root_libero: <spazio libero su />, come 12G
```

**Verifica.** `../../verifica.sh 01 1`

> [!question]- Indizio 1
> Riesci a farlo prima a mano, un dato alla volta? Quale comando ti ha già risposto a domande simili negli appunti di [[orientarsi-documentarsi|Orientarsi e documentarsi]]?

> [!question]- Indizio 2
> Ti manca il nome di un comando. Come chiedi al sistema «quale comando parla di memoria»? Cosa cerca `apropos`, e dove?

> [!question]- Indizio 3
> Un comando stampa una tabella e a te serve una casella. Come isoli prima la riga e poi la colonna? E come fai finire l'output di un comando in mezzo a una frase?

**Dopo.** Perché il file parte con `#!`, e chi legge quella riga: la shell o il kernel? Cosa cambia fra `bash scheda.sh` e `./scheda.sh`? Perché `./` è necessario?

---

## Problema 2 — `argomenti.sh`

**Situazione.** Ogni comando Linux riceve una lista di argomenti. Prima di scrivere script che ne accettano, vuoi vedere con i tuoi occhi cosa arriva.

**Compito.** `./argomenti.sh uno "due tre" quattro cinque` deve stampare:

```text
script: argomenti.sh
quanti: 4
1: uno
2: due tre
3: quattro
```

Il nome va stampato senza percorso, anche se lanci lo script con `../l01/argomenti.sh`.

**Verifica.** `../../verifica.sh 01 2`

> [!question]- Indizio 1
> Prova `echo` con un argomento fra virgolette e uno senza. Chi toglie le virgolette: la shell o `echo`? Cosa riceve quindi lo script?

> [!question]- Indizio 2
> Lancia lo script da un'altra cartella e guarda cosa contiene la variabile col suo nome. Il percorso è un testo: quale comando visto nel manuale Bash ne tiene solo l'ultimo pezzo?

**Dopo.** Scrivi una prova in cui `"$*"` e `"$@"` danno risultati diversi. Il manuale dice che la differenza si vede cambiando `IFS`: è l'unico modo? Cosa fanno le virgolette?

---

## Problema 3 — `salva-conf.sh`

**Situazione.** Regola di ogni sistemista: prima di modificare una configurazione se ne salva una copia datata. Il manuale parte da uno script simile, ma con i nomi di file scritti dentro: il tuo deve funzionare con qualsiasi file.

**Compito.** `./salva-conf.sh FILE CARTELLA` copia `FILE` in `CARTELLA/<nome del file>.AAAAMMGG`, con la data di oggi.

- La cartella si crea se manca, anche con più livelli.
- Nomi con spazi devono funzionare.
- Se il file non esiste, lo script esce con un codice diverso da 0. Ti basta ciò che già fanno i comandi: `if` arriva nella prossima lezione.

**Verifica.** `../../verifica.sh 01 3`

> [!question]- Indizio 1
> Prova: `./salva-conf.sh "dati/conf di prova.ini" "dati/le copie"`. Quanti argomenti riceve ogni comando dentro lo script? Come lo controlli?

> [!question]- Indizio 2
> Con quale codice esce uno script che non chiama `exit`? Cosa succederebbe se dopo la copia aggiungessi un `echo "fatto"`?

> [!question]- Indizio 3
> Quali opzioni di `date` conosci per scegliere il formato? Cosa dice `man date` sui segnaposto?

**Dopo.** Lancia lo script due volte lo stesso giorno. Cosa succede alla prima copia? È accettabile, per una copia di sicurezza?

---

## Problema 4 — `conta-righe.sh`

**Situazione.** Un collega ti lascia uno script che «funzionava». Lo trovi già in `palestra/l01/conta-righe.sh`. Deve stampare:

```text
dati/nome con spazi.log: 12 righe
```

**Compito.** Ripara lo script. Prima di correggere un errore, prevedi a voce cosa succederà e controlla con `bash -x`, poi passa al successivo. Gli errori sono più d'uno, e uno non è dentro il testo.

**Verifica.** `../../verifica.sh 01 4`

> [!question]- Indizio 1
> Leggi il primo messaggio d'errore parola per parola: cosa ha creduto di dover eseguire la shell?

> [!question]- Indizio 2
> Se assegni a una variabile il nome di un comando, la shell esegue il comando? Cosa stai mettendo in `righe`?

> [!question]- Indizio 3
> Il messaggio finale stampa letteralmente i nomi delle variabili. Quali caratteri decidono se `$` viene interpretato?

**Dopo.** Cosa fa esattamente `bash -x`? E `shellcheck conta-righe.sh`, sullo script ancora rotto? Quanti di questi errori avrebbe trovato al posto tuo?

---

## Diario

Domande numerate, risposte e correzioni di questa lezione.

### Problema 0 — Previsioni

**Errori di previsione e cosa me li ha fatti capire.**

- Pensavo che `echo` prendesse un solo argomento e che la parola dopo fosse un nuovo comando (righe 1, 3, 14). Capito dalla sinossi di `man echo`: `[STRING]...`, i tre puntini vogliono dire «uno o più».
- `"ciao $nomeX"` non dà `ciao marioX`: la shell legge il nome finché trova lettere, cifre o `_`, quindi cerca `nomeX`, che non esiste e vale vuoto.
- `x=5 echo "[$x]"` stampa `[]`: non è un errore di sintassi. Capito con `x=5 bash -c 'echo "[$x]"'`, dopo un `unset x` (la riga 7 aveva lasciato `x=5` nella shell e falsava la prova).
- `$0 $$ $#` sono tre valori, non quattro. Il `-` in `-bash` l'ho trovato in `man bash`, sezione INVOCATION.
- `wc -c` dà 10 per `lab-rocky`: il decimo byte è il `\n`, visto con `od -c`.

> **D1.** Nella riga 1 quanti argomenti riceve `echo`, e chi toglie gli spazi?
> **R.** Due: gli spazi fuori dalle virgolette li toglie la shell, sono solo separatori. Lo spazio nell'output lo rimette `echo` fra un argomento e l'altro. ✅

> **D2.** E nella riga 2?
> **R.** Uno solo: le virgolette tengono insieme tutto, spazi compresi. ✅

> **D3.** Dove capisce la shell che il nome di una variabile è finito?
> **R.** Al primo carattere che non può stare in un nome; le graffe `${nome}` lo delimitano in modo esplicito. Con `$nome-X` si ferma prima del `-`. ✅

> **D4.** Perché `x=5 echo "[$x]"` stampa `[]`?
> **R.** Prima ho pensato a un errore di sintassi, poi a una subshell. ❌ La mia shell espande `$x` prima di lanciare il comando, quando è ancora vuota. `x=5` davanti a un comando va solo nell'**ambiente** di quel comando e sparisce quando finisce: per questo `x=5 bash -c 'echo "[$x]"'` stampa `[5]`, perché lì espande il `bash` nuovo. ✅

> **D5.** Perché `ls /nessuno` esce con 2?
> **R.** Il codice lo sceglie `ls`: 0 successo, 1 problemi minori, 2 problema serio (argomento inesistente). Sezione Exit status di `man ls`. ✅

> **D6.** Cosa indica il `-` in `-bash`?
> **R.** Che è una shell di login: legge `/etc/profile` e `~/.bash_profile`; una non di login legge solo `~/.bashrc`. ✅

> **D7.** Di chi è il PID in `$$`?
> **R.** Della shell in cui lavoro; un `bash` lanciato dentro ne ha un altro. ✅

> **D8.** Perché `$#` è 0, e cosa stampa `bash -c 'echo $0 / $#' prova a b c`?
> **R.** Nessuno ha impostato i parametri posizionali (si fa con `set --`, non `typeset`). Stampa `prova / 3`: la prima parola va in `$0`. ✅

> **D9.** Se `cd` fosse un programma su disco, cosa succederebbe?
> **R.** Il figlio cambierebbe cartella, la mia shell resterebbe dov'era. Per questo è un comando interno. ✅

> **D10.** Come trovi il `ls` vero dietro l'alias?
> **R.** `type -a ls`: mostra l'alias e `/usr/bin/ls`. ✅

> **D11.** Perché `wc -c` su `/etc/hostname` dà 10?
> **R.** 9 lettere più il `\n` finale. ✅

> **D12.** Perché i backtick non si annidano?
> **R.** Apertura e chiusura sono lo stesso carattere: la shell li accoppia in ordine. `$(...)` sì. ✅

**Dopo.**

> **D13.** Perché `nome = mario` dà errore e `nome=mario` no?
> **R.** Con gli spazi `nome` è la prima parola, quindi un comando da cercare; senza è un'assegnazione. ✅

> **D14.** Cosa vuol dire che una variabile è sempre una stringa?
> **R.** `echo $a+$b` con 2 e 3 dà `2+3`; per calcolare serve `$((a+b))`. ✅

> **D15.** Comando interno o programma su disco?
> **R.** L'interno gira nella shell, quello su disco è un processo nuovo. ✅

### Problema 1 — `scheda.sh`

**Errori e cosa me li ha fatti capire.**

- `hostname`, `uname -r` e `whoami` li conoscevo già.
- Per i comandi che non conosco uso `man -k` con la parola giusta. Con `core` escono solo i core dump; con `cpu` arriva `lscpu`, con `disk` arriva `df`.
- `free -hm` era sbagliato: `-h` arrotonda e aggiunge l'unità, per avere solo il numero in MiB serve `-m`.
- Metodo per le tabelle: prima isolo la riga, poi la colonna. Per `df` l'ho fatto da solo.
- La pipeline per `lscpu` l'ho chiesta io, me l'ha data Claude.

> **D16.** Meglio scegliere la riga di una tabella per nome o per posizione?
> **R.** Per nome: regge anche se l'ordine o il numero delle righe cambia. Con `free` all'inizio ho usato la posizione (penultima riga), poi l'ho cambiata per nome. ✅

- Nella prima riga avevo scritto `lab:` invece di `host:`: il correttore confronta il testo esatto.
- Su `df` avevo preso il campo 2 (`Size`) invece del 4 (`Avail`): l'ho visto rileggendo l'intestazione di `df -h /`.
- Avevo usato `df -H`: conta in potenze di 1000, mentre `-h` conta in potenze di 1024 e quindi la sua `G` è un GiB. Lo stesso disco dava 16G e 15G.
- Per l'output di un comando dentro una frase si usa la sostituzione di comando, come alla riga 14 del problema 0. Ho reso eseguibile il file con `chmod u+x`.

**Dopo.**

> **D17.** Chi legge `#!` quando lancio `./scheda.sh`: la shell o il kernel? E perché `/usr/bin/env bash`?
> **R.** Non lo sapevo ❌. Lo legge il **kernel**, durante `execve`: se trova `#!` lancia l'interprete indicato e gli passa lo script come argomento. Per bash quella riga è un commento. `env` cerca `bash` nel `PATH`, quindi funziona anche dove `bash` non sta in `/bin`: è più portabile, ma dipende dal `PATH` di chi lancia lo script. Si vede con `man 2 execve`.

> **D18.** Cosa cambia fra `bash scheda.sh` e `./scheda.sh`?
> **R.** In tutti e due i casi nasce un nuovo processo bash, che non è una subshell in senso stretto. Con `bash scheda.sh` il kernel esegue `bash`, e `bash` legge lo script come testo: basta il permesso `r` e lo shebang viene ignorato. Con `./scheda.sh` il kernel esegue il file stesso: serve `x`, e lo shebang sceglie l'interprete. Provato togliendo `x` con `chmod u-x`. ✅

> **D19.** Perché serve `./`?
> **R.** Senza `/` la shell cerca il comando nelle cartelle del `PATH`, e `.` non c'è per sicurezza: un `ls` lasciato in `/tmp` verrebbe eseguito al posto di quello vero. Con una `/` nel nome la shell usa direttamente quel percorso. ✅

Approfondimento: [[eseguire-uno-script|Eseguire uno script]].

### Problema 2 — `argomenti.sh`

**Errori e cosa me li ha fatti capire.**

- Prima versione senza virgolette: passava `verifica.sh`, ma `shellcheck` dava 5 osservazioni. Con `"due     tre"` o `"*"` l'output sarebbe cambiato: `$2` senza virgolette si spezza e i pezzi si espandono come glob.
- Per confrontare `"$@"` e `"$*"` passavo tutto a `echo ... | while read`: `echo` riunisce gli argomenti con uno spazio e il `while` vede una riga sola, quindi i confini si perdono prima di guardarli. Ho capito che serviva un comando che contasse `$#`: il mio `argomenti.sh`, chiamato da `prova.sh`.
- Lanciando via `ssh ... "...uno "due tre" quattro"` le virgolette interne chiudevano quelle esterne: la shell del Mac le consumava e la shell remota riceveva `uno due tre quattro`. Due shell leggono la riga; con `'due tre'` dentro le doppie arrivano alla VM.

**Dopo.**

> **D20.** Scrivi una prova in cui `"$*"` e `"$@"` danno risultati diversi.
> **R.** `./argomenti.sh "$@"` e `./argomenti.sh "$*"` dentro `prova.sh`, lanciato con `uno "due tre" quattro`: il primo dà `quanti: 3`, il secondo `quanti: 1` con tutto in `$1`. ✅

> **D21.** Serve cambiare `IFS` per vedere la differenza? Cosa fanno le virgolette?
> **R.** No, non ho toccato `IFS`: la differenza la fanno le virgolette. `"$@"` dà un argomento per ogni parametro, con i confini originali; `"$*"` li unisce in un argomento solo (col primo carattere di `IFS`, lo spazio, in mezzo: per questo `IFS` cambia il *separatore* visibile). Senza virgolette `$@` e `$*` sono uguali: tutto viene spezzato sugli spazi, e `"due tre"` diventa due argomenti. Correzione: le virgolette non vengono «mantenute» dentro gli argomenti, la shell le ha già tolte alla chiamata; `"$@"` mantiene i **confini** fra argomenti. ✅

> **D22.** Cambia qualcosa fra `"$@"` e `'$@'`?
> **R.** Sì: fra apici singoli non c'è espansione, `argomenti.sh` riceve un solo argomento, il testo `$@`. Via `ssh` serve `'\$@'`: la `\` protegge `$` dalla shell del Mac (dentro le doppie), e la shell della VM vede `'$@'`, letterale. ✅

Approfondimento: [[parametri-posizionali|Parametri posizionali]].

### Problema 3 — `salva-conf.sh`

**Errori e cosa me li ha fatti capire.**

- Controllo iniziale del file senza `if`: ho pensato a `test || exit $?`, poi ho cercato in `help set` un modo per fermare lo script al primo comando fallito.
- Prove via `ssh "..."` con nomi fra virgolette doppie: le virgolette interne chiudevano quelle esterne e lo script riceveva `./file`. Con gli apici singoli fuori il nome arriva intero.
- `cp: l'obiettivo ... non è una directory`: il nome costruito, senza virgolette, si spezzava sugli spazi e `cp` riceveva più di due argomenti.
- Toglievo l'estensione: «nome del file» è il nome intero, `.ini` compreso.
- Passava `verifica.sh` per caso: passavo a `date -r` il nome senza percorso, che esisteva solo perché avevo fatto `touch` nella stessa cartella. Prova da `/tmp` con `/etc/hostname`.
- `date -r` dà la data di **modifica** del file, non quella di oggi: si vedeva solo con un file datato col `touch -d 2026-01-01`.

**Dopo.**

> **D23.** Lanci lo script due volte lo stesso giorno: cosa succede alla prima copia? È accettabile per una copia di sicurezza?
> **R.** La prima copia viene sovrascritta. Non è accettabile: se al mattino salvo il file buono, lo rompo e al pomeriggio rilancio lo script, mi resta la copia rotta e perdo quella che mi serviva. ✅

> **D24.** Con `set -e` lo script si ferma quando fallisce `date` dentro `$( )`, in un'assegnazione. Perché? Qual è il codice di uscita di un'assegnazione?
> **R.** Un'assegnazione con `$( )` prende il codice dell'ultima sostituzione di comando: `x=$(false)` dà 1, `x=$(true)` e `x=ciao` danno 0. La shell principale vede fallire l'assegnazione e `set -e` la ferma. Correzione: prima pensavo che la subshell ereditasse `set -e`, ma la subshell è un processo separato e non può far uscire la shell principale. ✅

Approfondimento: [[codici-di-uscita|Codici di uscita e set -e]].

### Problema 4 — `conta-righe.sh`

**Errori e cosa me li ha fatti capire.**

- L'errore fuori dal testo l'ho visto subito con `verifica.sh`: mancava il permesso di esecuzione, messo con `chmod u+x`.
- Le tre previsioni sulle righe erano giuste: spazi intorno a `=`, `wc` senza `$( )`, apici singoli nell'`echo`.
- Per la riga 2 dicevo «fallisce per gli spazi», ma non sapevo chi avesse stampato `=: cannot open '='`. Era il comando `file` (`type file` → `/usr/bin/file`), lanciato con l'argomento `=`. Il messaggio non cominciava con `./conta-righe.sh: riga N:`, quindi non era di bash.
- I file in `dati/` contenevano `0`: li aveva sovrascritti una prova precedente. Rigenerati con `../../prepara.sh 01`.

**Dopo.**

> **D25.** Chi ha stampato `=: cannot open '='`?
> **R.** Il comando `file`: con gli spazi `file = $1` è un comando con argomento `=`, e `$1` vuoto senza virgolette sparisce. ✅

> **D26.** Cosa fa esattamente `bash -x`?
> **R.** Pensavo che stampasse le righe dello script e poi l'output. ❌ Stampa ogni comando **dopo l'espansione e prima dell'esecuzione**, su **stderr**, preceduto da `PS4` (`+`). Gli apici singoli nella traccia (`+ echo 'ciao mondo'`) indicano un solo argomento. Visto con `2>/dev/null` e `>/dev/null`.

> **D27.** Quanti errori trova `shellcheck` sullo script rotto, e perché non il permesso?
> **R.** Tre su quattro ✅. Il perché l'ho sbagliato due volte: «è un errore logico», poi «sta nella directory». ❌ Il permesso è un **metadato** del file, nell'inode, insieme a proprietario e date; la directory associa solo il nome all'inode. Shellcheck legge il contenuto, non i metadati. E trova anche errori logici: `file = $1` è sintassi valida.

Approfondimento: [[debug-script|Fare debug di uno script]].

## Sintesi

- **Virgolette sempre.** Prima di lanciare un comando la shell spezza la riga sugli spazi: un argomento con uno spazio dentro, senza virgolette, diventa due argomenti, e l'errore resta nascosto finché non arriva il nome sbagliato.
- **Lo shebang** (`#!`) lo legge il kernel, non la shell: sceglie l'interprete quando lancio `./pino.sh`. Con `bash pino.sh` lo lancio io e basta il permesso `r`; con `./pino.sh` serve `x`.
- **`"$@"` e `"$*"`**: il primo tiene ogni argomento separato, il secondo li unisce in uno solo.
- **`bash -x`** mostra ogni comando già espanso, prima di eseguirlo, su stderr. Stdout e stderr li devo ancora vedere bene.

---

↑ [[00-percorso|Il percorso]] · → [[13-espansioni|Lezione 13]]
