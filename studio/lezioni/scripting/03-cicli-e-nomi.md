---
tags:
  - lezione
  - scripting
aliases:
  - Scripting 03 — Cicli e nomi di file
---
# Scripting 03 — Cicli e nomi di file

I cicli servono a fare la stessa cosa molte volte, e i veri nemici sono i nomi di file: possono contenere spazi, asterischi, trattini e quasi ogni altro carattere.

```sh
./prepara.sh 03 && cd palestra/l03
```

## La mappa

| # | Problema | Stato |
|---|---|---|
| 1 | `aggiungi-suffisso.sh` — rinominare senza disastri | — |
| 2 | `riprova.sh` — insistere con criterio | — |
| 3 | `vecchi.sh` — fare pulizia guardando prima | — |

---

## Problema 1 — `aggiungi-suffisso.sh`

**Situazione.** Devi marcare tutti i file di una cartella prima di una migrazione. La cartella `dati/nomi-difficili` è lo specchio di ciò che trovi sui server veri.

> [!info] Il contesto
> **Lo scenario.** I dati di un servizio passano su un disco o un server nuovo. Prima di spostarli si marcano i file, così a migrazione finita si vede subito cosa è stato copiato e cosa no.
> - **Migrazione** (latino *migrare*, «trasferirsi»): il passaggio di dati o servizi da un sistema a un altro.
> - **Suffisso** (latino *suffixum*, «fissato sotto», cioè dopo): un pezzo aggiunto in fondo al nome.
> - **Nomi difficili**: sui server veri i file li creano programmi e persone di ogni tipo, con spazi, asterischi, trattini iniziali o accenti.
>
> **Perché conta.** Un nome spezzato in due o scambiato per un'opzione fa rinominare il file sbagliato, o ne sovrascrive un altro. Su migliaia di file non te ne accorgi.

**Compito.** `./aggiungi-suffisso.sh SUFFISSO [CARTELLA]`; la cartella predefinita è quella corrente.

- Aggiunge `.SUFFISSO` ai file normali, stampando ogni nuovo nome su una riga.
- Non entra nelle sottocartelle e non le rinomina.
- Chi ha già il suffisso resta com'è, quindi rilanciare non cambia nulla.
- Cartella vuota: nessun output e codice 0.
- Senza argomenti: codice 2.

Lavora su una copia: `cp -R dati/nomi-difficili prova`.

**Verifica.** `../../verifica.sh 03 1`

> [!question]- Indizio 1
> Nel manuale trovi `for file in $(ls ...)`. Provalo con `echo` al posto di `mv`, su `dati/nomi-difficili`. Quante voci vedi, e quanti file ci sono? Chi fa a pezzi i nomi?

> [!question]- Indizio 2
> Chi espande `*` in un `for`? A quel punto i nomi passano ancora da uno spazio di testo da spezzare?

> [!question]- Indizio 3
> Lancia il `for` sulla cartella vuota: cosa vale la variabile al primo giro? Cerca in `man bash` come far sparire un glob che non trova niente. Oppure: quale test ti protegge?

> [!question]- Indizio 4
> `mv` crede che `-inizia-col-trattino.txt` sia un'opzione. Come si dice a un comando «da qui in poi non ci sono opzioni»? In alternativa, c'è un modo di scrivere il nome che non inizi col trattino?

**Dopo.** Un `.nascosto` viene rinominato? Dovrebbe? Chi gestisce la regola dei file col punto, la shell o `ls`?

---

## Problema 2 — `riprova.sh`

**Situazione.** Il database si riavvia e per qualche secondo rifiuta le connessioni. Gli script di avvio devono ritentare, senza insistere per sempre e senza nascondere l'errore.

> [!info] Il contesto
> **Lo scenario.** Dopo un riavvio, o un aggiornamento notturno, i servizi ripartono in ordine sparso. L'applicazione parte prima che il database sia pronto, prova a collegarsi e riceve un rifiuto.
> - **Database** (inglese, «base di dati»): il programma che conserva e cerca i dati di un'applicazione, come PostgreSQL o MariaDB.
> - **Connessione rifiutata** (in inglese *connection refused*): la risposta di una macchina su cui, a quella porta, nessun programma sta ancora ascoltando.
> - **Script di avvio**: lo script che prepara e lancia un servizio quando la macchina si accende.
>
> **Perché conta.** Chi si arrende al primo errore lascia il servizio spento per un problema di pochi secondi. Chi insiste per sempre resta appeso e nasconde un guasto vero.

**Compito.** `./riprova.sh TENTATIVI PAUSA COMANDO [ARGOMENTI...]`

