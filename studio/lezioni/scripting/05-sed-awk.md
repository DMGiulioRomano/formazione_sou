---
tags:
  - lezione
  - scripting
aliases:
  - Scripting 05 — sed e awk
---
# Scripting 05 — sed e awk

`sed` e `awk` non hanno un capitolo in nessuno dei due libri, ma ogni sistemista li incontra. Sono linguaggi veri: leggono righe, decidono, trasformano.

```sh
./prepara.sh 05 && cd palestra/l05
```

## La mappa

| # | Problema | Stato |
|---|---|---|
| 1 | `genera-conf.sh` — configurazioni da un modello | — |
| 2 | `report-http.sh` — un rapporto da un log | — |
| 3 | `imposta.sh` — cambiare una configurazione senza romperla | — |

---

## Problema 1 — `genera-conf.sh`

**Situazione.** Hai venti siti con la stessa configurazione, salvo pochi valori. Scriverle a mano significa introdurre venti errori diversi.

**Compito.** `./genera-conf.sh MODELLO NOME=VALORE...` stampa il modello con ogni `{{NOME}}` sostituito.

- I valori possono contenere `/`, `&` e `=`.
- Se resta un segnaposto: codice 1, e stderr nomina ciò che manca.
- Modello mancante: codice 2.

```sh
./genera-conf.sh dati/sito.conf.tmpl DOMINIO=esempio.it ROOT=/var/www/sito 'TITOLO=A&B' ADMIN=anna
```

**Verifica.** `../../verifica.sh 05 1`

> [!question]- Indizio 1
> Scrivi la sostituzione con `sed` per un solo valore, poi passa `ROOT=/var/www`. Cosa ha capito `sed` di quelle barre? Devono essere per forza barre?

> [!question]- Indizio 2
> Ora prova `TITOLO=A&B`. Cosa significa `&` nella parte destra di un `s///`? `man sed`, oppure `info sed`.

> [!question]- Indizio 3
> Da `A=b=c` vuoi `A` e `b=c`. Cerca in `man bash` come tagliare una variabile al *primo* `=` e all'*ultimo*.

> [!question]- Indizio 4
> Dopo le sostituzioni come riconosci ciò che è rimasto? Quale opzione di `grep` stampa solo il pezzo trovato?

**Dopo.** Cosa succede se il valore di un parametro contiene a sua volta `{{ADMIN}}`? Questa è una forma di iniezione: quando diventa pericolosa? `sed` è l'unica strada, o la shell sa già sostituire testo?

---

## Problema 2 — `report-http.sh`

**Situazione.** Ogni mattina vuoi un riepilogo del server web, non l'elenco delle richieste. Con una pipeline per ogni numero rileggeresti il file sette volte.

**Compito.** `./report-http.sh FILE` legge il log una volta sola e stampa esattamente questo. File mancante: codice 1.

```text
richieste: 370
2xx: 282
3xx: 45
4xx: 33
5xx: 10
byte_totali: 923109
ora_di_punta: 09 (157)
```

`ora_di_punta` è l'ora con più richieste, e fra parentesi quante.

**Verifica.** `../../verifica.sh 05 2`

> [!question]- Indizio 1
> Un programma `awk` è fatto di coppie *condizione { azione }*, ripetute per ogni riga. Quali due condizioni speciali girano prima della prima riga e dopo l'ultima?

> [!question]- Indizio 2
> Come spezza `awk` una riga, e come si chiama il campo dello stato? Stampa i campi uno alla volta per contarli. Alcune dimensioni valgono `-`: che valore numerico ha per `awk`?

> [!question]- Indizio 3
> Vuoi contare per categoria senza sapere quali ci saranno. Che tipo di indice accettano gli array di `awk`?

> [!question]- Indizio 4
> L'ora sta dentro un campo come `[02/Nov/2026:09:14:03`. Quali funzioni di `awk` tagliano una stringa? Cerca `split` e `substr` in `man awk`.

**Dopo.** Perché il rapporto stampa `4xx: 33` e non scompare la riga se non ci sono errori di quel tipo? Il tuo script li mostra anche a zero? Prova con un log di una riga. Il `%` di `printf` in `awk` può dipendere dalla lingua del sistema?

---

## Problema 3 — `imposta.sh`

**Situazione.** Devi disattivare il login di root su cento server. Lo script gira più volte, perciò deve essere *idempotente*: il secondo giro non cambia nulla e lo dice. È il principio alla base di Ansible e simili.

**Compito.** `./imposta.sh FILE CHIAVE VALORE` lavora su file di forma `Chiave valore`, come `dati/sshd_config`.

| Stato del file | Cosa fa |
|---|---|
| C'è una riga attiva `Chiave ...` | La sostituisce; un eventuale `#Chiave ...` resta com'è |
| C'è solo una riga `#Chiave ...`, col `#` attaccato | La sostituisce al suo posto |
| La chiave non c'è | Aggiunge la riga in fondo |

- Stampa `cambiato` e lascia una copia `FILE.bak` della versione precedente.
- Se il risultato sarebbe identico, stampa `invariato` e non tocca né il file né la copia.
- `PasswordAuthenticationExtra` non è `PasswordAuthentication`.
- `# PermitRootLogin va disattivato` è un commento discorsivo e non si tocca.
- File mancante: codice 1. Numero di argomenti sbagliato: codice 2.

Lavora su una copia di `dati/sshd_config`.

**Verifica.** `../../verifica.sh 05 3`

> [!question]- Indizio 1
> Come fai a dire «cambiato» o «invariato» senza ragionare caso per caso? Se produci prima il nuovo testo altrove, quale comando confronta due file e risponde col solo codice di uscita?

> [!question]- Indizio 2
> Per decidere cosa fare a una riga commentata devi sapere se *più avanti* c'è una riga attiva. Quante volte puoi leggere un file? Come si controlla prima?

> [!question]- Indizio 3
> Con una regex, quale carattere deve seguire la chiave perché `PasswordAuthenticationExtra` non venga presa? Con `awk`, quale campo confronteresti, e serve una regex?

> [!question]- Indizio 4
> Un valore come `/etc/issue.net` rompe il tuo `sed`? Hai già visto questo problema: quale strumento evita di costruire un comando col valore dentro?

**Dopo.** Cosa succede se la corrente salta a metà scrittura? Come si sostituisce un file in modo atomico? Cosa perdi con `mv` riguardo a proprietario e permessi rispetto a `cat > file`? Prima di riavviare davvero `sshd`, quale controllo della sintassi faresti?

---

## Diario

Domande numerate, risposte e correzioni di questa lezione.

## Sintesi

Da scrivere a lezione finita, con le tue parole.

---

← [[17-regex|Lezione 17]] · ↑ [[00-percorso|Il percorso]] · → [[06-robustezza|Lezione 06]]
