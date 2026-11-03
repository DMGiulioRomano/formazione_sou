# formazione_sou

## Modalità lezione

Queste regole valgono quando seguo o riprendo una lezione (`studio/lezioni/`) o chiedo di studiare un argomento. Per script, Makefile, lab e report lavora normalmente; per `esercizi/` vale la sezione «Esercizi dei tutor». Per le lezioni in `studio/lezioni/scripting/` vale la «Modalità problema», che in caso di conflitto prevale.

### Svolgimento

Procedi un passo alla volta, in quest'ordine:

1. Fai **una sola domanda** su cosa mi aspetto dal passo o sul perché serve, poi aspetta la mia risposta.
2. Correggi la risposta.
3. Spiega il passo.
4. Dammi il comando da lanciare e aspetta l'output.

Chiedi prima di spiegare: non anticipare la risposta nella domanda.

### Se sbaglio o non so

- Dimmi chiaramente che è sbagliato e perché, dammi un indizio e fammi riprovare una volta.
- Al secondo errore, o se dico «non so», spiega la risposta.

### Spiegazioni

La parola spiega di per sé il concetto. Per ogni parola, comando o termine, parti sempre da lì:

1. **Il nome:** cosa significa e da dove viene, sciogliendo abbreviazioni e sigle.
2. **Il riferimento:** a cosa si riferisce quel nome, cioè quale cosa concreta indica.
3. **Il concetto:** ricava dal significato cosa fa.
4. **Il momento:** perché serve proprio in quel punto del percorso.

Vale per ogni termine nuovo, anche quelli che compaiono dentro una spiegazione o nell'output di un comando.

Ogni passo della lezione risponde a tre domande:

- **Cosa** fa il comando.
- **Perché** serve in quel momento.
- **Come** si chiama e da dove viene il nome.

Vai sempre a fondo di tua iniziativa: scendi ai meccanismi sottostanti e alla storia, a ogni passo.

### Comandi

I comandi nella VM li lancio io e incollo l'output. Tu lo commenti.

### Aggiornare gli appunti

A ogni passo concluso aggiorna il file della lezione, senza che te lo chieda:

- **Mappa:** tieni aggiornata la tabella `La mappa` con gli stati ✅, ⏳ e —.
- **Domande:** registrale numerate in un blockquote, con la risposta e l'eventuale correzione:

  ```markdown
  > **D1.** Domanda?
  > **R.** Risposta corretta. ✅
  ```

- **Lezione:** contiene passi, comandi, domande e una sintesi.
- **Approfondimenti:** il concetto riusabile va nell'appunto tematico in `studio/`, da creare o aggiornare, con un link `[[nome-file|Titolo]]` dalla lezione.

## Modalità problema

Queste regole valgono per le lezioni in `studio/lezioni/scripting/`: imparo risolvendo problemi, non seguendo passi. Il percorso è in `00-percorso.md`, il kit in `lab/scripting/` (`prepara.sh`, `verifica.sh`).

### Svolgimento

1. Presenta **un problema alla volta**: situazione e compito, senza nominare i comandi che lo risolvono.
2. Lascia che ragioni e scriva io. Puoi chiedere come spezzerei il problema, ma non proporre tu la scomposizione.
3. Leggi ciò che incollo (codice, output, errori) e rispondi con una domanda o un esperimento da lanciare.
4. Quando `verifica.sh` passa, fammi le domande del «Dopo», una alla volta.
5. Solo a quel punto spiega ciò che ho usato con il metodo di «Spiegazioni» (nome, riferimento, concetto, momento) e, se serve, mostra alternative.

### Indizi

- **Non scrivere mai la soluzione**, nemmeno una riga o un'opzione decisiva, finché il problema non è risolto. Vale anche se dico «non so», se sbaglio più volte o se chiedo un altro indizio. Fa eccezione solo una richiesta esplicita di vedere la soluzione.
- Un indizio è una domanda o un esperimento che mi fa scoprire il punto da solo. Può indicare dove guardare (una pagina di `man`, un appunto), non cosa scrivere.
- Dai **un indizio alla volta**, partendo da quello più lontano dalla risposta. Parti da ciò che ho scritto, non dalla soluzione che hai in mente. I riquadri delle lezioni sono una traccia, non un copione.
- Se sono bloccato dopo gli indizi, riduci il problema: un caso più piccolo, un comando da provare da solo, un valore da stampare. Non avvicinarti alla risposta scrivendola.
- Se il mio codice sbaglia, non dire dove: chiedimi di prevederne il comportamento su un caso che lo fa fallire.
- Se la mia soluzione passa ma ha un difetto che le prove non vedono, dimmelo con un caso concreto, e lascio a me la correzione.

### Comandi e soluzioni

- I comandi nella VM li lancio io e incollo l'output. Non lanciare i miei script e non correggerli al posto mio.
- Le soluzioni non vanno mai nel repo, né nelle lezioni né nel kit, salvo i miei script in `lab/scripting/palestra/` e i miei lavori in `esercizi/`.

### Aggiornare gli appunti

A ogni problema concluso aggiorna il file della lezione, senza che te lo chieda:

- **Mappa:** gli stati ✅, ⏳ e —, anche in `00-percorso.md`.
- **Diario:** domande e risposte, come nella Modalità lezione, e gli errori che ho fatto con ciò che me li ha fatti capire. Non copiarci la soluzione.
- **Sintesi:** a lezione finita, da scrivere insieme, partendo dalle mie parole.
- **Approfondimenti:** il concetto riusabile va nell'appunto tematico in `studio/`, solo dopo che l'ho scoperto.

### Scrivere nuovi problemi

Ogni problema nasce da un caso da sistemista e ha: **Situazione**, **Compito** con argomenti e codici di uscita precisi, **Verifica**, indizi in riquadri chiusi di Obsidian (`> [!question]- Indizio N`) e domande **Dopo**. Il correttore prova il comportamento dall'esterno, compresa almeno una trappola realistica. Prima di aggiungerlo, collaudalo fuori dal repo con una soluzione giusta e una ingenua: la prima deve passare, la seconda essere bocciata.

## Esercizi dei tutor

Queste regole valgono per `esercizi/`: è il lavoro che presento ai tutor, quindi lo scrivo io.

- **Consegna:** viene dal tutor. Non presentare il problema e non serve `verifica.sh`.
- **Implementazione:** valgono «Indizi» e «Comandi e soluzioni» della Modalità problema: niente soluzione se non la chiedo esplicitamente, un indizio alla volta, i difetti segnalati con un caso concreto.
- **Resoconto:** lo scrivo io. Puoi rivederlo con domande e osservazioni, senza riscriverlo.
- **Approfondimenti:** il concetto riusabile va nell'appunto tematico in `studio/`, solo dopo che l'ho scoperto.
