---
tags:
  - shell
  - nota
aliases:
  - Condizioni, modelli e trappole
---
# Condizioni, modelli e trappole

Quello che serve per far decidere uno script: come si scrive una prova, come si confronta una stringa con un modello, quando `set -e` non interviene, e alcune trappole invisibili. Nato dal problema 2 della [[13-espansioni|lezione 13]].

## `[` e `[[`

| | `[ … ]` | `[[ … ]]` |
|---|---|---|
| Cos'è | Un comando, sinonimo di `test` (esiste anche `/usr/bin/[`) | Una parola riservata della shell |
| Origine | Unix, POSIX | KornShell (1988), non POSIX |
| Argomenti | Espansi prima: divisione in parole e glob | Niente divisione in parole né glob sulle variabili |
| `==` | Confronto esatto; il portabile è `=` | A destra, senza virgolette, un **modello** |
| Virgolette | Obbligatorie sulle variabili | Facoltative a sinistra; a destra tolgono il modello |

L'ordine è sempre **operatore, poi stringa**: `[ -z "$x" ]`. Con gli argomenti al contrario, `[ "$x" -z ]`, si ottiene «atteso operatore unario» e codice 2, cioè errore d'uso, non falso.

Le prove non si accorpano come le opzioni di `ls`: `[ -rf f ]` è un errore. Si combinano con le liste: `[ -r f ] && [ -f f ]`.

Prove utili:

- `-z` (*zero length*): stringa vuota. `-n` (*non-zero*): stringa non vuota.
- `-f`: esiste ed è un **regular file**. `-r`: il processo può leggerlo. `-d`: è una cartella.

### Variabili vuote senza virgolette

Senza virgolette una variabile vuota **sparisce** dagli argomenti di `[`. Con un solo argomento `test` risponde «vero se non vuoto», quindi:

```sh
u=''; [ -n $u ]; echo $?    # 0: [ riceve solo "-n", stringa non vuota
```

`-z` senza virgolette funziona per caso, per lo stesso motivo. `test "$x"` senza operatore si regge sulla stessa regola: meglio scrivere `-n`.

## Il regular file

*Regular*, «ordinario»: il file con un contenuto di byte. Per Unix «file» è tutto ciò che ha un inode; il tipo si vede nel primo carattere di `ls -l` o con `stat -c '%F'`:

| Carattere | Tipo |
|---|---|
| `-` | file regolare |
| `d` | cartella |
| `l` | collegamento simbolico |
| `c`, `b` | dispositivo a caratteri, a blocchi |
| `p` | pipe con nome (FIFO) |
| `s` | socket |

Una cartella è leggibile (`-r` vero), ma il suo contenuto è un elenco di nomi: `grep` la rifiuta. Per leggere righe di testo serve `-f`.

## I modelli (glob)

Un **modello** (*pattern*, dal latino *patronus*, «esemplare da copiare») descrive un insieme di stringhe:

- `*`: qualunque sequenza, anche vuota.
- `?`: un carattere qualsiasi.
- `[abc]`, `[0-9]`: un carattere fra quelli indicati.
- Gli altri caratteri valgono per sé stessi.

Il nome *glob* viene da `/etc/glob`, il programma che nel primo Unix espandeva i nomi di file (*global*). Il meccanismo è uno solo, cambia con che cosa si confronta il modello:

| Dove | Confrontato con |
|---|---|
| `ls *.txt` | i nomi dei file della cartella |
| `${p##*/}`, `${p%.sh}` | il valore della variabile, per togliere un pezzo |
| `[[ $x == \#* ]]`, `case` | una stringa: sì o no |

Non sono le espressioni regolari: in una regex `*` vuol dire «il carattere precedente, zero o più volte».

### Togliere prefissi e suffissi

| Forma | Toglie | `p=/home/remoto/tabella.sh` |
|---|---|---|
| `${p#*/}` | il prefisso più corto | `home/remoto/tabella.sh` |
| `${p##*/}` | il prefisso più lungo | `tabella.sh` |
| `${p%.sh}` | il suffisso più corto | `/home/remoto/tabella` |
| `${p%/*}` | il suffisso più corto | `/home/remoto` |

