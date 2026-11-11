---
tags:
  - lezione
  - scripting
aliases:
  - Scripting 18 — Redirezioni, here-doc e interazione
---
# Scripting 18 — Redirezioni, here-doc e interazione

Uno script vive di tre canali: legge da 0, scrive su 1, si lamenta su 2. Le redirezioni li ricollegano, e il loro ordine conta; gli *here-doc* generano file interi; `exec` cambia i canali di tutto lo script; `read` fa domande a un umano, se c'è. Si fa dopo la lezione 06. Riferimenti: [[file-descriptor|File descriptor]], [[redirezione-pipe|Redirezione e pipe]], sezione *REDIRECTION* di `man bash`.

```sh
./prepara.sh 18 && cd palestra/l18
```

## La mappa

| # | Problema | Stato |
|---|---|---|
| 0 | Previsioni — carta e penna, poi la prova | — |
| 1 | `genera-vhost.sh` — un file di configurazione da un modello | — |
| 2 | `con-log.sh` — vedere e registrare, senza perdere il codice | — |
| 3 | `chiedi.sh` — sei sicuro? | — |

---

## Problema 0 — Previsioni

**Situazione.** `2>&1 >file` e `>file 2>&1` sembrano la stessa cosa. Non lo sono, e la differenza la scopri quando un errore sparisce.

**Compito.** Lavora in una cartella vuota. Per ogni riga scrivi **prima** cosa compare sul terminale e cosa finisce nei file, poi lanciala.

```sh
ls /etc/passwd /nessuno >out 2>&1; cat out
ls /etc/passwd /nessuno 2>&1 >out; echo ---; cat out
ls /nessuno 2>&1 | wc -l
ls /nessuno 2>/dev/null | wc -l
{ echo uno; echo due >&2; } >out 2>err; cat out err
echo ciao >out >altro; cat out altro
set -o noclobber; echo x >out; echo y >|out; cat out; set +o noclobber
cat <<FINE
casa: $HOME, oggi: $(date +%A)
FINE
cat <<'FINE'
casa: $HOME, oggi: $(date +%A)
FINE
cat <<-FINE
		rientrato con tab
	FINE
tr a-z A-Z <<<"una stringa"
exec 3>tre.txt; echo nel tre >&3; exec 3>&-; cat tre.txt
exec 4<&0; read -r riga <<<"da qui"; echo "$riga"
echo errore >&2 2>/dev/null
( echo dentro; ls /nessuno ) 2>&1 | sed 's/^/| /'
```

**Verifica.** Si controlla a mano, con Claude.

**Dopo.** In che ordine bash applica le redirezioni di un comando? Cosa fa esattamente `2>&1`: copia il canale o lo collega per sempre? Perché `cmd >file 2>&1` e `cmd &>file` sono uguali, e cosa fa `|&`? Dove finisce un here-doc: in un file temporaneo o in una pipe? Prova `ls -l /proc/self/fd/0 <<<x`.

---

## Problema 1 — `genera-vhost.sh`

**Situazione.** Ogni nuovo sito sul server web vuole il suo blocco di configurazione. Scriverlo a mano porta errori di battitura; generarlo con `echo` riga per riga è illeggibile. E nginx usa variabili con il `$`, proprio come la shell.

**Compito.** `./genera-vhost.sh NOME PORTA RADICE` stampa esattamente:

```text
# generato da genera-vhost.sh: non modificare a mano
server {
    listen 8080;
    server_name sito.example;
    root "/srv/www/sito uno";
    access_log /var/log/nginx/sito.example.log;

    location / {
        try_files $uri $uri/ =404;
    }

    location /stato {
        return 200 "ok da $hostname\n";
    }
}
```

con i tuoi valori al posto di `sito.example`, `8080` e `/srv/www/sito uno`. `$uri`, `$hostname` e `\n` sono di nginx e restano così.

- `NOME` è fatto di minuscole, cifre, punti e trattini; `PORTA` va da 1 a 65535; `RADICE` è un percorso assoluto. Altrimenti, o con un numero di argomenti sbagliato, codice 2 e nulla su stdout.

**Verifica.** `../../verifica.sh 18 1`

> [!question]- Indizio 1
> Prova le righe 8-13 del problema 0. Ti serve che alcune variabili si espandano e altre no, nello stesso testo. Quali modi hai per impedire a un singolo `$` di essere interpretato?

