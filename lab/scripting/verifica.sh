#!/usr/bin/env bash
# Correttore delle lezioni di scripting. Prova il comportamento dei tuoi script
# dall'esterno: non contiene soluzioni, solo casi di prova e risultati attesi.
#
#   ./verifica.sh 04        tutti i problemi della lezione 04
#   ./verifica.sh 04 2      solo il problema 2
#
# Gli script girano in cartelle temporanee, con un tempo massimo e con guardie su
# rm e find che bloccano le cancellazioni fuori da lì. Le guardie intercettano solo
# i comandi cercati nel PATH: restano valide le cautele scritte nelle lezioni.
set -u

RADICE=$(cd "$(dirname "$0")" && pwd)
PALESTRA=${PALESTRA:-$RADICE/palestra}
LIMITE=${LIMITE:-20}
PASSATE=0
FALLITE=0
export LC_ALL=C

BASE=$(cd "$(mktemp -d)" && pwd -P)
GUARDIA=$BASE/guardia
TV=$BASE/lavoro
mkdir -p "$GUARDIA" "$TV"
trap 'chmod -R u+rwx "$BASE" 2>/dev/null; command rm -rf "$BASE"' EXIT
export TMPDIR=$TV

scrivi_guardie() {
    local vero_rm vero_find
    vero_rm=$(type -P rm)
    vero_find=$(type -P find)
    cat >"$GUARDIA/rm" <<EOF
#!/usr/bin/env bash
for a in "\$@"; do
    [[ \$a == -* ]] && continue
    [[ \$a == /* ]] && p=\$a || p=\$PWD/\$a
    if [[ \$p != "$BASE"/* ]]; then
        echo "GUARDIA: bloccato rm su \$p" >&2
        echo "\$p" >>"$BASE/bloccati"
        exit 99
    fi
done
exec "$vero_rm" "\$@"
EOF
    cat >"$GUARDIA/find" <<EOF
#!/usr/bin/env bash
pericoloso=0
for a in "\$@"; do
    case \$a in -delete | -exec | -execdir | -ok) pericoloso=1 ;; esac
done
if (( pericoloso )); then
    for a in "\$@"; do
        [[ \$a == -* ]] && break
        [[ \$a == /* ]] && p=\$a || p=\$PWD/\$a
        if [[ \$p != "$BASE"/* ]]; then
            echo "GUARDIA: bloccato find su \$p" >&2
            echo "\$p" >>"$BASE/bloccati"
            exit 99
        fi
    done
fi
exec "$vero_find" "\$@"
EOF
    chmod +x "$GUARDIA/rm" "$GUARDIA/find"
}

# ---- Strumenti di prova ----------------------------------------------------

passa() { PASSATE=$((PASSATE + 1)); printf '  ok    %s\n' "$1"; }
boccia() {
    FALLITE=$((FALLITE + 1))
    printf '  NO    %s\n' "$1"
    shift
    local r
    for r in "$@"; do printf '        %s\n' "$r"; done
}

# Lancia un comando riempiendo OUT, ERR e RC. INGRESSO indica il file da usare
# come standard input.
INGRESSO=/dev/null
lancia() {
    local e=$BASE/stderr
    : >"$e"
    OUT=$(PATH="$GUARDIA:$PATH" timeout "$LIMITE" "$@" 2>"$e" <"$INGRESSO")
    RC=$?
    ERR=$(cat "$e")
    if [[ -s $BASE/bloccati ]]; then
        boccia "cancellazione fuori dalla sandbox" "ha provato a cancellare: $(paste -sd' ' "$BASE/bloccati")" \
            "Fermati e rileggi lo script prima di rilanciarlo fuori dal correttore."
        command rm -f "$BASE/bloccati"
    fi
    if [[ $RC -eq 124 ]]; then
        ERR="$ERR (interrotto dopo ${LIMITE}s: ciclo infinito o attesa di un input?)"
    fi
}

# codice DESCRIZIONE CODICE_ATTESO COMANDO...
codice() {
    local d=$1 a=$2
    shift 2
    lancia "$@"
    if [[ $RC -eq $a ]]; then passa "$d"; else boccia "$d" "codice di uscita atteso $a, ottenuto $RC" "stderr: ${ERR:-(vuoto)}"; fi
}

# uscita DESCRIZIONE STDOUT_ATTESO COMANDO...
uscita() {
    local d=$1 a=$2
    shift 2
    lancia "$@"
    if [[ $OUT == "$a" ]]; then
        passa "$d"
    else
        boccia "$d" "--- atteso ---" "$a" "--- ottenuto (codice $RC) ---" "$OUT" "--- stderr ---" "${ERR:-(vuoto)}"
    fi
}

# vero DESCRIZIONE CONDIZIONE...   (la condizione gira senza guardie né limiti)
vero() {
    local d=$1
    shift
    if "$@"; then passa "$d"; else boccia "$d" "condizione non vera: $*"; fi
}

# trova il valore di una chiave "chiave: valore" nell'ultimo OUT
campo() { sed -n "s/^$1: //p" <<<"$OUT"; }

corrisponde() { [[ $1 =~ $2 ]]; }

tmp() { mktemp -d "$TV/XXXXXX"; }

# interni COMANDO...: lancia lo script con bash ma senza PATH, così che funzionino
# solo i comandi interni della shell.
BASH_VERO=$(type -P bash)
interni() { lancia env PATH=/senza-path "$BASH_VERO" "$@"; }

# Controlla che lo script esista e sia eseguibile, e lo mette in X.
script() {
    X=$L/$1
    if [[ ! -e $X ]]; then
        boccia "$1 esiste" "manca $X"
        return 1
    fi
    if [[ ! -x $X ]]; then
        boccia "$1 è eseguibile" "il file c'è ma non ha il permesso di esecuzione"
        return 1
    fi
    if command -v shellcheck >/dev/null; then
        local avvisi
        avvisi=$(shellcheck -f gcc "$X" 2>/dev/null | wc -l)
        if ((avvisi > 0)); then printf '  nota  shellcheck ha %s osservazioni su %s: leggile\n' "$avvisi" "$1"; fi
    fi
    return 0
}

# ---- Lezione 01 ------------------------------------------------------------

p_01_1() {
    script scheda.sh || return
    lancia "$X"
    vero "host corretto" test "$(campo host)" = "$(uname -n)"
    vero "kernel corretto" test "$(campo kernel)" = "$(uname -r)"
    vero "utente corretto" test "$(campo utente)" = "$(id -un)"
    vero "core corretti" test "$(campo core)" = "$(nproc)"
    vero "ram_mib è un numero" corrisponde "$(campo ram_mib)" '^[0-9]+$'
    vero "disco_root_libero ha un'unità" corrisponde "$(campo disco_root_libero)" '^[0-9.,]+[KMGT]$'
    codice "termina con codice 0" 0 "$X"
}

p_01_2() {
    script argomenti.sh || return
    local a=$'script: argomenti.sh\nquanti: 4\n1: uno\n2: due tre\n3: quattro'
    uscita "conserva gli spazi di un argomento" "$a" "$X" uno "due tre" quattro cinque
    local t
    t=$(tmp)
    uscita "stampa il nome anche se lanciato da altrove" "$a" env -C "$t" "$X" uno "due tre" quattro cinque
}

p_01_3() {
    script salva-conf.sh || return
    local t oggi
    t=$(tmp)
    oggi=$(date +%Y%m%d)
    printf 'porta = 8080\n' >"$t/conf di prova.ini"
    codice "riesce su un nome con spazi" 0 "$X" "$t/conf di prova.ini" "$t/copie/di oggi"
    vero "copia nel posto giusto" test -f "$t/copie/di oggi/conf di prova.ini.$oggi"
    vero "copia identica" cmp -s "$t/conf di prova.ini" "$t/copie/di oggi/conf di prova.ini.$oggi"
    lancia "$X" "$t/non-esiste.ini" "$t/copie"
    vero "file mancante: codice diverso da 0" test "$RC" -ne 0
}

p_01_4() {
    script conta-righe.sh || return
    uscita "nome con spazi" "$L/dati/nome con spazi.log: 12 righe" "$X" "$L/dati/nome con spazi.log"
    uscita "file di una riga" "$L/dati/corto.log: 1 righe" "$X" "$L/dati/corto.log"
}

# ---- Lezione 02 ------------------------------------------------------------

p_02_1() {
    script utente-esiste.sh || return
    local f=$L/dati/passwd
    codice "root esiste" 0 "$X" root "$f"
    codice "mario esiste" 0 "$X" mario "$f"
    codice "gianni esiste" 0 "$X" gianni "$f"
    codice "'pippo' non esiste" 1 "$X" pippo "$f"
    codice "'mar' è solo l'inizio di un nome" 1 "$X" mar "$f"
    codice "'bash' compare, ma non come nome" 1 "$X" bash "$f"
    codice "'1000' compare, ma non come nome" 1 "$X" 1000 "$f"
    codice "'m.rio' non è un nome: il punto non è un jolly" 1 "$X" 'm.rio' "$f"
    codice "senza argomenti: uso sbagliato" 2 "$X"
    vero "l'errore d'uso va su stderr" test -n "$ERR"
    vero "...e non su stdout" test -z "$OUT"
    codice "secondo argomento omesso: usa /etc/passwd" 0 "$X" root
    codice "file passwd inesistente: uso sbagliato" 2 "$X" root "$f.manca"
}

p_02_2() {
    script soglia-disco.sh || return
    local f=$L/dati/df.txt
    INGRESSO=$f
    uscita "/ al 42%" "OK / 42%" "$X" 80 90 /
    uscita "/var all'85%" "WARNING /var 85%" "$X" 80 90 /var
    vero "...codice 1" test "$RC" -eq 1
    uscita "/home al 96%" "CRITICAL /home 96%" "$X" 80 90 /home
    vero "...codice 2" test "$RC" -eq 2
    uscita "/boot al 9%: confronto fra numeri" "OK /boot 9%" "$X" 80 90 /boot
    vero "...codice 0" test "$RC" -eq 0
    uscita "/var/log è un'altra riga rispetto a /var" "CRITICAL /var/log 97%" "$X" 80 90 /var/log
    uscita "soglia esatta: 85 con soglia 85 è WARNING" "WARNING /var 85%" "$X" 85 90 /var
    uscita "punto di mount assente: / di default" "OK / 42%" "$X" 80 90
    codice "mount inesistente: codice 3" 3 "$X" 80 90 /nessuno
    codice "soglie invertite: codice 3" 3 "$X" 90 80 /
    codice "soglia non numerica: codice 3" 3 "$X" alta 90 /
    codice "argomenti mancanti: codice 3" 3 "$X"
    INGRESSO=/dev/null
}

p_02_3() {
    script estrai.sh || return
    local t d=$L/dati
    t=$(tmp)
    codice ".tar" 0 "$X" "$d/pacchetto.tar" "$t/a"
    vero "...estratto" test -f "$t/a/sito/index.html"
    codice ".tar.gz" 0 "$X" "$d/pacchetto.tar.gz" "$t/b"
    vero "...estratto" test -f "$t/b/sito/index.html"
    codice ".tgz" 0 "$X" "$d/pacchetto.tgz" "$t/c c"
    vero "...estratto in una cartella con spazi" test -f "$t/c c/sito/index.html"
    codice ".gz singolo" 0 "$X" "$d/nota.txt.gz" "$t/e"
    vero "...decompresso senza .gz" test -f "$t/e/nota.txt"
    vero "...l'originale resta al suo posto" test -f "$d/nota.txt.gz"
    codice "formato sconosciuto" 2 "$X" "$d/strano.rar" "$t/f"
    codice "archivio inesistente" 3 "$X" "$d/manca.tar" "$t/g"
    codice "pochi argomenti" 1 "$X" "$d/pacchetto.tar"
}

# ---- Lezione 03 ------------------------------------------------------------

p_03_1() {
    script aggiungi-suffisso.sh || return
    local t
    t=$(tmp)
    cp -R "$L/dati/nomi-difficili" "$t/x"
    codice "riesce sui nomi difficili" 0 "$X" bak "$t/x"
    vero "uno.txt.bak" test -f "$t/x/uno.txt.bak"
    vero "'due parole.txt.bak'" test -f "$t/x/due parole.txt.bak"
    vero "-inizia-col-trattino.txt.bak" test -f "$t/x/-inizia-col-trattino.txt.bak"
    vero "'asterisco*.txt.bak'" test -f "$t/x/asterisco*.txt.bak"
    vero "chi ha già il suffisso non lo raddoppia" test -f "$t/x/gia.bak"
    vero "le cartelle non si toccano" test -d "$t/x/una_cartella"
    vero "il conteggio dei file non cambia" test "$(ls -A "$t/x" | wc -l)" -eq 6
    lancia "$X" bak "$t/x"
    vero "rilanciato non cambia nulla" test -z "$OUT" -a "$RC" -eq 0
    cp -R "$L/dati/vuota" "$t/v"
    uscita "cartella vuota: nessun output" "" "$X" bak "$t/v"
    vero "...e nessun file strano" test "$(ls -A "$t/v" | wc -l)" -eq 0
    mkdir "$t/qui"
    : >"$t/qui/a"
    codice "senza cartella: quella corrente" 0 env -C "$t/qui" "$X" bak
    vero "...rinominato" test -f "$t/qui/a.bak"
    codice "senza argomenti: errore" 2 "$X"
}

p_03_2() {
    script riprova.sh || return
    local t
    t=$(tmp)
    codice "riesce al terzo tentativo" 0 "$X" 5 0 "$L/dati/instabile.sh" "$t/cnt"
    vero "...e si ferma lì" test "$(cat "$t/cnt")" -eq 3
    vero "...segnalando i fallimenti su stderr" test "$(grep -c 'tentativo' <<<"$ERR")" -eq 2
    rm -f "$t/cnt"
    codice "troppo pochi tentativi: fallisce" 1 "$X" 2 0 "$L/dati/instabile.sh" "$t/cnt"
    vero "...dopo esattamente 2" test "$(cat "$t/cnt")" -eq 2
    codice "restituisce il codice dell'ultimo tentativo" 7 "$X" 2 0 sh -c 'exit 7'
    uscita "conserva gli argomenti con spazi" "a b" "$X" 1 0 printf '%s\n' "a b"
    local inizio fine
    inizio=$SECONDS
    lancia "$X" 2 1 false
    fine=$SECONDS
    vero "nessuna pausa dopo l'ultimo tentativo" test $((fine - inizio)) -lt 2
    codice "tentativi non numerici: errore d'uso" 2 "$X" tanti 0 true
    codice "senza comando: errore d'uso" 2 "$X" 3 0
}

p_03_3() {
    script vecchi.sh || return
    local t a
    t=$(tmp)
    cp -pR "$L/dati/vecchi" "$t/v"
    a="$t/v/cache/x.tmp
$t/v/log/app log.2
$t/v/log/app.log.1
totale: 3 file, 3300 byte"
    uscita "elenca i file più vecchi di 30 giorni" "$a" "$X" "$t/v" 30
    vero "senza --cancella non tocca nulla" test -f "$t/v/cache/x.tmp"
    uscita "con 50 giorni ne resta uno" "$t/v/log/app log.2
totale: 1 file, 2000 byte" "$X" "$t/v" 50
    uscita "nessun risultato" "totale: 0 file, 0 byte" "$X" "$t/v" 365
    uscita "--cancella elenca e cancella" "$a" "$X" "$t/v" 30 --cancella
    vero "...i vecchi sono spariti" test ! -e "$t/v/log/app log.2"
    vero "...i recenti no" test -f "$t/v/log/app.log" -a -f "$t/v/cache/recente.tmp"
    vero "...le cartelle no" test -d "$t/v/log"
    codice "cartella inesistente" 1 "$X" "$t/manca" 30
    codice "giorni non numerici" 2 "$X" "$t/v" molti
    codice "pochi argomenti" 2 "$X" "$t/v"
}

# ---- Lezione 04 ------------------------------------------------------------

p_04_1() {
    script percorso.sh || return
    uscita "classifica ogni elemento" "/bin ok
/non/esiste manca
/bin duplicato
(vuoto) pericoloso
/usr/bin ok" "$X" "/bin:/non/esiste:/bin::/usr/bin"
    uscita "un solo elemento" "/bin ok" "$X" "/bin"
    local t
    t=$(tmp)
    : >"$t/file"
    uscita "un file non è una cartella" "$t/file manca" "$X" "$t/file"
    mkdir "$t/con spazio"
    uscita "cartella con spazio" "$t/con spazio ok" "$X" "$t/con spazio"
    codice "senza argomenti usa \$PATH" 0 "$X"
    vero "...e stampa almeno una riga" test -n "$OUT"
}

p_04_2() {
    script utenti-reali.sh || return
    uscita "solo persone, in ordine" "anna /home/anna /bin/bash
mario /home/mario /bin/bash
marta /home/marta /bin/zsh
zeno /home/zeno /bin/bash" "$X" "$L/dati/passwd"
    codice "file mancante" 1 "$X" "$L/dati/manca"
    codice "senza argomenti usa /etc/passwd" 0 "$X"
}

p_04_3() {
    script top-ip.sh || return
    local f=$L/dati/access.log
    uscita "i primi 5, col pareggio ordinato per IP" "120 203.0.113.7
85 198.51.100.23
60 192.0.2.44
40 203.0.113.9
25 192.0.2.10" "$X" "$f"
    uscita "N scelto a mano" "120 203.0.113.7
85 198.51.100.23" "$X" "$f" 2
    uscita "il pareggio del sesto posto" "25 192.0.2.10
25 198.51.100.5" bash -c '"$1" "$2" 6 | tail -n 2' _ "$X" "$f"
    codice "file mancante" 1 "$X" "$f.manca"
}

p_04_4() {
    script ssh-attacchi.sh || return
    local f=$L/dati/auth.log
    uscita "soglia 5" "203.0.113.7 42
198.51.100.23 9
198.51.100.66 6" "$X" "$f" 5
    uscita "soglia 10" "203.0.113.7 42" "$X" "$f" 10
    uscita "soglia 4 include 192.0.2.44" "203.0.113.7 42
198.51.100.23 9
198.51.100.66 6
192.0.2.44 4" "$X" "$f" 4
    uscita "soglia altissima: niente" "" "$X" "$f" 1000
    codice "soglia non numerica" 2 "$X" "$f" tanti
    codice "file mancante" 1 "$X" "$f.manca" 5
}

# ---- Lezione 05 ------------------------------------------------------------

p_05_1() {
    script genera-conf.sh || return
    local f=$L/dati/sito.conf.tmpl
    uscita "valori con / e &" 'server {
    server_name esempio.it;
    root /var/www/sito;
    add_header X-Titolo "A&B";
    # esempio.it gestito da anna
}' "$X" "$f" DOMINIO=esempio.it ROOT=/var/www/sito 'TITOLO=A&B' ADMIN=anna
    codice "tutto riempito: codice 0" 0 "$X" "$f" DOMINIO=d ROOT=r TITOLO=t ADMIN=a
    codice "segnaposto rimasto: codice 1" 1 "$X" "$f" DOMINIO=d ROOT=r
    vero "...e stderr nomina chi manca" grep -q 'TITOLO' <<<"$ERR"
    vero "...anche il secondo" grep -q 'ADMIN' <<<"$ERR"
    uscita "un valore con = dentro" 'server {
    server_name a=b;
    root r;
    add_header X-Titolo "t";
    # a=b gestito da a
}' "$X" "$f" DOMINIO=a=b ROOT=r TITOLO=t ADMIN=a
    codice "template mancante: codice 2" 2 "$X" "$f.manca" A=b
}

p_05_2() {
    script report-http.sh || return
    uscita "il rapporto completo" "richieste: 370
2xx: 282
3xx: 45
4xx: 33
5xx: 10
byte_totali: 923109
ora_di_punta: 09 (157)" "$X" "$L/dati/access.log"
    codice "file mancante" 1 "$X" "$L/dati/manca.log"
}

p_05_3() {
    script imposta.sh || return
    local t f
    t=$(tmp)
    f=$t/sshd_config
    cp "$L/dati/sshd_config" "$f"
    uscita "una chiave commentata si attiva" "cambiato" "$X" "$f" Port 2222
    vero "...al suo posto" grep -qx 'Port 2222' "$f"
    vero "...senza lasciare il vecchio commento" test "$(grep -c '^#Port' "$f")" -eq 0
    vero "...con la copia di sicurezza" test -f "$f.bak"
    vero "...che contiene la versione precedente" grep -q '^#Port 22$' "$f.bak"
    uscita "rifarlo non cambia nulla" "invariato" "$X" "$f" Port 2222
    vero "...e la copia resta quella di prima" grep -q '^#Port 22$' "$f.bak"
    uscita "una chiave attiva si sostituisce" "cambiato" "$X" "$f" PermitRootLogin no
    vero "...il nuovo valore c'è" grep -qx 'PermitRootLogin no' "$f"
    vero "...il commento discorsivo no" grep -qx '# PermitRootLogin va disattivato in produzione' "$f"
    uscita "non confonde chiavi con lo stesso inizio" "cambiato" "$X" "$f" PasswordAuthentication no
    vero "...la chiave giusta" grep -qx 'PasswordAuthentication no' "$f"
    vero "...l'altra è intatta" grep -qx 'PasswordAuthenticationExtra no' "$f"
    uscita "con attiva e commentata tocca l'attiva" "cambiato" "$X" "$f" UsePAM no
    vero "...nuovo valore" grep -qx 'UsePAM no' "$f"
    vero "...commento intatto" grep -qx '#UsePAM yes' "$f"
    uscita "una chiave nuova si aggiunge" "cambiato" "$X" "$f" MaxAuthTries 3
    vero "...in fondo" test "$(tail -n 1 "$f")" = "MaxAuthTries 3"
    uscita "un valore con /" "cambiato" "$X" "$f" Banner /etc/issue.net
    vero "...scritto bene" grep -qx 'Banner /etc/issue.net' "$f"
    codice "file mancante" 1 "$X" "$f.manca" a b
    codice "pochi argomenti" 2 "$X" "$f" a
}

# ---- Lezione 06 ------------------------------------------------------------

p_06_1() {
    script pulisci.sh || return
    local t testimone
    t=$(tmp)
    mkdir -p "$t/casa" "$t/corrente" "$t/da svuotare/sotto"
    testimone=$t/corrente/testimone
    : >"$testimone"
    : >"$t/casa/testimone-home"
    : >"$t/da svuotare/normale"
    : >"$t/da svuotare/.nascosto"
    : >"$t/da svuotare/con spazio"
    : >"$t/da svuotare/sotto/file"
    local HOME=$t/casa
    export HOME
    codice "senza argomenti: 2" 2 env -C "$t/corrente" "$X"
    vero "...la cartella corrente è salva" test -e "$testimone"
    vero "...la home è salva" test -e "$t/casa/testimone-home"
    codice "cartella inesistente: 1" 1 env -C "$t/corrente" "$X" "$t/non esiste"
    vero "...la cartella corrente è salva" test -e "$testimone"
    codice "stringa vuota: 2" 2 env -C "$t/corrente" "$X" ""
    vero "...la cartella corrente è salva" test -e "$testimone"
    codice "rifiuta la home: 3" 3 env -C "$t/corrente" "$X" "$t/casa"
    vero "...la home è salva" test -e "$t/casa/testimone-home"
    codice "rifiuta la home scritta in altro modo: 3" 3 env -C "$t/corrente" "$X" "$t/casa/"
    vero "...la home è salva" test -e "$t/casa/testimone-home"
    codice "svuota davvero" 0 env -C "$t/corrente" "$X" "$t/da svuotare"
    vero "...la cartella resta" test -d "$t/da svuotare"
    vero "...vuota, nascosti compresi" test "$(ls -A "$t/da svuotare" | wc -l)" -eq 0
    vero "...la cartella corrente è salva" test -e "$testimone"
    echo "  nota  il rifiuto di / non si prova qui di proposito: vedi la lezione."
}

p_06_2() {
    script chiavi.sh || return
    local f=$L/dati/consumi.txt
    uscita "senza opzioni: il minimo" "test-app" "$X" "$f"
    uscita "-n 3: confronto numerico" "test-app
cron
sshd" "$X" -n 3 "$f"
    uscita "-a -n 2: i massimi" "postgres
test-db" "$X" -a -n 2 "$f"
    uscita "opzioni raggruppate e attaccate: -an2" "postgres
test-db" "$X" -an2 "$f"
    uscita "-x esclude le righe" "cron
sshd" "$X" -x test -n 2 "$f"
    uscita "-- chiude le opzioni" "test-app" "$X" -- "$f"
    codice "opzione sconosciuta" 2 "$X" -z "$f"
    vero "...con l'uso su stderr" test -n "$ERR"
    codice "-n non numerico" 2 "$X" -n tre "$f"
    codice "senza file" 2 "$X" -n 3
    codice "file mancante" 1 "$X" "$f.manca"
}

p_06_3() {
    script mycd.sh || return
    local t r
    t=$(tmp)
    t=$(cd "$t" && pwd -P)
    mkdir -p "$t/prod/app" "$t/dev/app" "$t/qui"
    r='source "$1"; shift; cd "$1"; shift; mycd "$@"; c=$?; echo "ora: $PWD"; exit "$c"'
    uscita "cambia cartella e lo racconta" "da: $t/qui
a: $t/prod
ora: $t/prod" bash -c "$r" _ "$X" "$t/qui" "$t/prod"
    uscita "due argomenti: sostituzione nel percorso" "da: $t/prod/app
a: $t/dev/app
ora: $t/dev/app" bash -c "$r" _ "$X" "$t/prod/app" prod dev
    lancia bash -c "$r" _ "$X" "$t/qui" "$t/manca"
    vero "cartella inesistente: codice non 0" test "$RC" -ne 0
    vero "...resta dov'era" corrisponde "$OUT" "ora: $t/qui\$"
    vero "...senza dire 'a:'" test "$(grep -c '^a:' <<<"$OUT")" -eq 0
    vero "...con l'errore su stderr" test -n "$ERR"
    lancia bash -c "$r" _ "$X" "$t/qui" nonce altro
    vero "testo assente dal percorso: codice non 0" test "$RC" -ne 0
    vero "...resta dov'era" corrisponde "$OUT" "ora: $t/qui\$"
    codice "tre argomenti: 2" 2 bash -c "$r" _ "$X" "$t/qui" a b c
    HOME=$t/prod uscita "senza argomenti: la home" "da: $t/qui
a: $t/prod
ora: $t/prod" bash -c "$r" _ "$X" "$t/qui"
}

p_06_4() {
    script lib-log.sh || return
    local t re='^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2} '
    t=$(tmp)
    lancia bash -c 'source "$1"; log_info "due parole"' _ "$X"
    vero "non scrive su stdout" test -z "$OUT"
    vero "riga con ora e livello su stderr" corrisponde "$ERR" "${re}INFO due parole\$"
    lancia bash -c 'source "$1"; log_errore guasto' _ "$X"
    vero "livello ERRORE" corrisponde "$ERR" "${re}ERRORE guasto\$"
    lancia bash -c 'LOG_LIVELLO=ERRORE; source "$1"; log_info nascosta; log_errore visibile' _ "$X"
    vero "LOG_LIVELLO=ERRORE nasconde INFO" test "$(grep -c nascosta <<<"$ERR")" -eq 0
    vero "...ma non ERRORE" test "$(grep -c visibile <<<"$ERR")" -eq 1
    lancia bash -c 'LOG_FILE="$2"; source "$1"; log_info salvata' _ "$X" "$t/mio.log"
    vero "LOG_FILE riceve anche lui la riga" grep -q 'INFO salvata' "$t/mio.log"
    vero "...e stderr pure" test -n "$ERR"
    codice "muori esce col codice dato" 4 bash -c 'source "$1"; muori 4 "fine"; exit 0' _ "$X"
    vero "...dopo aver scritto l'errore" corrisponde "$ERR" "ERRORE fine\$"
    codice "caricarla non cambia il comportamento della shell" 0 bash -c 'source "$1"; false; true' _ "$X"
    uscita "caricarla non stampa nulla" "" bash -c 'source "$1"' _ "$X"
}

# ---- Lezione 07 ------------------------------------------------------------

p_07_1() {
    script crea-utenti.sh || return
    local csv=$L/dati/nuovi-utenti.csv t a
    t=$(tmp)
    mkdir "$t/etc" "$t/stub"
    cp "$L/dati/passwd" "$L/dati/group" "$t/etc/"
    a='groupadd sviluppo
useradd -m -g sviluppo -s /bin/bash -e 2027-06-30 luca
useradd -m -g sviluppo -s /bin/zsh sara
groupadd ops
useradd -m -g ops -s /bin/bash -e 2027-01-31 piero
useradd -m -g staff -s /bin/bash dana'
    ETC=$t/etc uscita "stampa i comandi senza eseguirli" "$a" "$X" "$csv"
    vero "righe sbagliate: codice 1" test "$RC" -eq 1
    vero "...e stderr cita la riga 6" grep -q 'riga 6' <<<"$ERR"
    vero "...e la riga 7" grep -q 'riga 7' <<<"$ERR"
    vero "salta mario segnalandolo" grep -q 'mario' <<<"$ERR"
    local c
    for c in useradd groupadd; do
        printf '#!/usr/bin/env bash\nprintf "%s" >>"%s"\nprintf " [%%s]" "$@" >>"%s"\necho >>"%s"\n' "$c" "$t/log" "$t/log" "$t/log" >"$t/stub/$c"
        chmod +x "$t/stub/$c"
    done
    PATH=$t/stub:$PATH ETC=$t/etc lancia "$X" "$csv" --esegui
    vero "--esegui lancia davvero i comandi" test -s "$t/log"
    vero "...tutti e sei" test "$(wc -l <"$t/log")" -eq 6
    vero "...con gli argomenti al posto giusto" grep -qxF 'useradd [-m] [-g] [sviluppo] [-s] [/bin/bash] [-e] [2027-06-30] [luca]' "$t/log"
    vero "...la scadenza vuota non passa un argomento vuoto" grep -qxF 'useradd [-m] [-g] [staff] [-s] [/bin/bash] [dana]' "$t/log"
    codice "CSV mancante" 2 "$X" "$csv.manca"
}

p_07_2() {
    script scadenze.sh || return
    local f=$L/dati/shadow
    uscita "entro 30 giorni" "teo scaduta
zeno scaduta
mario 5
anna 10" "$X" "$f" 30 2026-11-03
    uscita "entro 7 giorni" "teo scaduta
zeno scaduta
mario 5" "$X" "$f" 7 2026-11-03
    uscita "entro 100 giorni arriva marta" "teo scaduta
zeno scaduta
mario 5
anna 10
marta 80" "$X" "$f" 100 2026-11-03
    uscita "cambiando giorno cambiano i conti (0 = scade oggi)" "teo scaduta
zeno scaduta
mario 0
anna 5" "$X" "$f" 5 2026-11-08
    TZ=America/New_York uscita "il fuso orario non sposta il risultato" "teo scaduta
zeno scaduta
mario 5" "$X" "$f" 7 2026-11-03
    TZ=Asia/Tokyo uscita "...nemmeno a est" "teo scaduta
zeno scaduta
mario 5" "$X" "$f" 7 2026-11-03
    codice "file mancante" 1 "$X" "$f.manca" 30
    codice "giorni non numerici" 2 "$X" "$f" tanti
}

p_07_3() {
    script audit-permessi.sh || return
    local t a
    t=$(tmp)
    mkdir "$t/albero"
    cp -PpR "$L/dati/albero/." "$t/albero/"
    chgrp "$(id -g)" "$t/albero/sgid.bin"
    chmod 2755 "$t/albero/sgid.bin"
    chmod 4755 "$t/albero/suid.bin"
    chmod 1777 "$t/albero/tmp-ok"
    a="scrivibile $t/albero/aperto.txt
scrivibile $t/albero/dir-aperta
scrivibile $t/albero/nome con spazi.txt
sgid $t/albero/sgid.bin
suid $t/albero/suid.bin"
    uscita "trova i problemi, e solo quelli" "$a" "$X" "$t/albero"
    vero "problemi trovati: codice 1" test "$RC" -eq 1
    mkdir "$t/pulito"
    : >"$t/pulito/ok"
    chmod 644 "$t/pulito/ok"
    uscita "albero pulito: nessun output" "" "$X" "$t/pulito"
    vero "...e codice 0" test "$RC" -eq 0
    codice "cartella mancante" 2 "$X" "$t/manca"
}

# ---- Lezione 08 ------------------------------------------------------------

p_08_1() {
    script backup.sh || return
    local t arch
    t=$(tmp)
    cp -R "$L/dati/sito web" "$t/sito web"
    codice "riesce su nomi con spazi" 0 "$X" "$t/sito web" "$t/dest nuova"
    arch=$OUT
    vero "stampa un solo percorso" test "$(wc -l <<<"$OUT")" -eq 1
    vero "il nome rispetta la convenzione" corrisponde "$(basename "$arch")" '^sito web_[0-9]{8}-[0-9]{6}\.tar\.gz$'
    vero "l'archivio esiste" test -f "$arch"
    vero "la somma esiste" test -f "$arch.sha256"
    vero "la somma si controlla dalla cartella dei backup" env -C "$t/dest nuova" sha256sum -c --quiet "$(basename "$arch").sha256"
    vero "la somma non contiene percorsi" test "$(grep -c '/' "$arch.sha256")" -eq 0
    vero "dentro, i percorsi partono da 'sito web/'" bash -c '! tar -tzf "$1" | grep -qv "^sito web"' _ "$arch"
    vero "dentro c'è il file annidato" bash -c 'tar -tzf "$1" | grep -q "immagini/logo.png"' _ "$arch"
    vero "non restano file temporanei" test "$(ls -A "$t/dest nuova" | wc -l)" -eq 2
    sleep 1
    lancia "$X" "$t/sito web/" "$t/dest nuova"
    vero "la barra finale non cambia il nome" corrisponde "$(basename "$OUT")" '^sito web_[0-9]{8}-[0-9]{6}\.tar\.gz$'
    mkdir "$t/d2"
    lancia "$X" "$t/manca" "$t/d2"
    vero "sorgente mancante: codice non 0" test "$RC" -ne 0
    vero "...e cartella dei backup vuota" test "$(ls -A "$t/d2" | wc -l)" -eq 0
    vero "...e nessun percorso su stdout" test -z "$OUT"
    codice "pochi argomenti" 2 "$X" "$t/sito web"
}

p_08_2() {
    script ruota.sh || return
    local t d a
    t=$(tmp)
    d=$t/b
    cp -R "$L/dati/backup" "$d"
    # le date dei file vanno al contrario dei nomi: il riferimento è il nome
    touch -d '1 day ago' "$d/web_20261101-020000.tar.gz"
    touch -d '100 days ago' "$d/web_20261028-020000.tar.gz"
    touch -d '50 days ago' "$d/web_20261030-020000.tar.gz"
    touch "$d/web_20261028-020000.tar.gz.sha256" "$d/web_20261029-020000.tar.gz"
    a="$d/web_20261028-020000.tar.gz
$d/web_20261028-020000.tar.gz.sha256
$d/web_20261029-020000.tar.gz
$d/web_20261029-020000.tar.gz.sha256
$d/web_20261030-020000.tar.gz
$d/web_20261030-020000.tar.gz.sha256"
    uscita "tiene i 2 più recenti per nome" "$a" "$X" "$d" web 2
    vero "senza --cancella non tocca nulla" test "$(ls -A "$d" | wc -l)" -eq 12
    uscita "N oltre il numero dei backup: nulla da fare" "" "$X" "$d" web 9
    uscita "--cancella elenca e cancella" "$a" "$X" "$d" web 2 --cancella
    vero "...restano i due più recenti" test -f "$d/web_20261101-020000.tar.gz" -a -f "$d/web_20261031-020000.tar.gz"
    vero "...i vecchi non ci sono più" test ! -e "$d/web_20261028-020000.tar.gz"
    vero "...web2 non è web" test -f "$d/web2_20260101-020000.tar.gz"
    vero "...db resta" test -f "$d/db_20260101-020000.tar.gz"
    mkdir "$t/sp"
    : >"$t/sp/mio sito_20261028-020000.tar.gz"
    : >"$t/sp/mio sito_20261029-020000.tar.gz"
    uscita "prefisso con spazi" "$t/sp/mio sito_20261028-020000.tar.gz" "$X" "$t/sp" "mio sito" 1
    codice "N=0 è un rifiuto" 2 "$X" "$d" web 0
    codice "N non numerico" 2 "$X" "$d" web due
    codice "cartella mancante" 1 "$X" "$t/manca" web 2
}

p_08_3() {
    script prova-ripristino.sh || return
    local t a mio
    t=$(tmp)
    mkdir "$t/mio sito" "$t/temp"
    printf 'uno\n' >"$t/mio sito/a.txt"
    a=$t/mio\ sito_20261103-020000.tar.gz
    tar -C "$t" -czf "$a" "mio sito"
    (cd "$t" && sha256sum "$(basename "$a")" >"$a.sha256")
    TMPDIR=$t/temp codice "backup sano: 0" 0 "$X" "$a" "$t/mio sito"
    vero "...nessun residuo temporaneo" test "$(ls -A "$t/temp" | wc -l)" -eq 0
    printf 'due\n' >"$t/mio sito/a.txt"
    TMPDIR=$t/temp codice "sorgente diversa: 2" 2 "$X" "$a" "$t/mio sito"
    vero "...nessun residuo neppure qui" test "$(ls -A "$t/temp" | wc -l)" -eq 0
    printf 'uno\n' >"$t/mio sito/a.txt"
    mio=$t/rotto.tar.gz
    cp "$a" "$mio"
    (cd "$t" && sha256sum rotto.tar.gz >rotto.tar.gz.sha256)
    printf 'x' >>"$mio"
    TMPDIR=$t/temp codice "archivio corrotto: 1" 1 "$X" "$mio" "$t/mio sito"
    codice "archivio mancante: 3" 3 "$X" "$t/manca.tar.gz" "$t/mio sito"
    codice "pochi argomenti: 3" 3 "$X" "$a"
    mkdir "$t/cwd"
    TMPDIR=$t/temp codice "funziona da qualsiasi cartella" 0 env -C "$t/cwd" "$X" "$a" "$t/mio sito"
}

# ---- Lezione 09 ------------------------------------------------------------

p_09_1() {
    script solo-uno.sh || return
    local t l p inizio fine
    t=$(tmp)
    l=$t/blocco
    codice "corsa normale: 0" 0 "$X" "$l" 0
    vero "...il blocco è sparito" test ! -e "$l"
    "$X" "$l" 30 >/dev/null 2>&1 &
    p=$!
    for _ in 1 2 3 4 5 6 7 8 9 10; do [[ -s $l/pid ]] && break; sleep 0.2; done
    vero "il pid è scritto in BLOCCO/pid" test -s "$l/pid"
    codice "seconda copia: 1" 1 "$X" "$l" 0
    vero "...spiega perché su stderr" test -n "$ERR"
    vero "...senza togliere il blocco" test -e "$l"
    inizio=$SECONDS
    kill -TERM "$p"
    wait "$p"
    RC=$?
    fine=$SECONDS
    vero "SIGTERM: esce subito, senza aspettare sleep" test $((fine - inizio)) -lt 3
    vero "SIGTERM: codice 143" test "$RC" -eq 143
    vero "SIGTERM: il blocco è sparito" test ! -e "$l"
    mkdir "$l"
    echo 999999 >"$l/pid"
    codice "blocco abbandonato: lo riprende" 0 "$X" "$l" 0
    vero "...e poi lo toglie" test ! -e "$l"
    local vinti=0 pids=()
    for _ in 1 2 3 4 5 6; do
        "$X" "$l" 1 >/dev/null 2>&1 &
        pids+=($!)
    done
    for p in "${pids[@]}"; do
        if wait "$p"; then vinti=$((vinti + 1)); fi
    done
    vero "sei copie insieme: ne parte una sola (partite: $vinti)" test "$vinti" -eq 1
    codice "pochi argomenti: 2" 2 "$X" "$l"
}

p_09_2() {
    script limite.sh || return
    local inizio fine
    inizio=$SECONDS
    codice "comando veloce: 0" 0 "$X" 10 true
    fine=$SECONDS
    vero "...senza aspettare la scadenza" test $((fine - inizio)) -le 2
    codice "restituisce il codice del comando" 7 "$X" 10 sh -c 'exit 7'
    uscita "argomenti con spazi" "a b" "$X" 10 printf '%s\n' "a b"
    inizio=$SECONDS
    codice "scadenza: 124" 124 "$X" 1 sleep 15
    fine=$SECONDS
    vero "...dopo circa 1 secondo" test $((fine - inizio)) -le 3
    inizio=$SECONDS
    codice "chi ignora SIGTERM: 124" 124 "$X" 1 bash -c 'trap "" TERM; while :; do sleep 0.2; done'
    fine=$SECONDS
    vero "...viene ucciso comunque, dopo altri 2 secondi" test $((fine - inizio)) -le 6
    codice "tempo non numerico: 2" 2 "$X" presto true
    codice "senza comando: 2" 2 "$X" 5
}

p_09_3() {
    script chi-consuma.sh || return
    INGRESSO=$L/dati/ps.txt
    uscita "i primi 3 e gli zombie" "mario 24.5 2
postgres 22.5 2
root 3.0 3
zombie: 2" "$X"
    uscita "N scelto a mano" "mario 24.5 2
zombie: 2" "$X" 1
    uscita "tutti" "mario 24.5 2
postgres 22.5 2
root 3.0 3
anna 2.0 2
zombie: 2" "$X" 10
    INGRESSO=/dev/null
    codice "N non numerico" 2 "$X" tanti
}

# ---- Lezione 10 ------------------------------------------------------------

p_10_1() {
    script rapporto.sh || return
    local t
    t=$(tmp)
    cp -R "$L/dati" "$t/dati"
    mkdir "$t/uscita"
    cp "$X" "$t/rapporto.sh"
    codice "gira con l'ambiente di cron, da /" 0 env -i HOME="$t" SHELL=/bin/sh LOGNAME="$(id -un)" PATH=/usr/bin:/bin bash -c "cd / && \"$t/rapporto.sh\""
    vero "scrive accanto allo script" test -f "$t/uscita/stato.txt"
    vero "riga 1: misura" test "$(sed -n 1p "$t/uscita/stato.txt" 2>/dev/null)" = "misura: ok"
    vero "riga 2: 3 errori" test "$(sed -n 2p "$t/uscita/stato.txt" 2>/dev/null)" = "3"
    vero "riga 3: l'utente non è vuoto" corrisponde "$(sed -n 3p "$t/uscita/stato.txt" 2>/dev/null)" "^generato da $(id -un) il [0-9]{4}-[0-9]{2}-[0-9]{2}\$"
    vero "non restano scritture nella cartella /" test ! -e /uscita
}

p_10_3() {
    script cron-corrisponde.sh || return
    local e
    while IFS='|' read -r e quando atteso desc; do
        codice "$desc" "$atteso" "$X" "$e" "$quando"
    done <<'CASI'
*/10 8-17 * * 1-5|2026-11-03 09:20|0|ogni 10 minuti in orario d'ufficio
*/10 8-17 * * 1-5|2026-11-03 09:25|1|...ma non al minuto 25
*/10 8-17 * * 1-5|2026-11-03 18:00|1|...né alle 18
*/10 8-17 * * 1-5|2026-11-08 09:20|1|...né di domenica
0 0 1 1 *|2027-01-01 00:00|0|capodanno
30 4 1,15 * *|2026-11-15 04:30|0|lista di giorni: il 15 sì
30 4 1,15 * *|2026-11-14 04:30|1|lista di giorni: il 14 no
* * * * 0|2026-11-08 12:00|0|domenica come 0
* * * * 7|2026-11-08 12:00|0|domenica come 7
* * * * 7|2026-11-09 12:00|1|lunedì non è 7
5-30/5 * * * *|2026-11-03 10:15|0|intervallo con passo: il 15 sì
5-30/5 * * * *|2026-11-03 10:17|1|intervallo con passo: il 17 no
5-30/5 * * * *|2026-11-03 10:00|1|intervallo con passo: lo 0 no
8 9 * * *|2026-11-03 09:08|0|08 e 09 non sono numeri ottali
0 12 13 * 5|2026-11-06 12:00|0|giorno e settimana: basta il venerdì
0 12 13 * 5|2026-12-13 12:00|0|giorno e settimana: basta il 13
0 12 13 * 5|2026-11-14 12:00|1|giorno e settimana: né l'uno né l'altro
0 12 * 11 *|2026-11-30 12:00|0|solo il mese
0 12 * 11 *|2026-12-01 12:00|1|mese sbagliato
* * * *|2026-11-03 09:00|2|quattro campi: errore
CASI
    codice "pochi argomenti: 2" 2 "$X" "* * * * *"
}

# ---- Lezione 11 ------------------------------------------------------------

p_11_1() {
    script sentinella.sh || return
    local t
    t=$(tmp)
    mkdir "$t/stub"
    cat >"$t/stub/df" <<'EOF'
#!/usr/bin/env bash
ultimo=${*: -1}
echo "Filesystem 1024-blocks Used Available Capacity Mounted on"
case $ultimo in
    /) echo "/dev/sda1 100 42 58 42% /" ;;
    /var) echo "/dev/sda2 100 85 15 85% /var" ;;
    /home) echo "/dev/sda3 100 96 4 96% /home" ;;
    *) echo "df: $ultimo: non trovato" >&2; exit 1 ;;
