---
tags:
  - lezione
  - scripting
aliases:
  - Scripting 21 — Rete
---
# Scripting 21 — Rete

Gli script da sistemista parlano con altre macchine: aspettano che un database si alzi, controllano che un sito risponda, leggono la configurazione di rete, avvisano prima che un certificato scada. La rete aggiunge un nemico nuovo: l'attesa che non finisce mai. Si fa dopo la lezione 10. Riferimenti: [[ss-porte|ss e porte]], [[ip-addr|ip addr]], [[ssh|SSH]].

```sh
./prepara.sh 21 && cd palestra/l21
```

Il problema 2 usa un `curl` finto in `dati/bin`, che si comporta come quello vero su un piccolo insieme di siti immaginari. Per provarlo a mano:

```sh
export PATH="$PWD/dati/bin:$PATH"
curl -s -o /dev/null -w '%{http_code}\n' http://sito/mancante
```

## La mappa

| # | Problema | Stato |
|---|---|---|
| 1 | `attendi-porta.sh` — aspettare il database, ma non per sempre | — |
| 2 | `controlla-url.sh` — il sito risponde? | — |
| 3 | `interfacce.sh` — la rete della macchina, da JSON | — |
| 4 | `scade-cert.sh` — il certificato scade fra quanto? | — |

---

## Problema 1 — `attendi-porta.sh`

**Situazione.** Il servizio web parte prima del database e muore perché non trova la porta 5432. Negli script di avvio dei container c'è sempre un pezzo che aspetta: si chiama spesso `wait-for-it`. Lo scrivi tu, e senza `nc`, che sul server non c'è.

> [!info] Il contesto
> **Lo scenario.** Un'applicazione è fatta di più servizi che partono tutti insieme: il sito, il database, la coda dei messaggi. Chi parte per primo trova gli altri non ancora pronti, e si ferma.
> - **Container** (inglese, «contenitore», come quelli delle navi): un pacchetto con un programma e tutto ciò che gli serve, che si avvia in pochi secondi. I container di un'applicazione spesso si avviano insieme.
> - **Porta TCP** (*Transmission Control Protocol*): il numero a cui un servizio aspetta le connessioni. `5432` è quella di PostgreSQL, un database molto usato.
> - **`nc`** (*netcat*, «il gatto della rete», perché fa per la rete ciò che `cat` fa per i file): un coltellino svizzero per le connessioni, che spesso manca sui server ridotti all'osso.
>
> **Perché conta.** Un servizio che muore perché l'altro non era pronto va riavviato a mano. Uno che aspetta per sempre blocca l'avvio di tutta l'applicazione.

**Compito.** `./attendi-porta.sh HOST PORTA SECONDI` riprova a collegarsi finché la porta TCP accetta, ma per non più di `SECONDI` secondi in tutto.

- Codice 0 appena la connessione riesce, 1 se il tempo scade. Su stdout non scrive nulla.
- Un host che non risponde affatto, nemmeno con un rifiuto, non deve far superare il tempo: il correttore prova `10.255.255.1`.
- Porta fuori da 1-65535, `SECONDI` non intero positivo, argomenti sbagliati: codice 2.

**Verifica.** `../../verifica.sh 21 1`. Il correttore apre e chiude porte vere su `127.0.0.1`.

> [!question]- Indizio 1
> Bash sa aprire una connessione TCP da solo, con un percorso che non esiste sul disco. Cerca `/dev/tcp` in `man bash`, sezione *REDIRECTION*. Come la apri, e come la chiudi?

> [!question]- Indizio 2
> Quale ciclo gira *finché una condizione non diventa vera*? E come tieni il conto del tempo passato senza chiamare `date`? Ricorda la variabile `SECONDS`.

> [!question]- Indizio 3
> Con `10.255.255.1` un solo tentativo resta appeso due minuti. Quale comando della lezione 09, già pronto, mette un tempo massimo a un altro comando? Come fai a dargli un tentativo di connessione, che è una redirezione e non un programma?

**Dopo.** Che differenza c'è, per il kernel, fra una porta chiusa e un host che non risponde? Cosa vedi con `ss -tn` mentre il tentativo è appeso? Perché aspettare che la porta sia aperta non basta a sapere che il database è pronto? Cosa fa `pg_isready`?

---

## Problema 2 — `controlla-url.sh`

**Situazione.** Il sito aziendale deve rispondere, e in fretta. Vuoi un controllo da mettere nella tua sentinella della lezione 11: dice il codice HTTP e il tempo, e ha un codice di uscita chiaro.

