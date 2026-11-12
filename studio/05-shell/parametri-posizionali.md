---
tags:
  - shell
aliases:
  - Parametri posizionali
---
# Parametri posizionali

Gli argomenti con cui lanci uno script arrivano già divisi dalla shell chiamante: le virgolette le ha tolte lei, lo script riceve solo la lista.

| Parametro | Nome | Cosa contiene |
| --- | --- | --- |
| `$0` | parametro zero | il nome con cui lo script è stato lanciato, percorso compreso (`basename "$0"` tiene l'ultimo pezzo) |
| `$1` … `$9`, `${10}` | posizionali | l'argomento in quella posizione |
| `$#` | *number sign*, «quanti» | il numero di argomenti (`$0` escluso) |
| `"$@"` | *at*, «tutti, ciascuno» | un argomento per ogni parametro, confini intatti |
| `"$*"` | *star*, «tutti insieme» | un argomento solo, parametri uniti dal primo carattere di `IFS` |

## `"$@"` contro `"$*"`

Con `uno "due tre" quattro`:

| Scritto | Argomenti che ne escono |
| --- | --- |
| `"$@"` | 3: `uno`, `due tre`, `quattro` |
| `"$*"` | 1: `uno due tre quattro` |
| `'$@'` | 1: il testo `$@`, perché gli apici singoli non espandono |
| `$@`, `$*` | 4: spezzati sugli spazi, e ogni pezzo può espandersi come glob |

La differenza la fanno le **virgolette**, non `IFS`: `IFS` cambia solo il carattere che `"$*"` mette in mezzo. Per inoltrare gli argomenti a un altro comando si scrive quasi sempre `"$@"`.

## Come si osserva

`echo` non serve: riunisce i suoi argomenti con uno spazio e nasconde i confini. Serve un comando che stampi il proprio `$#`, come `argomenti.sh`.

## Due shell, due letture

`ssh host "... cmd uno "due tre""` passa per la shell locale e poi per quella remota. Le virgolette interne uguali alle esterne le consuma la prima; per farle arrivare alla seconda si usa l'altro tipo: `"... cmd uno 'due tre'"`.

---

Da: [[01-primo-script|Scripting 01]], problema 2 · ↑ [[mappa-shell|Shell]]
