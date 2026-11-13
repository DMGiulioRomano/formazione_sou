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

> [!info] Il contesto
> **Lo scenario.** Il gruppo di assistenza, che risponde alle chiamate degli utenti, non ha i poteri dell'amministratore. Per alcune operazioni precise gli si permette di lanciare uno script come root, e solo quello.
> - **`sudo`** (*superuser do*, «fai come superutente», 1980): il comando che lascia eseguire un comando con l'identità di root, secondo regole scritte da chi amministra la macchina.
> - **`eval`** (da *evaluate*, «valuta»): il comando interno che prende una stringa e la fa rileggere alla shell come se fosse una riga di codice.
> - **Iniezione** (in inglese *injection*): far passare un pezzo di comando dentro un dato, così che il programma lo esegua invece di trattarlo come testo.
>
> **Perché conta.** Uno script lanciabile come root che accetta un argomento qualsiasi regala i poteri di root a chiunque possa lanciarlo. Basta un nome utente scritto con malizia.

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

> [!info] Il contesto
> **Lo scenario.** Un lavoro notturno deve entrare nel database con un utente e una password. La password deve stare da qualche parte sulla macchina, e arrivare al programma, senza che altri la vedano lungo il percorso.
> - **Client** (latino *cliens*, «chi si appoggia a un protettore»): il programma che si collega a un servizio per chiedergli qualcosa, qui al database.
> - **`ps`** (*process status*, «stato dei processi»): il comando che elenca i processi della macchina, con le loro righe di comando.
> - **Cronologia** (in inglese *history*): il file in cui la shell conserva i comandi che hai scritto, per poterli richiamare.
>
> **Perché conta.** Una password vista da un altro utente, o rimasta in un file di cronologia, va considerata pubblica: si cambia, e si cambia ovunque sia usata.

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

> [!info] Il contesto
> **Lo scenario.** Le applicazioni moderne girano spesso in container costruiti il più piccoli possibile, per avviarsi in fretta e offrire meno punti d'attacco. Dentro c'è il minimo indispensabile, e bash di solito non è fra questo.
> - **Container minimale**: un container con solo i file strettamente necessari, a volte pochi megabyte in tutto.
> - **`dash`** (*Debian Almquist shell*) e **BusyBox**: una shell piccola e veloce, e un solo programma che fa da shell e da decine di comandi insieme. Sono le shell più comuni dove manca bash.
> - **Portabilità** (latino *portare*): la capacità di uno script di girare su sistemi diversi senza modifiche.
>
> **Perché conta.** Uno script che usa le comodità di bash, lanciato da una shell che non le conosce, si ferma con errori strani, o peggio fa qualcosa di diverso senza dire niente.

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