> [!info] Il contesto
> **Lo scenario.** Il sito aziendale va controllato dall'esterno, come lo vedrebbe un cliente: risponde? risponde bene? risponde in fretta? Il controllo lo lancerà ogni pochi minuti un altro programma.
> - **Sentinella** (da *sentire*, nel senso di «stare in ascolto»: chi fa la guardia): lo script di sorveglianza che scriverai nella lezione 11.
> - **Codice HTTP**: il numero con cui il server risponde, come `200` (tutto bene), `404` (non trovato) o `500` (errore del server).
> - **Tempo di risposta**: quanto passa fra la richiesta e la risposta completa. Un sito che risponde in dieci secondi è guasto, per chi lo usa.
>
> **Perché conta.** Un controllo che dice «ok» quando il sito risponde con una pagina d'errore, o che resta appeso su un sito che non risponde, non serve a niente proprio quando serve.

**Compito.** `./controlla-url.sh URL [SECONDI]` stampa una riga `URL CODICE MILLISECONDI` ed esce con:

| Codice | Quando |
|---|---|
| 0 | Risposta 2xx, anche dopo un redirect, che va seguito |
| 1 | Risposta 4xx o 5xx |
| 2 | Nessuna risposta: connessione rifiutata, oppure più di `SECONDI` secondi (5 se manca). Il codice stampato è `000` |
| 3 | Argomenti sbagliati |

- Il corpo della pagina non si stampa. `MILLISECONDI` è un intero.

**Verifica.** `../../verifica.sh 21 2`. I siti immaginari: `http://sito/` risponde bene, `/mancante` e `/errore` sono errori, `/sposta` è un redirect, `http://giu/` rifiuta la connessione, `http://lento/` non risponde mai.

> [!question]- Indizio 1
> `curl http://sito/mancante; echo $?`: con quale codice esce `curl` quando la pagina non c'è? Per `curl` una risposta 404 è un errore? `man curl`, opzione `--fail`.

> [!question]- Indizio 2
> `man curl`, cerca `--write-out`. Quali variabili danno il codice HTTP e il tempo totale? E quale opzione butta il corpo?

> [!question]- Indizio 3
> `http://lento/` blocca il tuo script? Quale opzione di `curl` mette un tempo massimo a tutta l'operazione? E come trasformi `0.123456` secondi in millisecondi interi, visto che la shell non ha decimali?

**Dopo.** Perché `curl -I` a volte dà un codice diverso da una richiesta normale? Cosa fa `--retry`? Come misureresti a parte il tempo di connessione e quello di risposta del server? Con `-k` cosa rinunci a controllare?

---

## Problema 3 — `interfacce.sh`

**Situazione.** Devi fare l'inventario della rete di cento VM. L'output di `ip addr` è pensato per gli occhi, cambia fra versioni e si rompe con le espressioni regolari. Da anni `ip` sa parlare JSON, e per il JSON c'è `jq`.

> [!info] Il contesto
> **Lo scenario.** Il responsabile chiede un elenco di tutti gli indirizzi delle macchine virtuali, da mettere nella documentazione. Raccoglierli a mano da cento terminali è impensabile.
> - **Interfaccia di rete**: il punto attraverso cui una macchina comunica, fisico come una scheda o virtuale come un ponte verso i container. Si chiama con nomi come `lo`, `enp0s3` o `wg0`.
> - **IPv4** (*Internet Protocol version 4*, 1981): gli indirizzi di quattro numeri separati da punti, come `10.0.2.15`. Un'interfaccia può averne più d'uno, o nessuno.
> - **JSON** (*JavaScript Object Notation*): un formato di testo con campi etichettati, pensato per essere letto dai programmi.
>
> **Perché conta.** Un'estrazione che si basa sull'aspetto dell'output si rompe al primo aggiornamento del sistema, e l'inventario diventa sbagliato senza che nessuno lo noti.

**Compito.** `./interfacce.sh [FILE]` legge l'output di `ip -j addr` da `FILE` o, se manca, lo chiede a `ip`. Stampa una riga per ogni indirizzo IPv4, nell'ordine dell'output:

```text
NOME STATO INDIRIZZO/PREFISSO
```

Un'interfaccia senza IPv4 stampa una riga con `-` al posto dell'indirizzo. Per `dati/ip-addr.json`:

```text
lo UNKNOWN 127.0.0.1/8
enp0s3 UP 10.0.2.15/24
enp0s8 UP 192.168.56.10/24
enp0s8 UP 192.168.56.11/24
docker0 DOWN 172.17.0.1/16
wg0 UNKNOWN -
```

