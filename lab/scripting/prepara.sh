#!/usr/bin/env bash
# Prepara la palestra di una lezione di scripting: crea palestra/lNN/dati/ con
# dati finti ma realistici e, dove serve, gli script rotti da riparare.
#
#   ./prepara.sh 04        prepara la lezione 04
#   ./prepara.sh tutte     prepara tutte le lezioni
#   ./prepara.sh a3        prepara l'area a3 degli allenamenti
#
# Rilanciarlo rigenera dati/ da zero, ma non tocca mai i tuoi script.
# Gira su Linux con i soli pacchetti di "base" (bash, coreutils, gawk, tar, gzip).
set -euo pipefail

RADICE=$(cd "$(dirname "$0")" && pwd)
PALESTRA=${PALESTRA:-$RADICE/palestra}
LEZIONI=(01 02 03 04 05 06 07 08 09 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 a1 a2 a3 a4 a5 a6 a7 a8)

# Giorni trascorsi dal 1970 per il giorno di riferimento dei dati di /etc/shadow.
# È fisso, così i risultati attesi non cambiano col passare del tempo.
GIORNO_ZERO=20760 # 2026-11-03

# Copia uno script rotto solo se manca: le tue riparazioni non si sovrascrivono.
script_rotto() {
    local nome=$1
    if [[ -e $nome ]]; then
        cat >/dev/null
    else
        cat >"$nome"
    fi
}

scrivi_passwd() {
    cat >"$1" <<'EOF'
root:x:0:0:root:/root:/bin/bash
bin:x:1:1:bin:/:/sbin/nologin
daemon:x:2:2:daemon:/:/sbin/nologin
nobody:x:65534:65534:Kernel Overflow User:/:/sbin/nologin
sshd:x:74:74:OpenSSH:/var/empty:/sbin/nologin
mario:x:1000:1000:Mario Rossi:/home/mario:/bin/bash
marta:x:1001:1001:Marta:/home/marta:/bin/zsh
zeno:x:1002:1002::/home/zeno:/bin/bash
anna:x:1003:1003:Anna Bianchi,Stanza 4:/home/anna:/bin/bash
backup:x:1004:1004:Utente tecnico:/srv/backup:/sbin/nologin
ex:x:1005:1005:Ex dipendente:/home/ex:/bin/false
gianni:x:999:999:Servizio:/var/lib/gianni:/bin/bash
EOF
}

# Log di un server web: 370 richieste, ordinate per ora. I numeri sono
# pseudocasuali ma riproducibili, perché il generatore è scritto qui.
scrivi_access_log() {
    awk 'function rnd(n) { seme = (seme * 16807) % 2147483647; return seme % n }
    BEGIN {
        seme = 12345
        n = split("203.0.113.7:120 198.51.100.23:85 192.0.2.44:60 203.0.113.9:40 198.51.100.5:25 192.0.2.10:25 203.0.113.200:10 10.0.0.5:5", ip, " ")
        np = split("/index.html /login /api/stato /static/app.js /static/logo.png /admin /wp-login.php", url, " ")
        i = 0
        for (k = 1; k <= n; k++) {
            split(ip[k], b, ":")
            for (j = 0; j < b[2]; j++) {
                i++
                st = 200
                if (i % 37 == 0) st = 500
                else if (i % 11 == 0) st = 404
                else if (i % 13 == 0) st = 301
                else if (i % 17 == 0) st = 304
                dim = (st == 304) ? "-" : 200 + rnd(5000)
                r = rnd(100)
                h = (r < 40) ? 9 : (r < 70) ? 14 : rnd(24)
                ora = sprintf("%02d:%02d:%02d", h, rnd(60), rnd(60))
                printf "%s\t%s - - [02/Nov/2026:%s +0100] \"GET %s HTTP/1.1\" %d %s\n", ora, b[1], ora, url[rnd(np) + 1], st, dim
            }
        }
    }' | LC_ALL=C sort -s -t "$(printf '\t')" -k1,1 | cut -f2- >"$1"
}

# Log di sshd, con le stesse righe che si trovano davvero su un server esposto.
scrivi_auth_log() {
    awk 'function rnd(n) { seme = (seme * 16807) % 2147483647; return seme % n }
    function riga(testo) {
        ora = sprintf("%02d:%02d:%02d", rnd(24), rnd(60), rnd(60))
        printf "%s\tNov  2 %s web01 %s\n", ora, ora, testo
    }
    function ripeti(quante, testo,    q) {
        for (q = 0; q < quante; q++) riga("sshd[" (1000 + rnd(9000)) "]: " testo " port " (30000 + rnd(30000)) " ssh2")
    }
    BEGIN {
        seme = 777
        ripeti(30, "Failed password for root from 203.0.113.7")
        ripeti(12, "Failed password for invalid user admin from 203.0.113.7")
        ripeti(9,  "Failed password for invalid user test from 198.51.100.23")
        ripeti(4,  "Failed password for root from 192.0.2.44")
        ripeti(6,  "Failed password for invalid user from from 198.51.100.66")
        ripeti(20, "Accepted publickey for mario from 192.0.2.10")
        ripeti(1,  "Accepted password for anna from 203.0.113.7")
        for (q2 = 0; q2 < 5; q2++) riga("sshd[" (1000 + rnd(9000)) "]: Connection closed by 198.51.100.23 port " (30000 + rnd(30000)))
        for (q2 = 0; q2 < 24; q2++) riga("CRON[" (1000 + rnd(9000)) "]: pam_unix(cron:session): session opened for user root")
    }' | LC_ALL=C sort -s -t "$(printf '\t')" -k1,1 | cut -f2- >"$1"
}

l01() {
    printf 'riga %s\n' {1..12} >"dati/nome con spazi.log"
    printf 'unica riga\n' >dati/corto.log
    printf '[rete]\nporta = 8080\n' >"dati/conf di prova.ini"
    script_rotto conta-righe.sh <<'EOF'
#!/usr/bin/env bash
# Conta le righe del file passato come primo argomento.
file = $1
righe=wc -l < $file
echo '$file: $righe righe'
EOF
}

