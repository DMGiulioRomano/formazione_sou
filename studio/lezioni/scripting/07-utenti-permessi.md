---
tags:
  - lezione
  - scripting
aliases:
  - Scripting 07 — Utenti e permessi
---
# Scripting 07 — Utenti e permessi

La sicurezza di ogni giorno di un sistema Linux sta in pochi file di testo e in pochi bit di permessi, quindi si può controllare con uno script. Riferimenti: *Admin Guide*, capitoli 7, 8.6 e 15.

```sh
./prepara.sh 07 && cd palestra/l07
```

## La mappa

| # | Problema | Stato |
|---|---|---|
| 1 | `crea-utenti.sh` — i nuovi assunti | — |
| 2 | `scadenze.sh` — password in scadenza | — |
| 3 | `audit-permessi.sh` — bit che non dovrebbero esserci | — |

---

## Problema 1 — `crea-utenti.sh`

**Situazione.** Le risorse umane mandano un elenco di assunti. Devi creare gli account, e il file contiene sempre qualche errore. Sbagliare a metà lascia il sistema in uno stato che nessuno conosce, perciò si guarda prima cosa accadrà.

**Compito.** `./crea-utenti.sh FILE [--esegui]`. Il file ha righe `nome;gruppo;shell;scadenza`, e la scadenza può mancare. Righe vuote e righe che iniziano con `#` si ignorano. Gli account esistenti si leggono da `$ETC/passwd` e `$ETC/group`, con `ETC` predefinita a `/etc`.

Senza `--esegui` stampa soltanto i comandi. Con `--esegui` li stampa e li esegue. Con `ETC=dati ./crea-utenti.sh dati/nuovi-utenti.csv` lo stdout è:

```text
groupadd sviluppo
useradd -m -g sviluppo -s /bin/bash -e 2027-06-30 luca
useradd -m -g sviluppo -s /bin/zsh sara
groupadd ops
useradd -m -g ops -s /bin/bash -e 2027-01-31 piero
useradd -m -g staff -s /bin/bash dana
```

- Un gruppo si crea una volta sola, e solo se manca.
- Utente già presente: messaggio su stderr col suo nome, poi si passa oltre senza errore.
- Riga non valida: stderr dice `riga N`, con la riga del file contata dalla prima, e si prosegue. Il nome è minuscolo, inizia con lettera o `_` e contiene solo lettere, cifre, `_` e `-`. La data ha la forma `AAAA-MM-GG`.
- Se c'era almeno una riga non valida, il codice finale è 1.
- File mancante: codice 2.

**Verifica.** `../../verifica.sh 07 1`. Poi prova sulla VM con `sudo ./crea-utenti.sh dati/nuovi-utenti.csv --esegui`, controlla con `id luca` e rimuovi ciò che hai creato.

> [!question]- Indizio 1
> Vuoi che stampare ed eseguire non possano mai divergere. Se scrivi due rami separati, cosa succede quando correggi solo uno dei due? Quale funzione piccola risolverebbe il problema?

> [!question]- Indizio 2
> `-e` compare solo se c'è una scadenza. Una variabile vuota fra virgolette diventa un argomento vuoto: `useradd` come la prende? Hai già costruito una riga di comando variabile nella lezione 06.

> [!question]- Indizio 3
> Per ricordare i gruppi già creati non basta rileggere `$ETC/group`, nella prova a secco. Perché? Cosa hai usato per ricordare i doppioni del PATH?

> [!question]- Indizio 4
> Il tuo ciclo vede l'ultima riga di un file che non finisce con un a capo? Cosa restituisce `read` in quel caso?

**Dopo.** `2027-13-45` passa il tuo controllo? Come lo rifiuteresti con `date`? E lo script come si comporta se muore a metà e lo rilanci? Questa è ancora idempotenza.

---

## Problema 2 — `scadenze.sh`

**Situazione.** Ogni lunedì vuoi avvisare chi ha la password in scadenza. In `/etc/shadow` non ci sono date: ci sono numeri di giorni.