esac
EOF
    chmod +x "$t/stub/df"
    printf 'disco / 80 90\n# commento\n\nfile /etc/passwd\ncomando true\n' >"$t/ok.conf"
    PATH=$t/stub:$PATH uscita "tutto bene" "OK disco /
OK file /etc/passwd
OK comando true" "$X" -c "$t/ok.conf"
    vero "...codice 0" test "$RC" -eq 0
    printf 'disco /var 80 90\nfile /etc/passwd\n' >"$t/warn.conf"
    PATH=$t/stub:$PATH uscita "un avviso" "WARNING disco /var
OK file /etc/passwd" "$X" -c "$t/warn.conf"
    vero "...codice 1" test "$RC" -eq 1
    printf 'disco /home 80 90\ndisco /var 80 90\nfile /non/esiste\ncomando false\ncomando sh -c "exit 0"\n' >"$t/crit.conf"
    PATH=$t/stub:$PATH uscita "il peggiore decide il codice" 'CRITICAL disco /home
WARNING disco /var
CRITICAL file /non/esiste
CRITICAL comando false
OK comando sh -c "exit 0"' "$X" -c "$t/crit.conf"
    vero "...codice 2" test "$RC" -eq 2
    PATH=$t/stub:$PATH uscita "-q mostra solo i problemi" 'CRITICAL disco /home
