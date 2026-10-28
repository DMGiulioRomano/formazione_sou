---
tags:
  - comandi
  - nota
aliases:
  - Comandi di ricerca
---
# Comandi di ricerca

Ecco le differenze principali tra questi cinque comandi Linux. La differenza fondamentale sta nel **dove** cercano (nel database, nel disco o nella memoria della shell) e **cosa stanno cercando** (file generici o comandi eseguibili).
Ecco un riepilogo rapido per capire quale scegliere al volo:

Comando	| Cosa cerca?	| Come lo cerca?	| Velocità	| Nota chiave
| -------------- | -------------- | -------------- | -------------- | -------------- |
which |	Solo file eseguibili nel $PATH.	| Scansiona le cartelle dei comandi. | Molto veloce | Trova cosa partirebbe se digitassi quel comando.
whereis	| Eseguibili, manuali e sorgenti di un comando.	| Cerca in percorsi standard hardcodati.	| Molto veloce	| Ignora i file personali, si concentra sui programmi.
type	| La natura di un comando.	| Interroga direttamente la Shell (bash/zsh).	| Istantaneo	| Dice se un comando è un alias, una funzione o un file.
locate	| Qualsiasi file o cartella nel sistema.	| Interroga un database precompilato.	| Velocissimo	| Non è in tempo reale (richiede updatedb).
find	| Qualsiasi file o cartella nel sistema.	| Scansiona il disco fisicamente in tempo reale.	| Più lento	| È il più potente, filtra per data, dimensione, permessi.
whence	| Come la shell interpreta un comando (Esclusivo Zsh/Ksh).	| Interroga la memoria e il PATH di Zsh.	| Istantaneo	| È il "padre" del which di macOS; molto flessibile.


Nel dettaglio: come funzionano e quando usarli


## 1. which (L'esploratore del PATH)

Cerca il file binario (l'eseguibile) di un comando, ma lo fa guardando esclusivamente dentro le cartelle elencate nella tua variabile d'ambiente $PATH (ovvero dove il sistema va a cercare i comandi).
• Uso ideale: Quando vuoi sapere l'esatto percorso del programma che stai per lanciare.
• Esempio: which python → /usr/bin/python

In Zsh, which non è un programma esterno separato, ma è un comando interno della shell (un alias implicito o equivalente del comando whence -c). Essendo integrato, which ha accesso completo a tutto ciò che la shell conosce in quel momento, inclusi:
• Gli alias attivi.
• Le funzioni di shell personalizzate.
• I comandi integrati della shell stessa (built-ins).

Quando digiti which comando, Zsh controlla prima di tutto se hai definito quel nome come alias. Se lo trova, ti restituisce la stringa dell'alias (es. comando: aliased to...). Se non trova alias, passa a cercare l'eseguibile nel $PATH.

Usa l'opzione -p: In Zsh, forza which a fare una ricerca puramente basata sul PATH.bash:

which -p nome_comando

## 2. whereis (Il cercatore di pacchetti)

Va oltre l'eseguibile. Cerca in un elenco di cartelle standard del sistema per trovare il binario, le pagine di manuale (man pages) e i codici sorgente di un programma.
• Uso ideale: Quando vuoi studiare un comando o leggerne il manuale e vuoi sapere dove sono salvati i file correlati.
• Esempio: whereis ls → ls: /bin/ls /usr/share/man/man1/ls.1.gz

## 3. type (L'analizzatore della Shell)

Questo non è un programma a sé stante, ma un comando integrato nella tua shell (shell builtin). Non cerca file sul disco, ma dice alla shell: "Dimmi che cos'è questo nome che ho digitato".
• Uso ideale: Per capire se un comando è un programma vero e proprio, un trucco (alias), o una funzione integrata nella shell.
• Esempio: type ll → ll is aliased to ls -l

## 4. locate (L'archivista)

Come abbiamo visto, cerca qualsiasi file nel sistema che corrisponda al nome inserito, sfruttando un indice (database) aggiornato periodicamente.
• Uso ideale: Quando ti ricordi il nome di un file ma non hai idea di dove sia nascosto e vuoi trovarlo in un millisecondo.
• Esempio: locate ricetta.txt

## 5. find (Il detective in tempo reale)

È lo strumento più potente e flessibile. Non usa database: setaccia fisicamente il disco rigido cartella per cartella nel momento esatto in cui lo premi. Ti permette di filtrare i file in base a criteri complessi (es. "trova tutti i file .png più grandi di 10MB modificati negli ultimi 3 giorni").
• Uso ideale: Quando cerchi file creati di recente o quando devi fare ricerche mirate usando filtri avanzati.
• Esempio: find /home/utente -name "*.pdf"

## 6. whence (Il motore interno di Zsh)

È un comando integrato esclusivo delle shell Zsh (la shell predefinita di macOS) e KornShell (ksh). Rappresenta il vero "cervello" della shell: quando digiti un comando, Zsh usa internamente whence per capire se deve eseguire un'azione integrata, un alias creato da te, una funzione o un programma installato sul disco.
• Uso ideale: Su macOS è lo strumento definitivo per fare diagnostica sui comandi, perché ti permette di bypassare gli alias (con il flag -p) o di vedere ogni singola sovrapposizione di nome presente nel sistema (con il flag -a).
• Esempio: whence -a ls → Può mostrarti sia l'alias ls='ls -G' sia il percorso reale /bin/ls.

## find nella lezione sui comandi

| Comando | Significato |
|--------|-------------|
| `find / -iname "ciao"` | Cerca in tutto il filesystem i file chiamati `ciao`, ignorando maiuscole/minuscole. |

**Esempio**
```bash
find /home -iname "*.pdf"
```

---

**Area:** [[mappa-comandi|Comandi]]  
**Fonte:** [[lezione-comandi-essenziali|Lezione — Comandi essenziali]]  
**Vedi anche:** [[path|PATH]] · [[alias-history|Alias e history]] · [[file-directory|File e directory]] · [[dpkg-apt|dpkg e APT]]