l02() {
    scrivi_passwd dati/passwd
    cat >dati/df.txt <<'EOF'
Filesystem     1024-blocks      Used Available Capacity Mounted on
/dev/sda1         18350080   7707033  10643047      42% /
/dev/sda3          1048576     94372    954204       9% /boot
/dev/sda4          8388608   7130317   1258291      85% /var
/dev/sda5          2097152   2034237     62915      97% /var/log
/dev/sda6         41943040  40265318   1677722      96% /home
tmpfs              2097152         0   2097152       0% /run/user/1000
EOF
    mkdir -p dati/contenuto/sito
    printf 'benvenuti\n' >dati/contenuto/sito/index.html
    printf 'nota di servizio\n' >dati/nota.txt
    (
        cd dati/contenuto
        tar -cf ../pacchetto.tar sito
        tar -czf ../pacchetto.tar.gz sito
        tar -czf ../pacchetto.tgz sito
    )
    gzip -c dati/nota.txt >dati/nota.txt.gz
    printf 'non sono un archivio\n' >dati/strano.rar
    rm -f dati/nota.txt
}

l03() {
    mkdir -p dati/nomi-difficili/una_cartella dati/vuota dati/vecchi/log dati/vecchi/cache
    (
        cd dati/nomi-difficili
        : >uno.txt
        : >"due parole.txt"
        : >-inizia-col-trattino.txt
        : >"asterisco*.txt"
        : >gia.bak
    )
    (
        cd dati/vecchi
        head -c 1000 /dev/zero >log/app.log.1
        head -c 2000 /dev/zero >"log/app log.2"
        head -c 500 /dev/zero >log/app.log
        head -c 300 /dev/zero >cache/x.tmp
        head -c 100 /dev/zero >cache/recente.tmp
        touch -d '40 days ago' log/app.log.1
        touch -d '60 days ago' "log/app log.2"
        touch -d '35 days ago' cache/x.tmp
        touch -d '2 days ago' cache/recente.tmp
        touch -d '90 days ago' log cache
    )
    cat >dati/instabile.sh <<'EOF'
#!/usr/bin/env bash
# Simula un servizio che si riprende: fallisce le prime due chiamate che usano lo
# stesso file contatore, poi riesce.
contatore=${1:?serve il file contatore}
n=$(( $(cat "$contatore" 2>/dev/null || echo 0) + 1 ))
echo "$n" >"$contatore"
(( n >= 3 ))
EOF
    chmod +x dati/instabile.sh
}

l04() {
    scrivi_passwd dati/passwd
    scrivi_access_log dati/access.log
    scrivi_auth_log dati/auth.log
    cat >dati/group <<'EOF'
root:x:0:
wheel:x:10:mario,anna
mario:x:1000:
marta:x:1001:
zeno:x:1002:
anna:x:1003:
sviluppo:x:2000:zeno,mario,zeno
vuoto:x:2001:
backup:x:1004:
ex:x:1005:
gianni:x:999:
EOF
}

l05() {
    scrivi_access_log dati/access.log
    cat >dati/sito.conf.tmpl <<'EOF'
server {
    server_name {{DOMINIO}};
    root {{ROOT}};
    add_header X-Titolo "{{TITOLO}}";
    # {{DOMINIO}} gestito da {{ADMIN}}
}
EOF
    cat >dati/sshd_config <<'EOF'
# Configurazione di esempio del demone SSH
#Port 22
PermitRootLogin yes
#PasswordAuthentication yes
PasswordAuthenticationExtra no
# PermitRootLogin va disattivato in produzione
#UsePAM yes
UsePAM yes
EOF
}

l06() {
    cat >dati/consumi.txt <<'EOF'
nginx 120
postgres 2048
redis 64
cron 9
sshd 12
test-app 5
test-db 700
php-fpm 350
EOF
    script_rotto pulisci-rotto.sh <<'EOF'
#!/usr/bin/env bash
# Svuota la cartella passata come argomento.
# ATTENZIONE: non lanciarlo. Il problema 1 chiede di capire perché.
DIR=$1
cd $DIR
rm -rf *
echo "Pulita $DIR"
EOF
}

l07() {
    scrivi_passwd dati/passwd
    cat >dati/group <<'EOF'
root:x:0:
wheel:x:998:mario
staff:x:50:
mario:x:1000:
EOF
    cat >dati/nuovi-utenti.csv <<'EOF'
# nome;gruppo;shell;scadenza
luca;sviluppo;/bin/bash;2027-06-30
sara;sviluppo;/bin/zsh;

mario;sviluppo;/bin/bash;2027-06-30
Nome Sbagliato;sviluppo;/bin/bash;
teo;ops;/sbin/nologin;31-12-2027
piero;ops;/bin/bash;2027-01-31
dana;staff;/bin/bash;
EOF
    local z=$GIORNO_ZERO
    cat >dati/shadow <<EOF
root:\$6\$sale\$hash:$((z - 100)):0:99999:7:::
bin:*:$((z - 500))::::::
mario:\$6\$sale\$hash:$((z - 85)):0:90:7:::
anna:\$6\$sale\$hash:$((z - 80)):0:90:7:::
zeno:\$6\$sale\$hash:$((z - 100)):0:90:7:::
marta:\$6\$sale\$hash:$((z - 10)):0:90:7:::
ex:!\$6\$sale\$hash:$((z - 200)):0:90:7:::
backup:*:$((z - 300)):0:90:7:::
gianni:\$6\$sale\$hash:$((z - 50)):0::7:::
teo:\$6\$sale\$hash:0:0:90:7:::
EOF
    mkdir -p dati/albero/dir-aperta dati/albero/tmp-ok dati/albero/sotto
    (
        cd dati/albero
        : >normale
        : >suid.bin
        : >sgid.bin
        : >aperto.txt
        : >"nome con spazi.txt"
        : >sotto/segreto
        ln -sf /etc/passwd link-innocuo
        chgrp "$(id -g)" sgid.bin
        chmod 644 normale
        chmod 4755 suid.bin
        chmod 2755 sgid.bin
        chmod 666 aperto.txt "nome con spazi.txt"
        chmod 777 dir-aperta
        chmod 1777 tmp-ok
        chmod 600 sotto/segreto
    )
}

