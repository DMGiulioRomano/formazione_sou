---
tags:
  - lezione
  - scripting
aliases:
  - Scripting 17 — Espressioni regolari
---
# Scripting 17 — Espressioni regolari

`grep`, `sed`, `awk`, `[[ =~ ]]` e mille programmi parlano la stessa lingua per descrivere testo: le espressioni regolari. Sono un linguaggio piccolo, ma ha dialetti (BRE, ERE, PCRE) e trappole, come i quantificatori golosi e i punti che valgono qualsiasi carattere. Qui si scrivono prima tante espressioni piccole, poi due programmi che smontano log veri. Si fa dopo la lezione 04. Riferimento: `man 7 regex`, `man grep` e [[manipolare-testo|Manipolare testo]].

```sh
./prepara.sh 17 && cd palestra/l17
```

## La mappa

| # | Problema | Stato |
|---|---|---|
| 0 | `regex.txt` — quattordici espressioni da scrivere | — |
| 1 | `estrai-errori.sh` — errori su più righe | — |
| 2 | `log-a-csv.sh` — da log a foglio di calcolo | — |

---

## Problema 0 — `regex.txt`

**Situazione.** Prima di usarle in uno script, le espressioni si provano da sole, su casi giusti e sbagliati. Chi valida un indirizzo IP con `[0-9.]+` accetta anche `999.1`.

**Compito.** Il file `regex.txt` elenca quattordici nomi. Accanto a ciascuno, dopo uno spazio, scrivi un'espressione **ERE**, cioè quella di `grep -E`. Il correttore la prova con `grep -Ex`: deve corrispondere a tutta la riga, quindi non servono `^` e `$`.

| Nome | Deve accettare | Deve rifiutare |
|---|---|---|
| `cifre` | Una o più cifre | Vuoto, lettere, spazi |
| `intero` | Intero con `+` o `-` facoltativo, senza zeri davanti salvo lo `0` | `007`, `--1`, `1.5` |
| `colore` | Colore CSS `#rgb` o `#rrggbb`, maiuscole o minuscole | `#ffff`, `fff`, `#ggg` |
| `ipv4` | Quattro ottetti da 0 a 255, senza zeri davanti | `256.1.1.1`, `01.2.3.4`, `1.2.3` |
| `mac` | Sei coppie esadecimali separate da `:` oppure da `-`, non mescolati | `52:54-00:12:34:56` |
| `data` | `AAAA-MM-GG`, mese da 01 a 12, giorno da 01 a 31 | `2026-13-01`, `2026-1-3` |
| `ora` | `HH:MM` da `00:00` a `23:59` | `24:00`, `9:05` |
| `utente` | Nome utente Linux: minuscola o `_`, poi minuscole, cifre, `_`, `-`, al massimo 32 caratteri; può finire con `$` | `Mario`, `1abc`, 33 caratteri |
| `email` | Semplificata: parte locale di lettere, cifre e `._%+-`, una `@`, un dominio con almeno un punto e un'estensione di almeno due lettere | `a@b`, `a@@x.com` |
| `semver` | `X.Y.Z` senza zeri davanti, con un `-etichetta` facoltativo di lettere, cifre, punti e trattini | `1.0`, `01.2.3`, `1.2.3-` |
| `assoluto` | Percorso che inizia con `/`, senza `//` e senza componenti `..` | `etc/x`, `/a/../b`, `/a//b` |
| `vuota` | Riga vuota, di soli spazi o tabulazioni, o che dopo questi inizia con `#` | `a # b` |
| `porta` | Numero da 1 a 65535, senza zeri davanti | `0`, `65536`, `080` |
| `host` | Nome host: etichette di lettere, cifre e `-` separate da punti; un'etichetta non inizia né finisce con `-` | `-web`, `a..b`, `un_host` |

**Verifica.** `../../verifica.sh 17 0`. Il correttore mostra i casi che sbagli, così puoi correggere un'espressione alla volta.

> [!question]- Indizio 1
> `grep -E 'x+'` e `grep 'x+'` danno lo stesso risultato? Cosa cambia fra BRE ed ERE, secondo `man 7 regex`?

> [!question]- Indizio 2
> Per i numeri da 0 a 255 non esiste una classe di caratteri. Spezza l'intervallo in casi: quali forme può avere un numero di una, due e tre cifre che sta sotto 256?

> [!question]- Indizio 3
> Per `mac`, come obblighi a usare sempre lo stesso separatore? Esiste un modo per dire «lo stesso carattere che hai trovato prima»? Cerca *back-reference*. È ERE? Se non lo è, scrivi le due forme come alternative.

> [!question]- Indizio 4
> «Senza componenti `..`» è una condizione *negativa*. Le ERE non hanno il «non contiene»: descrivi invece com'è fatto un componente ammesso.

**Dopo.** Perché la tua `data` accetta `2026-02-31`? Fin dove ha senso validare con una regex, e quando serve un programma? Cosa aggiunge `grep -P`, e perché non c'è in tutti i sistemi? Cosa significa che `*` è «goloso»?

