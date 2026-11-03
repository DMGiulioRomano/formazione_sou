---
tags:
  - comandi
  - nota
aliases:
  - Leggere la sintassi di man
---
# Leggere la sintassi di man

**Idea guida**: la sinossi di una pagina di manuale è una piccola grammatica: dice cosa è obbligatorio, cosa è facoltativo e cosa va sostituito.

## Dove si trova un builtin

`read` è un builtin della shell (lo conferma `type read`), quindi `man read` non ne spiega il funzionamento: sul mio Mac apre la pagina generica `builtin(1)`. In zsh i builtin sono descritti tutti insieme in un'unica pagina:

```bash
man zshbuiltins
```

## Le convenzioni

| Notazione | Significato |
|-----------|-------------|
| `[ ... ]` | elemento facoltativo |
| testo sottolineato | segnaposto, da sostituire con un valore |
| `...` | l'elemento precedente può essere ripetuto |
| testo in grassetto | va scritto così com'è |

## Esempio: la sinossi di read

Da `man zshbuiltins`:

```
read [ -rszpqAclneE ] [ -t [ num ] ] [ -k [ num ] ] [ -d delim ]
     [ -u n ] [ [name][?prompt] ] [ name ... ]
```

| Parte | Come si legge | Uso |
|-------|---------------|-----|
| `[ -rszpqAclneE ]` | opzioni facoltative | `read -r` |
| `[ -t [ num ] ]` | `-t` è facoltativa, e lo è anche il suo valore | `read -t` oppure `read -t 5` |
| `[ -d delim ]` | `-d` è facoltativa, ma se c'è vuole un valore; `delim` è sottolineato, quindi va sostituito | `read -d :` |
| `[ name ... ]` | zero, uno o più nomi di variabile | `read a b c` |

Le parentesi si possono annidare: si leggono dall'esterno verso l'interno.

---

**Area:** [[mappa-comandi|Comandi]]  
**Vedi anche:** [[orientarsi-documentarsi|Orientarsi e documentarsi]] · [[while-read|Leggere righe con while read]] · [[alias-history|Alias e history]]