l08() {
    mkdir -p "dati/sito web/immagini" dati/backup
    (
        cd "dati/sito web"
        printf '<h1>home</h1>\n' >index.html
        printf 'porta=8080\n' >"conf server.ini"
        head -c 2048 /dev/zero >immagini/logo.png
    )
    local d
    for d in 20261028 20261029 20261030 20261031 20261101; do
        : >"dati/backup/web_$d-020000.tar.gz"
        : >"dati/backup/web_$d-020000.tar.gz.sha256"
    done
    : >dati/backup/web2_20260101-020000.tar.gz
    : >dati/backup/db_20260101-020000.tar.gz
}

l09() {
    cat >dati/ps.txt <<'EOF'
USER         PID STAT %CPU %MEM COMMAND
root           1 Ss    0.1  0.5 systemd
root         200 Ss    0.0  2.5 systemd-journal
mario       1000 Sl   12.0 20.5 firefox
mario       1010 R    30.0  4.0 python3
postgres     800 Ss    1.0 15.2 postgres
postgres     801 Ss    0.5  7.3 postgres
anna        1200 Z     0.0  0.0 defunct
anna        1300 S     0.0  2.0 bash
root         300 Z+    0.0  0.0 defunct
EOF
}

l10() {
    mkdir -p dati/bin uscita
    cat >dati/bin/misura <<'EOF'
#!/bin/sh
echo "misura: ok"
EOF
    chmod +x dati/bin/misura
    printf 'INFO avvio\nERRORE disco\nINFO controllo\nERRORE rete\nERRORE rete\n' >dati/eventi.log
    script_rotto rapporto.sh <<'EOF'
#!/usr/bin/env bash
# Scrive lo stato del sistema in uscita/stato.txt. Pensato per girare ogni notte.
export PATH="$PATH:dati/bin"
misura > uscita/stato.txt
grep -c ERRORE dati/eventi.log >> uscita/stato.txt
echo "generato da $USER il $(date +%F)" >> uscita/stato.txt
EOF
    chmod +x rapporto.sh
    # Esportazione di journalctl -o json: un evento per riga.
    cat >dati/journal.json <<'EOF'
{"__REALTIME_TIMESTAMP": "1793663400123456", "PRIORITY": "3", "SYSLOG_IDENTIFIER": "backup", "MESSAGE": "disco pieno", "_HOSTNAME": "lab-rocky", "_SYSTEMD_UNIT": "backup.service"}
{"__REALTIME_TIMESTAMP": "1793664000123456", "PRIORITY": "3", "SYSLOG_IDENTIFIER": "backup", "MESSAGE": "disco pieno", "_HOSTNAME": "lab-rocky", "_SYSTEMD_UNIT": "backup.service"}
{"__REALTIME_TIMESTAMP": "1793664900123456", "PRIORITY": "6", "SYSLOG_IDENTIFIER": "sshd", "MESSAGE": "Accepted publickey", "_HOSTNAME": "lab-rocky", "_SYSTEMD_UNIT": "sshd.service"}
{"__REALTIME_TIMESTAMP": "1793667720123456", "PRIORITY": "3", "SYSLOG_IDENTIFIER": "httpd", "MESSAGE": "AH00072: make_sock: could not bind", "_HOSTNAME": "lab-rocky", "_SYSTEMD_UNIT": "httpd.service"}
{"__REALTIME_TIMESTAMP": "1793667780123456", "PRIORITY": "2", "SYSLOG_IDENTIFIER": "httpd", "MESSAGE": "critico", "_HOSTNAME": "lab-rocky", "_SYSTEMD_UNIT": "httpd.service"}
{"__REALTIME_TIMESTAMP": "1793673000123456", "PRIORITY": "3", "SYSLOG_IDENTIFIER": "backup", "MESSAGE": "tar: errore di scrittura", "_HOSTNAME": "lab-rocky", "_SYSTEMD_UNIT": "backup.service"}
{"__REALTIME_TIMESTAMP": "1793675400123456", "PRIORITY": "4", "SYSLOG_IDENTIFIER": "crond", "MESSAGE": "avviso", "_HOSTNAME": "lab-rocky", "_SYSTEMD_UNIT": "crond.service"}
{"__REALTIME_TIMESTAMP": "1793675460123456", "PRIORITY": "3", "SYSLOG_IDENTIFIER": "kernel", "MESSAGE": "I/O error, dev sda", "_HOSTNAME": "lab-rocky"}
{"__REALTIME_TIMESTAMP": "1793678400123456", "PRIORITY": "0", "SYSLOG_IDENTIFIER": "systemd-logind", "MESSAGE": "emergenza", "_HOSTNAME": "lab-rocky", "_SYSTEMD_UNIT": "systemd-logind.service"}
{"__REALTIME_TIMESTAMP": "1793685540123456", "PRIORITY": "3", "SYSLOG_IDENTIFIER": "postgres", "MESSAGE": "connessione persa", "_HOSTNAME": "lab-rocky", "_SYSTEMD_UNIT": "postgresql.service"}
{"__REALTIME_TIMESTAMP": "1793685600123456", "PRIORITY": "3", "SYSLOG_IDENTIFIER": "postgres", "MESSAGE": "fuori finestra", "_HOSTNAME": "lab-rocky", "_SYSTEMD_UNIT": "postgresql.service"}
{"__REALTIME_TIMESTAMP": "1793691000123456", "PRIORITY": "3", "SYSLOG_IDENTIFIER": "httpd", "MESSAGE": "fuori finestra", "_HOSTNAME": "lab-rocky", "_SYSTEMD_UNIT": "httpd.service"}
EOF
}

l11() {
    cat >dati/sentinella.conf <<'EOF'
# tipo   parametri
disco    /  80 90
disco    /var 80 90
file     /etc/passwd
processo systemd
comando  true
EOF
    cat >dati/regola.txt <<'EOF'
report.txt: a.txt b.txt
	cat a.txt b.txt > report.txt
	echo fatto
EOF
}