---

## Problema 1 — `estrai-errori.sh`

**Situazione.** Un'applicazione Java è caduta stanotte. Il log è lungo migliaia di righe e ogni errore si porta dietro una traccia di dieci righe. `grep ERROR` ti dà solo la prima riga di ciascuno, `grep -A 10` ne taglia alcune e ne aggiunge altre.

**Compito.** `./estrai-errori.sh FILE [LIVELLO]`, con `LIVELLO` predefinito `ERROR`.

- Un **evento** inizia con una riga `AAAA-MM-GG HH:MM:SS LIVELLO messaggio`, all'inizio della riga. Tutte le righe successive che non iniziano così fanno parte dello stesso evento.
- Stampa per intero gli eventi di quel livello, nell'ordine del file, separati da una riga `--`.
- Il livello è una parola esatta: `ERRORE` non è `ERROR`.
- Codice 0 se ha trovato qualcosa, 1 se no, 2 per file illeggibile o argomenti sbagliati.

```sh
./estrai-errori.sh dati/app.log
```

L'output inizia così:

```text
2026-11-03 02:14:07 ERROR connessione al database fallita
java.net.ConnectException: Connection refused
    at db.Pool.connect(Pool.java:42)
    at app.Main.main(Main.java:7)
--
2026-11-03 02:15:00 ERROR timeout sulla coda
```

**Verifica.** `../../verifica.sh 17 1`

> [!question]- Indizio 1
> Ogni riga è o l'inizio di un evento o un suo seguito. Quale informazione devi ricordare mentre scorri le righe, per sapere se stampare quella corrente?

> [!question]- Indizio 2
> In `awk` una condizione è una regex o un'espressione; una variabile può fare da «interruttore». Quando lo accendi, quando lo spegni, e quando stampi `--`?

> [!question]- Indizio 3
> Una riga di traccia contiene `ErrorHandler`, un'altra è rientrata e contiene una data. Le tue condizioni le scambiano per l'inizio di un evento?

**Dopo.** Come faresti lo stesso con `grep -z` o con `awk` cambiando `RS`? Cosa fa `journalctl` con i messaggi su più righe? Su Rocky, cosa trovi in `/var/log/messages` quando un programma scrive una traccia su stderr sotto systemd?

---

## Problema 2 — `log-a-csv.sh`

**Situazione.** Il marketing vuole il log del sito in Excel. Il formato *combined* di Apache e nginx sembra fatto di spazi, ma l'agente contiene spazi, virgole e virgolette, e alcune richieste sono rotte.

**Compito.** `./log-a-csv.sh FILE` converte ogni riga del tipo

```text
203.0.113.7 - - [02/Nov/2026:09:14:03 +0100] "GET /index.html HTTP/1.1" 200 5120 "-" "Mozilla/5.0 (X11; Linux)"
```

in una riga CSV, con l'intestazione in testa:

```text
ip,data,metodo,percorso,stato,byte,agente
203.0.113.7,2026-11-02 09:14:03,GET,/index.html,200,5120,Mozilla/5.0 (X11; Linux)
```

- La data diventa `AAAA-MM-GG HH:MM:SS`; il fuso si ignora.
- Byte `-` diventa `0`. Una richiesta `"-"` ha metodo e percorso vuoti.
- Un campo che contiene `,` o `"` va fra virgolette doppie, con le `"` interne raddoppiate, come vuole lo standard CSV (RFC 4180). Nel log una `"` dentro l'agente è scritta `\"`.
- Una riga che non ha questa forma si salta, con `riga N non riconosciuta` su stderr, e alla fine il codice è 1. Altrimenti 0. File illeggibile: 2.

**Verifica.** `../../verifica.sh 17 2`

> [!question]- Indizio 1
> Spezzare sugli spazi non funziona. Scrivi un'espressione con un gruppo per ogni campo. Come descrivi «tutto fino alla prossima virgoletta che non sia preceduta da una barra»?

> [!question]- Indizio 2
> Con `[[ =~ ]]` i gruppi finiscono in `BASH_REMATCH`; con `sed -E` si richiamano con `\1`; `gawk` ha `match()` con un array. Quale ti fa anche trasformare il mese in numero?

> [!question]- Indizio 3
> Prova la riga con `\"` nell'agente. Il tuo gruppo si ferma alla prima virgoletta, all'ultima, o a quella giusta?

**Dopo.** Il tuo CSV si apre bene in LibreOffice? Cosa succede con un agente che contiene un a capo? Quanto ci mette su un milione di righe, e quale strumento sceglieresti per farlo ogni notte?

---

## Diario

Domande numerate, risposte e correzioni di questa lezione.

## Sintesi

Da scrivere a lezione finita, con le tue parole.

---

← [[16-array|Lezione 16]] · ↑ [[00-percorso|Il percorso]] · → [[05-sed-awk|Lezione 05]]