WARNING disco /var
CRITICAL file /non/esiste
CRITICAL comando false' "$X" -q -c "$t/crit.conf"
    sleep 19 &
    local p=$!
    printf 'processo sleep\nprocesso sicuramente-assente\n' >"$t/proc.conf"
    PATH=$t/stub:$PATH uscita "processi" "OK processo sleep
CRITICAL processo sicuramente-assente" "$X" -c "$t/proc.conf"
    kill "$p" 2>/dev/null
    wait "$p" 2>/dev/null
    printf 'file /etc/passwd\nboh qualcosa\n' >"$t/bad.conf"
    PATH=$t/stub:$PATH uscita "riga sconosciuta: si ferma prima di controllare" "" "$X" -c "$t/bad.conf"
    vero "...codice 3" test "$RC" -eq 3
    vero "...con il numero di riga su stderr" grep -q '2' <<<"$ERR"
    codice "configurazione mancante: 3" 3 "$X" -c "$t/manca.conf"
    codice "opzione sconosciuta: 3" 3 "$X" -z
}

p_11_2() {
    script makecmd.sh || return
    local t r=$L/dati/regola.txt
    t=$(tmp)
    printf 'a\n' >"$t/a.txt"
    printf 'b\n' >"$t/b.txt"
    INGRESSO=$r
    uscita "bersaglio assente: costruisce e stampa" "cat a.txt b.txt > report.txt
echo fatto
fatto" env -C "$t" "$X"
    vero "...il risultato c'è" test "$(cat "$t/report.txt")" = $'a\nb'
    uscita "bersaglio aggiornato: nulla" "" env -C "$t" "$X"
    touch -d '10 seconds ago' "$t/report.txt"
    touch "$t/b.txt"
    uscita "una dipendenza più recente: ricostruisce" "cat a.txt b.txt > report.txt
echo fatto
fatto" env -C "$t" "$X"
    touch "$t/report.txt"
    rm "$t/a.txt"
    touch -d '10 seconds ago' "$t/b.txt"
    uscita "una dipendenza assente si ignora" "" env -C "$t" "$X"
    printf 'x: \n\tfalse\n\techo mai\n' >"$t/r2"
    INGRESSO=$t/r2
    uscita "un comando fallito ferma tutto" "false" env -C "$t" "$X"
    vero "...col suo codice" test "$RC" -eq 1
    printf 'questa non è una regola\n' >"$t/r3"
    INGRESSO=$t/r3
    codice "regola malformata: 2" 2 env -C "$t" "$X"
    INGRESSO=/dev/null
}