l12() {
    mkdir -p dati/bin
    # Finto VBoxManage: stesso formato di quello vero, con VM scelte per mettere alla prova.
    cat >dati/bin/VBoxManage <<'EOF'
#!/usr/bin/env bash
case ${1:-} in
    list)
        printf '"%s" {0000-%s}\n' lab-arch 1 "lab rocky" 2 "senza rete" 3 web 4
        ;;
    showvminfo)
        echo "name=\"$2\""
        case $2 in
            lab-arch)
                echo 'Forwarding(0)="ssh,tcp,127.0.0.1,2222,,22"'
                ;;
            "lab rocky")
                echo 'Forwarding(0)="ssh,tcp,127.0.0.1,2223,,22"'
                echo 'Forwarding(1)="http,tcp,127.0.0.1,8080,,80"'
                ;;
            "senza rete")
                echo 'description="Forwarding da configurare"'
                ;;
            web)
                echo 'Forwarding(0)="https,tcp,,8443,,443"'
                ;;
            *)
                echo "VBoxManage: error: Could not find a registered machine named '$2'" >&2
                exit 1
                ;;
        esac
        ;;
    *)
        echo "VBoxManage: comando non previsto da questa finta" >&2
        exit 2
        ;;
esac
EOF
    # Finto ssh: come quello vero, legge lo stdin che eredita.
    cat >dati/bin/remoto <<'EOF'
#!/usr/bin/env bash
cat >/dev/null
if [[ $1 == spento ]]; then
    echo "remoto: $1: connessione rifiutata" >&2
    exit 255
fi
echo "[$1] $2"
EOF
    # Finto programma di esportazione: il database "rotto" si interrompe a metà.
    cat >dati/bin/dump <<'EOF'
#!/usr/bin/env bash
echo "-- esportazione di $1"
echo "INSERT INTO clienti VALUES (1);"
if [[ $1 == rotto ]]; then
    echo "dump: errore di lettura a metà tabella" >&2
    exit 3
