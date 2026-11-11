---
tags:
  - lezione
  - scripting
aliases:
  - Scripting 10 — Automazione
---
# Scripting 10 — Automazione

Uno script serve davvero quando gira senza di te. Riferimenti: *Admin Guide*, capitoli 11.3 e 12, e [[systemd|systemd]]. Su Rocky ci sono sia `cron`, di cui parla il libro, sia i timer di systemd: qui si vedono entrambi.

```sh
./prepara.sh 10 && cd palestra/l10
```

## La mappa

| # | Problema | Stato |
|---|---|---|
| 1 | `rapporto.sh` — «a mano funziona» | — |
| 2 | Il backup notturno, con un timer e con cron | — |
| 3 | `cron-corrisponde.sh` — capire cron programmandolo | — |

---

## Problema 1 — `rapporto.sh`

**Situazione.** Il classico. Lo script che trovi in `palestra/l10/rapporto.sh` funziona quando lo lanci dalla sua cartella. Stanotte, sotto cron, non ha prodotto niente, e di errori non c'è traccia.

**Compito.** Ripara lo script, in modo che scriva `uscita/stato.txt` accanto a sé, partendo da qualsiasi cartella e con l'ambiente ridotto di cron. Il contenuto è:

```text
misura: ok
3
generato da <utente> il <data>
```

Prima riproduci il guasto, poi correggilo:

```sh
cd / && env -i HOME="$HOME" SHELL=/bin/sh LOGNAME="$LOGNAME" PATH=/usr/bin:/bin "$OLDPWD/rapporto.sh"
```

**Verifica.** `../../verifica.sh 10 1`

> [!question]- Indizio 1
> Elenca le cose che lo script dà per scontate: in quale cartella si trova, quali variabili esistono, dove stanno i comandi. Cosa dà cron di tutto questo? Fai scrivere `env` a un lavoro di cron per vederlo.

> [!question]- Indizio 2
> Da dentro uno script, come sai dove si trova lo script stesso, qualunque sia la cartella corrente? `$0` è assoluto? Come lo rendi tale?

> [!question]- Indizio 3
> `$USER` è impostata dalla shell di login, non dal kernel. Quale comando dà il nome partendo dall'UID del processo?

**Dopo.** Dove finiscono stdout e stderr di un lavoro cron? E di un servizio systemd? Il manuale raccomanda percorsi assoluti: perché uno script robusto preferisce comunque impostare da sé il proprio `PATH`?

---

## Problema 2 — Il backup notturno

**Situazione.** Metti in produzione ciò che hai scritto nelle lezioni 08 e 09: ogni notte alle 02:30 backup di una cartella e rotazione, senza sovrapposizioni. La macchina può essere spenta a quell'ora: se lo è, il lavoro deve partire appena si riaccende.

**Compito, sulla VM.**

1. Scrivi uno script che unisca `backup.sh` e `ruota.sh` tenendo gli ultimi 7, usando la tua `lib-log.sh`.
2. Fallo girare con una coppia unit e timer di systemd.
3. Scrivi la riga `crontab` equivalente, con `crontab -e` (`cronie` è già installato). Trova cosa non riesce a replicare.

Si controlla a mano, non c'è correttore:

```sh
systemd-analyze verify <i tuoi file>
systemctl list-timers
systemctl start <il tuo servizio>     # lo prova subito
journalctl -u <il tuo servizio>
```

Criteri: il lavoro compare fra i timer, l'avvio manuale produce un archivio, i log sono in `journalctl`, e un guasto simulato risulta `failed` in `systemctl status`.

> [!question]- Indizio 1
> Negli appunti su [[systemd|systemd]]: quale tipo di servizio descrive un lavoro che parte, finisce e non resta in esecuzione? Quanti file servono, e come si riconoscono fra loro?

> [!question]- Indizio 2
> `man systemd.timer` e `man systemd.time`: come si scrive «ogni giorno alle 02:30»? Quale opzione si occupa delle esecuzioni perse a macchina spenta?

> [!question]- Indizio 3
> Per guastarlo apposta: cosa decide per systemd se un lavoro è fallito? Hai già la risposta dalla lezione 02.

> [!question]- Indizio 4
> Il servizio fallisce con `203/EXEC` o `Permission denied`, anche se lo script è eseguibile e a mano parte? Su Rocky c'è un secondo controllo oltre ai permessi Unix. Cosa dicono `ls -Z` sul tuo script e `sudo ausearch -m avc -ts recent`? Dove stanno di norma i programmi lanciati dal sistema, e cosa cambia con un servizio dell'utente (`systemctl --user`)?

**Dopo.** Confronta cron e timer su log, dipendenze, esecuzioni perse e limiti di risorse. Serve ancora il tuo `solo-uno.sh`, con systemd? Lancia il servizio due volte di seguito per scoprirlo. Quale utente lo esegue? Come limiteresti ciò che può fare?

---

## Problema 3 — `cron-corrisponde.sh`

**Situazione.** Nessuno ricorda se `*/10 8-17 * * 1-5` include le 17:30. Quando ti chiedono «partirà domenica?» vuoi una risposta sicura. E per capire una notazione non c'è niente di meglio che implementarla.

**Compito.** `./cron-corrisponde.sh "ESPRESSIONE" "AAAA-MM-GG HH:MM"` esce con 0 se quel momento corrisponde, con 1 se non corrisponde, con 2 per errori d'uso come un numero di campi diverso da cinque.

Ogni campo (minuti, ore, giorno del mese, mese, giorno della settimana) accetta `*`, numeri, intervalli `8-17`, liste `1,15`, passi `*/10` e `5-30/5`. Sono le regole della tabella nell'*Admin Guide* 12.5, più queste due:

- Il giorno della settimana va da 0 a 7, e sia 0 sia 7 sono la domenica.
- Se giorno del mese e giorno della settimana sono **entrambi** diversi da `*`, basta che ne corrisponda uno. È una vera stranezza di cron.

**Verifica.** `../../verifica.sh 10 3`

> [!question]- Indizio 1
> Non scrivere tutto insieme. Cosa devi saper fare per *un* campo e *un* numero? Quale firma avrebbe quella funzione? Il resto è ripeterla.

> [!question]- Indizio 2
> Prova in shell `echo $(( 09 + 1 ))`. Cosa è successo, e in quale base legge i numeri che iniziano con zero? `man bash`, *Arithmetic Evaluation*.

> [!question]- Indizio 3
> `5-30/5` si scompone in due passaggi. Per quale `v` vale? Trova una condizione aritmetica che usi `v`, l'inizio, la fine e il passo. Il `*` si può vedere come un intervallo?

> [!question]- Indizio 4
> Come ottieni minuti, ora e giorno della settimana da una data già scritta? Quali segnaposto ha `date`?

**Dopo.** `0 0 31 2 *` scatta mai? Il tuo script lo può dire? Provalo con date reali, poi confrontalo con la tabella di `man 5 crontab`, se hai installato `cronie`: trovi forme che non gestisci?

---

## Diario

Domande numerate, risposte e correzioni di questa lezione.

## Sintesi

Da scrivere a lezione finita, con le tue parole.

---

← [[09-processi-segnali|Lezione 09]] · ↑ [[00-percorso|Il percorso]] · → [[11-progetto-finale|Lezione 11]]
