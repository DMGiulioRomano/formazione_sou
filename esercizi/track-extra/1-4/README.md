# Esercizi 1-4 track extra

Assegnato da: Paolo il 2026-11-03. Consegna: 2026-11-03.

## esercizio 1

### Consegna

Touch: Illustrare almeno 2 casi in cui il comando touch può generare una condizione di errore.

### Implementazione

touch resituisce errore se:
- uso come argomento di input un file con un path in cui ci sono cartelle non esistenti (es. `touch cartella_insesistente/file.acaso`);
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

Script finale, provato sulla VM Rocky: [script_es3](./script_es3)

```text
[remoto@lab-rocky esercizi1-4]$ ./script_es3
TRUE
```

spiegazione:
- `rpm -q kernel`: quali pacchetti pacchetti kernel installati, uno per riga 
- `sort -Vr | head -1`: li ordina attracverso il numero di versione (`-V`), e in reverse (`-r`), poi tiene solo la prima riga. Potevo anche fare solo `sort -v | tail -1`, abbastanza uguali, ma mi piaceva così;  
- `krn=$(...)`: ho messo tutto dentro una variabile così che posso usare le modifiche dovute dalla parameter expansion del punto subito sotto;
- `${krn#kernel-}`: toglie il prefisso `kernel-`, così il formato è lo stesso di `uname -r`;
- `"$(uname -r)"`: la versione del kernel che sta girando;
- `if [ ... = ... ]`: stampa `TRUE` se coincidono, oppure `FALSE`; 

### Resoconto

Cosa ho scoperto:
- Per trovare il kernel più recente devo confrontare le versioni campo per campo. All'inizio pensavo di fare un Max o qualcoda del genere, poi ho pensato che bastava ordinare la lista e prendere l'estremo.
- L'ordine in cui `rpm` stampa i pacchetti non è garantito, quindi lo impongo io con `sort` che non si sa mai.
- Avevo scritto `... | head -1 | read -r krn` e `krn` restava vuota. In bash ogni comando di una pipeline gira in una subshell, e la variabile sparisce con lei: l'ho verificato con `echo ciao | read -r x; echo "[$x]"`, che stampa `[]`. Ho risolto con `krn=$(...)`.

Prove:
- un solo kernel, in esecuzione; 
- un kernel più recente di quello che sta girando;
- lista vuota; 

Con la lista vuota e le variabili senza virgolette, `[` dava l'errore «atteso operatore unario» e poi l'`if` stampava comunque `FALSE`. Con le virgolette la variabile vuota resta un argomento e l'errore sparisce.

```bash
krn=$(rpm -q kernel | sort -Vr | head -1); if [ "$(uname -r)" = "${krn#kernel-}" ]; then echo "TRUE"; else echo "FALSE"; fi
```

Poi l'ho trasformato in script.

## esercizio 4

### Consegna

Find e Cron: Utilizzare il comando find per trovare e cancellare i file più vecchi di 30 giorni (ad esempio in /var/log o simili). Schedulare tale comando in crontab di root ogni lunedi mattina alle 6:30. Sulle manpages trovate tutte le info di cui avete bisogno.

### Implementazione

Riga nel crontab di root, da aprire con `sudo crontab -u root -e`:

```text
30 6 * * 1 find /var/log /tmp /var/tmp -type f -mtime +29 -delete
```

spiegazione:
- `30 6 * * 1`: minuto 30, ora 6, qualsiasi giorno del mese, qualsiasi mese, giorno della settimana 1 cioè lunedì (domenica è 0 o 7);
- `find /var/log /tmp /var/tmp`: `find` accetta più punti di partenza; percorsi assoluti, perché cron non parte dalla mia cartella e ha un ambiente ridotto;
- `-type f`: solo file regolari, le cartelle restano;
- `-mtime +29`: modificati da almeno 30 giorni interi (spiego sotto perché non `+30`);
- `-delete`: cancella, ed è l'ultima cosa dell'espressione.

Per controllare: `sudo crontab -u root -l` mostra la riga installata.

Cartelle scelte oltre a `/var/log`:
- `/tmp` e `/var/tmp`: file temporanei, per definizione si possono buttare. Su Rocky li pulisce anche `systemd-tmpfiles`, quindi qui la riga fa da rete di sicurezza.

Escluse:
- `/var/cache`: si rigenera, ma cancellarla a metà (es. i metadati di `dnf`) costringe a riscaricare tutto e non libera granché; meglio i comandi dei programmi, come `dnf clean all`.

### Resoconto

Ho cercato in `man find` e ho trovato `-mtime n`. Il paragrafo sugli argomenti numerici dice che `n` vuol dire esattamente n, `+n` più di n e `-n` meno di n, quindi pensavo a `+30`. Poi ho letto alla voce `-atime` che `find` divide l'età per 24 ore e scarta la parte decimale quindi un file di 30 giorni e 12 ore vale 30, e `+30` lo scarta perché 30 non è maggiore di 30. Con `+29` invece prendo i file che hanno almeno 30 giorni interi, ed è quello che intendo per «più vecchi di 30 giorni».

Per cancellare c'è l'azione `-delete`. Ho aggiunto `-type f` per non toccare le cartelle. Ho scoperto che l'ordine conta: `find` valuta l'espressione da sinistra a destra e `-delete` restituisce sempre vero. `find prova -delete -type f -mtime +29` cancella tutto prima di controllare il resto. Le azioni vanno in fondo. Prima di aggiungere `-delete` conviene lanciare il comando senza, e guardare cosa trova.

poi ho visto che per cron ci sono due manuali (`man crontab` per il comando, `man 5 crontab` per il formato del file). Da lì ho visto che ci sono cinque campi di tempo (minuto, ora, giorno del mese, mese, giorno della settimana), poi il comando; `*` vuol dire qualsiasi valore. `crontab -l` mostra il crontab, `-e` lo modifica, `-u root` sceglie l'utente; per toccare quello di root serve `sudo`. Dentro la riga invece `sudo` non serve, perché cron la esegue già come root.

Gli eserci sono stati particolarmente ostici ma fondamentali per sviluppare qualche competenza in bash e mi hanno spinto a imparare la sintassi del manuale man e a studiare il man bash che probabilmente continuerò anche prossima settimana.
