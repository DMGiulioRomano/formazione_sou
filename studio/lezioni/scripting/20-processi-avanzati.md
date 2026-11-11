---
tags:
  - lezione
  - scripting
aliases:
  - Scripting 20 — Processi avanzati
---
# Scripting 20 — Processi avanzati

Nella lezione 09 hai messo in fila processi, segnali e lock; nella 12 hai visto chi è figlio di chi. Qui li fai lavorare insieme: tanti lavori in parallelo ma non troppi, un processo che segue un file che cambia sotto di lui, e `/proc`, la finestra del kernel su ogni processo vivo. Si fa dopo le lezioni 09 e 12. Riferimenti: [[gestione-processi|Gestione dei processi]], `man 5 proc`.

```sh
./prepara.sh 20 && cd palestra/l20
```

## La mappa

| # | Problema | Stato |
|---|---|---|
| 1 | `paralleli.sh` — tanti lavori, al massimo N insieme | — |
| 2 | `segui-log.sh` — allarmi da un log che ruota | — |
| 3 | `disco-fantasma.sh` — il disco è pieno ma i file non ci sono | — |
| 4 | `proc-info.sh` — un processo visto da dentro | — |
| 5 | `lancia-lungo.sh` — sopravvivere alla chiusura di SSH | — |

---

## Problema 1 — `paralleli.sh`

**Situazione.** Devi controllare cinquanta macchine e ognuna impiega dieci secondi: in fila sono otto minuti. Lanciarle tutte insieme satura la rete e il server da cui parti. Ti serve una via di mezzo.

**Compito.** `./paralleli.sh N FILE COMANDO [ARG...]` esegue `COMANDO ARG... MACCHINA` per ogni riga di `FILE`, saltando righe vuote e `#`, con al massimo `N` esecuzioni contemporanee.

- Per ogni macchina, **nell'ordine del file**, stampa `== MACCHINA` seguito da tutto ciò che il comando ha scritto, stdout e stderr insieme. L'output di due macchine non si mescola mai.
- In fondo `falliti: K`. Codice 0 se K è 0, altrimenti 1.
- `N` non intero o minore di 1, file illeggibile, pochi argomenti: codice 2.

```sh
./paralleli.sh 3 dati/macchine.txt dati/bin/controlla
```

**Verifica.** `../../verifica.sh 20 1`. Il correttore misura quanti lavori girano insieme e quanto dura tutto.

> [!question]- Indizio 1
> Come avvii un comando senza aspettarlo, e come aspetti che *uno qualsiasi* dei lavori avviati finisca? `help wait`: cosa fa l'opzione `-n`?

> [!question]- Indizio 2
> I lavori finiscono in un ordine qualunque, ma l'output va stampato nell'ordine del file. Dove lo tieni nel frattempo?

> [!question]- Indizio 3
> Ti servono i codici di tutti i lavori, anche di quelli finiti mentre aspettavi altro. Puoi aspettare un PID preciso più tardi e avere ancora il suo codice?

**Dopo.** Cosa fa `xargs -P`, e come avresti risolto con quello? Perché `parallel` di GNU esiste, se c'è `xargs`? Quanto conviene alzare `N`: dove sta il limite?

---

## Problema 2 — `segui-log.sh`

**Situazione.** Vuoi un allarme appena nel log compare un errore, senza aspettare il rapporto del mattino. Di notte però `logrotate` rinomina il file e ne crea uno nuovo: il tuo controllo continua a guardare quello vecchio e non vede più nulla.

**Compito.** `./segui-log.sh FILE REGEX [MAX]`:

- Ignora ciò che c'è già nel file e segue solo le righe nuove. Per ogni riga che corrisponde all'espressione ERE stampa `ALLARME: riga`, subito, non quando il buffer si riempie.
- Se il file viene rinominato e ricreato, continua sul file nuovo.
- Con `MAX`, dopo `MAX` allarmi termina con codice 0, entro un paio di secondi, e **non lascia processi attivi**.
- File inesistente o argomenti sbagliati: codice 2.

**Verifica.** `../../verifica.sh 20 2`. Il correttore scrive nel file, lo ruota e controlla che non resti nulla in esecuzione.

> [!question]- Indizio 1
> `man tail`: che differenza c'è fra `-f` e `-F`? Quale segue il *nome* e quale il *descrittore*? E come parti dalla fine senza mostrare le righe vecchie?

> [!question]- Indizio 2
> Gli allarmi arrivano a blocchi, o solo quando il processo finisce? Rileggi il «Dopo» del problema 2 della lezione 18: cosa fa un programma che scrive in una pipe invece che sul terminale? `man grep`, cerca *line-buffered*.

> [!question]- Indizio 3
> Hai raggiunto `MAX`, ma lo script non termina. Chi è rimasto vivo, e quando se ne accorgerebbe che nessuno lo ascolta più? Rileggi `SIGPIPE` nella lezione 12. Puoi fermarlo tu, se conosci il suo PID?

**Dopo.** Che cosa fa `logrotate` con `create` e con `copytruncate`, e quale dei due il tuo script regge? Cosa usa `journalctl -f` al posto di questo meccanismo? Cos'è `inotifywait`?

---

## Problema 3 — `disco-fantasma.sh`

**Situazione.** `df` dice che `/var` è pieno al 100%. `du` sulla stessa cartella dice 2 GB su 20. Qualcuno ha cancellato un log enorme mentre un processo lo teneva aperto: il nome è sparito, lo spazio no, finché il processo non lo chiude.

**Compito.** `./disco-fantasma.sh` cerca, fra i processi che puoi leggere, i file cancellati ma ancora aperti, e stampa:

