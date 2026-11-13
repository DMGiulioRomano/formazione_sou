---
tags:
  - lezione
  - scripting
aliases:
  - Scripting 09 — Processi e segnali
---
# Scripting 09 — Processi e segnali

Uno script che gira di notte vive insieme ad altri processi: può sovrapporsi a se stesso, restare appeso, essere ucciso a metà. Riferimenti: *Admin Guide*, capitolo 9, e [[gestione-processi|Gestione dei processi]]. Questa è la lezione più difficile finora: i problemi 1 e 2 chiedono tempo.

```sh
./prepara.sh 09 && cd palestra/l09
```

## La mappa

| # | Problema | Stato |
|---|---|---|
| 1 | `solo-uno.sh` — mai due copie insieme | — |
| 2 | `limite.sh` — un tempo massimo | — |
| 3 | `chi-consuma.sh` — chi si mangia la memoria | — |

---

## Problema 1 — `solo-uno.sh`

**Situazione.** Il backup parte ogni ora, ma oggi ne impiega due. La copia successiva parte sopra la prima, poi un'altra ancora: il server rallenta, ogni copia dura di più, e la macchina si ferma.

> [!info] Il contesto
> **Lo scenario.** Un lavoro periodico è pensato per durare meno dell'intervallo fra un avvio e l'altro. Poi i dati crescono, o il disco rallenta, e un giorno la copia di prima è ancora in corso quando parte quella dopo.
> - **Lavoro periodico**: un comando che il sistema lancia da solo a intervalli fissi, per esempio ogni ora.
> - **Blocco** (in inglese *lock*, «serratura»): un segno condiviso che dice «qui sto lavorando io». Chi lo trova occupato non entra.
> - **Proprietario** del blocco: il processo che l'ha preso. Se muore senza liberarlo, il blocco resta **orfano**.
>
> **Perché conta.** Due copie che scrivono lo stesso archivio lo rovinano, e dieci copie che si contendono il disco fermano la macchina. Un blocco orfano, al contrario, ferma per sempre tutti i lavori successivi.

**Compito.** `./solo-uno.sh BLOCCO SECONDI` è lo scheletro di ogni lavoro periodico: prende il blocco, lavora per `SECONDI` secondi con `sleep`, lascia il blocco.

- Il blocco è una cartella `BLOCCO` con dentro un file `pid`, che contiene il PID del proprietario.
- Se un'altra copia viva ha il blocco: spiegazione su stderr e codice 1, senza toccarlo.
- Se il proprietario è morto, per esempio dopo un `kill -9`, il blocco si riprende.
- Finendo normalmente il blocco sparisce, codice 0.
- Con `SIGTERM` il blocco sparisce **subito**, senza aspettare la fine dello `sleep`, e il codice è 143.
- Se sei copie partono insieme, ne lavora una sola.
- Pochi argomenti: codice 2.

**Verifica.** `../../verifica.sh 09 1`

> [!question]- Indizio 1
> Scrivi «se non esiste, crealo» come due comandi. Cosa succede se due processi eseguono il primo nello stesso istante? Serve una singola operazione che crei e fallisca se esiste già. Fra i comandi per le cartelle, quale fallisce se il nome c'è già?

> [!question]- Indizio 2
> Le uscite sono tante e un segnale può arrivare ovunque. Hai già usato il comando che registra la pulizia. Copre `SIGTERM` da solo? Cosa significa 143, cioè 128 + quanto?

> [!question]- Indizio 3
> Il tuo gestore di `SIGTERM` parte solo quando finisce `sleep 30`? Bash aspetta il comando in primo piano prima di occuparsi di un segnale. Se `sleep` gira in sottofondo, cosa fa la shell mentre aspetta, e quale comando interrompe l'attesa?

> [!question]- Indizio 4
> Come chiedi al kernel se un PID è vivo senza fargli nulla? `man 2 kill`: cosa succede col segnale numero 0? E se il file `pid` è ancora vuoto perché l'altra copia lo sta scrivendo?

**Dopo.** Cosa fa `flock`, da `util-linux`, e perché un lock del kernel non resta mai orfano? I PID vengono riusati: quale difetto ha quindi il tuo controllo? `kill -9` può essere intercettato da `trap`?

---

## Problema 2 — `limite.sh`

**Situazione.** Un comando di rete resta appeso per sempre e blocca tutta la catena. Il comando `timeout` esiste già, ma ricostruirlo è il modo migliore per capire processi, attese e segnali. Qui non puoi usarlo.

