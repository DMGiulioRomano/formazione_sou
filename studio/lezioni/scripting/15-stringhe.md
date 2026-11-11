---
tags:
  - lezione
  - scripting
aliases:
  - Scripting 15 — Stringhe senza comandi esterni
---
# Scripting 15 — Stringhe senza comandi esterni

Ogni `$(echo "$x" | sed ...)` crea due processi per cambiare due lettere. Bash sa tagliare, sostituire, cambiare maiuscole e riconoscere pattern da solo, ed è centinaia di volte più veloce. Qui il correttore lancia i tuoi script **senza `PATH`**: funzionano solo i comandi interni. Si fa dopo la lezione 03. Riferimento: la sezione *Parameter Expansion* di `man bash`, e [[variabili-opzioni|Variabili e opzioni della shell]].

```sh
./prepara.sh 15 && cd palestra/l15
```

Per provare a mano come il correttore:

```sh
env PATH=/nessuno /usr/bin/bash ./normalizza-nome.sh "Mario Rossi"
```

## La mappa

| # | Problema | Stato |
|---|---|---|
| 1 | `normalizza-nome.sh` — dal nome della persona al nome utente | — |
| 2 | `maschera.sh` — segreti fuori dai log | — |
| 3 | `versione.sh` — è abbastanza recente? | — |
| 4 | `parse-url.sh` — smontare un indirizzo | — |

---

## Problema 1 — `normalizza-nome.sh`

**Situazione.** Le risorse umane scrivono i nomi come capita: maiuscole, doppi spazi, apostrofi, accenti. `useradd` vuole nomi corti, minuscoli e senza simboli. Lo script della lezione 07 riceverà nomi già puliti da questo.

**Compito.** `./normalizza-nome.sh NOME...` unisce gli argomenti con uno spazio e stampa il nome utente:

1. Le vocali accentate minuscole (`à á è é ì í ò ó ù ú`) diventano la vocale semplice, poi tutto diventa minuscolo.
2. Le parole sono separate da spazi, anche più d'uno. Da ogni parola si tolgono i caratteri che non sono `a-z` o `0-9`; le parole che restano vuote non contano.
3. La prima parola è il nome, le altre attaccate fra loro il cognome: `nome.cognome`. Con una parola sola, solo quella.
4. Al massimo 32 caratteri: il resto si taglia.

| Ingresso | Uscita |
|---|---|
| `"Mario Rossi"` | `mario.rossi` |
| `"  Anna   Maria  D'Amico "` | `anna.mariadamico` |
| `Mario De Rossi` (tre argomenti) | `mario.derossi` |
| `"Niccolò Fabbrò"` | `niccolo.fabbro` |

Se non resta nulla: codice 1. Senza argomenti: codice 2.

**Verifica.** `../../verifica.sh 15 1`

> [!question]- Indizio 1
> Quali trasformazioni di *Parameter Expansion* cambiano maiuscole e minuscole? E quale sostituisce tutte le occorrenze di un pattern, non solo la prima?

> [!question]- Indizio 2
> Come esprimi «tutto ciò che non è una lettera o una cifra» in un pattern della shell? Cerca *Pattern Matching* e le classi fra `[` `]`.

> [!question]- Indizio 3
> Prova con `"Mario *"`. Quante parole trovi, e da dove vengono? Come spezzi una stringa in parole senza che la shell espanda gli asterischi? `read -a` è un'idea.

> [!question]- Indizio 4
> Come prendi i primi 32 caratteri di una variabile? *Parameter Expansion*, forma con i due punti.

**Dopo.** Perché `${x,,}` non cambia `È` con `LC_ALL=C`, e lo cambia con `LC_ALL=it_IT.UTF-8`? Cosa fa `iconv -t ascii//TRANSLIT`, e perché qui non potevi usarlo? Quanti caratteri accetta davvero `useradd`? Cerca `LOGIN_NAME_MAX` o prova.

---

## Problema 2 — `maschera.sh`

**Situazione.** Devi mandare un log al fornitore per un'assistenza. Dentro ci sono password, token e numeri di carta. Prima di spedirlo li copri, senza toccare nient'altro: un log alterato non serve a nessuno.

**Compito.** `./maschera.sh` legge lo stdin e scrive lo stdout:

- **Chiavi segrete.** Una chiave è una parola di lettere, cifre, `_` e `-` che **finisce** con `password`, `passwd`, `secret` o `token`, con qualsiasi maiuscola, come `DB_PASSWORD` o `apiToken`. Se è seguita da `=` oppure da `:` e spazi, il valore che viene dopo, fino al primo spazio, diventa `****`. Un valore vuoto resta vuoto.
- **Carte.** Una sequenza di esattamente 16 cifre, non attaccata ad altre cifre, diventa dodici `*` seguiti dalle ultime quattro cifre.
- Tutto il resto resta identico: spazi, tabulazioni, barre rovesciate, righe vuote. Anche l'ultima riga senza a capo va stampata.

```text
login ok user=mario password=Segreta1 from 203.0.113.7
DB_PASSWORD:  abc  porta=5432
passwordless=yes
carta 4111111111111111 scade
```

diventa

```text
login ok user=mario password=**** from 203.0.113.7
DB_PASSWORD:  ****  porta=5432
passwordless=yes
carta ************1111 scade
```

