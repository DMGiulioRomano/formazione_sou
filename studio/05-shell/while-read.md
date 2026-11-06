---
tags:
  - shell
  - nota
aliases:
  - Leggere righe con while read
---
# Leggere righe con while read

**Idea guida**: `while read` elabora un output una riga per volta. Il `while` non itera su nulla: riesegue un comando finché questo riesce, e la posizione nell'input la tiene la [[pipe|pipe]].

```bash
comando | while read -r l; do
  echo "$l"
done
```

## Come funziona il ciclo

`read` non è un iterabile: è un comando normale, che a ogni esecuzione legge una sola riga dallo stdin e termina.

1. `read` preleva i byte fino al primo `\n` e mette il testo in `l`, senza il `\n`.
2. Se ha letto una riga esce con codice 0, quindi il `while` esegue il corpo e ricomincia.
3. A fine input esce con un codice diverso da 0, e il ciclo si ferma.

Tutti i `read` leggono dalla stessa pipe, dove ciò che è già stato letto è consumato. Si vede anche senza ciclo:

```bash
printf 'a\nb\nc\n' | { read x; read y; echo "$x $y"; }    # a b
```

In Python, la pipe somiglia all'iteratore e `read` a una chiamata a `next()`. La differenza è che `next()` segnala la fine con un'eccezione, `read` con il codice di uscita.

```python
stream = iter(["a", "b", "c"])  # la pipe
x = next(stream)                # read x -> "a"
y = next(stream)                # read y -> "b"
```

## Le opzioni di read

| Scrittura | Effetto |
|-----------|---------|
| `read l` | interpreta `\` come carattere di escape |
| `read -r l` | tratta `\` come un carattere normale |
| `IFS= read -r l` | conserva anche gli spazi all'inizio e alla fine della riga |

Il manuale di zsh riassume `read` in una frase: *Read one line and break it into fields*. Legge una riga e la rompe in campi, usando come separatori i caratteri di `$IFS`. La sintassi completa è spiegata in [[leggere-man|Leggere la sintassi di man]].

Con una sola variabile la riga non viene spezzata in parole, ma senza `IFS=` perde gli spazi ai bordi. Con più variabili (`read a b`) viene divisa.

## read in fondo a una pipeline

In bash ogni comando di una pipeline gira in una **subshell** separata (`man bash`, sezione *Pipelines*). La variabile che `read` assegna esiste solo lì e sparisce quando la subshell termina:

```bash
echo ciao | read -r x; echo "[$x]"    # []
```

Dentro un `while read` non si nota, perché il corpo del ciclo gira nella stessa subshell. Dopo la pipeline, invece, la variabile è vuota.

Per salvare in una variabile l'output di un comando, si usa la sostituzione di comando, che gira nella shell corrente:

```bash
x=$(echo ciao); echo "[$x]"           # [ciao]
```

## read contro head

Entrambi riconoscono le righe dal `\n`, ma leggono in modo diverso:

- **`read`** su una pipe preleva un byte alla volta. Deve fermarsi subito dopo il `\n`, perché i byte prelevati non si possono rimettere e il `read` successivo resterebbe senza.
- **`head`** legge a blocchi e cerca i `\n` nel blocco, che è più efficiente.

## Esempio completo

Questo comando elenca i link simbolici nella home con la loro destinazione:

```bash
find ~ -maxdepth 2 -type l -not -path '*/Library/*' 2>/dev/null |
  while read -r l; do echo "$l -> $(readlink "$l")"; done |
  head -60
```

| Parte | Significato |
|-------|-------------|
| `-maxdepth 2` | scende di una sola sottocartella: livello 1 `~/x`, livello 2 `~/x/y` |
| `-type l` | tiene solo i link simbolici |
| `-not -path '*/Library/*'` | scarta i path che contengono `/Library/`, con la L maiuscola e come componente del path |
| `2>/dev/null` | nasconde gli errori di `find`, non quelli degli altri comandi della pipeline |
| `$(readlink "$l")` | inserisce nella stringa la destinazione del link, così come è scritta nel link: relativa o assoluta |
| `head -60` | limita a 60 righe l'output di tutto il ciclo |

## Glob senza corrispondenze: zsh e bash

Un glob che non trova nulla si comporta in modo diverso secondo la shell:

```bash
ls -d /tmp /nonesiste/* 2>/dev/null
```

- **zsh**: errore `no matches found` e `ls` non parte nemmeno, anche se `/tmp` esiste. Il messaggio viene dalla shell e `2>/dev/null` non lo nasconde.
- **bash**: passa il pattern così com'è a `ls`, che mostra `/tmp` e segnala l'altro path come errore, nascosto da `2>/dev/null`.

Quindi in zsh un `ls` senza risultati non dimostra che le cartelle non esistono.

---

**Area:** [[mappa-shell|Shell]]  
**Vedi anche:** [[pipe|Come funziona una pipe]] · [[redirezione-pipe|Redirezione e pipe]] · [[tipi-di-shell|Tipi di shell e su]] · [[comandi-ricerca|Comandi di ricerca]] · [[manipolare-testo|Manipolare testo]] · [[leggere-man|Leggere la sintassi di man]]