> [!info] Il contesto
> **Lo scenario.** Molti lavori dipendono dalla rete: scaricare un file, interrogare un servizio, copiare su un'altra macchina. Se dall'altra parte nessuno risponde, il comando aspetta, e con lui tutto ciò che viene dopo.
> - **Appeso** (in inglese *hung*): un processo vivo che non avanza e non finisce.
> - **Tempo massimo** (in inglese *timeout*): la durata oltre la quale si smette di aspettare e si dichiara il fallimento.
> - **Segnale**: un avviso che il kernel consegna a un processo, per esempio «termina» o «muori subito».
>
> **Perché conta.** Un solo comando appeso blocca la catena di lavori notturni, e al mattino non è partito niente. Senza un limite, nessuno se ne accorge finché qualcuno non guarda.

**Compito.** `./limite.sh SECONDI COMANDO [ARGOMENTI...]`

- Se il comando finisce in tempo, esci **subito** col suo stesso codice.
- Se scade il tempo gli mandi `SIGTERM`; se dopo 2 secondi è vivo, `SIGKILL`. Il codice è 124.
- Argomenti con spazi intatti.
- Tempo non numerico o comando assente: codice 2.

**Verifica.** `../../verifica.sh 09 2`

> [!question]- Indizio 1
> Devono succedere due cose insieme: il comando lavora e qualcuno guarda l'orologio. Quanti processi servono? Come si avvia un processo senza aspettarlo, e dove trovi il suo PID?

> [!question]- Indizio 2
> `wait PID` restituisce il codice di quel processo. Chi aspetti, il comando o il cronometro? Se il comando finisce prima, cosa ne fai del cronometro?

> [!question]- Indizio 3
> Un comando ucciso da `SIGTERM` e uno che esce da solo con 143 danno lo stesso codice. Come fa quindi lo script principale a sapere che è stata proprio la scadenza? I due processi come si passano un'informazione?

> [!question]- Indizio 4
> Attenzione al caso in cui il comando finisce nell'istante della scadenza. Se fermi il cronometro mentre sta `sleep`, il suo figlio `sleep` che fine fa? Cosa succede se uccidi prima quel figlio?

**Dopo.** Se `COMANDO` crea dei figli, il tuo `SIGKILL` li colpisce? Cosa sono i gruppi di processi, e cosa fa `timeout` vero? Leggi `man timeout`, poi guarda con `ps` cosa resta dopo il tuo script.

---

## Problema 3 — `chi-consuma.sh`

**Situazione.** La macchina è al limite. Vuoi sapere non quale processo, ma quale *utente* sta consumando la memoria, e se ci sono zombie.

> [!info] Il contesto
> **Lo scenario.** Su un server condiviso da molti utenti, per esempio quello di un laboratorio universitario o di un gruppo di sviluppo, la memoria finisce e tutto rallenta. Prima di agire vuoi sapere chi sta usando le risorse, per parlarne con la persona giusta.
> - **Al limite**: con la memoria quasi tutta occupata, il kernel inizia a spostare dati sul disco, e tutto diventa lento.
> - **Zombie** (dalle credenze haitiane, il morto che cammina): un processo già terminato che compare ancora nell'elenco dei processi.
>
> **Perché conta.** Il processo che consuma di più non dice tutto: cento processi piccoli dello stesso utente pesano più di uno grande. E gli zombie vanno contati a parte, perché raccontano un problema diverso.

**Compito.** `ps -eo user,pid,stat,pcpu,pmem,comm | ./chi-consuma.sh [N]` legge da stdin, e `N` è 3 di norma. Stampa `utente memoria processi`, con un decimale, dalla memoria più alta. L'ultima riga conta gli zombie, cioè i processi il cui stato inizia con `Z`. `N` non numerico: codice 2.

```sh
./chi-consuma.sh < dati/ps.txt
```

```text
mario 24.5 2
postgres 22.5 2
root 3.0 3
zombie: 2
```

**Verifica.** `../../verifica.sh 09 3`

> [!question]- Indizio 1
> La prima riga è un'intestazione. Quale variabile di `awk` dice a che riga sei? Hai già sommato per categoria nella lezione 05.

> [!question]- Indizio 2
> Lo stato di un processo può essere `Z` o `Z+`. Come scrivi «inizia con»?

> [!question]- Indizio 3
> Vuoi tagliare a `N` le righe degli utenti, ma lasciare sempre la riga degli zombie. Se fai tutto in un solo `awk | sort | head`, cosa succede a quella riga? Lo stdin si può leggere due volte?

**Dopo.** Uno zombie consuma memoria? Si può uccidere? Cosa bisogna fare, e a chi? Quanto vale il `%MEM` di `ps`, e perché la somma delle percentuali può superare la memoria reale? Pensa alle librerie condivise.

---

## Diario

Domande numerate, risposte e correzioni di questa lezione.

## Sintesi

Da scrivere a lezione finita, con le tue parole.

---

← [[08-backup|Lezione 08]] · ↑ [[00-percorso|Il percorso]] · → [[20-processi-avanzati|Lezione 20]]
