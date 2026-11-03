#!/usr/bin/env bash
# Prepara la palestra di una lezione di scripting: crea palestra/lNN/dati/ con
# dati finti ma realistici e, dove serve, gli script rotti da riparare.
#
#   ./prepara.sh 04        prepara la lezione 04
#   ./prepara.sh tutte     prepara tutte le lezioni
#
# Rilanciarlo rigenera dati/ da zero, ma non tocca mai i tuoi script.
# Gira su Linux con i soli pacchetti di "base" (bash, coreutils, gawk, tar, gzip).
set -euo pipefail

RADICE=$(cd "$(dirname "$0")" && pwd)
PALESTRA=${PALESTRA:-$RADICE/palestra}
LEZIONI=(01 02 03 04 05 06 07 08 09 10 11)

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
bin:x:1:1:bin:/:/usr/bin/nologin
daemon:x:2:2:daemon:/:/usr/bin/nologin
nobody:x:65534:65534:Kernel Overflow User:/:/usr/bin/nologin
sshd:x:74:74:OpenSSH:/var/empty:/usr/bin/nologin
mario:x:1000:1000:Mario Rossi:/home/mario:/bin/bash
marta:x:1001:1001:Marta:/home/marta:/bin/zsh
zeno:x:1002:1002::/home/zeno:/bin/bash
anna:x:1003:1003:Anna Bianchi,Stanza 4:/home/anna:/bin/bash
backup:x:1004:1004:Utente tecnico:/srv/backup:/usr/bin/nologin
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
teo;ops;/usr/bin/nologin;31-12-2027
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

prepara() {
    local n=$1 cartella=$PALESTRA/l$1
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
