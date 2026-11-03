---
tags:
  - lezione
  - scripting
aliases:
  - Scripting 04 — Il testo come dati
---
# Scripting 04 — Il testo come dati

In Unix quasi tutto è testo diviso in righe e campi, e combinando pochi filtri ottieni una piccola analisi dati. È qui che la pipe si guadagna la fama.

```sh
./prepara.sh 04 && cd palestra/l04
```

## La mappa

| # | Problema | Stato |
|---|---|---|
| 1 | `percorso.sh` — ispezionare il PATH | — |
| 2 | `utenti-reali.sh` — chi è una persona? | — |
| 3 | `top-ip.sh` — chi bussa di più | — |
| 4 | `ssh-attacchi.sh` — chi sta forzando la porta | — |

---

## Problema 1 — `percorso.sh`

**Situazione.** Un comando parte nella versione sbagliata, o non si trova. Il colpevole è spesso `PATH`: voci morte, doppioni, oppure una voce vuota che fa eseguire ciò che sta nella cartella corrente, cosa pericolosa.

**Compito.** `./percorso.sh [VALORE]`, dove il predefinito è il contenuto di `$PATH`. Per ogni elemento, in ordine, stampa una riga:

```text
/bin ok
/non/esiste manca
/bin duplicato
(vuoto) pericoloso
/usr/bin ok
```

Questo è l'output di `./percorso.sh "/bin:/non/esiste:/bin::/usr/bin"`. Un file che non è una cartella conta come `manca`. Le cartelle con spazi devono funzionare.

**Verifica.** `../../verifica.sh 04 1`

> [!question]- Indizio 1
> Quante soluzioni vedi per spezzare il testo sui `:`? Con quale tieni intatti gli spazi nei nomi? Rileggi la voce su `IFS` del manuale.

> [!question]- Indizio 2
> Per i doppioni devi ricordare cosa hai già visto. In quale struttura, senza lanciare un comando per ogni voce? `man bash`, sezione *Arrays*.

**Dopo.** `/bin:` e `:/bin` hanno una voce vuota? Il tuo script la vede? Prova, e poi confronta con [[path|PATH]]. Perché `.` nel PATH è pericoloso per root?

---

## Problema 2 — `utenti-reali.sh`

**Situazione.** Un revisore chiede l'elenco delle persone con accesso alla macchina, non degli account di servizio. Questa regola esiste in pratica su molte distribuzioni.

**Compito.** `./utenti-reali.sh [FILE]`, predefinito `/etc/passwd`. Stampa `nome home shell`, in ordine di nome, per chi:

- ha UID da 1000 in su, escluso `nobody` (65534);
- ha una shell con cui entrare: non finisce con `nologin` o `false`.

File illeggibile: codice 1.

**Verifica.** `../../verifica.sh 04 2`

> [!question]- Indizio 1
> Guarda il campo commento di `anna` e quello vuoto di `zeno`. Quale carattere separa davvero i campi? Se spezzi con quello, il commento dà fastidio?

> [!question]- Indizio 2
> Rileggi [[while-read|while read]]. A quante variabili può distribuire `read` una riga? Quale variabile decide dove spezzarla, e puoi cambiarla solo per quel comando?

**Dopo.** Da dove viene il numero 1000? Controlla su `/etc/login.defs`. Una shell `nologin` impedisce davvero ogni accesso? Pensa a una chiave SSH con un comando forzato.

---

## Problema 3 — `top-ip.sh`

**Situazione.** Il sito è lento. La prima domanda davanti a un log è sempre la stessa: chi sta facendo tutte queste richieste?

**Compito.** `./top-ip.sh FILE [N]`, predefinito 5. Stampa le prime `N` righe `conteggio ip`, dal conteggio più alto. A parità di conteggio ordina per IP in ordine crescente, come testo. File mancante: codice 1. La prima riga su `dati/access.log` è:

```text
120 203.0.113.7
```

**Verifica.** `../../verifica.sh 04 3`

> [!question]- Indizio 1
> Spezza il problema: isolare il campo, contare, ordinare, tagliare. Quale di questi passi il libro Rocky spiega insieme a un comando che lavora solo su righe *consecutive*?

> [!question]- Indizio 2
> Con `sort` su tutta la riga, `9` e `120` come si confrontano? Quale opzione dice «questo è un numero»?

> [!question]- Indizio 3
> Il pareggio chiede due criteri, uno per numero e decrescente, l'altro per testo e crescente. `man sort`: come si danno criteri diversi a colonne diverse?

**Dopo.** Provalo con `LC_ALL=it_IT.UTF-8` e con `LC_ALL=C`. Cambia qualcosa? Perché `sort` dipende dalla lingua? Quanto regge questa pipeline su un log di 50 GB?

---

## Problema 4 — `ssh-attacchi.sh`

**Situazione.** Su un server esposto, qualcuno prova password a raffica. Vuoi gli indirizzi da bloccare. Il log non è una tabella ordinata: le frasi cambiano forma.

**Compito.** `./ssh-attacchi.sh FILE SOGLIA` stampa `ip tentativi` per gli indirizzi con almeno `SOGLIA` password sbagliate, dal più attivo. Soglia non numerica: codice 2. File mancante: codice 1.

```text
203.0.113.7 42
198.51.100.23 9
198.51.100.66 6
```

**Verifica.** `../../verifica.sh 04 4`

> [!question]- Indizio 1
> Metti in colonna una riga con `for root` e una con `for invalid user admin`. In quale posizione sta l'IP in ciascuna? Puoi contare dall'inizio?

> [!question]- Indizio 2
> Cerca nel log le righe di `198.51.100.66`. Come si chiama l'utente che l'attaccante ha provato? Cosa fa questo nome a una ricerca del testo `from`? Può sfruttarlo un attaccante?

> [!question]- Indizio 3
> Se non puoi contare da sinistra, da dove puoi contare? Oppure: quale parola sta sempre *subito dopo* l'IP?

**Dopo.** Guarda le righe `Accepted` di `203.0.113.7`. Cosa è successo, e cosa faresti subito? Qual è il rischio di trasformare questo script in un blocco automatico del firewall, visto che anche il nome utente è scritto dall'attaccante?

---

## Diario

Domande numerate, risposte e correzioni di questa lezione.

## Sintesi

Da scrivere a lezione finita, con le tue parole.

---

← [[03-cicli-e-nomi|Lezione 03]] · ↑ [[00-percorso|Il percorso]] · → [[05-sed-awk|Lezione 05]]