# ---- Lezione 12 ------------------------------------------------------------

p_12_1() {
    script chi-gira.sh || return
    lancia bash -c 'echo "attesa: $$"; exec "$1"' _ "$X"
    local a p g s d c
    a=$(campo attesa) p=$(campo principale) g=$(campo graffe) s=$(campo parentesi)
    d=$(campo sinistra) c=$(campo destra)
    local z
    z=$(campo sostituzione)
    vero "codice 0" test "$RC" -eq 0
    vero "principale è il PID dello script" test "$p" = "$a"
    vero "graffe ha un numero" corrisponde "$g" '^[0-9]+$'
    vero "graffe resta nel processo principale" test "$g" = "$p"
    vero "tutte le voci sono numeri" corrisponde "$s $d $c $z" '^[0-9]+ [0-9]+ [0-9]+ [0-9]+$'
    local n
    n=$(printf '%s\n' "$p" "$s" "$d" "$c" "$z" | sort -u | wc -l)
    vero "parentesi, sinistra, destra e sostituzione hanno PID propri" test "$n" -eq 5
}

p_12_2() {
    script riepilogo-vm.sh || return
    local PATH=$L/dati/bin:$PATH
    local a=$'lab-arch|ssh|2222\nlab rocky|ssh|2223\nlab rocky|http|8080\nsenza rete|-|-\nweb|https|8443\ntotale: 4'
    uscita "riepilogo completo, con il totale delle regole" "$a" "$X"
    vero "codice 0" test "$RC" -eq 0
    vero "nessun errore da VBoxManage" test -z "$ERR"
}

