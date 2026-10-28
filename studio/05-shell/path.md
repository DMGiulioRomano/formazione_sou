---
tags:
  - shell
  - nota
aliases:
  - PATH
---
# PATH

- PATH: è una stringa e contiene percorsi separati sa :
è variabile d'ambiente

- path: è l'array corrispondente. 

sono sincronizzate automaticamente.

siccome spesso si fanno cose come 

```bash
EXPORT PATH="$HOME/.local/bin:$PATH"
```

spesso si duplicano gli elementi. 

Così è utile usare **typeset -U path** che rende path (legato a PATH) automaticamente deduplicato.
In questo caso bisogna usare path come array!

```bash
path=("$HOME/.local/bin" $path)
```

Stai costruendo un nuovo array: primo elemento ~/.local/bin, poi tutti gli elementi di $path. 

path però funziona solo su zsh.

meglio usare un costrutto case con $PATH:

```bash
case ":$PATH:" in
    *":$HOME/.local/bin:"*) ;;
    *) PATH="$HOME/.local/bin:$PATH"; export PATH ;;
esac
```

---

**Area:** [[mappa-shell|Shell]]  
**Vedi anche:** [[variabili-opzioni|Variabili e opzioni della shell]] · [[comandi-ricerca|Comandi di ricerca]] · [[tipi-di-shell|Tipi di shell e su]]
