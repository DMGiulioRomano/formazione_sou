---
tags:
  - processi
  - nota
aliases:
  - tmux in pratica
---
# tmux in pratica

Prontuario operativo, organizzato per domande. La teoria (perché usarlo, configurazione, casi d'uso) sta in [[tmux|tmux]].

## Il prefisso

`Ctrl+b` da solo non fa nulla: avvisa tmux che il tasto successivo è un suo comando.

1. premi `Ctrl+b`
2. **rilascia** entrambi i tasti
3. premi il tasto del comando (es. `c`)

Nella nota, «`Ctrl+b` → `c`» significa questa sequenza. Sulla tastiera italiana: `%` = `Shift+5`, `$` = `Shift+4`, `&` = `Shift+6`. `Ctrl+b` → `?` elenca tutte le scorciatoie.

## Sessione, finestra, pannello

```
SESSIONE  "lavoro"            ← il contenitore, tipo «un progetto»
 ├── FINESTRA 0               ← come una tab
 │    ├── pannello  ┐
 │    └── pannello  ┘ schermo diviso a metà
 └── FINESTRA 1
      └── pannello
```

Dividere lo schermo **non** crea una nuova sessione: crea due pannelli nella stessa finestra. La sessione muore solo quando chiudi l'ultimo pannello dell'ultima finestra.

## Sessioni

| Domanda | Fuori da tmux | Dentro tmux |
| --- | --- | --- |
| Come ne creo una? | `tmux new -s nome` | `Ctrl+b` → `:` → `new -s nome` |
| Come vedo quali esistono? | `tmux ls` | `Ctrl+b` → `s` |
| Come entro in una già attiva? | `tmux attach -t nome` (o `tmux a`) | `Ctrl+b` → `s`, frecce, Invio |
| Come la rinomino? | `tmux rename-session -t vecchio nuovo` | `Ctrl+b` → `$` |
| Come ne chiudo una precisa? | `tmux kill-session -t nome` | `Ctrl+b` → `s`, frecce, `x`, `y` |
| Come chiudo quella in cui sono? | — | `Ctrl+b` → `:` → `kill-session` |
| Come le chiudo tutte? | `tmux kill-server` | — |

- Il nome è la parola prima dei due punti nell'output di `tmux ls`. Senza `-s` le sessioni si chiamano `0`, `1`, `2`…
- `tmux new -A -s nome` entra nella sessione se esiste, altrimenti la crea.
- `Ctrl+b` → `d` **non** chiude: stacca. La sessione resta viva in background e la ritrovi con `tmux attach`.

## Finestre

| Domanda | Comando |
| --- | --- |
| Come ne creo una? | `Ctrl+b` → `c` |
| Come mi sposto? | `Ctrl+b` → `n` (successiva), `p` (precedente), `0`…`9` (diretta) |
| Come la rinomino? | `Ctrl+b` → `,` — da fuori: `tmux rename-window -t sessione:0 nome` |
| Come la elimino? | `Ctrl+b` → `&` → `y`, oppure `exit` in tutti i suoi pannelli |

La finestra attiva è quella segnata con `*` nella barra in basso.

## Pannelli

| Domanda | Comando |
| --- | --- |
| Come divido affiancati? | `Ctrl+b` → `%` |
| Come divido sopra/sotto? | `Ctrl+b` → `"` |
| Come mi sposto? | `Ctrl+b` → freccia |
| Come vedo quali sono aperti? | `Ctrl+b` → `q` (numeri a schermo), `tmux list-panes` (`-a` per tutti), `Ctrl+b` → `w` (albero) |
| Come chiudo quello in cui sono? | `exit`, oppure `Ctrl+b` → `x` → `y` |
| Come ne chiudo un altro dal pannello in cui sono? | `Ctrl+b` → `q` per leggere il numero, poi `tmux kill-pane -t 1` |
| Come tengo solo quello in cui sono? | `tmux kill-pane -a` |

---

**Area:** [[mappa-processi|Processi]]  
**Vedi anche:** [[tmux|tmux]] · [[gestione-processi|Gestione dei processi]]