p_12_3() {
    script su-tutte.sh || return
    local PATH=$L/dati/bin:$PATH t
    t=$(tmp)
    local a=$'[alfa] uptime\n[beta] uptime\n[gamma] uptime\nfalliti: 1'
    uscita "tutte le macchine, anche l'ultima riga senza a capo" "$a" "$X" "$L/dati/macchine.txt" uptime
    vero "una macchina spenta dà codice 1" test "$RC" -eq 1
    printf 'alfa\n  beta\n' >"$t/ok"
    uscita "nessun fallimento" $'[alfa] df -h\n[beta] df -h\nfalliti: 0' "$X" "$t/ok" "df -h"
    vero "...con codice 0" test "$RC" -eq 0
    codice "file mancante: 2" 2 "$X" "$t/manca" uptime
    codice "pochi argomenti: 2" 2 "$X"
}

p_12_4() {
    script esporta-db.sh || return
    local PATH=$L/dati/bin:$PATH t
    t=$(tmp)
    codice "esportazione riuscita: 0" 0 "$X" clienti "$t/d.sql.gz"
    vero "l'archivio contiene tutto" test "$(gzip -dc "$t/d.sql.gz" 2>/dev/null | tail -1)" = "-- fine"
    vero "nessun file in più" test "$(find "$t" -type f | wc -l)" -eq 1
    local prima
    prima=$(cksum <"$t/d.sql.gz")
    codice "dump fallito: il suo codice, 3" 3 "$X" rotto "$t/d.sql.gz"
    vero "il backup precedente resta intatto" test "$(cksum <"$t/d.sql.gz")" = "$prima"
    vero "nessun avanzo" test "$(find "$t" -type f | wc -l)" -eq 1
    codice "dump fallito senza backup precedente: 3" 3 "$X" rotto "$t/nuovo.sql.gz"
    vero "nessun archivio mutilato" test ! -e "$t/nuovo.sql.gz"
    lancia "$X" clienti "$t/non/esiste/d.sql.gz"
    vero "cartella di destinazione mancante: errore" test "$RC" -ne 0
    codice "pochi argomenti: 2" 2 "$X" clienti
}

p_12_5() {
    script prime.sh || return
    uscita "si ferma anche su un comando infinito" $'y\ny\ny' "$X" 3 yes
    vero "...e non è un errore: 0" test "$RC" -eq 0
    uscita "meno righe di N" $'a\nb' "$X" 10 sh -c 'echo a; echo b; exit 5'
    vero "riporta il codice del comando" test "$RC" -eq 5
    uscita "conserva gli argomenti" "a  b" "$X" 1 printf '%s\n' "a  b"
    vero "comando riuscito: 0" test "$RC" -eq 0
    codice "comando inesistente: 127" 127 "$X" 1 comando-che-non-esiste
    codice "N non numerico: 2" 2 "$X" tre yes
    codice "pochi argomenti: 2" 2 "$X" 3
}

p_12_6() {
    script confronta.sh || return
    local t ro f
    t=$(tmp)
    ro=$t/sola-lettura
    f=$t/finti
    mkdir "$ro" "$f"
    printf '#!/bin/sh\necho "mktemp vietato" >&2\nexit 1\n' >"$f/mktemp"
    chmod +x "$f/mktemp"
    cp "$L/dati/pacchetti-a.txt" "$t/lista a.txt"
    cp "$L/dati/pacchetti-b.txt" "$t/lista b.txt"
    chmod a-w "$ro"
    local PATH=$f:$PATH TMPDIR=$ro
    uscita "differenze, senza file temporanei" $'- curl\n- vim\n+ nginx\n+ zsh' env -C "$ro" "$X" "$t/lista a.txt" "$t/lista b.txt"
    vero "liste diverse: 1" test "$RC" -eq 1
    uscita "stesso contenuto, altro ordine" "" env -C "$ro" "$X" "$t/lista a.txt" "$t/lista a.txt"
    vero "liste uguali: 0" test "$RC" -eq 0
    codice "file mancante: 2" 2 env -C "$ro" "$X" "$t/lista a.txt" "$t/manca"
    codice "pochi argomenti: 2" 2 env -C "$ro" "$X"
    chmod u+w "$ro"
}

p_12_7() {
    script ogni-cartella.sh || return
    local t a
    t=$(tmp)
    cp -R "$L/dati/progetti" "$t/p"
    a=$'== api\nnote delle api\n== sito web\nnote del sito\n== vuoto\nfalliti: 1'
    uscita "esegue in ogni cartella, anche con RADICE relativa" "$a" env -C "$t" "$X" p sh -c 'cat nota.txt 2>/dev/null'
    vero "un comando fallito dà codice 1" test "$RC" -eq 1
    mkdir "$t/nulla"
    uscita "nessuna sottocartella" "falliti: 0" "$X" "$t/nulla" true
    vero "...con codice 0" test "$RC" -eq 0
    codice "RADICE inesistente: 2" 2 "$X" "$t/manca" true
    codice "pochi argomenti: 2" 2 "$X" "$t/p"
    if (($(id -u) != 0)); then
        mkdir -p "$t/q/a" "$t/q/chiusa" "$t/q/z"
        chmod 000 "$t/q/chiusa"
        lancia env -C "$t" "$X" q touch segno
        chmod 755 "$t/q/chiusa"
        vero "cartella inaccessibile contata fra i falliti" test "$(campo falliti)" = 1
        vero "il comando non è partito nel posto sbagliato" test ! -e "$t/q/segno" -a ! -e "$t/segno"
        vero "le altre cartelle sono servite" test -e "$t/q/a/segno" -a -e "$t/q/z/segno"
    fi
}

# ---- Lezione 13 ------------------------------------------------------------

p_13_1() {
    script crea-struttura.sh || return
    local t n
    t=$(tmp)
    codice "N=12: codice 0" 0 "$X" "$t/la mia app" 12
    vero "nessun output" test -z "$OUT"
    n=$(find "$t/la mia app" -mindepth 3 -type d | wc -l)
    vero "2 ambienti x 12 nodi x 3 cartelle = 72" test "$n" -eq 72
    vero "web01 ha due cifre" test -d "$t/la mia app/prod/web01/conf"
    vero "arriva fino a web12" test -d "$t/la mia app/staging/web12/log"
    vero "non va oltre N" test ! -e "$t/la mia app/prod/web13"
    vero "niente graffe rimaste nei nomi" test -z "$(find "$t" -name '*[{}]*')"
    codice "rilanciato: ancora 0" 0 "$X" "$t/la mia app" 12
    codice "N=1" 0 "$X" "$t/uno" 1
    vero "...crea solo web01" test "$(find "$t/uno/prod" -mindepth 1 -maxdepth 1 | wc -l)" -eq 1
    codice "N=99" 0 "$X" "$t/tanti" 99
    vero "...arriva a web99" test -d "$t/tanti/prod/web99/bin"
    codice "N=0: 2" 2 "$X" "$t/zero" 0
    codice "N=100: 2" 2 "$X" "$t/cento" 100
    codice "N non numerico: 2" 2 "$X" "$t/x" dodici
    codice "argomenti mancanti: 2" 2 "$X" "$t/x"
    vero "con N sbagliato non crea nulla" test ! -e "$t/cento" -a ! -e "$t/x"
}

p_13_2() {
    script tabella.sh || return
    local a t
    t=$(tmp)
    a='UTENTE       HOME                        MB   QUOTA
anna         /home/anna                 512   12.5%
mario        /home/mario              20480   85.0%
utentelungon /home/utente prova           7    0.3%
TOTALE                                20999'
    uscita "tabella allineata" "$a" "$X" "$L/dati/spazio.txt"
    vero "codice 0" test "$RC" -eq 0
    printf 'zeno;/home/zeno;1;100\n' >"$t/uno.txt"
    uscita "una riga sola, quota al 100%" 'UTENTE       HOME                        MB   QUOTA
zeno         /home/zeno                   1  100.0%
TOTALE                                    1' "$X" "$t/uno.txt"
    codice "file mancante: 1" 1 "$X" "$t/manca.txt"
}