fi
echo "INSERT INTO clienti VALUES (2);"
echo "-- fine"
EOF
    chmod +x dati/bin/*
    printf '# macchine del laboratorio\nalfa\n\nbeta\nspento\ngamma' >dati/macchine.txt
    printf 'vim\nbash\ngit\nbash\ncurl\n' >dati/pacchetti-a.txt
    printf 'git\nzsh\nbash\nnginx\n' >dati/pacchetti-b.txt
    mkdir -p "dati/progetti/sito web" dati/progetti/api dati/progetti/vuoto
    echo "note del sito" >"dati/progetti/sito web/nota.txt"
    echo "note delle api" >dati/progetti/api/nota.txt
}

l13() {
    mkdir -p dati/vetrina
    touch dati/vetrina/a.txt dati/vetrina/b.txt "dati/vetrina/file con spazi.txt"
    cat >dati/spazio.txt <<'DATI'
# utente;home;megabyte;quota
anna;/home/anna;512;12.5

mario;/home/mario;20480;85
utentelungone;/home/utente prova;7;0.3
DATI
}

l14() {
    # Questa lezione non ha bisogno di dati: gli ingressi sono numeri.
    printf 'Gli ingressi di questa lezione sono numeri: non servono file.\n' >dati/LEGGIMI
}

l15() {
    printf '%s\n' 'login ok user=mario password=Segreta1 from 203.0.113.7' \
        'DB_PASSWORD:  abc  porta=5432' 'passwordless=yes' 'carta 4111111111111111 scade' \
        '  	rientro con \\ barre e password=' 'Secret=a secret=b apiToken=xyz;tokens=3' \
        '' 'numero 41111111111111112 troppo lungo' 'Il campo password non va' >dati/assistenza.log
    printf 'ultima riga token=senza-a-capo' >>dati/assistenza.log
    printf '%s\n' 'https://example.com' 'HTTPS://mario:segreta@Example.COM:8443/a/b?x=1' \
        'ssh://git@[2001:db8::1]:2222/repo.git' 'redis://cache:6379' >dati/servizi.txt
}

l16() {
    printf '%s\n' '# host;ruolo;ambiente' 'web01;web;prod' 'web02;Web;prod' 'db01;db;prod' '' \
        'web03;web;test' 'db02;db;prod' 'web01;web;test' 'mail01;posta' >dati/macchine.txt
    printf 'cache01;cache;test' >>dati/macchine.txt
    cat >dati/app.ini <<'DATI'
; configurazione dell'app
nome = demo
[db]
host = db.interno
porta=5432
password = a;b=c#d
[ cache ]
host    =   cache.interno
  # commento rientrato
porta = 6379
[db]
porta = 6432
DATI
    sed 's/$/\r/' dati/app.ini >dati/app-windows.ini
    mkdir -p dati/foto/vacanze dati/foto/vecchie dati/foto/doc
    (
        cd dati/foto
        printf 'JPEG del mare\n' | tee vacanze/mare.jpg "copia di mare.jpg" "vecchie/mare (1).jpg" >/dev/null
        printf 'relazione annuale\n' | tee doc/relazione.txt "doc/relazione finale.txt" >/dev/null
        printf 'contenuto unico\n' >unico.txt
        printf 'contenuto diver\n' >"stessa dimensione.txt"
        printf 'nome strano\n' | tee f.txt $'a capo\nqui.txt' >/dev/null
        : >vuoto1
        : >vuoto2
        ln -s vacanze/mare.jpg link-mare.jpg
    )
    cat >dati/app.conf <<'DATI'
# configurazione
NOME=demo
PORTA=8080
  RIENTRO=si
MESSAGGIO="ciao a tutti"
SINGOLE='$HOME resta così'
COMANDO=$(touch pwned)
URL=http://host/?a=1&b=2
1SBAGLIATA=x
CON SPAZIO=x
VUOTA=
DATI
}

l17() {
    # regex.txt è il tuo file: si crea solo se manca.
    script_rotto regex.txt <<'DATI'
# Un nome per riga, poi uno spazio e la tua espressione ERE (quella di grep -E).
# Il correttore la prova con grep -Ex: non servono ^ e $.
cifre
intero
colore
ipv4
mac
data
ora
utente
email
semver
assoluto
vuota
porta
host
DATI
    cat >dati/app.log <<'DATI'
2026-11-03 02:14:00 INFO avvio del servizio
2026-11-03 02:14:07 ERROR connessione al database fallita
java.net.ConnectException: Connection refused
    at db.Pool.connect(Pool.java:42)
    at app.Main.main(Main.java:7)
2026-11-03 02:14:30 WARN coda lenta
    at app.ErrorHandler.handle(ErrorHandler.java:3)
  2026-11-03 02:14:35 ERROR rientrata, fa parte dell'avviso
2026-11-03 02:14:31 ERRORE messaggio da un modulo italiano
2026-11-03 02:15:00 ERROR timeout sulla coda
2026-11-03 02:16:00 INFO ripresa
2026-11-03 02:17:00 ERROR disco pieno
DATI
    printf 'Caused by: java.io.IOException: No space left on device' >>dati/app.log
    cat >dati/access.log <<'DATI'
203.0.113.7 - - [02/Nov/2026:09:14:03 +0100] "GET /index.html HTTP/1.1" 200 5120 "-" "Mozilla/5.0 (X11; Linux)"
198.51.100.23 - mario [02/Nov/2026:09:15:10 +0100] "POST /login HTTP/1.1" 302 - "https://sito/" "curl/8.0, test"
192.0.2.44 - - [02/Nov/2026:10:00:00 +0100] "-" 400 0 "-" "-"
192.0.2.10 - - [03/Dec/2026:23:59:59 +0100] "GET /cerca?q=a,b HTTP/1.1" 200 99 "-" "Bot \"strano\" 1.0"
questa riga non è un log
10.0.0.5 - - [04/Jan/2027:00:00:01 +0000] "HEAD / HTTP/1.0" 200 0 "-" "Wget"
DATI
}

l18() {
    # Un comando che parla su entrambi i canali, per provare con-log.sh a mano.
    cat >dati/chiacchierone <<'DATI'
#!/usr/bin/env bash
echo "inizio"
for i in 1 2 3; do echo "passo $i"; echo "avviso $i" >&2; sleep 0.2; done
printf 'ultima riga senza a capo'
exit 3
DATI
    chmod +x dati/chiacchierone
    printf 'sì\n' >dati/risposta-si.txt
}

l19() {
    mkdir -p dati/bin "dati/grandi/cartella con spazi/sotto" "dati/da archiviare/sito web" dati/log
    # Il collega lo ha salvato da Windows: ogni riga finisce con \r\n.
    sed 's/$/\r/' <<'DATI' | script_rotto somma-usato.sh
#!/usr/bin/env bash
# Somma la colonna Used di un output di df -P salvato in un file.
tot=0
while read -r fs blocchi usati resto; do
    [[ $usati =~ ^[0-9]+$ ]] || continue
    tot=$((tot + usati))
done <"$1"
echo "usati: $tot"
DATI
    script_rotto stato-servizio.sh <<'DATI'
#!/usr/bin/env bash
# Dice se un servizio è attivo: codice 0 se lo è, 1 se no.
controlla() {
    local stato=$(servizio is-active "$1")
    if [ $? -ne 0 ]; then
        echo "$1: fermo ($stato)"
        return 1
    fi
    echo "$1: attivo"
}
controlla "$1"
DATI
    script_rotto trova-grandi.sh <<'DATI'
#!/usr/bin/env bash
# Elenca i file più grandi di MB megabyte (10 se manca) sotto CARTELLA.
if [ -n $2 ]; then
    soglia=$2
else
    soglia=10
fi
if [ $1 = "" ]; then
    echo "uso: $0 CARTELLA [MB]" >&2
    exit 2
fi
find $1 -type f -size +${soglia}M | sort
DATI
    script_rotto archivia.sh <<'DATI'
#!/usr/bin/env bash
# Archivia la cartella SORGENTE in DEST/archivio.tar.gz.
SORGENTE=$1
DEST=$2
cd $DEST
tar -czf archivio.tar.gz -C "$(dirname $SORGENTE)" "$(basename $SORGENTE)"
echo "$DEST/archivio.tar.gz"
DATI
    script_rotto ha-errori.sh <<'DATI'
#!/usr/bin/env bash
# Stampa i file che contengono ERROR. Codice 1 se ce n'è almeno uno.
trovati=0
for f in "$@"; do
    grep -q ERROR "$f"
    echo "controllato: $f" >&2
    if [ $? -eq 0 ]; then
        echo "$f"
        trovati=1
    fi
done
exit $trovati
DATI
    script_rotto fine-mese.sh <<'DATI'
#!/usr/bin/env bash
# Quanti giorni mancano alla fine del mese di una data AAAA-MM-GG.
anno=$(date -d "$1" +%Y)
mese=$(date -d "$1" +%m)
giorno=$(date -d "$1" +%d)
prossimo=$((mese + 1))
if [ $prossimo -eq 13 ]; then prossimo=1; anno=$((anno + 1)); fi
ultimo=$(date -d "$anno-$prossimo-01 -1 day" +%d)
echo $((ultimo - giorno))
DATI
    cat >dati/lento-originale.sh <<'DATI'
#!/usr/bin/env bash
# Conta le richieste fallite (4xx e 5xx) per IP e stampa le dieci peggiori.
declare -A falliti
while read -r riga; do
    ip=$(echo "$riga" | cut -d' ' -f1)
    stato=$(echo "$riga" | awk '{print $9}')
    if [[ $stato == [45]?? ]]; then
        falliti[$ip]=$(( ${falliti[$ip]:-0} + 1 ))
    fi
done <"$1"
for ip in "${!falliti[@]}"; do
    echo "${falliti[$ip]} $ip"
done | sort -k1,1nr -k2,2 | head -n 10
DATI
    chmod +x dati/lento-originale.sh
    script_rotto lento.sh <dati/lento-originale.sh
    chmod +x ./*.sh
    cat >dati/bin/servizio <<'DATI'
#!/usr/bin/env bash
# Finto systemctl is-active: stessi codici di quello vero.
[[ $1 == is-active ]] || exit 2
case $2 in
    sshd | crond) echo active ;;
    httpd) echo inactive; exit 3 ;;
    *) echo unknown; exit 4 ;;
esac
DATI
    chmod +x dati/bin/servizio
    cat >dati/df.txt <<'DATI'
Filesystem     1024-blocks    Used Available Capacity Mounted on
/dev/sda1         18350080 7707033  10643047      42% /
/dev/sda3          1048576   94372    954204       9% /boot
tmpfs              2097152       0   2097152       0% /run/user/1000
DATI
    truncate -s 11M "dati/grandi/cartella con spazi/grande.img"
    truncate -s 1M "dati/grandi/cartella con spazi/piccolo.img"
    truncate -s 30M "dati/grandi/cartella con spazi/sotto/enorme.img"
    echo "pagina" >"dati/da archiviare/sito web/index.html"
    printf 'INFO ok\nERROR rotto\n' >dati/log/a.log
    printf 'INFO ok\n' >dati/log/b.log
    printf 'WARN quasi\nERROR di nuovo\n' >"dati/log/c con spazi.log"
    awk 'function rnd(n) { seme = (seme * 16807) % 2147483647; return seme % n }
    BEGIN {
        seme = 4242
        split("200 200 200 200 200 301 304 404 403 500 502 503", st, " ")
        for (i = 0; i < 100000; i++) {
            ip = (rnd(3) ? "203.0.113." : "198.51.100.") (rnd(40) + 1)
            printf "%s - - [02/Nov/2026:%02d:%02d:%02d +0100] \"GET /p%d HTTP/1.1\" %s %d \"-\" \"agente\"\n", ip, int(i / 4200), rnd(60), rnd(60), rnd(50), st[rnd(12) + 1], rnd(9000)
        }
    }' >dati/grande.log
}

l20() {
    mkdir -p dati/bin
    printf '%s\n' '# macchine da controllare' alfa beta '' gamma spenta delta epsilon >dati/macchine.txt
    cat >dati/bin/controlla <<'DATI'
#!/usr/bin/env bash
# Finto controllo di una macchina: impiega un secondo e parla su entrambi i canali.
echo "controllo $1"
sleep 1
if [[ $1 == spenta ]]; then echo "$1: non risponde" >&2; exit 1; fi
echo "$1: ok"
DATI
    chmod +x dati/bin/controlla
    printf '2026-11-03 02:00:00 INFO avvio\n' >dati/app.log
}

l21() {
    mkdir -p dati/bin
    # Finto curl: capisce le opzioni più comuni e simula pochi siti immaginari.
    cat >dati/bin/curl <<'DATI'
#!/usr/bin/env bash
silenzio=0 mostra=0 fallisci=0 segui=0 testa=0 uscita=- formato= max= url=
while (($#)); do
    case $1 in
        -s | --silent) silenzio=1 ;;
        -S | --show-error) mostra=1 ;;
        -f | --fail) fallisci=1 ;;
        -L | --location) segui=1 ;;
        -I | --head) testa=1 ;;
        -sS | -Ss) silenzio=1 mostra=1 ;;
        -fsS | -sSf | -fs | -sf) silenzio=1 fallisci=1; [[ $1 == *S* ]] && mostra=1 ;;
        -sL | -Ls) silenzio=1 segui=1 ;;
        -o | --output) uscita=$2; shift ;;
        -o*) uscita=${1#-o} ;;
        -w | --write-out) formato=$2; shift ;;
        --write-out=*) formato=${1#*=} ;;
        -m | --max-time) max=$2; shift ;;
        -m*) max=${1#-m} ;;
        --max-time=*) max=${1#*=} ;;
        --connect-timeout | --retry | -A | --user-agent | -H | --header) shift ;;
        -*) ;;
        *) url=$1 ;;
    esac
    shift
done
errore() { if ((!silenzio || mostra)); then echo "curl: ($1) $2" >&2; fi; }
scrivi() {
    local f=${formato//'%{http_code}'/$1}
    f=${f//'%{response_code}'/$1}
    f=${f//'%{time_total}'/$2}
    printf '%b' "$f"
}
host=${url#*://}; host=${host%%/*}; percorso=/${url#*://*/}; [[ $url == *://*/* ]] || percorso=/
case $host in
    giu) errore 7 "Failed to connect to giu port 80: Connection refused"; scrivi 000 0.001000; exit 7 ;;
    lento)
        if [[ -n $max ]] && ((${max%%.*} < 30)); then
            sleep "$max"; errore 28 "Operation timed out after ${max} seconds with 0 bytes received"; scrivi 000 "$max"; exit 28
        fi
        sleep 30; exit 0 ;;
    sito) ;;
    *) errore 6 "Could not resolve host: $host"; scrivi 000 0.002000; exit 6 ;;
