# Esercizi 1-4 track extra

Assegnato da: Paolo il 2026-11-03. Consegna: 2026-11-03.

## esercizio 1

### Consegna

Touch: Illustrare almeno 2 casi in cui il comando touch può generare una condizione di errore.

### Implementazione

touch resituisce errore se:
- uso come argomento di input un file con un path in cui ci sono cartelle non esistenti (es. `touhc cartella_insesistente/file.acaso`);
- provo a usarlo su un file sul quale non ho i permessi giusti, es i file che sono modificabili solo da root;

### Resoconto

Ho letto il manuale `man touch` e ho visto che l'argomento doveva essere un file. Così ho tentato inserendo in input qualche argomento che non poteva essere preso. la cartella essendo anch'esso un file su linux può essere data in input se esiste. se invece provo a creare un file specificando una cartella che non esiste invece di creare la cartella e il file restituirà errore.

``` bash
giuliodemattia@MBPdiGiDeMattia esercizi $ touch cartella_in
esistente/file.acaso
touch: cannot touch 'cartella_inesistente/file.acaso': No such file or directory
giuliodemattia@MBPdiGiDeMattia esercizi $
```

## esercizio 2

### Consegna

Numero Processi: Contare il numero totale di processi attualmente in esecuzione sulla propria macchina senza utilizzare utility interattive come "top".

### Implementazione

```bash
ps -A; 
```

### Resoconto

output:

```bash
line=10; a="i primi"; z="gli ultimi"; prox="processi dentro il pd -A"; echo ""; echo "$a $line $prox"; echo ""; ps -A | head -$line; echo ""; echo "$z $line $prox"; echo ""; ps -A | tail -$line; echo ""
```

``` text
i primi 10 processi dentro il pd -A

  PID TTY           TIME CMD
    1 ??         0:51.15 /sbin/launchd
   76 ??         0:28.97 /usr/libexec/logd
   77 ??         0:00.04 /usr/libexec/smd
   78 ??         0:07.58 /usr/libexec/UserEventAgent (System)
   81 ??         0:00.63 /System/Library/PrivateFrameworks/Uninstall.framework/Resources/uninstalld
   82 ??         0:38.61 /System/Library/Frameworks/CoreServices.framework/Versions/A/Frameworks/FSEvents.framework/Versions/A/Support/fseventsd
   83 ??         0:02.28 /System/Library/PrivateFrameworks/MediaRemote.framework/Support/mediaremoted
   86 ??         0:02.57 /usr/sbin/systemstats --daemon
   88 ??         0:17.92 /usr/libexec/configd

gli ultimi 10 processi dentro il pd -A

30561 ttys001    0:00.03 tmux new-session
30565 ttys003    0:00.12 -bash
30584 ttys004    0:00.06 -bash
30621 ttys004    0:00.33 nvim track-extra_1-4.md
32709 ttys005    0:00.19 -bash
33292 ttys005    0:00.00 -bash
33293 ttys005    0:00.02 pbcopy
33296 ttys005    0:00.00 ps -A
33297 ttys005    0:00.00 tail -10
33051 ttys006    0:00.07 -bash
```

Siccome l'output era abnorme, ho filtrato e riportato solo inizio e fine così mi sono anche allenato a concatenare i comandi.


## esercizio 3

### Consegna

Kernel Version: Trovare il modo (o più modi) per capire se il Kernel attualmente running è il più recente installato sulla macchina. Scrivere uno script che esegua automaticamente il controllo e risponda TRUE/FALSE.

### Implementazione

Script finale, provato sulla VM Rocky:

```bash
krn=$(rpm -q kernel | sort -Vr | head -1); if [ "$(uname -r)" = "${krn#kernel-}" ]; then echo "TRUE"; else echo "FALSE"; fi
```

| Pezzo | Cosa fa |
|-------|---------|
| `rpm -q kernel` | elenca i pacchetti kernel installati, uno per riga |
| `sort -Vr \| head -1` | li ordina come numeri di versione, dal più recente, e tiene il primo |
| `krn=$(...)` | salva il risultato in una variabile, nella shell corrente |
| `${krn#kernel-}` | toglie il prefisso `kernel-`, così il formato è lo stesso di `uname -r` |
| `"$(uname -r)"` | il kernel in esecuzione |
| `if [ ... = ... ]` | stampa `TRUE` se coincidono, altrimenti `FALSE` |

### Resoconto

Il 2026-11-05 avevo uno script con `while read` che confrontava il kernel in esecuzione con ogni riga di `rpm -q kernel`: con più kernel stampava più risposte. Il 2026-11-06 l'ho finito.

Cosa ho scoperto:

- Per trovare il kernel più recente devo confrontare le versioni campo per campo. Non serve scriverlo a mano: basta ordinare la lista e prendere l'estremo.
- L'ordine in cui `rpm` stampa i pacchetti non è garantito, quindi lo impongo io con `sort`.
- `sort` di default ordina come un dizionario: `10 9 100` diventa `10 100 9`. `sort -n` legge solo `5.14` all'inizio della versione, e a parità torna all'ordine da dizionario, quindi mette `1000` prima di `687`. `sort -V` (*version sort*) confronta campo per campo ed è quello giusto.
- Avevo scritto `... | head -1 | read -r krn` e `krn` restava vuota. In bash ogni comando di una pipeline gira in una subshell, e la variabile sparisce con lei: l'ho verificato con `echo ciao | read -r x; echo "[$x]"`, che stampa `[]`. Ho risolto con `krn=$(...)`.
- Avevo scritto `"uname -r"`: fra virgolette è solo testo, il comando parte con `$(uname -r)`.
- Per vedere cosa confrontava l'`if` ho stampato i due lati fra parentesi quadre: così si vede subito un lato vuoto.

Prove:

| Caso | Come | Risultato |
|------|------|-----------|
| un solo kernel, in esecuzione | `rpm -q kernel` vero sulla VM | `TRUE` |
| un kernel più recente di quello in esecuzione | `printf` con una riga finta `el9_9` | `FALSE` |
| lista vuota | `printf ""` | `FALSE` |

Con la lista vuota e le variabili senza virgolette, `[` dava l'errore «atteso operatore unario» e poi l'`if` stampava comunque `FALSE`. Con le virgolette la variabile vuota resta un argomento e l'errore sparisce.

Limite noto: se `rpm` non trova kernel lo script risponde `FALSE`, anche se in quel caso il controllo non è stato possibile.

## esercizio 4

### Consegna

### Implementazione

### Resoconto