p_13_3() {
    script riesegui.sh || return
    local t reg riga cmd att ott
    t=$(tmp)
    reg=$t/registro.log
    printf '#!/usr/bin/env bash\nprintf "[%%s]" "$@"; echo\nexit 4\n' >"$t/mostra"
    chmod +x "$t/mostra"
    REGISTRO=$reg uscita "l'output del comando passa inalterato" "[a b][]" "$X" "$t/mostra" "a b" ""
    vero "esce con il codice del comando" test "$RC" -eq 4
    vero "scrive una riga nel registro" test "$(wc -l <"$reg" 2>/dev/null)" = 1
    REGISTRO=$reg lancia "$X" "$t/mostra" "due  spazi" "it's" '"doppie"' '$HOME' '*' $'a capo\nqui' ""
    att=$("$t/mostra" "due  spazi" "it's" '"doppie"' '$HOME' '*' $'a capo\nqui' "")
    vero "il registro ha una riga per comando" test "$(wc -l <"$reg")" -eq 2
    riga=$(tail -n 1 "$reg")
    vero "data, ora e codice all'inizio" corrisponde "$riga" '^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2} 4 '
    cmd=${riga#* * }
    ott=$(cd "$t" && bash -c "$cmd" 2>&1)
    if [[ $ott == "$att" ]]; then
        passa "la riga registrata ricrea gli stessi argomenti"
    else
        boccia "la riga registrata ricrea gli stessi argomenti" "riga: $cmd" "atteso: $att" "ottenuto: $ott"
    fi
    REGISTRO=$reg lancia "$X" true
    vero "comando riuscito: codice 0 registrato" corrisponde "$(tail -n 1 "$reg")" '^[^ ]+ 0 '
    codice "senza argomenti: 2" 2 "$X"
}

# ---- Lezione 14 ------------------------------------------------------------

# ipc DESCRIZIONE ARGOMENTO RETE BROADCAST MASCHERA HOST
ipc() {
    local ind=${2%/*}
    interni "$X" "$2"
    local a="indirizzo: $ind
rete: $3
broadcast: $4
maschera: $5
host: $6"
    if [[ $OUT == "$a" && $RC -eq 0 ]]; then
        passa "$1"
    else
        boccia "$1" "--- atteso ---" "$a" "--- ottenuto (codice $RC) ---" "$OUT" "--- stderr ---" "${ERR:-(vuoto)}"
    fi
}

p_14_1() {
    script ip-calc.sh || return
    ipc "/22 a metà di un ottetto" 192.168.10.37/22 192.168.8.0 192.168.11.255 255.255.252.0 1022
    ipc "/8" 10.20.30.40/8 10.0.0.0 10.255.255.255 255.0.0.0 16777214
    ipc "/24" 172.16.5.1/24 172.16.5.0 172.16.5.255 255.255.255.0 254
    ipc "/31: due host" 10.1.2.3/31 10.1.2.2 10.1.2.3 255.255.255.254 2
    ipc "/32: un host" 10.1.2.3/32 10.1.2.3 10.1.2.3 255.255.255.255 1
    ipc "/0: tutto internet" 0.0.0.0/0 0.0.0.0 255.255.255.255 0.0.0.0 4294967294
    local e
    for e in 256.1.1.1/24 1.2.3/24 1.2.3.4 1.2.3.4/33 1.2.3.4/x 192.168.010.1/24 a.b.c.d/8 1.2.3.4.5/8 ""; do
        interni "$X" "$e"
        vero "rifiuta '$e' con 2" test "$RC" -eq 2
    done
    interni "$X" 1.2.3.4/8 5.6.7.8/8
    vero "due argomenti: 2" test "$RC" -eq 2
}

p_14_2() {
    script umana.sh || return
    local c
    for c in "0|0 B" "1023|1023 B" "1024|1.0 KiB" "1100|1.1 KiB" "1075|1.0 KiB" "1076|1.1 KiB" \
        "1536|1.5 KiB" "1048575|1.0 MiB" "1048576|1.0 MiB" "5368709120|5.0 GiB" \
        "1099511627776|1.0 TiB" "1125899906842624|1024.0 TiB"; do
        interni "$X" "${c%%|*}"
        if [[ $OUT == "${c#*|}" && $RC -eq 0 ]]; then
            passa "${c%%|*} -> ${c#*|}"
        else
            boccia "${c%%|*} -> ${c#*|}" "ottenuto (codice $RC): $OUT" "stderr: ${ERR:-(vuoto)}"
        fi
    done
    for c in -5 1.5 abc 1e3 ""; do
        interni "$X" "$c"
        vero "rifiuta '$c' con 2" test "$RC" -eq 2
    done
    interni "$X"
    vero "senza argomenti: 2" test "$RC" -eq 2
}

p_14_3() {
    script durata.sh || return
    local c
    for c in "59|00:00:59" "0|00:00:00" "3600|01:00:00" "86399|23:59:59" "86400|1g 00:00:00" \
        "93784|1g 02:03:04" "02:03:04|7384" "1g 02:03:04|93784" "08:09:00|29340" "00:00:09|9" "30g 00:00:00|2592000"; do
        local ing=${c%%|*}
        if [[ $ing == *g\ * ]]; then
            interni "$X" "${ing%% *}" "${ing#* }"
        else
            interni "$X" "$ing"
        fi
        if [[ $OUT == "${c#*|}" && $RC -eq 0 ]]; then
            passa "$ing -> ${c#*|}"
        else
            boccia "$ing -> ${c#*|}" "ottenuto (codice $RC): $OUT" "stderr: ${ERR:-(vuoto)}"
        fi
    done
    for c in 24:00:00 00:60:00 00:00:60 1:2:3 ab 12:00 -5 1.5; do
        interni "$X" "$c"
        vero "rifiuta '$c' con 2" test "$RC" -eq 2
    done
    interni "$X" xg 01:00:00
    vero "giorni non numerici: 2" test "$RC" -eq 2
    interni "$X"
    vero "senza argomenti: 2" test "$RC" -eq 2
}

# ---- Lezione 15 ------------------------------------------------------------

# caso DESCRIZIONE ATTESO ARGOMENTI...   (lancia "$X" senza PATH)
caso() {
    local d=$1 a=$2
    shift 2
    interni "$X" "$@"
    if [[ $OUT == "$a" && $RC -eq 0 ]]; then
        passa "$d"
    else
        boccia "$d" "--- atteso ---" "$a" "--- ottenuto (codice $RC) ---" "$OUT" "--- stderr ---" "${ERR:-(vuoto)}"
    fi
}

p_15_1() {
    script normalizza-nome.sh || return
    # Come al terminale della VM: con una lingua UTF-8 le lettere accentate sono un carattere solo.
    local -x LC_ALL=C.UTF-8
    caso "nome e cognome" mario.rossi "Mario Rossi"
    caso "spazi doppi e apostrofo" anna.mariadamico "  Anna   Maria  D'Amico "
    caso "più argomenti" mario.derossi Mario De Rossi
    caso "accenti" niccolo.fabbro "Niccolò Fabbrò"
    caso "trattino e cifre" annamaria.rossi007 "Anna-Maria Rossi 007"
    caso "una parola sola" admin "ADMIN"
    caso "un asterisco non porta dentro i nomi dei file" mario "Mario *"
    caso "parole che restano vuote non contano" rossi "' Rossi"
    caso "al massimo 32 caratteri" bartholomew.montgomeryfitzwillia "Bartholomew Montgomery-Fitzwilliam Smythe"
    interni "$X" '!!! ???'
    vero "non resta nulla: 1" test "$RC" -eq 1
    interni "$X"
    vero "senza argomenti: 2" test "$RC" -eq 2
}

p_15_2() {
    script maschera.sh || return
    local a
    a='login ok user=mario password=**** from 203.0.113.7
DB_PASSWORD:  ****  porta=5432
passwordless=yes
carta ************1111 scade
  	rientro con \\ barre e password=
Secret=**** secret=**** apiToken=****

numero 41111111111111112 troppo lungo
Il campo password non va
ultima riga token=****'
    INGRESSO=$L/dati/assistenza.log
    caso "copre i segreti e lascia il resto intatto" "$a"
    INGRESSO=/dev/null
    interni "$X"
    vero "stdin vuoto: nessun output, codice 0" test -z "$OUT" -a "$RC" -eq 0
}

p_15_3() {
    script versione.sh || return
    local c
    for c in "1.10 1.9 2" "1.9 1.10 1" "1.2 1.2.0 0" "1.2.0 1.2 0" "v2.0 1.99.99 2" "1.08 1.8 0" \
        "1.2.3 1.2.10 1" "10 9 2" "0.9 0.10 1" "V3 v3.0.0 0" "2.30.1 2.30 2" "0 0.0.1 1"; do
        set -- $c
        interni "$X" "$1" "$2"
        vero "$1 contro $2: $3" test "$RC" -eq "$3"
    done
    for c in 1..2 1.a "" 1.2- .1 vv1; do
        interni "$X" "$c" 1.0
        vero "rifiuta '$c' con 3" test "$RC" -eq 3
    done
    interni "$X" 1.0
    vero "un argomento solo: 3" test "$RC" -eq 3
    vero "non stampa nulla" test -z "$OUT"
}

p_15_4() {
    script parse-url.sh || return
    caso "il minimo" $'schema: https\nutente: -\nhost: example.com\nporta: 443\npercorso: /' https://example.com
    caso "tutto, in maiuscolo, con password" $'schema: https\nutente: mario\nhost: example.com\nporta: 8443\npercorso: /a/b?x=1' 'HTTPS://mario:segreta@Example.COM:8443/a/b?x=1'
    vero "la password non compare" test "${OUT/segreta/}" = "$OUT"
    caso "IPv6 con porta" $'schema: ssh\nutente: git\nhost: 2001:db8::1\nporta: 2222\npercorso: /repo.git' 'ssh://git@[2001:db8::1]:2222/repo.git'
    caso "IPv6 senza porta" $'schema: ftp\nutente: -\nhost: ::1\nporta: 21\npercorso: /pub' 'ftp://[::1]/pub'
    caso "una @ nel percorso non è un utente" $'schema: http\nutente: -\nhost: host\nporta: 80\npercorso: /u/@me' 'http://host/u/@me'
    caso "schema senza porta predefinita" $'schema: redis\nutente: -\nhost: cache\nporta: -\npercorso: /' 'redis://cache'
    caso "porta esplicita su schema sconosciuto" $'schema: redis\nutente: -\nhost: cache\nporta: 6379\npercorso: /' 'redis://cache:6379'
    local e
    for e in example.com 'https:///percorso' 'https://host:99999/' 'https://host:0/' 'https://host:ab/' 'https://[::1/x' 'https://mario@/' ""; do
        interni "$X" "$e"
        vero "rifiuta '$e' con 2" test "$RC" -eq 2
    done
    interni "$X"
    vero "senza argomenti: 2" test "$RC" -eq 2
}

# ---- Lezione 16 ------------------------------------------------------------

p_16_1() {
    script inventario.sh || return
    local t
    t=$(tmp)
    uscita "raggruppa per ruolo e per ambiente" $'cache (1): cache01\ndb (2): db01 db02\nweb (3): web01 web02 web03\nambienti: prod=4 test=2' "$X" "$L/dati/macchine.txt"
    vero "segnalazioni: codice 1" test "$RC" -eq 1
    vero "segnala il doppione alla riga 8" grep -q 'riga 8: host duplicato: web01' <<<"$ERR"
    vero "segnala la riga storta 9" grep -q 'riga 9' <<<"$ERR"
    printf 'b;x;prod\na;x;prod\n' >"$t/pulito.txt"
    uscita "file pulito" $'x (2): a b\nambienti: prod=2' "$X" "$t/pulito.txt"
    vero "...con codice 0" test "$RC" -eq 0
    codice "file mancante: 2" 2 "$X" "$t/manca.txt"
    codice "senza argomenti: 2" 2 "$X"
}

p_16_2() {
    script ini-get.sh || return
    local f=$L/dati/app.ini w=$L/dati/app-windows.ini
    uscita "valore semplice" db.interno "$X" "$f" db host
    uscita "chiave ripetuta in una sezione riaperta: vale l'ultima" 6432 "$X" "$f" db porta
    uscita "; e # dentro il valore restano" 'a;b=c#d' "$X" "$f" db password
    uscita "sezione con spazi nelle quadre, spazi intorno all'=" cache.interno "$X" "$f" cache host
    uscita "la stessa chiave in un'altra sezione" 6379 "$X" "$f" cache porta
    uscita "sezione vuota, prima delle quadre" demo "$X" "$f" "" nome
    codice "chiave in un'altra sezione: 1" 1 "$X" "$f" db nome
    codice "maiuscole diverse: 1" 1 "$X" "$f" db HOST
    codice "sezione inesistente: 1" 1 "$X" "$f" web host
    codice "un commento non è una chiave: 1" 1 "$X" "$f" cache '# commento rientrato'
    uscita "file di Windows: niente \\r" db.interno "$X" "$w" db host
    uscita "file di Windows, sezione con spazi" 6379 "$X" "$w" cache porta
    codice "file mancante: 2" 2 "$X" "$f.manca" db host
    codice "argomenti mancanti: 2" 2 "$X" "$f" db
}

p_16_3() {
    script doppioni.sh || return
    local a t
    t=$(tmp)
    a='dati/foto/a capo?qui.txt
dati/foto/f.txt

dati/foto/copia di mare.jpg
dati/foto/vacanze/mare.jpg
dati/foto/vecchie/mare (1).jpg

dati/foto/doc/relazione finale.txt
dati/foto/doc/relazione.txt'
    uscita "gruppi di doppioni" "$a" "$X" dati/foto
    vero "doppioni trovati: 1" test "$RC" -eq 1
    printf 'a\n' >"$t/uno"
    printf 'b\n' >"$t/due"
    : >"$t/vuoto"
    : >"$t/vuoto2"
    uscita "nessun doppione, e i file vuoti non contano" "" "$X" "$t"
    vero "...codice 0" test "$RC" -eq 0
    codice "cartella mancante: 2" 2 "$X" "$t/manca"
    codice "senza argomenti: 2" 2 "$X"
}

# carica NOME_ARRAY FILE: carica la libreria in una shell nuova, nella cartella di FILE,
# e stampa l'array,
# le variabili globali nuove e il codice restituito.
carica() {
    lancia env -C "${2%/*}" bash -c '
        source "$1" || exit 99
        declare -A '"$1"'=()
        __prima=$(compgen -v)
        carica_conf "$2" '"$1"'
        __rc=$?
        __dopo=$(compgen -v)
        for __k in "${!'"$1"'[@]}"; do printf "%s=%s\n" "$__k" "${'"$1"'[$__k]}"; done | LC_ALL=C sort
        echo "rc=$__rc"
        comm -13 <(sort <<<"$__prima") <(sort <<<"$__dopo") | grep -vxE "__.*|BASH_.*|_" | sed "s/^/globale nuova: /"
        echo "viva"
    ' _ "$X" "$2"
}

p_16_4() {
    script carica-conf.sh || return
    local t a n
    t=$(tmp)
    cp "$L/dati/app.conf" "$t/app.conf"
    a='COMANDO=$(touch pwned)
MESSAGGIO=ciao a tutti
NOME=demo
PORTA=8080
RIENTRO=si
SINGOLE=$HOME resta così
URL=http://host/?a=1&b=2
VUOTA=
rc=2
viva'
    for n in conf riga valore chiave k v; do
        carica "$n" "$t/app.conf"
        if [[ $OUT == "$a" ]]; then
            passa "carica i valori in un array chiamato '$n'"
        else
            boccia "carica i valori in un array chiamato '$n'" "--- atteso ---" "$a" "--- ottenuto ---" "$OUT" "--- stderr ---" "${ERR:-(vuoto)}"
        fi
    done
    vero "nessun comando eseguito dal file" test ! -e "$t/pwned" -a ! -e "$L/pwned"
    vero "segnala la riga 9" grep -q 'riga 9' <<<"$ERR"
    vero "segnala la riga 10" grep -q 'riga 10' <<<"$ERR"
    printf 'A=1\n# solo un commento\n\nB="2"\n' >"$t/buono.conf"
    carica conf "$t/buono.conf"
    vero "file valido: restituisce 0" test "$OUT" = $'A=1\nB=2\nrc=0\nviva'
    carica conf "$t/manca.conf"
    vero "file mancante: restituisce 1, array vuoto, shell viva" test "$OUT" = $'rc=1\nviva'
}

# ---- Lezione 17 ------------------------------------------------------------

# Casi per regex.txt: "+" deve corrispondere, "-" no. Uno per riga.
declare -A KATA_17=(
    [cifre]=$'+0\n+123\n+007\n-\n-12a\n- 1\n-1 2'
    [intero]=$'+0\n+-5\n+42\n++7\n-007\n---1\n-1.5\n-\n--\n-+'
    [colore]=$'+#fff\n+#A0b1C2\n+#000000\n-#ffff\n-fff\n-#ggg\n-#12345'
    [ipv4]=$'+0.0.0.0\n+255.255.255.255\n+192.168.1.10\n+10.0.0.5\n-256.1.1.1\n-1.2.3\n-01.2.3.4\n-1.2.3.4.\n-1.2.3.4.5\n-300.0.0.0\n-1..2.3'
    [mac]=$'+52:54:00:12:34:56\n+52-54-00-AB-cd-EF\n-52:54-00:12:34:56\n-5254.0012.3456\n-52:54:00:12:34\n-52:54:00:12:34:5g'
    [data]=$'+2026-11-03\n+2024-02-29\n+1999-12-31\n-2026-13-01\n-2026-1-3\n-2026-00-10\n-2026-11-32\n-2026-11-00\n-26-11-03'
    [ora]=$'+00:00\n+23:59\n+09:05\n+19:30\n-24:00\n-9:05\n-12:60\n-12:5'
    [utente]=$'+mario\n+_svc\n+web-01\n+samba$\n+a\n+abcdefghijklmnopqrstuvwxyz012345\n-Mario\n-1abc\n-a b\n-abcdefghijklmnopqrstuvwxyz0123456\n-ma$rio\n-'
    [email]=$'+a.b@example.com\n+x+tag@mail.co.uk\n+nome_cognome@sub.dominio.it\n-a@b\n-@x.com\n-a@@x.com\n-a@x.c\n-a b@x.com\n-a@x.'
    [semver]=$'+1.0.0\n+2.30.1-rc1\n+0.0.0\n+1.2.3-alpha.1\n-1.0\n-01.2.3\n-1.2.3-\n-1.2.03\n-v1.2.3'
    [assoluto]=$'+/\n+/etc\n+/home/mario/file.txt\n+/a/..b/c\n+/a/b../c\n-etc/x\n-//etc\n-/a/../b\n-/a//b\n-/..\n-/a/..'
    [vuota]=$'+\n+   \n+\t \n+# commento\n+  #x\n-a # b\n-x\n- x'
    [porta]=$'+1\n+80\n+8080\n+65535\n+65000\n+59999\n-0\n-65536\n-70000\n-080\n-655350'
    [host]=$'+web01\n+a.b-c.example\n+A1\n+x\n-\n--web\n-web-\n-a..b\n-un_host\n-.web\n-web.'
)

p_17_0() {
    local f=$L/regex.txt nome re caso testo err
    if [[ ! -r $f ]]; then
        boccia "regex.txt esiste" "manca $f: rilancia ./prepara.sh 17"
        return
    fi
    for nome in cifre intero colore ipv4 mac data ora utente email semver assoluto vuota porta host; do
        re=$(sed -n "s/^$nome //p" "$f" | head -n 1)
        if [[ -z $re ]]; then
            boccia "$nome" "nessuna espressione: scrivila dopo il nome, separata da uno spazio"
            continue
        fi
        err=()
        while IFS= read -r caso; do
            testo=${caso:1}
            if [[ ${caso:0:1} == + ]]; then
                grep -Exq -- "$re" <<<"$testo" 2>/dev/null || err+=("dovrebbe accettare: '$testo'")
            else
                grep -Exq -- "$re" <<<"$testo" 2>/dev/null && err+=("dovrebbe rifiutare: '$testo'")
            fi
        done <<<"${KATA_17[$nome]}"
        if grep -Eq -- "$re" </dev/null 2>/dev/null; (($? == 2)); then
            err=("espressione non valida per grep -E: $re")
        fi
        if ((${#err[@]} == 0)); then passa "$nome"; else boccia "$nome" "${err[@]}"; fi
    done
}

p_17_1() {
    script estrai-errori.sh || return
    local f=$L/dati/app.log
    uscita "eventi ERROR completi" '2026-11-03 02:14:07 ERROR connessione al database fallita
java.net.ConnectException: Connection refused
    at db.Pool.connect(Pool.java:42)
    at app.Main.main(Main.java:7)
--
2026-11-03 02:15:00 ERROR timeout sulla coda
--
2026-11-03 02:17:00 ERROR disco pieno
Caused by: java.io.IOException: No space left on device' "$X" "$f"
    vero "trovati: codice 0" test "$RC" -eq 0
    uscita "un altro livello, con righe che sembrano inizi ma non lo sono" '2026-11-03 02:14:30 WARN coda lenta
    at app.ErrorHandler.handle(ErrorHandler.java:3)
  2026-11-03 02:14:35 ERROR rientrata, fa parte dell'"'"'avviso' "$X" "$f" WARN
    uscita "il livello è una parola esatta" '2026-11-03 02:14:31 ERRORE messaggio da un modulo italiano' "$X" "$f" ERRORE
    codice "livello assente: 1" 1 "$X" "$f" DEBUG
    codice "file mancante: 2" 2 "$X" "$f.manca"
    codice "senza argomenti: 2" 2 "$X"
}

p_17_2() {
    script log-a-csv.sh || return
    local t
    t=$(tmp)
    uscita "converte il log" 'ip,data,metodo,percorso,stato,byte,agente
203.0.113.7,2026-11-02 09:14:03,GET,/index.html,200,5120,Mozilla/5.0 (X11; Linux)
198.51.100.23,2026-11-02 09:15:10,POST,/login,302,0,"curl/8.0, test"
192.0.2.44,2026-11-02 10:00:00,,,400,0,-
192.0.2.10,2026-12-03 23:59:59,GET,"/cerca?q=a,b",200,99,"Bot ""strano"" 1.0"
10.0.0.5,2027-01-04 00:00:01,HEAD,/,200,0,Wget' "$X" "$L/dati/access.log"
    vero "una riga saltata: codice 1" test "$RC" -eq 1
    vero "...e la segnala" grep -q 'riga 5' <<<"$ERR"
    head -n 1 "$L/dati/access.log" >"$t/una.log"
    lancia "$X" "$t/una.log"
    vero "tutto riconosciuto: codice 0" test "$RC" -eq 0
    codice "file mancante: 2" 2 "$X" "$t/manca.log"
}

# ---- Lezione 18 ------------------------------------------------------------

p_18_1() {
    script genera-vhost.sh || return
    local a
    a='# generato da genera-vhost.sh: non modificare a mano
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
}'
    uscita "il blocco completo, con le variabili di nginx intatte" "$a" "$X" sito.example 8080 "/srv/www/sito uno"
    vero "codice 0" test "$RC" -eq 0
    uscita "altri valori" "${a//sito.example/api-2.lab}" "$X" api-2.lab 8080 "/srv/www/sito uno"
    lancia "$X" sito.example 8443 '/srv/$HOME/`id`'
    vero "una RADICE con \$ e \` resta testo" grep -qF 'root "/srv/$HOME/`id`";' <<<"$OUT"
    local e
    for e in "Sito 80 /srv" "sito 0 /srv" "sito 65536 /srv" "sito 80a /srv" "sito 80 relativa" "sito_x 80 /srv"; do
        set -- $e
        lancia "$X" "$1" "$2" "$3"
        vero "rifiuta '$e' con 2 e stdout vuoto" test "$RC" -eq 2 -a -z "$OUT"
    done
    codice "argomenti mancanti: 2" 2 "$X" sito 80
}

p_18_2() {
    script con-log.sh || return
    local t f
    t=$(tmp)
    f=$t/registro.log
    cat >"$t/prova" <<'PROVA'
#!/usr/bin/env bash
printf 'uno\ndue\n'
for i in $(seq 1 200); do echo "errore $i" >&2; done
printf 'senza a capo'
exit 3
PROVA
    chmod +x "$t/prova"
    echo "riga di prima" >"$f"
    uscita "lo stdout del comando arriva inalterato" $'uno\ndue\nsenza a capo' "$X" "$f" "$t/prova"
    vero "esce con il codice del comando" test "$RC" -eq 3
    vero "lo stderr resta su stderr" grep -qx 'errore 200' <<<"$ERR"
    vero "...e non si mescola allo stdout" test "${OUT/errore/}" = "$OUT"
    vero "il file conserva ciò che c'era" test "$(head -n 1 "$f")" = "riga di prima"
    vero "righe dello stdout con ora ed etichetta" grep -qE '^[0-9]{2}:[0-9]{2}:[0-9]{2} out\| due$' "$f"
    vero "anche l'ultima riga senza a capo" grep -qE '^[0-9]{2}:[0-9]{2}:[0-9]{2} out\| senza a capo$' "$f"
    vero "tutte le 200 righe di stderr, già scritte all'uscita" test "$(grep -cE '^[0-9:]{8} err\| errore [0-9]+$' "$f")" -eq 200
    vero "l'ultima riga è la fine, con il codice" corrisponde "$(tail -n 1 "$f")" '^[0-9]{2}:[0-9]{2}:[0-9]{2} fine codice 3$'
    printf 'da stdin\n' >"$t/ingresso"
    INGRESSO=$t/ingresso
    uscita "lo stdin passa al comando" "da stdin" "$X" "$t/altro.log" cat
    INGRESSO=/dev/null
    vero "comando riuscito: fine codice 0" corrisponde "$(tail -n 1 "$t/altro.log")" ' fine codice 0$'
    codice "pochi argomenti: 2" 2 "$X" "$f"
}

# chiede RISPOSTE CODICE_ATTESO DESCRIZIONE ARGOMENTI...
chiede() {
    local r=$1 a=$2 d=$3 t
    shift 3
    t=$(tmp)
    printf '%b' "$r" >"$t/in"
    INGRESSO=$t/in lancia "$X" "$@"
    if [[ $RC -eq $a && -z $OUT ]]; then
        passa "$d"
    else
        boccia "$d" "codice atteso $a, ottenuto $RC" "stdout: ${OUT:-(vuoto)}" "stderr: ${ERR:-(vuoto)}"
    fi
}

p_18_3() {
    script chiedi.sh || return
    chiede 'sì\n' 0 "sì: 0" "Procedo?"
    chiede 'SI\n' 0 "SI: 0" "Procedo?"
    chiede '  yes  \n' 0 "yes con spazi: 0" "Procedo?"
    chiede 'No\n' 1 "No: 1" "Procedo?"
    chiede 'n' 1 "n senza a capo: 1" "Procedo?"
    chiede '\n' 1 "riga vuota: vale il predefinito n" "Procedo?" n
    chiede '\n' 0 "riga vuota: vale il predefinito s" "Procedo?" s
    chiede '\n\ns\n' 0 "riga vuota senza predefinito: richiede" "Procedo?"
    chiede 'boh\nforse\nn\n' 1 "due risposte storte, poi n: 1" "Procedo?"
    vero "...segnalandole su stderr" test "$(grep -c 'rispondi s o n' <<<"$ERR")" -eq 2
    vero "...e la domanda sta su stderr" grep -qF 'Procedo? [s/n]' <<<"$ERR"
    chiede 'a\nb\nc\ns\n' 2 "tre risposte storte: 2" "Procedo?"
    chiede '' 0 "stdin vuoto con predefinito s: 0" "Procedo?" s
    vero "...e la domanda mostra il predefinito" grep -qF '[S/n]' <<<"$ERR"
    chiede '' 2 "stdin vuoto senza predefinito: 2" "Procedo?"
    chiede 's\n' 2 "predefinito non valido: 2" "Procedo?" forse
    chiede '' 2 "senza argomenti: 2"
    local inizio=$SECONDS
    lancia bash -c 'exec "$@" < <(sleep 6)' _ env CHIEDI_TEMPO=1 "$X" "Procedo?" n
    vero "nessuna risposta entro CHIEDI_TEMPO: predefinito n" test "$RC" -eq 1
    vero "...senza aspettare oltre" test $((SECONDS - inizio)) -le 4
}

# ---- Lezione 19 ------------------------------------------------------------

p_19_1() {
    script somma-usato.sh || return
    uscita "somma la colonna Used" "usati: 7801405" "$X" "$L/dati/df.txt"
    vero "il file non ha più i fine riga di Windows" test -z "$(grep -l $'\r' "$X")"
}

p_19_2() {
    script stato-servizio.sh || return
    local PATH=$L/dati/bin:$PATH
    uscita "servizio attivo" "sshd: attivo" "$X" sshd
    vero "...codice 0" test "$RC" -eq 0
    uscita "servizio fermo" "httpd: fermo (inactive)" "$X" httpd
    vero "...codice 1" test "$RC" -eq 1
    uscita "servizio sconosciuto" "boh: fermo (unknown)" "$X" boh
    vero "...codice 1" test "$RC" -eq 1
}

p_19_3() {
    script trova-grandi.sh || return
    local d="$L/dati/grandi/cartella con spazi"
    uscita "soglia predefinita di 10 MB" "$d/grande.img
$d/sotto/enorme.img" "$X" "$d"
    uscita "soglia esplicita" "$d/sotto/enorme.img" "$X" "$d" 20
    uscita "soglia bassa" "$d/grande.img
$d/piccolo.img
$d/sotto/enorme.img" "$X" "$d" 0
    codice "senza cartella: 2" 2 "$X"
    vero "...e senza cercare altrove" test -z "$OUT"
}

p_19_4() {
    script archivia.sh || return
    local t
    t=$(tmp)
    mkdir -p "$t/le copie" "$t/da archiviare/sito web"
    echo pagina >"$t/da archiviare/sito web/index.html"
    uscita "percorsi relativi con spazi" "le copie/archivio.tar.gz" env -C "$t" "$X" "da archiviare/sito web" "le copie"
    vero "codice 0" test "$RC" -eq 0
    vero "l'archivio contiene la cartella" test "$(tar -tzf "$t/le copie/archivio.tar.gz" 2>/dev/null | sort | head -n 1)" = "sito web/"
    lancia env -C "$t" "$X" "da archiviare/sito web" "non esiste"
    vero "DEST mancante: codice 1" test "$RC" -eq 1
    vero "...e nessun archivio altrove" test -z "$(find "$t" -name archivio.tar.gz ! -path "$t/le copie/*")"
}

p_19_5() {
    script ha-errori.sh || return
    uscita "solo i file con ERROR" "a.log
c con spazi.log" env -C "$L/dati/log" "$X" a.log b.log "c con spazi.log"
    vero "trovati: codice 1" test "$RC" -eq 1
    uscita "nessun errore" "" env -C "$L/dati/log" "$X" b.log
    vero "...codice 0" test "$RC" -eq 0
}

p_19_6() {
    script fine-mese.sh || return
    local c
    for c in "2026-08-09 22" "2026-09-08 22" "2026-02-08 20" "2024-02-29 0" "2026-12-31 0" "2026-11-03 27" "2026-01-01 30"; do
        set -- $c
        uscita "$1: $2 giorni" "$2" "$X" "$1"
    done
    codice "data non valida: 2" 2 "$X" 2026-13-45
    codice "senza argomenti: 2" 2 "$X"
}

# Quattro versioni difettose di versione.sh: ognuna risponde come quella dello
# studente, salvo un difetto tipico.
scrivi_mutanti_19() {
    local d=$1 vera=$2
    cat >"$d/testo" <<MUT
#!/usr/bin/env bash
# Difetto: confronta le versioni come testo.
if [[ \$1 =~ [0-9]{2} || \$2 =~ [0-9]{2} ]] && [[ \$1 =~ ^v?[0-9.]+\$ && \$2 =~ ^v?[0-9.]+\$ ]]; then
    a=\${1#[vV]} b=\${2#[vV]}
    [[ \$a == "\$b" ]] && exit 0
    [[ \$a < \$b ]] && exit 1
    exit 2
fi
exec "$vera" "\$@"
MUT
    cat >"$d/corta" <<MUT
#!/usr/bin/env bash
# Difetto: una versione con meno numeri sembra più vecchia.
a=\${1//[^.]/} b=\${2//[^.]/}
if [[ \$1 =~ ^v?[0-9.]+\$ && \$2 =~ ^v?[0-9.]+\$ && \${#a} -ne \${#b} ]]; then
    (( \${#a} < \${#b} )) && exit 1
    exit 2
fi
exec "$vera" "\$@"
MUT
    cat >"$d/accetta" <<MUT
#!/usr/bin/env bash
# Difetto: non controlla l'ingresso.
if [[ \$# -ne 2 || ! \$1 =~ ^[vV]?[0-9]+(\.[0-9]+)*\$ || ! \$2 =~ ^[vV]?[0-9]+(\.[0-9]+)*\$ ]]; then exit 0; fi
exec "$vera" "\$@"
MUT
    cat >"$d/ottale" <<MUT
#!/usr/bin/env bash
# Difetto: un numero con lo zero davanti fa fallire il conto.
if [[ \$1 =~ (^|[.vV])0[0-9] || \$2 =~ (^|[.vV])0[0-9] ]]; then
    echo "versione: valore troppo grande per la base" >&2
    exit 1
fi
exec "$vera" "\$@"
MUT
    chmod +x "$d"/*
}

p_19_7() {
    local lib=$L/prova-lib.sh
    if [[ ! -r $lib ]]; then
        boccia "prova-lib.sh esiste" "manca $lib"
        return
    fi
    lancia bash -c '
        source "$1" || exit 99
        assert_eq a a "uguali"
        assert_eq a "b c" "diversi"
        assert_code 0 "vero" true
        assert_code 1 "codice" sh -c "echo rumore; echo rumore >&2; exit 2"
        assert_code 0 "spazi negli argomenti" test "a  b" = "a  b"
        riepilogo
    ' _ "$lib"
    local a="ok - uguali
NO - diversi: atteso 'a', ottenuto 'b c'
ok - vero
NO - codice: codice atteso 1, ottenuto 2
ok - spazi negli argomenti
passate: 3, fallite: 2"
    if [[ $OUT == "$a" ]]; then passa "la libreria riporta prove riuscite e fallite"; else boccia "la libreria riporta prove riuscite e fallite" "--- atteso ---" "$a" "--- ottenuto ---" "$OUT" "--- stderr ---" "${ERR:-(vuoto)}"; fi
    vero "riepilogo con fallite: restituisce 1" test "$RC" -eq 1
    vero "assert_code non mostra l'output del comando" test "${ERR/rumore/}" = "$ERR"
    lancia bash -c 'source "$1"; assert_eq x x uno; assert_code 3 due sh -c "exit 3"; riepilogo' _ "$lib"
    vero "tutto riuscito: passate 2, fallite 0, restituisce 0" test "$(tail -n 1 <<<"$OUT")" = "passate: 2, fallite: 0" -a "$RC" -eq 0
    script test-versione.sh || return
    local vera=$PALESTRA/l15/versione.sh t m
    if [[ ! -x $vera ]]; then
        boccia "c'è la tua versione.sh della lezione 15" "manca $vera: risolvi prima il problema 3 della lezione 15"
        return
    fi
    lancia "$X" "$vera"
    vero "sulla tua versione.sh i test passano" test "$RC" -eq 0
    vero "...e sono almeno dieci" test "$(grep -cE '^(ok|NO) - ' <<<"$OUT")" -ge 10
    t=$(tmp)
    scrivi_mutanti_19 "$t" "$vera"
    for m in testo corta accetta ottale; do
        lancia "$X" "$t/$m"
        vero "i test scoprono la versione difettosa '$m' ($(sed -n 2p "$t/$m" | cut -c3-))" test "$RC" -ne 0
    done
}

p_19_8() {
    script veloce.sh || return
    local t f orig=$L/dati/lento-originale.sh inizio fine ms
    t=$(tmp)
    head -n 1500 "$L/dati/grande.log" >"$t/piccolo.log"
    {
        for ip in 192.0.2.9 192.0.2.10 192.0.2.1 198.51.100.7 203.0.113.70 203.0.113.8 10.0.0.5 10.0.0.50 10.0.0.6 192.0.2.2 192.0.2.3 192.0.2.30; do
            printf '%s - - [02/Nov/2026:10:00:00 +0100] "GET / HTTP/1.1" 404 10 "-" "a"\n' "$ip"
        done
        printf '%s - - [02/Nov/2026:10:00:00 +0100] "GET / HTTP/1.1" 200 10 "-" "a"\n' 192.0.2.99 192.0.2.99
        printf '%s - - [02/Nov/2026:10:00:00 +0100] "GET / HTTP/1.1" 503 10 "-" "a"\n' 10.0.0.5 192.0.2.10
        printf '\n'
    } >"$t/pareggi.log"
    printf '%s - - [02/Nov/2026:10:00:00 +0100] "GET / HTTP/1.1" 200 1 "-" "a"\n' 192.0.2.1 >"$t/nessuno.log"
    for f in piccolo pareggi nessuno; do
        uscita "stesso output di lento.sh su $f.log" "$("$orig" "$t/$f.log")" "$X" "$t/$f.log"
    done
    inizio=$(date +%s%N)
    LIMITE=10 lancia "$X" "$L/dati/grande.log"
    fine=$(date +%s%N)
    ms=$(((fine - inizio) / 1000000))
    vero "sul file grande: sotto i 3 secondi (impiegati ${ms} ms)" test "$ms" -lt 3000
    vero "...e stampa dieci righe" test "$(wc -l <<<"$OUT")" -eq 10
}

p_19_9() {
    local lib=$L/traccia-errori.sh t
    if [[ ! -r $lib ]]; then
        boccia "traccia-errori.sh esiste" "manca $lib"
        return
    fi
    t=$(tmp)
    cat >"$t/prova.sh" <<'PROVA'
#!/usr/bin/env bash
source "$TRACCIA"
interna() {
    echo "prima"
    if false; then echo mai; fi
    grep -q nulla /dev/null || true
    false
    echo "mai qui"
}
esterna() {
    interna
}
echo inizio
esterna
echo "mai qui"
PROVA
    cat >"$t/prova2.sh" <<'PROVA'
#!/usr/bin/env bash
source "$TRACCIA"
echo uno
ls /nessuno/percorso
echo "mai qui"
PROVA
    chmod +x "$t"/*.sh
    TRACCIA=$lib uscita "si ferma al primo errore vero" $'inizio\nprima' "$t/prova.sh"
    vero "...con il suo codice" test "$RC" -eq 1
    local a="ERRORE: 'false' è uscito con 1
  in prova.sh:7, nella funzione interna
  chiamata da prova.sh:11, nella funzione esterna
  chiamata da prova.sh:14"
    if [[ $ERR == "$a" ]]; then passa "traccia completa su stderr"; else boccia "traccia completa su stderr" "--- attesa ---" "$a" "--- ottenuta ---" "${ERR:-(vuota)}"; fi
    TRACCIA=$lib lancia "$t/prova2.sh"
    vero "fuori dalle funzioni: codice del comando" test "$RC" -eq 2
    vero "...e traccia di un livello" test "$(grep -v '^ls:' <<<"$ERR")" = "ERRORE: 'ls /nessuno/percorso' è uscito con 2
  in prova2.sh:4"
}

# ---- Avvio -----------------------------------------------------------------

scrivi_guardie

n=${1:-}
if [[ -z $n ]]; then
    echo "Uso: $0 NN [PROBLEMA]" >&2
    exit 2
fi
L=$PALESTRA/l$n
if [[ ! -d $L/dati ]]; then
    echo "Manca $L/dati: lancia prima ./prepara.sh $n" >&2
    exit 2
fi

mapfile -t PROVE < <(declare -F | awk '{print $3}' | grep "^p_${n}_" | sort -t_ -k3,3n)
if [[ -n ${2:-} ]]; then
    if ! declare -F "p_${n}_$2" >/dev/null; then
        echo "Il problema $2 della lezione $n si controlla a mano: vedi la lezione." >&2
        exit 2
    fi
    PROVE=("p_${n}_$2")
fi

cd "$L" || exit 2
for p in "${PROVE[@]}"; do
    printf '\n== Lezione %s, problema %s ==\n' "$n" "${p##*_}"
    "$p"
done

printf '\nPassate: %d   Non passate: %d\n' "$PASSATE" "$FALLITE"
((FALLITE == 0))