**Compito.** `./scadenze.sh FILE N [OGGI]`, dove `OGGI` è `AAAA-MM-GG` e di norma è la data corrente.

Il file ha il formato di `/etc/shadow`; i campi sono descritti nell'*Admin Guide* 7.3.6. Una password scade dopo `ultimo cambio + durata massima`. Stampa chi scade entro `N` giorni, dal più urgente:

```text
teo scaduta
zeno scaduta
mario 5
anna 10
```

- Giorni rimasti negativi: `scaduta`. Zero: `0`, perché scade oggi.
- Si ignorano gli account senza password usabile, con il secondo campo che inizia con `!` o `*`.
- Si ignora chi non ha scadenza: durata massima vuota o `99999`.
- Il risultato non dipende dal fuso orario della macchina.
- File mancante: codice 1. `N` non numerico: codice 2.

**Verifica.** `../../verifica.sh 07 2`

> [!question]- Indizio 1
> Il manuale dà una formula per trasformare una data in giorni. Provala con `TZ=UTC` e con `TZ=Europe/Rome` sulla stessa data. Quanto vale l'una e quanto l'altra? Cosa conta davvero `date +%s`, a partire da quale istante?

> [!question]- Indizio 2
> Quando `date -d 2026-11-03` legge una data senza ora, quale mezzanotte intende? Come gli dici quale fuso usare? `man date`.

> [!question]- Indizio 3
> Vuoi ordinare per giorni rimasti, ma stampare `scaduta`. In quale momento conviene trasformare il numero in parola?

**Dopo.** Lo script reale deve leggere `/etc/shadow`: chi può farlo? Prova da utente normale: quale permesso lo vieta, e con che codice esce il tuo script? Cosa vale il terzo campo a 0, e cosa significa per il login di `teo`?

---

## Problema 3 — `audit-permessi.sh`

**Situazione.** Un eseguibile SUID di troppo o un file scrivibile da chiunque sono tra le prime cose che un attaccante cerca dopo essere entrato. Conviene cercarle prima.

**Compito.** `./audit-permessi.sh CARTELLA` stampa una riga per ogni scoperta, in ordine (`LC_ALL=C sort`):

| Etichetta | Cosa |
|---|---|
| `suid` | File normale col bit SUID |
| `sgid` | File normale col bit SGID |
| `scrivibile` | File o cartella scrivibile da chiunque |

- I link simbolici non contano.
- Una cartella scrivibile da chiunque ma col bit sticky, come `/tmp`, non è un problema.
- Codice 0 se è tutto pulito, 1 se c'è qualche scoperta, 2 se la cartella non esiste.

```text
scrivibile dati/albero/aperto.txt
scrivibile dati/albero/dir-aperta
scrivibile dati/albero/nome con spazi.txt
sgid dati/albero/sgid.bin
suid dati/albero/suid.bin
```

**Verifica.** `../../verifica.sh 07 3`

> [!question]- Indizio 1
> Cosa mostra `ls -l` per un link simbolico nella colonna dei permessi? Perché è un falso allarme?

> [!question]- Indizio 2
> `man find`, voce `-perm`: che differenza c'è fra `-perm 777`, `-perm -777` e `-perm /777`? Quale chiede «almeno questi bit»?

> [!question]- Indizio 3
> Quali cifre ottali corrispondono a SUID, SGID e sticky? Come esprimi «scrivibile da altri, ma senza sticky» combinando due test?

**Dopo.** Lancia lo script su `/usr/bin` nella VM. Quali programmi SUID trovi, e perché `passwd` deve esserlo? Il bit SUID su uno script di shell funziona? Cerchi anche file senza proprietario: quale test di `find` li trova, e da dove saltano fuori?

---

## Diario

Domande numerate, risposte e correzioni di questa lezione.

## Sintesi

Da scrivere a lezione finita, con le tue parole.

---

← [[06-robustezza|Lezione 06]] · ↑ [[00-percorso|Il percorso]] · → [[08-backup|Lezione 08]]