File illeggibile o JSON non valido: codice 2.

**Verifica.** `../../verifica.sh 21 3`

> [!question]- Indizio 1
> Guarda il file con `jq . dati/ip-addr.json | less`. Com'è fatto: un oggetto o un array? Dove stanno nome, stato e indirizzi?

> [!question]- Indizio 2
> In `jq`, `.[]` scorre un array e `select()` filtra. Come tieni solo gli indirizzi con `family` uguale a `inet`? Come costruisci una stringa con più campi?

> [!question]- Indizio 3
> L'interfaccia senza IPv4 sparisce del tutto? Cosa produce `jq` su un array vuoto, e come dai un valore di ripiego? Cerca `//` e `if` nel manuale di `jq`.

**Dopo.** Cosa fa `jq -r`? Quali altri comandi di Rocky parlano JSON? Prova `lsblk -J`, `ss -j` (se c'è), `systemctl show --output=json`, `nmcli -t`. Perché il JSON è meglio del testo per gli script, e cosa costa?

---

## Problema 4 — `scade-cert.sh`

**Situazione.** Un certificato scaduto ferma un sito più di un guasto hardware, e capita sempre di domenica. Vuoi un avviso con un mese di anticipo.

> [!info] Il contesto
> **Lo scenario.** Ogni sito in HTTPS ha un certificato con una data di scadenza, di solito fra tre mesi e un anno. Lo rinnova qualcuno, se se ne ricorda; quando nessuno se ne ricorda, il sito diventa irraggiungibile per i browser.
> - **Certificato**: un documento digitale, firmato da un ente di cui i browser si fidano, che lega un nome di sito a una chiave crittografica. È ciò che fa apparire il lucchetto.
> - **PEM** (*Privacy-Enhanced Mail*, un progetto del 1993 per la posta cifrata): il formato di testo con le righe `-----BEGIN CERTIFICATE-----`, rimasto in uso anche se il progetto è stato abbandonato.
> - **Common Name** (`CN`, «nome comune»): il campo del certificato che, per tradizione, contiene il nome del sito.
>
> **Perché conta.** Un certificato scaduto non dà preavviso: il sito funziona fino a un istante preciso, poi i browser rifiutano di aprirlo. Un mese di anticipo dà il tempo di rinnovarlo con calma.

**Compito.** `./scade-cert.sh FILE [GIORNI]`, dove `FILE` è un certificato PEM e `GIORNI` è 30 se manca. La data di oggi è quella UTC, oppure quella della variabile `OGGI` (`AAAA-MM-GG`), per le prove.

| Situazione | Stampa | Codice |
|---|---|---|
| Mancano più di `GIORNI` giorni | `NOME scade il AAAA-MM-GG, fra N giorni` | 0 |
| Ne mancano `GIORNI` o meno | come sopra | 1 |
| È già scaduto | `NOME è scaduto il AAAA-MM-GG, da N giorni` | 2 |
| File mancante, non è un certificato, argomenti sbagliati | spiegazione su stderr | 3 |

- `NOME` è il *Common Name* (`CN`) del soggetto, anche con spazi; `-` se non c'è.
- La data è quella di scadenza, in UTC. I giorni si contano fra le date, senza l'ora.

**Verifica.** `../../verifica.sh 21 4`. Il correttore crea i certificati al momento, con `openssl`.

> [!question]- Indizio 1
> `man openssl-x509`: quali opzioni stampano solo la data di fine e il soggetto? Com'è scritta la data? `date -d` la capisce?

> [!question]- Indizio 2
> Il soggetto si stampa in modi diversi a seconda della versione di `openssl`: `CN = nome` oppure `CN=nome`. Come estrai il nome senza dipendere dagli spazi? Esiste anche un'opzione `-nameopt`.

> [!question]- Indizio 3
> Due date, un numero di giorni: hai già fatto questo conto nella lezione 07. Perché conviene lavorare in UTC?

**Dopo.** Come controlleresti il certificato di un sito vivo invece che un file? Prova `openssl s_client -connect host:443 -servername host </dev/null`. Cosa sono la catena e il `-servername`? Cosa fa `openssl x509 -checkend`?

---

## Diario

Domande numerate, risposte e correzioni di questa lezione.

## Sintesi

Da scrivere a lezione finita, con le tue parole.

---

← [[10-automazione|Lezione 10]] · ↑ [[00-percorso|Il percorso]] · → [[22-sicurezza-portabilita|Lezione 22]]