> [!question]- Indizio 2
> E la barra rovesciata di `\n`? In un here-doc senza virgolette, quali caratteri dopo `\` hanno un significato speciale? Cerca *Here Documents* in `man bash`.

> [!question]- Indizio 3
> Il rientro del modello è di quattro spazi. Se rientri anche il tuo here-doc per leggibilità, cosa finisce nell'output? Cosa toglie `<<-`, e cosa no?

**Dopo.** Confronta questo modo con `genera-conf.sh` della lezione 05: quando conviene l'uno e quando l'altro? Come scriveresti il file solo se è cambiato, per non far ricaricare nginx inutilmente? Su Rocky, dove vanno i blocchi `server` e cosa controlla `nginx -t`? Con SELinux attivo, una `RADICE` sotto `/home` funzionerebbe?

---

## Problema 2 — `con-log.sh`

**Situazione.** Durante un aggiornamento vuoi vedere l'output del comando mentre gira e, insieme, conservarne una copia con l'ora, per il rapporto. Con `comando | tee file` il codice di uscita diventa quello di `tee`, e gli errori si mescolano all'output.

**Compito.** `./con-log.sh FILE COMANDO [ARG...]`:

- Esegue il comando. Il suo stdout arriva sullo stdout, il suo stderr sullo stderr, inalterati e separati. Lo stdin passa al comando.
- Aggiunge a `FILE` ogni riga, nella forma `HH:MM:SS out| riga` o `HH:MM:SS err| riga`, anche l'ultima senza a capo.
- In fondo aggiunge `HH:MM:SS fine codice N`. Quando lo script termina, il file è **completo**.
- Esce con il codice del comando. Pochi argomenti: codice 2.

**Verifica.** `../../verifica.sh 18 2`

> [!question]- Indizio 1
> Parti da `comando | tee -a file`. Cosa perdi? Quale variabile della lezione 12 ti restituisce il codice giusto?

> [!question]- Indizio 2
> Ora i flussi sono due e ciascuno va trattato a parte. Hai già usato una costruzione che dà a un comando un «file» che in realtà è un processo. Dove la metti, dopo `>` e dopo `2>`?

> [!question]- Indizio 3
> Il correttore legge il file appena lo script è uscito e trova righe mancanti, o la riga `fine` non in fondo? Chi aspetta i processi lanciati con `>(...)`? Se nessuno li aspetta, esiste un modo di ottenere due flussi separati usando solo pipe, che la shell aspetta sempre? Pensa a scambiare 1 e 2 con un terzo descrittore.

**Dopo.** L'ordine delle righe `out` ed `err` nel file è quello reale? Perché no, e cosa c'entra il *buffering* dei programmi quando scrivono in una pipe invece che su un terminale? Cosa fa `stdbuf -oL`? Come ottieni lo stesso effetto per tutto uno script con `exec`?

---

## Problema 3 — `chiedi.sh`

**Situazione.** Lo script di rilascio, prima di toccare la produzione, deve chiedere conferma. Ma lo stesso script gira anche di notte senza nessuno davanti, e lì una domanda senza risposta lo bloccherebbe per sempre.

**Compito.** `./chiedi.sh DOMANDA [PREDEFINITO]`, dove `PREDEFINITO` è `s` o `n`.

- Scrive su **stderr** `DOMANDA [s/n] ` (con `[S/n]` o `[s/N]` se c'è un predefinito), sempre, anche quando lo stdin non è un terminale, e legge una riga dallo stdin. Su stdout non scrive mai nulla.
- `s`, `si`, `sì`, `y`, `yes`, con qualsiasi maiuscola, danno codice 0; `n`, `no` danno 1. Gli spazi intorno si ignorano.
- Una riga vuota vale il predefinito; senza predefinito si richiede.
- Qualsiasi altra risposta: `rispondi s o n` su stderr e si richiede. Dopo tre risposte non valide: codice 2.
- Se lo stdin finisce senza risposta, o se `CHIEDI_TEMPO` è impostata e passano quei secondi, vale il predefinito; senza predefinito, codice 2.
- `PREDEFINITO` diverso da `s` o `n`, o argomenti sbagliati: codice 2.

**Verifica.** `../../verifica.sh 18 3`

> [!question]- Indizio 1
> `help read`: quali opzioni scrivono un invito e impongono un tempo massimo? Leggi bene la frase sull'invito: compare sempre? Come distingui uno stdin finito da una riga vuota, guardando il codice di uscita?

> [!question]- Indizio 2
> Perché la domanda va su stderr? Pensa a `if ./chiedi.sh "Procedo?"; then ...` e a `risposta=$(./chiedi.sh ...)`.

> [!question]- Indizio 3
> `SÌ` funziona? Le maiuscole delle lettere accentate dipendono dalla lingua: puoi elencare le forme accettate in un `case` invece di convertire.

**Dopo.** Come sai, da dentro uno script, se c'è un terminale collegato? Cerca `-t` fra i test. Cosa fa `read -s`, e perché serve per le password? Dove legge `sudo` la password, se lo stdin è un file? Guarda `/dev/tty`.

---

## Diario

Domande numerate, risposte e correzioni di questa lezione.

## Sintesi

Da scrivere a lezione finita, con le tue parole.

---

← [[06-robustezza|Lezione 06]] · ↑ [[00-percorso|Il percorso]] · → [[19-debug-test|Lezione 19]]