esac
case $percorso in
    /mancante) codice=404 ;;
    /errore) codice=500 ;;
    /sposta) if ((segui)); then codice=200; else codice=301; fi ;;
    *) codice=200 ;;
esac
if ((testa)); then corpo="HTTP/1.1 $codice"$'\n'; else corpo="<html>pagina $percorso</html>"$'\n'; fi
if ((fallisci && codice >= 400)); then
    errore 22 "The requested URL returned error: $codice"; scrivi "$codice" 0.031000; exit 22
fi
if [[ $uscita == - ]]; then printf '%s' "$corpo"; else printf '%s' "$corpo" >"$uscita"; fi
scrivi "$codice" 0.042517
DATI
    chmod +x dati/bin/curl
    cat >dati/ip-addr.json <<'DATI'
[{"ifindex":1,"ifname":"lo","flags":["LOOPBACK","UP","LOWER_UP"],"mtu":65536,"qdisc":"noqueue","operstate":"UNKNOWN","group":"default","txqlen":1000,"link_type":"loopback","address":"00:00:00:00:00:00","broadcast":"00:00:00:00:00:00","addr_info":[{"family":"inet","local":"127.0.0.1","prefixlen":8,"scope":"host","label":"lo","valid_life_time":4294967295,"preferred_life_time":4294967295},{"family":"inet6","local":"::1","prefixlen":128,"scope":"host","valid_life_time":4294967295,"preferred_life_time":4294967295}]},{"ifindex":2,"ifname":"enp0s3","flags":["BROADCAST","MULTICAST","UP","LOWER_UP"],"mtu":1500,"qdisc":"fq_codel","operstate":"UP","group":"default","txqlen":1000,"link_type":"ether","address":"08:00:27:3a:1b:2c","broadcast":"ff:ff:ff:ff:ff:ff","addr_info":[{"family":"inet","local":"10.0.2.15","prefixlen":24,"broadcast":"10.0.2.255","scope":"global","dynamic":true,"noprefixroute":true,"label":"enp0s3","valid_life_time":86313,"preferred_life_time":86313},{"family":"inet6","local":"fe80::a00:27ff:fe3a:1b2c","prefixlen":64,"scope":"link","noprefixroute":true,"valid_life_time":4294967295,"preferred_life_time":4294967295}]},{"ifindex":3,"ifname":"enp0s8","flags":["BROADCAST","MULTICAST","UP","LOWER_UP"],"mtu":1500,"qdisc":"fq_codel","operstate":"UP","group":"default","txqlen":1000,"link_type":"ether","address":"08:00:27:4d:5e:6f","broadcast":"ff:ff:ff:ff:ff:ff","addr_info":[{"family":"inet","local":"192.168.56.10","prefixlen":24,"broadcast":"192.168.56.255","scope":"global","noprefixroute":true,"label":"enp0s8","valid_life_time":4294967295,"preferred_life_time":4294967295},{"family":"inet","local":"192.168.56.11","prefixlen":24,"broadcast":"192.168.56.255","scope":"global","secondary":true,"label":"enp0s8","valid_life_time":4294967295,"preferred_life_time":4294967295}]},{"ifindex":4,"ifname":"docker0","flags":["NO-CARRIER","BROADCAST","MULTICAST","UP"],"mtu":1500,"qdisc":"noqueue","operstate":"DOWN","group":"default","link_type":"ether","address":"02:42:ac:11:00:01","broadcast":"ff:ff:ff:ff:ff:ff","addr_info":[{"family":"inet","local":"172.17.0.1","prefixlen":16,"broadcast":"172.17.255.255","scope":"global","label":"docker0","valid_life_time":4294967295,"preferred_life_time":4294967295}]},{"ifindex":5,"ifname":"wg0","flags":["POINTOPOINT","NOARP","UP","LOWER_UP"],"mtu":1420,"qdisc":"noqueue","operstate":"UNKNOWN","group":"default","txqlen":1000,"link_type":"none","addr_info":[{"family":"inet6","local":"fd00::2","prefixlen":64,"scope":"global","valid_life_time":4294967295,"preferred_life_time":4294967295}]}]
DATI
}

