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
