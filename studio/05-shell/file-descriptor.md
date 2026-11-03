---
tags:
  - shell
  - nota
aliases:
  - File descriptor
---
# File descriptor

**Idea guida**: un processo non legge e non scrive "sul terminale" o "su un file", ma su canali numerati. A cosa siano collegati lo decide chi lo avvia.

## I tre canali standard

Ogni processo ha una tabella di canali aperti, i *file descriptor*. I primi tre hanno un ruolo fisso:

| Numero | Nome | Uso |
|--------|------|-----|
| 0 | stdin | da qui legge |
| 1 | stdout | qui scrive |
| 2 | stderr | qui scrive gli errori |

## Il processo non sa cosa c'è dietro

Un programma scrive sul canale 1 e basta: dietro può esserci il terminale, un file o una pipe. Il collegamento lo prepara la shell prima di avviarlo.

La sintassi della redirezione si legge quindi come un'operazione sui numeri:

| Scrittura | Significato |
|-----------|-------------|
| `2>/dev/null` | collega il canale 2 a `/dev/null`: gli errori spariscono |
| `>&2` | collega il canale 1 a dove punta il canale 2: l'output va fra gli errori |

**Esempio**: `>&2` fa arrivare un messaggio al terminale anche se lo stdout è collegato a una pipe.

```bash
echo "messaggio per me" >&2
```

## Stdout non è un server

Un file descriptor è una destinazione di scrittura, non un servizio che resta in ascolto. Anche una connessione di rete si usa attraverso un file descriptor, ma un socket è bidirezionale e permette di costruirci sopra richieste e risposte. Il confronto con la pipe è in [[pipe|Come funziona una pipe]].

---

**Area:** [[mappa-shell|Shell]]  
**Vedi anche:** [[redirezione-pipe|Redirezione e pipe]] · [[pipe|Come funziona una pipe]] · [[gestione-processi|Gestione dei processi]]