l22() {
    mkdir -p dati/bin dati/home/mario dati/home/anna dati/albero/doc "dati/albero/foto vecchie" dati/albero/.config
    scrivi_passwd dati/passwd
    head -c 20000 /dev/zero >dati/home/mario/dati.bin
    cat >dati/spazio-home.sh <<'DATI'
#!/usr/bin/env bash
# Pensato per sudo: mostra quanto occupa la home di un utente.
# Da leggere, non da eseguire: ha difetti voluti.
BASE=${BASE:-/home}
eval "spazio=\$(du -sk $BASE/$1 | cut -f1)"
echo "$1: $spazio KB"
DATI
    cat >dati/bin/dbclient <<'DATI'
#!/usr/bin/env bash
# Finto client di database. Registra in DBLOG argomenti e ambiente.
attesa=$(head -n 1 "${FINTO_ATTESO_FILE:-$(dirname "$0")/../atteso.txt}" 2>/dev/null)
{ printf 'argomenti:'; printf ' [%s]' "$@"; echo; echo "ambiente:"; env; } >>"${DBLOG:-/dev/null}"
utente= pw= stdin=0
while (($# > 1)); do
    case $1 in
        -u) utente=$2; shift ;;
        -p) pw=$2; shift ;;
        --password-stdin) stdin=1 ;;
    esac
    shift
done
((stdin)) && IFS= read -r pw
[[ -z $pw && -n ${DBPASS:-} ]] && pw=$DBPASS
if [[ $pw != "$attesa" ]]; then echo "dbclient: accesso negato per $utente" >&2; exit 5; fi
echo "risultato di: $1"
DATI
    chmod +x dati/bin/dbclient
    printf '%s\n' 'S3gr3t0 con spazi & $imboli!' >dati/atteso.txt
    touch dati/albero/doc/relazione.PDF dati/albero/doc/note.txt dati/albero/doc/README \
        "dati/albero/foto vecchie/mare 1.jpg" "dati/albero/foto vecchie/mare 2.JPG" \
        dati/albero/archivio.tar.gz dati/albero/.config/.bashrc dati/albero/script.sh dati/albero/altro.sh
    cat >dati/conta-estensioni.sh <<'DATI'