Sulla tastiera americana `#` sta a sinistra di `$` (inizio), `%` a destra (fine). `${0##*/}` dà il nome dello script come fa `basename`, senza lanciare un processo.

### Il `#` a inizio parola

`#` all'inizio di una parola apre un commento fino a fine riga:

```sh
[[ $u == #* ]]     # bash vede solo "[[ $u ==": errore
[[ $u == \#* ]]    # # letterale, * resta modello
[[ $u == '#'* ]]   # equivalente
[[ $u == '#*' ]]   # sbagliato: anche * diventa letterale
```

`echo a#b` stampa `a#b`; `echo a #b` stampa `a`.

## Quando `set -e` non interviene

`set -e` (*errexit*) fa uscire la shell quando un comando fallisce, ma non nei contesti in cui un fallimento può essere una decisione voluta:

1. la condizione di `if`, `elif`, `while`, `until`;
2. le liste `&&` e `||`, tranne il comando dopo l'ultimo operatore;
3. un comando preceduto da `!`;
4. le pipeline, tranne l'ultimo comando (salvo `set -o pipefail`);
5. tutto il corpo di una funzione chiamata in un contesto condizionale (`if f; then`);
6. le sostituzioni `$( )` il cui codice nessuno raccoglie, per esempio dentro una redirezione `<<<`.

Interviene invece su un comando semplice qualsiasi: un `printf` con «numero non valido» esce con 1 e ferma lo script a metà output.

È una rete di sicurezza, non un modo di gestire gli errori. Gli errori previsti si controllano prima e a mano, con un messaggio sullo stderr e un `exit` con il codice voluto:

```sh
if ! [ -f "$1" ]; then
    echo "${0##*/}: \"$1\" non esiste o non è un regular file" >&2
    exit 1
fi
```

`!` si applica al primo comando: per negare una lista serve un gruppo, `! ( a && b )` (subshell) o `! { a && b; }` (shell corrente; spazio dopo `{` e `;` prima di `}`).

## `read`, here-string e fine file

- `$( )` toglie **tutti** gli a capo finali dall'output.
- `<<<` (*here-string*) passa al comando la stringa **più un `\n`**. Una stringa vuota diventa una riga vuota, che `read` legge con successo: un giro in più con campi vuoti. Dopo `<<<` bash non divide in parole, ma le virgolette restano la buona abitudine (prima di bash 4.4 le righe si univano).
- `<<< "$1"` passa il **nome** del file come testo; il contenuto si legge con `< "$1"`.
- `read -r` (*raw*): senza `-r` il `\` è un carattere di escape e viene mangiato.
- Ultima riga senza a capo: `read` riempie le variabili ma esce con 1, e `while` salta il corpo. In `read …; echo` il `;` ignora il codice e l'`echo` parte lo stesso: cambia chi guarda il codice. Per non perdere la riga:

  ```sh
  while IFS=';' read -r a b || [ -n "$a" ]; do …; done < file
  ```

Vedi anche [[while-read|Leggere righe con while read]].

## Trappole invisibili

- **Spazio non separabile** (U+00A0, byte `c2 a0`, Option + Spazio sul Mac): sembra uno spazio, ma per bash è una lettera. `test` + U+00A0 + `"$x"` diventa il comando `test mario`, «comando non trovato». Si trova con `cat -A` (`M-BM-`) o `grep -n $'\xc2\xa0' file`.
- **Byte e caratteri:** `printf` conta la larghezza in byte. `ò` in UTF-8 sono due byte, quindi `%-12s` mette uno spazio in meno e `%.12s` può spezzare un carattere. `${#x}` conta i caratteri in un locale UTF-8; `wc -c` conta i byte, `wc -m` i caratteri.
- **Locale:** `LC_ALL`, poi `LC_NUMERIC`, poi `LANG`, se no `C`. Con `it_IT.UTF-8` `printf '%.1f' 12.5` rifiuta il punto. Arriva dall'ambiente di chi lancia lo script (sistema, utente, ssh con `SendEnv`/`AcceptEnv`; cron non ne ha): lo script fissa da sé `LC_NUMERIC=C` dove serve.

---

↑ [[mappa-shell|Mappa della shell]]