```text
PID COMANDO BYTE PERCORSO
...
totale: BYTE
```

- Una riga per ogni coppia processo e file, anche se il processo lo ha aperto più volte, dal più grande. `COMANDO` è il nome del processo, `PERCORSO` quello che aveva il file.
- I processi che non puoi leggere si saltano in silenzio.
- La radice di `/proc` si può cambiare con la variabile `PROC`, per le prove.
- Codice 0 se ha trovato qualcosa, 1 se no, senza stampare nulla.

**Verifica.** `../../verifica.sh 20 3`

> [!question]- Indizio 1
> `ls -l /proc/$$/fd`: cosa sono quelle voci? Prova ad aprire un file con `exec 3>prova`, a cancellarlo e a guardare di nuovo.

> [!question]- Indizio 2
> Come leggi la destinazione di un link simbolico? E come conosci la dimensione del file a cui punta, anche se non ha più un nome? `man stat`, cerca `-L`.

> [!question]- Indizio 3
> Dove sta il nome di un processo in `/proc`, senza lanciare `ps`?

**Dopo.** Come recuperi il contenuto di quel file? Prova `cp /proc/PID/fd/N salvato`. Come liberi lo spazio senza uccidere il processo? Cosa fa `lsof +L1`, e perché `: > /proc/PID/fd/N` funziona?

---

## Problema 4 — `proc-info.sh`

**Situazione.** Un processo si comporta in modo strano e `ps` taglia la riga di comando. Vuoi vedere con precisione gli argomenti che ha ricevuto, chi l'ha lanciato, in quale cartella gira e con quale ambiente.

**Compito.** `./proc-info.sh PID [VARIABILE]` stampa:

```text
pid: 4321
comando: copia-notte
argomenti: [/bin/bash] [/usr/local/bin/copia-notte] [a b] []
genitore: 4300
utente: mario
cartella: /srv/dati
```

- Gli argomenti fra quadre, uno per uno, anche vuoti o con spazi, come li ha ricevuti il processo.
- `utente` è il nome dell'utente reale; `cartella` la cartella corrente del processo.
- Con `VARIABILE` aggiunge `VARIABILE=valore` preso dall'ambiente del processo, oppure esce con 1 se lì non c'è.
- PID inesistente o argomenti sbagliati: codice 2.

**Verifica.** `../../verifica.sh 20 4`

> [!question]- Indizio 1
> `cat /proc/$$/cmdline` sembra una parola sola. Guardalo con `od -c`: cosa separa gli argomenti? Perché proprio quel carattere?

> [!question]- Indizio 2
> `x=$(< /proc/$$/cmdline)`: cosa dice bash, e cosa resta in `x`? Come leggi dati separati da quel carattere senza perderli? L'hai fatto nella lezione 16.

> [!question]- Indizio 3
> In `/proc/PID/status` ci sono `PPid` e `Uid`. Quale dei numeri di `Uid` è l'utente reale? Come passi da un numero a un nome, anche per gli utenti che non stanno in `/etc/passwd`?

**Dopo.** Perché l'ambiente in `/proc/PID/environ` non cambia quando il processo fa `export`? Chi può leggere `environ` di un processo altrui, e cosa significa per le password passate nelle variabili? Cosa mostrano `/proc/PID/limits` e `/proc/PID/maps`?

---

## Problema 5 — `lancia-lungo.sh`

**Situazione.** Lanci una copia di 3 ore via SSH. Il Wi-Fi cade, la sessione si chiude, e la copia muore con lei. Il giorno dopo un collega ti dice «dovevi usare `nohup`», un altro «dovevi usare `tmux`».

**Compito.** `./lancia-lungo.sh COMANDO [ARG...]` avvia il comando in modo che sopravviva alla chiusura del terminale, e torna subito:

- Stampa solo il PID del comando, ed esce con 0 entro un secondo.
- Il comando non legge dal terminale (il suo stdin è `/dev/null`), e stdout e stderr finiscono, in aggiunta, nel file indicato da `LOG`, predefinito `./lungo.log`.
- Il comando non fa parte della sessione da cui l'hai lanciato: un `SIGHUP` mandato a quella sessione non lo raggiunge.
- Nessun argomento: codice 2.

**Verifica.** `../../verifica.sh 20 5`. Poi provalo davvero sulla VM: lancia `./lancia-lungo.sh sleep 600` via SSH, chiudi la finestra, rientra e cerca il processo.

> [!question]- Indizio 1
> Chi manda `SIGHUP` quando chiudi un terminale, e a chi? Cerca *SIGHUP* in `man bash` e *session* in `man 7 credentials`.

> [!question]- Indizio 2
> `nohup` ignora il segnale; un altro comando di `util-linux` crea una sessione nuova. Quale, e che differenza fa?

> [!question]- Indizio 3
> Come ottieni il PID del comando se a lanciarlo è un altro programma, che magari fa a sua volta `fork`? Esiste un'opzione che lo fa aspettare, o puoi far scrivere il PID al comando stesso, prima di `exec`.

**Dopo.** Cosa fa `disown`? Cosa farebbe `systemd-run --user`, e cosa offrono `tmux` e `screen` che questo script non offre? Cosa fa `loginctl enable-linger`, e perché su Rocky un processo dell'utente può morire al logout anche con `nohup`?

---

## Diario

Domande numerate, risposte e correzioni di questa lezione.

## Sintesi

Da scrivere a lezione finita, con le tue parole.

---

← [[09-processi-segnali|Lezione 09]] · ↑ [[00-percorso|Il percorso]] · → [[10-automazione|Lezione 10]]
