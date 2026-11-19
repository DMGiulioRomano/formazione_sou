# Esercizio ODD/EVEN track extra

Assegnato da: ... il 2026-11-... Consegna: 2026-11-...

## Consegna

ODD/EVEN: Scrivere uno script che accetti un argomento numerico e stampi la sequenze di numeri da 1 a quel numero con l'indicazione se è pari o dispari. Controllare il corretto numero di argomenti passati allo script e che l'argomento sia di tipo numerico, in caso contrario generare una condizione di errore.

## Implementazione

Script finale, provato sulla VM Rocky: [od-ev.sh](./od-ev.sh)

```text
[remoto@lab-rocky 5]$ ./od-ev.sh 5
1: dispari
2: pari
3: dispari
4: pari
5: dispari
```

Lo script fa quattro controlli in fila e solo se passano tutti parte il ciclo. Ogni controllo ha la forma `prova || { echo "messaggio" >&2; exit 1; }`: se la prova fallisce, il messaggio va sullo stderr e lo script esce con codice 1; se riesce, la lista prosegue con il controllo dopo (`&&`).

| # | Controllo | Errore se | Messaggio | Codice |
|---|---|---|---|---|
| 1 | `[[ $# == 1 ]]` | non c'è esattamente un argomento | `numero di argomenti != 1` | 1 |
| 2 | `! [[ -z $1 ]]` | l'argomento è vuoto (`''`) | `stringa vuota` | 1 |
| 3 | `! [[ $1 == *[!0-9]* ]]` | contiene un carattere che non è una cifra | `stringa non valida, ricontrollare che sia un numero` | 1 |
| 4 | `[[ $(( 10#$1 )) -gt 0 ]]` | vale zero (`0`, `00`) | `numero minore o uguale a 0` | 1 |

spiegazione:
- `nex=$0`: il nome con cui è stato lanciato lo script, da mettere davanti ai messaggi d'errore come fanno i comandi di sistema;
- `$#`: il numero di argomenti. `''` conta come argomento, per questo serve anche il controllo 2;
- `-z`: vero se la stringa ha lunghezza zero (*zero length*);
- `*[!0-9]*`: glob che corrisponde a una stringa con, da qualche parte, un carattere fuori da `0-9`. Il `!` subito dopo `[` nega l'insieme, i due `*` dicono «qualsiasi cosa prima e dopo». Il `!` davanti a `[[` rovescia il risultato: la prova riesce se quel carattere **non** c'è;
- `$(( 10#$1 ))`: valuta l'argomento in base 10. Senza `10#` un numero con lo zero iniziale verrebbe letto in ottale: `08` darebbe errore e `010` varrebbe 8;
- `-gt 0`: maggiore di zero (*greater than*); arrivati qui l'argomento è fatto solo di cifre, quindi il confronto è sicuro;
- `exit 1`: chiude lo script con un codice diverso da 0, così anche un altro script che lo chiama si accorge dell'errore;
- `for i in $(seq 1 $1)`: `seq` stampa i numeri da 1 all'argomento, uno per riga, e il ciclo li prende uno alla volta;
- `((i % 2))`: il resto della divisione per 2. `(( ))` è vero quando il risultato è diverso da zero, cioè per i dispari.

Prove:

```bash
for a in 5 0 00 08 010 abc -3 3+4 ''; do echo "== [$a]"; ./od-ev.sh "$a"; echo "codice: $?"; done
./od-ev.sh;     echo "codice: $?"
./od-ev.sh 3 4; echo "codice: $?"
```

| Argomento | Risultato | Codice |
|---|---|---|
| `5` | da 1 a 5 | 0 |
| `08` | da 1 a 8 | 0 |
| `010` | da 1 a 10 | 0 |
| `0`, `00` | `numero minore o uguale a 0` | 1 |
| `abc`, `-3`, `3+4` | `stringa non valida, ricontrollare che sia un numero` | 1 |
| `''` | `stringa vuota` | 1 |
| nessuno, `3 4` | `numero di argomenti != 1` | 1 |

## Resoconto

Ho gestito con un messaggio diverso ogni problema di validazione dell'argomento dello script. Per farlo ho dovuto spezzare ogni problema in una condizione diversa e ho preferito usare le liste di comandi con gli operatori `&&` e `||` avendo preso già manualità con la sintassi normale if;then;else.
Poiché con una regex avrei potuto rifiutare tutti gli errori insieme e preferivo spezzarli per il motivo che ho detto sopra, ho usato al posto della regex `[[ $1 =~ ^[1-9][0-9]*$ ]]` («una cifra da 1 a 9, poi zero o più cifre, dall'inizio alla fine») un glob. 
Con un glob di base non si può dire «una o più cifre», perché ogni `[0-9]` vale un solo carattere e `*` vuol dire «qualsiasi cosa», non «ripeti il precedente». Allora ho ribaltato la condizione: invece di descrivere la stringa giusta descrivo quella sbagliata, cioè una stringa che contiene da qualche parte un carattere che non è una cifra (`*[!0-9]*`).

Ho trovato un errore nascosto: all'interno del comando `[[ ]]` durante la valutazione delle espressioni, se l'argomento è un numero che inizia con zero, questo viene considerato in base ottale. Invece di eliminare direttamente il caso, ho forzato la base 10 con la forma `base#n` dell'aritmetica di bash: `$(( 10#$1 ))`. 

Approfondimento: [Condizioni, modelli e trappole](../../../studio/05-shell/condizioni-modelli.md)
