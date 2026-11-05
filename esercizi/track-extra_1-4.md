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

Innanzitutto cerco quale comando devo usare per sapere tutti i kernel che ho installati sulla mia macchina. 
Se non sbaglio si faceva con `uname -a`. Poi devo vedere 

**Stato dello script: non finito.** Ultima versione provata sulla VM Rocky, con risposta `TRUE`:

```bash
rpm -q kernel | while read -r krn; do if [ "$(uname -r)" = "${krn#kernel-}" ]; then echo TRUE; else echo FALSE; fi; done
```

Funziona solo con un kernel installato, come sulla VM. Con più kernel stampa una riga per kernel e non stabilisce quale sia il più recente.

### Resoconto

Sospeso il 2026-11-05.

Punti chiariti:

- `uname -r` dà il kernel in esecuzione: non cambia se installo un kernel nuovo senza riavviare.
- `rpm -q kernel` interroga il database di `rpm` su disco e dà i kernel installati.
- Le due stringhe differiscono per il prefisso `kernel-`, che tolgo con la parameter expansion `${krn#kernel-}`. L'espansione lavora su una variabile, quindi prima devo salvarci l'output del comando.
- `if` decide in base al codice di uscita di `[ ... ]`: `0` se il test riesce, `1` se fallisce.

Da fare:

1. Ricavare dalla lista di `rpm -q kernel` un solo valore, il kernel più recente. Prima lo descrivo a parole: che operazione farei a mano su quelle righe?
2. Confrontare il kernel in esecuzione con quel valore e stampare una sola risposta, `TRUE` o `FALSE`.
3. Provare il caso con due kernel: le simulazioni con `printf` si sono spezzate nell'incolla, quindi non ho ancora un risultato valido. Se si spezza ancora, metto la prova in un file.

## esercizio 4

### Consegna

### Implementazione

### Resoconto