**Verifica.** `../../verifica.sh 15 2`

> [!question]- Indizio 1
> Una riga può contenere più segreti. Puoi trattare la riga un pezzo alla volta: trova il primo segreto, stampa ciò che lo precede, poi riparti da ciò che lo segue?

> [!question]- Indizio 2
> `[[ $riga =~ ... ]]` riempie `BASH_REMATCH`. Cosa contiene l'elemento 0, e cosa i successivi? Con un gruppo per «ciò che sta prima» e uno per «ciò che sta dopo» hai già i pezzi.

> [!question]- Indizio 3
> Le tue righe perdono gli spazi iniziali o le barre rovesciate? Rileggi [[while-read|while read]]: quali opzioni e quale `IFS` conservano la riga intatta?

> [!question]- Indizio 4
> «Non attaccata ad altre cifre» vuol dire guardare il carattere prima e quello dopo. Come lo scrivi, ricordando che può essere anche l'inizio o la fine della riga?

**Dopo.** Cosa ti sfugge ancora? Pensa a una password in un URL (`https://mario:segreta@host`), a un'intestazione `Authorization: Bearer ...`, a una chiave privata su più righe. Quanto è più lento il tuo script di un `sed -E` equivalente su un log di 100 000 righe? Misuralo con `time`.

---

## Problema 3 — `versione.sh`

**Situazione.** Uno script di installazione deve rifiutarsi di partire se `git` è più vecchio della 2.30. Confrontare le versioni come testo dice che `2.9` viene dopo `2.30`.

**Compito.** `./versione.sh A B` confronta due versioni e non stampa nulla:

| Codice | Significato |
|---|---|
| 0 | A e B sono uguali |
| 1 | A è più vecchia di B |
| 2 | A è più nuova di B |
| 3 | Uso sbagliato o versione non valida |

Una versione è fatta di numeri separati da punti, con una `v` o `V` facoltativa davanti. I numeri mancanti valgono 0, quindi `1.2` e `1.2.0` sono uguali, e anche `1.08` e `1.8`.

**Verifica.** `../../verifica.sh 15 3`

> [!question]- Indizio 1
> Confronta a mano `1.10` e `1.9`, poi `1.2` e `1.2.0`. Quali passi fai? Sono gli stessi passi da scrivere.

> [!question]- Indizio 2
> Come spezzi la versione sui punti in un array? Che valore ha un elemento che non esiste?

> [!question]- Indizio 3
> `1.08` ti dà un errore? L'hai già incontrato nella lezione 14.

**Dopo.** Cosa fa `sort -V`, e dove sbaglia? Come tratteresti `2.0.0-rc1`, che per semver viene *prima* di `2.0.0`? Come useresti il tuo script per controllare la versione di bash che hai, cioè `$BASH_VERSION`?

---

## Problema 4 — `parse-url.sh`

**Situazione.** Un file di configurazione contiene gli indirizzi dei servizi come URL. Per controllare che le porte siano aperte ti servono host e porta separati, e i log non devono mai mostrare la password che a volte c'è dentro.

**Compito.** `./parse-url.sh URL`, dove l'URL è `schema://[utente[:password]@]host[:porta][percorso]`:

```text
$ ./parse-url.sh 'HTTPS://mario:segreta@Example.COM:8443/a/b?x=1'
schema: https
utente: mario
host: example.com
porta: 8443
percorso: /a/b?x=1
```

- Schema e host si stampano in minuscolo. Un host IPv6 è scritto fra quadre, come `[2001:db8::1]`, e si stampa senza.
- Senza utente: `-`. La password non si stampa mai.
- Senza porta: 80 per `http`, 443 per `https`, 22 per `ssh`, 21 per `ftp`, altrimenti `-`. Una porta scritta va da 1 a 65535.
- Il percorso parte dalla prima `/` dopo l'host; se manca, è `/`.
- Senza `://`, host vuoto, porta non valida, quadre non chiuse o argomenti sbagliati: codice 2.

**Verifica.** `../../verifica.sh 15 4`

> [!question]- Indizio 1
> Smonta l'URL un pezzo alla volta, da sinistra: cosa togli per primo, e quale forma di *Parameter Expansion* ti dà ciò che sta prima e ciò che sta dopo un separatore?

> [!question]- Indizio 2
> `https://host/u/@me`: dov'è l'utente? Il separatore `@` conta ovunque, o solo in un certo tratto dell'URL?

> [!question]- Indizio 3
> In `[2001:db8::1]:2222` i due punti sono tanti. Quali indicano la porta? Prova a trattare l'host fra quadre come un caso a parte, con `=~`.

**Dopo.** Perché `%40` in un URL è una `@`? Cosa fa la *percent-encoding*, e il tuo script la gestisce? Dove leggeresti la porta predefinita di un servizio invece di scriverla nello script? Guarda `/etc/services`.

---

## Diario

Domande numerate, risposte e correzioni di questa lezione.

## Sintesi

Da scrivere a lezione finita, con le tue parole.

---

← [[03-cicli-e-nomi|Lezione 03]] · ↑ [[00-percorso|Il percorso]] · → [[12-processi-pipe-subshell|Lezione 12]]