- Esegue il comando fino al successo, al massimo `TENTATIVI` volte, attendendo `PAUSA` secondi fra un tentativo e l'altro.
- Ogni fallimento scrive su stderr una riga con la parola `tentativo`, per esempio `tentativo 2/5 fallito`.
- Niente pausa dopo l'ultimo tentativo.
- Il codice finale è 0 se riesce, altrimenti quello dell'ultimo tentativo.
- Argomenti non validi o comando assente: codice 2.

Per provarlo: `./riprova.sh 5 1 dati/instabile.sh /tmp/contatore`, che riesce al terzo tentativo se il contatore parte da zero.

**Verifica.** `../../verifica.sh 03 2`

> [!question]- Indizio 1
> Il comando e i suoi argomenti sono tutti argomenti del tuo script. Se togli i primi due dalla lista, cosa resta? Quale comando del manuale sposta le variabili posizionali?

> [!question]- Indizio 2
> `riprova.sh 1 0 printf '%s\n' "a b"` deve stampare `a b` su una riga. Fra `$*`, `$@`, `"$*"` e `"$@"`, quale conserva i confini fra gli argomenti?

> [!question]- Indizio 3
> `$?` cambia dopo *ogni* comando, anche dopo un `echo`. In che punto va salvato?

**Dopo.** I sistemi veri raddoppiano la pausa a ogni tentativo. Quale problema risolve questa scelta quando riparte un server con mille client? Come la aggiungeresti?

---

## Problema 3 — `vecchi.sh`

**Situazione.** Il disco si riempie di log e cache dimenticati. Cancellare alla cieca è il modo classico di farsi male, perciò lo strumento mostra prima cosa farebbe.

> [!info] Il contesto
> **Lo scenario.** Un allarme avvisa che un disco è quasi pieno. Dentro ci sono anni di log e di file temporanei che nessuno ha mai tolto, e il responsabile chiede di liberare spazio senza perdere nulla di utile.
> - **Cache** (francese *cacher*, «nascondere»): una copia di dati tenuta da parte per riaverli in fretta. Si può cancellare, ma va ricostruita.
> - **Prova a secco** (in inglese *dry run*, «corsa asciutta»: si dice venga dalle esercitazioni dei pompieri fatte senza acqua): eseguire tutto tranne l'azione vera, per vedere cosa succederebbe.
>
> **Perché conta.** Una cancellazione non si annulla. Mostrare prima l'elenco è l'ultima occasione per accorgersi che il criterio prende anche file che servono.

**Compito.** `./vecchi.sh CARTELLA GIORNI [--cancella]`

- Cerca in profondità i file normali più vecchi di `GIORNI` giorni, in base all'ultima modifica.
- Stampa un percorso per riga, in ordine, e infine `totale: N file, M byte`.
- Solo con `--cancella` li rimuove davvero; le cartelle restano.
- Cartella inesistente: codice 1. Giorni non numerici o argomenti mancanti: codice 2.

Per l'ordine usa `LC_ALL=C sort`. Prova su `dati/vecchi`, e con `--cancella` solo su una copia fatta con `cp -pR`.

**Verifica.** `../../verifica.sh 03 3`

> [!question]- Indizio 1
> Negli appunti di [[comandi-ricerca|Comandi di ricerca]] c'è il comando giusto. `man find`: cosa significano davvero `+30`, `30` e `-30` per i test sul tempo?

> [!question]- Indizio 2
> Vuoi il totale alla fine. Se metti un ciclo dopo una pipe, le variabili sopravvivono al `done`? Prova. In quale processo gira quel ciclo? Vedi [[while-read|while read]].

> [!question]- Indizio 3
> Quel problema si aggira facendo arrivare i dati al ciclo in un altro modo: dentro `man bash`, cerca *Process Substitution*. In alternativa, cosa puoi calcolare con un solo comando prima del ciclo?

> [!question]- Indizio 4
> Come ottieni dimensione e percorso di un file senza un secondo comando per ogni file? `man find`: quali *azioni* stampano su misura?

**Dopo.** Il tuo script regge un nome che contiene un a capo? Cosa fanno `find -print0` e `read -d ''`? Cosa succede a `-mtime +30` per un file vecchio di 30 giorni e 23 ore?

---

## Diario

Domande numerate, risposte e correzioni di questa lezione.

## Sintesi

Da scrivere a lezione finita, con le tue parole.

---

← [[14-aritmetica|Lezione 14]] · ↑ [[00-percorso|Il percorso]] · → [[15-stringhe|Lezione 15]]
