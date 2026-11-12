---
tags:
  - shell
aliases:
  - Fare debug di uno script
---
# Fare debug di uno script

## Chi ha scritto il messaggio d'errore

Il primo indizio è il prefisso. Gli errori di bash cominciano con `nome-script: riga N:`. Se il messaggio comincia in un altro modo, l'ha stampato un comando lanciato dallo script. Esempio: `file = $1` non è un'assegnazione, ma il comando `/usr/bin/file` con l'argomento `=`, e il messaggio `=: cannot open '='` è suo.

## `bash -x`

`-x` è la forma breve di `set -o xtrace` (*execution trace*). Per ogni comando semplice la shell stampa una riga:

- **dopo** l'espansione: variabili sostituite, virgolette tolte, parole divise;
- **prima** dell'esecuzione;
- su **stderr**, quindi `2>/dev/null` la nasconde e `>/dev/null` la lascia;
- preceduta dal valore di `PS4`, di default `+ ` (un `+` in più per ogni livello di annidamento).

Mostra cosa riceve davvero il comando. Gli apici nella traccia li aggiunge bash per segnare i confini: `+ echo 'ciao mondo'` vuol dire un solo argomento. Per un pezzo di script basta `set -x` … `set +x`.

## `shellcheck`

È un analizzatore statico: legge il testo senza eseguirlo e segnala gli errori tipici con un codice `SCnnnn`, spiegato su `https://www.shellcheck.net/wiki/SCnnnn`. Trova anche righe sintatticamente valide ma quasi certamente sbagliate, come gli spazi intorno a `=` (SC2283) o `var=cmd` invece di `var=$(cmd)` (SC2037).

Non vede ciò che non sta nel testo. I permessi, per esempio, sono metadati del file, nell'inode, e si leggono con `ls -l` o `stat`, non con `cat`.

Vedi anche: [[eseguire-uno-script|Eseguire uno script]], [[codici-di-uscita|Codici di uscita e set -e]].