#!/usr/bin/env bash
# Conta i file per estensione, dal più frequente.
declare -A n
while IFS= read -r -d '' f; do
    b=${f##*/}
    if [[ $b == *.* && $b != .* ]]; then e=${b##*.}; e=${e,,}; else e=senza; fi
    n[$e]=$(( ${n[$e]:-0} + 1 ))
done < <(find "${1:-.}" -type f -print0)
for e in "${!n[@]}"; do printf '%s %s\n' "${n[$e]}" "$e"; done | LC_ALL=C sort -k1,1nr -k2,2
DATI
    chmod +x dati/conta-estensioni.sh
}

l23() {
    mkdir -p dati/backup dati/backup-vuoto "dati/altra cartella"
    touch dati/backup/web_20261101-020000.tar.gz dati/backup/web_20261102-020000.tar.gz \
        dati/backup/web2_20261102-020000.tar.gz dati/backup/db_20261102-023000.sql.gz dati/backup/leggimi.txt
}

l24() {
    mkdir -p dati/bin dati/pacchetti
    # Tre pacchetti da rilasciare: il terzo ha un controllo che fallisce.
    local v d
    for v in 1 2 3 4; do
        d=$(mktemp -d)
        echo "versione $v" >"$d/index.html"
        if [[ $v == 3 ]]; then printf '#!/bin/sh\necho "manca la configurazione" >&2\nexit 1\n' >"$d/controllo.sh"; fi
        if [[ $v == 2 ]]; then printf '#!/bin/sh\ntest -f index.html\n' >"$d/controllo.sh"; fi
        [[ -e $d/controllo.sh ]] && chmod +x "$d/controllo.sh"
        tar -czf "dati/pacchetti/sito-$v.tar.gz" -C "$d" .
        rm -rf "$d"
    done
    # Comandi di sistema finti: lavorano sotto la RADICE data con -R, --root o --installroot.
    cat >dati/bin/_finti <<'DATI'
# Funzioni comuni dei comandi finti.
radice() {
    R= ARGS=()
    while (($#)); do
        case $1 in
            -R | --root | --installroot) R=$2; shift ;;
            --installroot=* | --root=*) R=${1#*=} ;;
            *) ARGS+=("$1") ;;
        esac
        shift
    done
    [[ -d $R/etc ]] || { echo "$NOME: radice non valida: '$R'" >&2; exit 2; }
}
registra() { printf '%s' "$NOME" >>"$R/comandi.log"; printf ' [%s]' "$@" >>"$R/comandi.log"; echo >>"$R/comandi.log"; }
DATI
    cat >dati/bin/groupadd <<'DATI'
#!/usr/bin/env bash
NOME=groupadd; source "$(dirname "$0")/_finti"; radice "$@"; registra "${ARGS[@]}"
g=${ARGS[-1]}
grep -q "^$g:" "$R/etc/group" && { echo "groupadd: group '$g' already exists" >&2; exit 9; }
echo "$g:x:$((2000 + $(wc -l <"$R/etc/group"))):" >>"$R/etc/group"
DATI
    cat >dati/bin/useradd <<'DATI'
#!/usr/bin/env bash
NOME=useradd; source "$(dirname "$0")/_finti"; radice "$@"; registra "${ARGS[@]}"
u=${ARGS[-1]} g=
for ((i = 0; i < ${#ARGS[@]}; i++)); do [[ ${ARGS[i]} == -g ]] && g=${ARGS[i + 1]}; done
gid=$(awk -F: -v g="$g" '$1 == g { print $3 }' "$R/etc/group")
[[ -n $gid ]] || { echo "useradd: group '$g' does not exist" >&2; exit 6; }
grep -q "^$u:" "$R/etc/passwd" && { echo "useradd: user '$u' already exists" >&2; exit 9; }
echo "$u:x:$((3000 + $(wc -l <"$R/etc/passwd"))):$gid::/home/$u:/bin/bash" >>"$R/etc/passwd"
mkdir -p "$R/home/$u"
DATI
    cat >dati/bin/usermod <<'DATI'
#!/usr/bin/env bash
NOME=usermod; source "$(dirname "$0")/_finti"; radice "$@"; registra "${ARGS[@]}"
u=${ARGS[-1]} g=
for ((i = 0; i < ${#ARGS[@]}; i++)); do [[ ${ARGS[i]} == -g ]] && g=${ARGS[i + 1]}; done
gid=$(awk -F: -v g="$g" '$1 == g { print $3 }' "$R/etc/group")
[[ -n $gid ]] || { echo "usermod: group '$g' does not exist" >&2; exit 6; }
grep -q "^$u:" "$R/etc/passwd" || { echo "usermod: user '$u' does not exist" >&2; exit 6; }
awk -F: -v OFS=: -v u="$u" -v gid="$gid" '$1 == u { $4 = gid } { print }' "$R/etc/passwd" >"$R/etc/passwd.nuovo" && mv "$R/etc/passwd.nuovo" "$R/etc/passwd"
DATI
    cat >dati/bin/rpm <<'DATI'
#!/usr/bin/env bash
NOME=rpm; source "$(dirname "$0")/_finti"; radice "$@"
p=${ARGS[-1]}
if grep -qx -- "$p" "$R/var/lib/pacchetti" 2>/dev/null; then echo "$p-1.0-1.el9.x86_64"; else echo "package $p is not installed"; exit 1; fi
DATI
    cat >dati/bin/dnf <<'DATI'
#!/usr/bin/env bash
NOME=dnf; source "$(dirname "$0")/_finti"; radice "$@"; registra "${ARGS[@]}"
p=${ARGS[-1]}
[[ $p == inesistente* ]] && { echo "Error: Unable to find a match: $p" >&2; exit 1; }
mkdir -p "$R/var/lib"; echo "$p" >>"$R/var/lib/pacchetti"
echo "Complete!"
DATI
    chmod +x dati/bin/groupadd dati/bin/useradd dati/bin/usermod dati/bin/rpm dati/bin/dnf
    mkdir -p dati/radice/etc dati/radice/var/lib dati/radice/home/mario
    printf 'root:x:0:0:root:/root:/bin/bash\nmario:x:1000:1000::/home/mario:/bin/bash\n' >dati/radice/etc/passwd
    printf 'root:x:0:\nmario:x:1000:\n' >dati/radice/etc/group
    printf 'bash\nvim-minimal\n' >dati/radice/var/lib/pacchetti
    printf 'Benvenuto\n' >dati/radice/etc/motd
    cat >dati/config.txt <<'DATI'
# stato voluto del laboratorio
gruppo sviluppo
gruppo mario
utente luca sviluppo
utente mario sviluppo
pacchetto vim-minimal
pacchetto git
riga etc/motd Benvenuto  in lab
riga etc/ssh/sshd_config.d/50-lab.conf PermitRootLogin no
cartella srv/progetti 2775
DATI
}

# Allenamenti: le aree a1-a8 non hanno dati propri, salvo qualche file d'esempio.
lkata() {
    printf 'Gli esercizi di questa area sono in studio/lezioni/scripting/allenamenti.md.\n' >dati/LEGGIMI
}
la1() { lkata; }
la2() { lkata; }
la3() { lkata; }
la4() { lkata; scrivi_passwd dati/passwd; }
la5() { lkata; }
la6() { lkata; }
la7() { lkata; }
la8() { lkata; }

prepara() {
    local n=$1 cartella=$PALESTRA/l$1
    # Gli allenamenti (a1-a8) stanno in palestra/aN, le lezioni in palestra/lNN.
    [[ $n == a* ]] && cartella=$PALESTRA/$n
    if ! declare -F "l$n" >/dev/null; then
        echo "Lezione sconosciuta: $n (valide: ${LEZIONI[*]})" >&2
        return 2
    fi
    mkdir -p "$cartella"
    if [[ -d $cartella/dati ]]; then
        chmod -R u+rwx "$cartella/dati"
        rm -rf "$cartella/dati"
    fi
    mkdir "$cartella/dati"
    (cd "$cartella" && "l$n")
    echo "Pronta: $cartella"
}

case ${1:-} in
    "" | -h | --help)
        echo "Uso: $0 NN|tutte   (lezioni: ${LEZIONI[*]})" >&2
        [[ -n ${1:-} ]]
        ;;
    tutte)
        for n in "${LEZIONI[@]}"; do prepara "$n"; done
        ;;
    *)
        prepara "$1"
        ;;
esac
