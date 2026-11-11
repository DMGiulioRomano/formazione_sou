---
tags:
  - lezione
  - scripting
aliases:
  - Scripting 22 — Sicurezza e portabilità
---
# Scripting 22 — Sicurezza e portabilità

Uno script che gira con `sudo`, o che riceve dati da altri, deve fidarsi il meno possibile di ciò che riceve: controlla gli argomenti, non li fa mai interpretare alla shell, non lascia segreti in giro. E uno script che deve girare ovunque, in un container minimale o sotto `/bin/sh`, non può contare sulle comodità di bash. Si fa dopo la lezione 06; il problema 3 è più facile dopo la 16.

```sh
./prepara.sh 22 && cd palestra/l22
```

## La mappa

| # | Problema | Stato |
|---|---|---|
| 1 | `spazio-home-sicuro.sh` — uno script per `sudo` che si fida poco | — |
| 2 | `segreti.sh` — una password che nessuno vede | — |
| 3 | `conta-estensioni-posix.sh` — lo stesso script, senza bash | — |

---

## Problema 1 — `spazio-home-sicuro.sh`

**Situazione.** L'assistenza può lanciare con `sudo` uno script che mostra quanto occupa la home di un utente: `dati/spazio-home.sh`. Chi l'ha scritto ha pensato solo ai nomi normali, e ha usato `eval`. Con `sudo`, tutto ciò che lo script fa, lo fa come root: un argomento inatteso non deve poter cambiare il suo comportamento.

**Compito.** Leggi l'originale **senza eseguirlo** e scrivi nel diario quali difetti vedi. Poi scrivi `./spazio-home-sicuro.sh NOME`, che fa lo stesso lavoro in modo sicuro. `BASE` (predefinita `/home`) e `PASSWD` (predefinita `/etc/passwd`) si possono cambiare per le prove.

- `NOME` è valido solo se è un nome utente Linux corretto (minuscola o `_`, poi minuscole, cifre, `_` e `-`, al massimo 32 caratteri), esiste in `PASSWD` e `BASE/NOME` è una cartella.
- Se è valido stampa `NOME: N KB`, dove `N` è l'occupazione secondo `du -sk`. Altrimenti codice 2, senza lanciare `du`.
- Niente `eval`, e ogni variabile fra virgolette.

**Verifica.** `../../verifica.sh 22 1`. Il correttore prova nomi validi e una serie di nomi non validi, e controlla che per questi `du` non parta.

> [!question]- Indizio 1
> Cosa fa `eval` con la stringa che riceve? In quale momento, rispetto alle espansioni, la riga viene riletta? Cosa dice `shellcheck` sull'originale?

> [!question]- Indizio 2
> È più sicuro elencare ciò che è vietato o descrivere ciò che è ammesso? Hai già scritto l'espressione giusta nella lezione 17.

> [!question]- Indizio 3
> «Esiste in `PASSWD`»: hai risolto questo problema nella lezione 02. Il nome può contenere caratteri che `grep` interpreta?

**Dopo.** Perché `sudo` ripulisce l'ambiente, e cosa fanno `secure_path` ed `env_reset` in `/etc/sudoers`? Perché il bit SUID su uno script non funziona? Cosa conviene scrivere in `sudoers` per permettere solo questo script, e con quali argomenti?

---

## Problema 2 — `segreti.sh`

**Situazione.** Uno script notturno interroga il database con un client a riga di comando. La password scritta nella riga di comando si vede con `ps` da qualsiasi utente della macchina, e finisce nella cronologia.

**Compito.** `./segreti.sh QUERY` esegue `dbclient -u app --password-stdin QUERY` e ne restituisce output e codice. Il finto `dbclient` sta in `dati/bin`.

- La password è la prima riga del file indicato da `SEGRETO`, predefinito `~/.config/db/segreto`, e può contenere spazi e simboli.
- Se il file manca, o è leggibile o scrivibile da gruppo o altri: spiegazione su stderr, codice 3, e `dbclient` non parte.
- La password non compare negli argomenti di `dbclient`, nel suo ambiente, né nell'output dello script.

**Verifica.** `../../verifica.sh 22 2`. Il finto `dbclient` registra i suoi argomenti e il suo ambiente.

> [!question]- Indizio 1
> Chi può leggere `/proc/PID/cmdline` di un tuo processo? E `/proc/PID/environ`? Provalo con due utenti.

> [!question]- Indizio 2
> Come controlli i permessi di un file da script? `man stat`, cerca il formato dei permessi in ottale.

> [!question]- Indizio 3
> `--password-stdin` legge dallo stdin. Quale costruzione della lezione 18 dà una stringa come stdin senza `echo` e senza file temporanei? Compare nella lista dei processi?

**Dopo.** Che cosa fa `umask 077` all'inizio di uno script che crea file con dati riservati? Cosa offre `systemd-creds`, o un gestore come Vault? Perché `set -x` è pericoloso in uno script con segreti?

---

## Problema 3 — `conta-estensioni-posix.sh`

**Situazione.** Lo script `dati/conta-estensioni.sh` conta i file per estensione. Ora deve girare dentro un container minimale dove c'è solo `/bin/sh`, che spesso è `dash` o `busybox`, non bash.

**Compito.** Scrivi `conta-estensioni-posix.sh`, che inizia con `#!/bin/sh` e dà **esattamente** lo stesso output dell'originale. Niente array, `[[ ]]`, `${x,,}`, `<( )`, `local`, `read -d`.

**Verifica.** `../../verifica.sh 22 3`. Il correttore lo esegue con `dash`, se c'è, e confronta l'output con quello dell'originale.

> [!question]- Indizio 1
> Lancia `dash dati/conta-estensioni.sh`, oppure `shellcheck -s sh`: cosa non capisce? Fai l'elenco, poi cerca un sostituto per ciascuno.

> [!question]- Indizio 2
> Senza array associativi, chi può contare per categoria? L'hai fatto nella lezione 05.

> [!question]- Indizio 3
> Senza `-print0` e `read -d ''`, come passi nomi con spazi da `find` a un altro comando? `man find`: cosa fa `-exec ... {} +`?

**Dopo.** Cos'è POSIX, e chi lo scrive? Su Rocky `/bin/sh` è bash: cosa cambia quando bash viene lanciato con quel nome? Prova `ls -l /bin/sh` e cerca `posix mode` in `man bash`.

---

## Diario

Domande numerate, risposte e correzioni di questa lezione.

## Sintesi

Da scrivere a lezione finita, con le tue parole.

---

← [[21-rete|Lezione 21]] · ↑ [[00-percorso|Il percorso]] · → [[23-shell-interattiva|Lezione 23]]
