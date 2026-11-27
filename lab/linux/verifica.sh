#!/usr/bin/env bash
# Correttore delle lezioni Linux. Guarda lo stato della macchina, non l'output dei tuoi
# comandi: tabelle delle partizioni (sfdisk -J), vista del kernel (/sys, lsblk -J),
# firme (blkid -p), montaggi (findmnt -J), servizi (systemctl show).
#
#   sudo ./verifica.sh NN [P]        il problema P della lezione NN (quello preparato se manca)
#   sudo ./verifica.sh NN pulizia    i bersagli sono tornati puliti
#   sudo ./verifica.sh stato         gli esiti registrati finora
#
# Codici: 0 tutto passa, 1 qualcosa non passa, 2 uso o scenario non preparato,
# 3 rifiuto (dispositivo o ambiente non previsto), 4 serve root.
# Prima di guardare qualsiasi cosa controlla, con la stessa guardia di prepara.sh, che i
# bersagli siano quelli dell'inventario: altrimenti si rifiuta con codice 3.
# Le funzioni p_NN_P si chiamano per nome, quindi shellcheck le crede irraggiungibili.
# shellcheck disable=SC2317
set -u

RADICE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=SCRIPTDIR/lib/comune.sh
source "$RADICE/lib/comune.sh"
# shellcheck source=SCRIPTDIR/lib/dati.sh
source "$RADICE/lib/dati.sh"
PALESTRA=${PALESTRA:-$RADICE/palestra}
LEZIONI=(01 02 03 04 05 06 07 08 09 10 11)
GUID_LINUX=0FC63DAF-8483-4772-8E79-3D69D8477DE4
PASSATE=0
FALLITE=0
export LC_ALL=C

# ---- Strumenti di prova ----------------------------------------------------------

passa() { PASSATE=$((PASSATE + 1)); printf '  ok    %s\n' "$1"; }
boccia() {
    FALLITE=$((FALLITE + 1))
    printf '  NO    %s\n' "$1"
    shift
    local r
    for r in "$@"; do printf '        %s\n' "$r"; done
}

# vero DESCRIZIONE COMANDO...
vero() {
    local d=$1
    shift
    if "$@" >/dev/null 2>&1; then passa "$d"; else boccia "$d"; fi
}

# uguale DESCRIZIONE ATTESO OTTENUTO
uguale() {
    if [[ $2 == "$3" ]]; then passa "$1"; else boccia "$1" "atteso:   $2" "ottenuto: ${3:-(niente)}"; fi
}

atteso() { sed -n "s/^$1=//p" "$STATO/atteso" 2>/dev/null | head -1; }

# Tabella delle partizioni scritta sul disco, in JSON; niente se non c'è.
tab() { sfdisk -J "$1" 2>/dev/null; }
jt() { local d=$1; shift; tab "$d" | jq -r "$@" 2>/dev/null; }
# Partizione numero N della tabella su disco, come oggetto JSON.
jpart() { tab "$1" | jq -c --arg n "$2" '.partitiontable.partitions[] | select(.node | test("[^0-9]" + $n + "$"))' 2>/dev/null; }
campo() { jq -r ".$2 // empty" <<<"$1"; }
# Firma letta direttamente dal dispositivo, senza la cache di blkid.
firma() { blkid -p -o export "$1" 2>/dev/null | sed -n "s/^$2=//p"; }
# Inizio e dimensione di una partizione come li vede il kernel.
vista_kernel() { [[ -n $1 ]] && echo "$(cat "/sys/class/block/${1##*/}/start") $(cat "/sys/class/block/${1##*/}/size")"; }
settori() { echo $(($(byte_di "$1") / 512)); }
sorgente_di() { findmnt -J -n -o SOURCE "$1" 2>/dev/null | jq -r '.filesystems[0].source // empty'; }
dim_fs() { findmnt -J -b -o SIZE "$1" 2>/dev/null | jq -r '.filesystems[0].size // 0'; }

# montato_da DESCRIZIONE PUNTO DISPOSITIVO: PUNTO è montato da DISPOSITIVO, che deve esistere.
montato_da() {
    if [[ -z $3 ]]; then
        boccia "$1" "il dispositivo che dovrebbe essere montato non c'è (filesystem o volume mancante, o non attivo)"
        return
    fi
    uguale "$1" "$3" "$(sorgente_di "$2")"
}

servizio_intatto() { # NOME: attivo e con lo stesso processo di quando è stato preparato
    [[ $(systemctl is-active "lab-occupa-$1") == active ]] &&
        [[ $(systemctl show -p MainPID --value "lab-occupa-$1") == "$(atteso "PID_$1")" ]]
}

disco() {
    local p
    p=$(percorso_bersaglio "$1")
    [[ -n $p ]] || { echo "Il bersaglio $1 non è collegato." >&2; exit 2; }
    echo "$p"
}

# ---- fstab, systemd e swap -----------------------------------------------------------

righe_fstab() { grep -Ev '^[[:space:]]*(#|$)' /etc/fstab; }
fstab_per_punto() { righe_fstab | awk -v t="$1" '$2 == t || $2 == t "/"'; }
conta() { grep -c . <<<"$1"; }

# Dove porta il primo campo di una riga di fstab: un dispositivo, o un file.
sorgente_reale() {
    local v=${1//\"/}
    case $v in
        UUID=* | LABEL=* | PARTUUID=* | PARTLABEL=*) blkid -c /dev/null -l -o device -t "$v" 2>/dev/null ;;
        *) realpath -q -- "$v" 2>/dev/null || echo "$v" ;;
    esac
}

# Righe di swap di fstab che portano a DEV (dispositivo o file).
fstab_swap_per() {
    local r
    righe_fstab | awk '$3 == "swap"' | while read -r r; do
        [[ $(sorgente_reale "${r%%[[:space:]]*}") == "$1" ]] && echo "$r"
    done
}

# Un identificatore che sta scritto sul disco stesso, e non dipende dall'ordine dei dischi.
stabile() {
    case ${1//\"/} in
        UUID=* | LABEL=* | PARTUUID=* | PARTLABEL=* | /dev/disk/by-uuid/* | /dev/disk/by-label/* | /dev/disk/by-partuuid/* | /dev/disk/by-partlabel/*) return 0 ;;
    esac
    return 1
}

ha_opzione() { tr ',' '\n' <<<"$1" | grep -qxF -- "$2"; }
opzioni_attive() { findmnt -n -o OPTIONS "$1" 2>/dev/null; }
# findmnt non legge da una pipe: la riga va in un file temporaneo.
verifica_riga() {
    local f rc
    f=$(mktemp)
    printf '%s\n' "$1" >"$f"
    findmnt --verify --tab-file "$f" >/dev/null 2>&1
    rc=$?
    rm -f "$f"
    return "$rc"
}
# Dopo ogni modifica di fstab systemd segna le sue unità come da ricaricare: quella di /
# nasce sempre da fstab, quindi dice se systemd ha riletto il file.
systemd_aggiornato() { [[ $(systemctl show -p NeedDaemonReload --value -- -.mount) == no ]]; }
dalla_fstab() { [[ $(systemctl show -p SourcePath --value -- "$1") == /etc/fstab ]]; }
unita() { systemd-escape -p --suffix="$2" "$1"; }
# Tipo e priorità di una swap attiva, da /proc/swaps.
swap_attiva() { awk -v d="$1" 'NR > 1 && $1 == d { print $2, $5 }' /proc/swaps; }
# Una durata di systemd (10s, 1min 30s, infinity) in secondi interi; niente se infinita.
secondi() { systemd-analyze timespan "$1" 2>/dev/null | awk -F': *' 'NF == 2 && $2 ~ /^[0-9]+$/ { print int($2 / 1000000) }'; }
entro_10() { [[ -n $1 ]] && (($1 >= 1 && $1 <= 10)); }

# campi_fstab RIGA: mette in F1-F4 i primi quattro campi.
campi_fstab() { read -r F1 _ F3 F4 _ <<<"$1"; F1=${F1//\"/}; }
# La sorgente cerca il filesystem per UUID: UUID=… o /dev/disk/by-uuid/… (M3).
per_uuid() { [[ ${1,,} == "uuid=${2,,}" || $1 == "/dev/disk/by-uuid/$2" ]]; }
ha_opzioni() { ha_opzione "$1" "$2" && ha_opzione "$1" "$3"; }
crea_con_file() { runuser -u "$1" -- mkdir "$2" && runuser -u "$1" -- touch "$2/dentro"; }
non_cancella() { ! runuser -u "$1" -- rm -f "$2" 2>/dev/null && test -e "$2"; }
non_rinomina() { ! runuser -u "$1" -- mv "$2" "$2.x" 2>/dev/null && test -e "$2"; }
non_elenca() { ! runuser -u "$1" -- ls "$2" >/dev/null 2>&1; }

# ---- LVM: report in JSON, come li vede il sistema (file dei dispositivi compreso) -------

vg_campo() { vgs --reportformat json --units b --nosuffix -o "$2" "$1" 2>/dev/null | jq -r ".report[0].vg[0].$2 // empty"; }
lv_campo() { lvs --reportformat json --units b --nosuffix -o "$2" "$1" 2>/dev/null | jq -r ".report[0].lv[0].$2 // empty"; }
pv_del_vg() { pvs --reportformat json -o pv_name -S "vg_name=$1" 2>/dev/null | jq -r '.report[0].pv[]?.pv_name' | sort | paste -sd' ' -; }
pv_campo() { pvs --reportformat json -o "$2" "$1" 2>/dev/null | jq -r ".report[0].pv[0].$2 // empty"; }
# I PV su cui stanno i segmenti di un LV.
lv_dispositivi() { lvs --reportformat json -o devices "$1" 2>/dev/null | jq -r '.report[0].lv[]?.devices' | tr ',' '\n' | sed 's/(.*//' | sort -u | paste -sd' ' -; }
elenco() { printf '%s\n' "$@" | sort | paste -sd' ' -; }
# Per un LV vanno bene anche i suoi nomi: VG e LV non dipendono dall'ordine dei dischi.
stabile_lv() { stabile "$1" || [[ ${1//\"/} == "/dev/mapper/$2-$3" || ${1//\"/} == "/dev/$2/$3" ]]; }
stessa_destinazione() { [[ -n $1 && $(realpath -q -- "$1") == $(realpath -q -- "$2") ]]; }
ha_tutti_i_file() { # CARTELLA MANIFEST QUANTI: gli stessi file, né uno in più né uno in meno
    controlla_manifest "$1" "$2" && [[ $(find "$1" -type f ! -path '*/lost+found/*' | wc -l) == "$3" ]]
}

# I controlli comuni a un volume XFS montato da fstab su PUNTO.
montato_da_fstab() { # PUNTO VG LV
    local lvp righe
    lvp=$(lv_campo "$2/$3" lv_dm_path)
    montato_da "$1 è montato da $3" "$1" "$lvp"
    righe=$(fstab_per_punto "$1")
    uguale "in /etc/fstab c'è una sola riga per $1" 1 "$(conta "$righe")"
    campi_fstab "$(head -1 <<<"$righe")"
    vero "la riga trova il volume per UUID, etichetta o nome del LV (ora: ${F1:-niente})" stabile_lv "$F1" "$2" "$3"
    vero "e porta proprio a $3" stessa_destinazione "$(sorgente_reale "$F1")" "$lvp"
    vero "findmnt --verify la trova corretta" verifica_riga "$(head -1 <<<"$righe")"
    vero "systemd ha riletto /etc/fstab" systemd_aggiornato
    vero "e l'unità di $1 nasce da /etc/fstab" dalla_fstab "$(unita "$1" mount)"
}

# ---- Lezione 01 --------------------------------------------------------------------

p_01_1() {
    local n c p
    n=$(disco "$(atteso NUOVO)")
    c=$(disco "$(atteso COLLEGA)")
    echo "  disco del database: $n ($(seriale_di "$n")), disco del collega: $c"
    uguale "il disco del database ha una tabella GPT" gpt "$(jt "$n" .partitiontable.label)"
    uguale "con una sola partizione" 1 "$(jt "$n" '.partitiontable.partitions | length')"
    p=$(jpart "$n" 1)
    uguale "che inizia a 1 MiB (settore 2048)" 2048 "$(campo "$p" start)"
    uguale "ed è da 1 GiB esatto (2097152 settori)" 2097152 "$(campo "$p" size)"
    uguale "con il nome dati-db" dati-db "$(campo "$p" name)"
    uguale "e il tipo Linux filesystem" "$GUID_LINUX" "$(campo "$p" type)"
    uguale "il kernel la vede con gli stessi settori" "2048 2097152" "$(vista_kernel "$(parte "$n" 1)")"
    # Il ticket: «Niente filesystem: lo creo io».
    uguale "e sopra non c'è un filesystem (lo crea Sara)" "" "$(firma "$(parte "$n" 1)" TYPE)"
    uguale "il disco del collega ha ancora il suo ext4" "ext4 collega 2f1c9e4a-6b3d-4f8e-9a71-0c5d2e8b4a13" \
        "$(firma "$c" TYPE) $(firma "$c" LABEL) $(firma "$c" UUID)"
    vero "e nessuna tabella delle partizioni" test -z "$(tab "$c")"
    vero "il suo filesystem è integro (e2fsck -fn)" e2fsck -fn "$c"
    uguale "il suo LEGGIMI.txt è intatto" "Disco di Sara per il nuovo monitoraggio. Non formattare." \
        "$(debugfs -R 'cat /LEGGIMI.txt' "$c" 2>/dev/null)"
}

p_01_2() {
    local d p n t ultimo
    d=$(disco D1)
    ultimo=$(($(settori "$d") - 1))
    uguale "la tabella è MBR (dos)" dos "$(jt "$d" .partitiontable.label)"
    uguale "con sei partizioni" 6 "$(jt "$d" '.partitiontable.partitions | length')"
    local -A dim=([1]=524288 [2]=524288 [3]=1048576 [5]=524288 [6]=524288)
    local -A tipo=([1]=83 [2]=82 [3]=83 [5]=8e [6]=83)
    for n in 1 2 3 5 6; do
        p=$(jpart "$d" "$n")
        uguale "la $n è da $((dim[$n] / 2048)) MiB" "${dim[$n]}" "$(campo "$p" size)"
        uguale "la $n ha tipo ${tipo[$n]}" "${tipo[$n]}" "$(campo "$p" type)"
    done
    uguale "la 1 inizia a 1 MiB" 2048 "$(campo "$(jpart "$d" 1)" start)"
    uguale "solo la 1 è avviabile" 1 "$(jt "$d" '[.partitiontable.partitions[] | select(.bootable == true)] | length')"
    uguale "la 1 è quella avviabile" true "$(campo "$(jpart "$d" 1)" bootable)"
    t=$(campo "$(jpart "$d" 4)" type)
    vero "la 4 è una partizione estesa (tipo 5, f o 85)" grep -qxE '5|f|85' <<<"$t"
    p=$(jpart "$d" 4)
    local s4 e4
    s4=$(campo "$p" start)
    e4=$((s4 + $(campo "$p" size) - 1))
    vero "la 4 arriva alla fine del disco" test "$e4" -ge $((ultimo - 2048))
    vero "le partizioni sono nell'ordine richiesto" test "$(jt "$d" '[.partitiontable.partitions[] | select(.node | test("[1-3]$")) | .start] | . == sort')" = true
    local ok=0 s
    for n in 5 6; do
        s=$(campo "$(jpart "$d" "$n")" start)
        [[ -n $s ]] && ((s > s4 && s + ${dim[$n]} - 1 <= e4)) && ok=$((ok + 1))
    done
    uguale "la 5 e la 6 stanno dentro la 4" 2 "$ok"
    local kernel=0
    for n in 1 2 3 5 6; do
        p=$(jpart "$d" "$n")
        [[ $(vista_kernel "$(parte "$d" "$n")") == "$(campo "$p" start) $(campo "$p" size)" ]] && kernel=$((kernel + 1))
    done
    uguale "il kernel vede le cinque partizioni con i dati, come sul disco" 5 "$kernel"
}

p_01_3() {
    local d p1 p2
    d=$(disco D2)
    uguale "il disco ha ancora il suo GUID" 6E1A0B2C-3D4E-4F50-8A61-72839405A6B7 "$(jt "$d" .partitiontable.id)"
    p1=$(jpart "$d" 1)
    uguale "la partizione 1 non è cambiata" "2048 1048576 9B2C4D6E-8F01-4A23-B456-789ABCDEF012 archivio" \
        "$(campo "$p1" start) $(campo "$p1" size) $(campo "$p1" uuid) $(campo "$p1" name)"
    uguale "ci sono due partizioni" 2 "$(jt "$d" '.partitiontable.partitions | length')"
    p2=$(jpart "$d" 2)
    uguale "la 2 inizia subito dopo la 1, al MiB" 1050624 "$(campo "$p2" start)"
    uguale "ed è da 1 GiB esatto" 2097152 "$(campo "$p2" size)"
    uguale "con il nome indici e il tipo Linux filesystem" "indici $GUID_LINUX" "$(campo "$p2" name) $(campo "$p2" type)"
    uguale "il kernel vede la 2, come sul disco" "1050624 2097152" "$(vista_kernel "$(parte "$d" 2)")"
    montato_da "/srv/archivio è montato dalla partizione 1" /srv/archivio "$(parte "$d" 1)"
    vero "il servizio non si è mai fermato (stesso processo)" servizio_intatto archivio
    vero "i dati dell'archivio sono intatti" controlla_manifest /srv/archivio "$STATO/l01/p3.manifest"
}

# ---- Lezione 01, problema 4: lo script si prova solo su loop, in una gabbia --------

PROVA_IMG=$STATO/prova

nuovo_loop() { # NOME MIB → percorso del loop
    mkdir -p "$PROVA_IMG"
    rm -f "$PROVA_IMG/$1.img"
    truncate -s "$2M" "$PROVA_IMG/$1.img"
    losetup -f --show -P "$PROVA_IMG/$1.img"
}
# nuovo_loop gira dentro $( ): i loop da liberare si ritrovano dalle loro immagini, anche
# da quelle di una prova interrotta, che risultano cancellate.
libera_loop() {
    local l p
    for l in $(losetup -nO NAME,BACK-FILE | awk -v d="$PROVA_IMG/" 'index($2, d) == 1 { print $1 }'); do
        for p in $(lsblk -nrpo NAME "$l"); do
            if findmnt -rn -S "$p" >/dev/null 2>&1; then umount "$p"; fi
            swapoff "$p" 2>/dev/null
        done
        losetup -d "$l" 2>/dev/null
    done
    rm -rf "$PROVA_IMG"
}

# gabbia DISPOSITIVI... -- COMANDO...: COMANDO gira in uno spazio dei montaggi privato,
# con un /dev che contiene solo i dispositivi indicati e le loro partizioni. Un argomento
# ALTRO=DISPOSITIVO aggiunge anche /dev/ALTRO, un secondo nome per lo stesso dispositivo.
gabbia() {
    local nodi=() d x
    while [[ $1 != -- ]]; do
        if [[ $1 == /dev/*=/dev/* ]]; then
            x=${1#*=}
            nodi+=("${1%%=*}:$(cat "/sys/class/block/${x##*/}/dev")")
        else
            for x in $(lsblk -nrpo NAME "$1"); do nodi+=("$x:$(cat "/sys/class/block/${x##*/}/dev")"); done
        fi
        shift
    done
    shift
    # shellcheck disable=SC2016 # lo script fra apici gira nella gabbia, con i suoi argomenti
    timeout 120 unshare --mount --propagation private -- bash -c '
        nodi=$1; shift
        mount -t tmpfs -o mode=755,size=1m gabbia /dev || exit 97
        mknod -m 666 /dev/null c 1 3; mknod -m 666 /dev/zero c 1 5
        mknod -m 666 /dev/random c 1 8; mknod -m 666 /dev/urandom c 1 9
        ln -s /proc/self/fd /dev/fd; ln -s /proc/self/fd/0 /dev/stdin
        ln -s /proc/self/fd/1 /dev/stdout; ln -s /proc/self/fd/2 /dev/stderr
        for n in $nodi; do
            p=${n%%:*} mm=${n#*:}
            mknod -m 660 "$p" b "${mm%%:*}" "${mm#*:}"
        done
        exec "$@"' gabbia "${nodi[*]}" "$@" </dev/null
}

# prova_script DESCRIZIONE CODICE_ATTESO DISPOSITIVI_DELLA_GABBIA -- ARGOMENTI...
prova_script() {
    local d=$1 a=$2 dev=() err
    shift 2
    while [[ $1 != -- ]]; do dev+=("$1"); shift; done
    shift
    err=$(gabbia "${dev[@]}" -- "$X" "$@" 2>&1 >/dev/null)
    RC=$?
    if ((RC == a)); then passa "$d"; else boccia "$d" "codice atteso $a, ottenuto $RC" "stderr: ${err:-(vuoto)}"; fi
}

geometria() { jt "$1" -c '[.partitiontable.partitions[] | [.start, .size, .type, (.name // ""), (.attrs // ""), (.bootable // false)]]'; }
identita() { jt "$1" -c '[.partitiontable.id] + [.partitiontable.partitions[] | (.uuid // empty)]'; }

p_01_4() {
    X=$PALESTRA/l01/clona-schema.sh
    [[ -f $X ]] || { boccia "clona-schema.sh esiste" "manca $X"; return; }
    [[ -x $X ]] || { boccia "clona-schema.sh è eseguibile" "il file c'è ma non ha il permesso di esecuzione"; return; }
    local s d m
    trap libera_loop RETURN

    s=$(nuovo_loop gpt 512)
    sfdisk -q "$s" <<EOF
label: gpt
start=2048, size=204800, type=$GUID_LINUX, name="sistema", attrs="LegacyBIOSBootable"
start=206848, size=409600, type=0657FD6D-A4AB-43C4-84E5-0933C84B4F4F, name="swap"
start=616448, size=204800, type=E6D6D379-F507-44C2-A23C-238F2A3DF928, name="dati"
EOF
    d=$(nuovo_loop grande 1024)
    prova_script "GPT su un disco vuoto più grande: riesce" 0 "$s" "$d" -- "$s" "$d"
    uguale "stesse partizioni: inizio, dimensione, tipo, nome, flag" "$(geometria "$s")" "$(geometria "$d")"
    local is id
    is=$(identita "$s")
    id=$(identita "$d")
    vero "GUID del disco nuovo" test "$(jq -r '.[0]' <<<"$is")" != "$(jq -r '.[0]' <<<"$id")"
    vero "nessun GUID di partizione in comune con la sorgente" test "$(jq -n --argjson a "$is" --argjson b "$id" '$a - ($a - $b) | length')" = 0
    vero "GUID tutti diversi fra loro" test "$(jq 'length == (unique | length)' <<<"$id")" = true
    # sfdisk lascia in fondo solo la GPT di riserva (33 settori); sgdisk tiene una riserva pari
    # a quella iniziale (2048). Una copia dell'intestazione della sorgente si ferma a metà disco.
    vero "l'area utilizzabile arriva alla fine del disco più grande (ultimo settore utile: $(jt "$d" .partitiontable.lastlba))" \
        test "$(jt "$d" .partitiontable.lastlba)" -ge $(($(settori "$d") - 34 - 2048))

    s=$(nuovo_loop mbr 512)
    sfdisk -q "$s" <<EOF
label: dos
start=2048, size=131072, type=83, bootable
start=133120, type=5
start=135168, size=131072, type=8e
start=268288, size=131072, type=83
EOF
    d=$(nuovo_loop mbr-dest 512)
    prova_script "MBR con estesa e logiche: riesce" 0 "$s" "$d" -- "$s" "$d"
    uguale "stesse partizioni MBR, con il flag di avvio" "$(geometria "$s")" "$(geometria "$d")"
    vero "identificativo MBR nuovo" test "$(jt "$s" .partitiontable.id)" != "$(jt "$d" .partitiontable.id)"

    s=$(nuovo_loop gpt2 512)
    sfdisk -q "$s" <<EOF
label: gpt
start=2048, size=819200, type=$GUID_LINUX, name="tutto"
EOF
    d=$(nuovo_loop con-ext4 512)
    mkfs.ext4 -q -F -U 0e0e0e0e-1111-4222-8333-444444444444 "$d"
    prova_script "destinazione con un filesystem: rifiuta con 3" 3 "$s" "$d" -- "$s" "$d"
    uguale "e il filesystem è ancora lì" "ext4 0e0e0e0e-1111-4222-8333-444444444444" "$(firma "$d" TYPE) $(firma "$d" UUID)"
    d=$(nuovo_loop con-tabella 512)
    sfdisk -q "$d" <<<'label: gpt'
    local prima
    prima=$(jt "$d" .partitiontable.id)
    prova_script "destinazione con una tabella: rifiuta con 3" 3 "$s" "$d" -- "$s" "$d"
    uguale "e la tabella non è cambiata" "$prima" "$(jt "$d" .partitiontable.id)"
    d=$(nuovo_loop montata 512)
    sfdisk -q "$d" <<<"label: gpt
start=2048, size=204800, type=$GUID_LINUX"
    udevadm settle
    mkfs.ext4 -q -F "${d}p1"
    m=$PROVA/montata
    mkdir -p "$m"
    mount "${d}p1" "$m"
    prova_script "destinazione con una partizione montata: rifiuta con 3" 3 "$s" "$d" -- "$s" "$d"
    umount "$m"
    # G3: ogni riga del contratto ha una prova che la distingue.
    d=$(nuovo_loop montata-intera 512)
    mkfs.ext4 -q -F "$d"
    mount "$d" "$m"
    prova_script "destinazione montata, senza tabella: rifiuta con 3" 3 "$s" "$d" -- "$s" "$d"
    umount "$m"
    d=$(nuovo_loop swap-attiva 512)
    mkswap "$d" >/dev/null
    swapon "$d"
    prova_script "destinazione usata come swap: rifiuta con 3" 3 "$s" "$d" -- "$s" "$d"
    swapoff "$d"
    d=$(nuovo_loop piccola 128)
    prova_script "destinazione troppo piccola: rifiuta con 4" 4 "$s" "$d" -- "$s" "$d"
    vero "e resta vuota" test -z "$(tab "$d")"
    # L'ultima partizione finisce a 401 MiB: con la GPT di riserva in fondo non ci sta per 33 settori.
    d=$(nuovo_loop al-limite 401)
    prova_script "destinazione grande quanto la fine dell'ultima partizione: rifiuta con 4 (manca il posto della GPT di riserva)" 4 "$s" "$d" -- "$s" "$d"
    vero "e resta vuota" test -z "$(tab "$d")"
    d=$(nuovo_loop appena-sopra 402)
    prova_script "destinazione di 1 MiB più grande: riesce" 0 "$s" "$d" -- "$s" "$d"

    prova_script "senza argomenti: 2" 2 "$s" --
    prova_script "con un argomento solo: 2" 2 "$s" -- "$s"
    prova_script "con tre argomenti: 2" 2 "$s" "$d" -- "$s" "$d" "$d"
    prova_script "sorgente uguale alla destinazione: 2" 2 "$s" -- "$s" "$s"
    prova_script "la sorgente anche come destinazione, con un altro nome: 2" 2 "$s" "/dev/gemello=$s" -- "$s" /dev/gemello
    # Un file usa e getta del correttore: uno script che scrive senza controllare non deve
    # poter rovinare un file del sistema (lo script gira da root, e /etc è quello vero).
    local finto=$PROVA_IMG/non-un-disco
    mkdir -p "$PROVA_IMG"
    printf 'non sono un disco\n' >"$finto"
    prova_script "destinazione che non è un dispositivo: 2" 2 "$s" -- "$s" "$finto"
    uguale "e il file è rimasto com'era" "non sono un disco" "$(head -c 100 "$finto" | tr -d '\0')"
    # Destinazione vuota anch'essa: con una piena varrebbero insieme il 2 e il 3 (M1).
    local d2
    d=$(nuovo_loop vuota 512)
    d2=$(nuovo_loop vuota2 512)
    prova_script "sorgente senza tabella: 2" 2 "$d" "$d2" -- "$d" "$d2"
    if command -v shellcheck >/dev/null; then
        local avvisi
        avvisi=$(shellcheck -f gcc "$X" 2>/dev/null | wc -l)
        ((avvisi == 0)) || printf '  nota  shellcheck ha %s osservazioni sul tuo script: leggile\n' "$avvisi"
    fi
}

# ---- Lezione 02 ----------------------------------------------------------------------

p_02_1() {
    local d p1 p2 p3 blocchi riservati
    d=$(disco D1)
    uguale "la tabella è quella preparata" "11111111-2222-4333-8444-000000000001 11111111-2222-4333-8444-000000000002 11111111-2222-4333-8444-000000000003" \
        "$(jt "$d" '[.partitiontable.partitions[].uuid] | join(" ")' | tr 'A-F' 'a-f')"
    p1=$(parte "$d" 1)
    p2=$(parte "$d" 2)
    p3=$(parte "$d" 3)
    uguale "partizione 1: XFS con etichetta APPDATI" "xfs APPDATI" "$(firma "$p1" TYPE) $(firma "$p1" LABEL)"
    uguale "partizione 2: ext4 con etichetta LOG" "ext4 LOG" "$(firma "$p2" TYPE) $(firma "$p2" LABEL)"
    blocchi=$(tune2fs -l "$p2" 2>/dev/null | sed -n 's/^Block count: *//p')
    riservati=$(tune2fs -l "$p2" 2>/dev/null | sed -n 's/^Reserved block count: *//p')
    if [[ -n $blocchi && -n $riservati ]]; then
        uguale "sulla 2 lo spazio riservato è l'1%" 1 "$(awk -v r="$riservati" -v b="$blocchi" 'BEGIN { x = 100 * r / b; print (x >= 0.9 && x <= 1.1) ? 1 : sprintf("%.2f%%", x) }')"
    else
        boccia "sulla 2 lo spazio riservato è l'1%" "non riesco a leggere il superblocco ext4"
    fi
    uguale "partizione 3: FAT32 con etichetta SCAMBIO" "vfat FAT32 SCAMBIO" "$(firma "$p3" TYPE) $(firma "$p3" VERSION) $(firma "$p3" LABEL)"
}

p_02_2() {
    local d s
    d=$(disco D1)
    s=$(sorgente_di /srv/posta)
    vero "/srv/posta è montato" test -n "$s"
    vero "da una partizione del disco della posta" test "$(disco_di "$s")" = "$d"
    uguale "con l'etichetta POSTA" POSTA "$(firma "$s" LABEL)"
    local tot lib
    read -r tot lib < <(stat -f -c '%c %d' /srv/posta 2>/dev/null || echo "0 0")
    vero "può contenere almeno 50.000 file (ora: $tot)" test "$tot" -ge 50000
    vero "con almeno 45.000 posti liberi (ora: $lib)" test "$lib" -ge 45000
    vero "tutti i messaggi ci sono, identici, nello stesso posto" controlla_manifest /srv/posta "$STATO/l02/p2.manifest"
    vero "con i proprietari, i permessi e le date di prima" controlla_meta /srv/posta "$STATO/l02/p2.meta"
}

# Il settore dell'intestazione GPT di riserva, letto dall'intestazione principale (LBA 1, campo AlternateLBA).
riserva_gpt() { dd if="$1" bs=512 skip=1 count=1 status=none 2>/dev/null | od -An -t u8 -j 32 -N 8 | tr -d ' '; }

p_02_3() {
    local d p tot fine s
    d=$(disco D2)
    tot=$(settori "$d")
    uguale "la GPT di riserva è in fondo al disco" $((tot - 1)) "$(riserva_gpt "$d")"
    vero "e l'area utilizzabile arriva in fondo (ultimo settore utile: $(jt "$d" .partitiontable.lastlba))" \
        test "$(jt "$d" .partitiontable.lastlba)" -ge $((tot - 34 - 2048))
    p=$(jpart "$d" 1)
    uguale "la partizione è la stessa: primo settore, PARTUUID, nome" "2048 22222222-3333-4444-8555-000000000031 app" \
        "$(campo "$p" start) $(campo "$p" uuid | tr 'A-F' 'a-f') $(campo "$p" name)"
    fine=$(($(campo "$p" start) + $(campo "$p" size) - 1))
    vero "e arriva in fondo al disco" test "$fine" -ge $((tot - 34 - 2048))
    uguale "il kernel la vede grande come sul disco" "2048 $(campo "$p" size)" "$(vista_kernel "$(parte "$d" 1)")"
    s=$(sorgente_di /srv/app)
    uguale "/srv/app è montato dalla partizione 1" "$(parte "$d" 1)" "$s"
    uguale "con lo stesso XFS di prima" "xfs 4d5e6f70-8192-43a4-b5c6-d7e8f90a1b2c" "$(firma "$s" TYPE) $(firma "$s" UUID)"
    local fs=$(($(dim_fs /srv/app))) part=$(($(campo "$p" size) * 512))
    vero "il filesystem usa la partizione intera ($((fs / MIB)) MiB su $((part / MIB)))" test $((fs * 10)) -ge $((part * 8))
    vero "il servizio non si è mai fermato (stesso processo)" servizio_intatto app
    vero "i dati sono intatti" controlla_manifest /srv/app "$STATO/l02/p3.manifest"
}

p_02_4() {
    local d p1 p2 s1 s2
    d=$(disco D1)
    p1=$(jpart "$d" 1)
    p2=$(jpart "$d" 2)
    uguale "partizione 1: stesso inizio e PARTUUID, 600 MiB esatti" "2048 1228800 33333333-4444-4555-8666-000000000041" \
        "$(campo "$p1" start) $(campo "$p1" size) $(campo "$p1" uuid | tr 'A-F' 'a-f')"
    uguale "partizione 2: stesso inizio e PARTUUID, 500 MiB esatti" "2099200 1024000 33333333-4444-4555-8666-000000000042" \
        "$(campo "$p2" start) $(campo "$p2" size) $(campo "$p2" uuid | tr 'A-F' 'a-f')"
    s1=$(sorgente_di /srv/log)
    s2=$(sorgente_di /srv/indici)
    uguale "/srv/log è montato dalla partizione 1, ext4 LOG" "$(parte "$d" 1) ext4 LOG" "$s1 $(firma "$s1" TYPE) $(firma "$s1" LABEL)"
    uguale "/srv/indici è montato dalla partizione 2, XFS INDICI" "$(parte "$d" 2) xfs INDICI" "$s2 $(firma "$s2" TYPE) $(firma "$s2" LABEL)"
    local b bs fs
    b=$(tune2fs -l "$s1" 2>/dev/null | sed -n 's/^Block count: *//p')
    bs=$(tune2fs -l "$s1" 2>/dev/null | sed -n 's/^Block size: *//p')
    fs=$((${b:-0} * ${bs:-0}))
    vero "l'ext4 sta nella partizione e la riempie, al MiB ($((fs / MIB)) MiB)" test "$fs" -le $((1228800 * 512)) -a "$fs" -ge $((1228800 * 512 - MIB))
    fs=$(dim_fs /srv/indici)
    vero "l'XFS riempie la sua partizione ($((fs / MIB)) MiB dichiarati su 500)" test $((fs * 10)) -ge $((1024000 * 512 * 8))
    vero "i dati di /srv/log sono intatti" controlla_manifest /srv/log "$STATO/l02/p4-log.manifest"
    vero "i dati di /srv/indici sono intatti" controlla_manifest /srv/indici "$STATO/l02/p4-indici.manifest"
    local buco
    # shellcheck disable=SC2016 # $t e $p sono variabili di jq
    buco=$(jt "$d" '.partitiontable as $t | [$t.partitions[] | [.start, .start + .size]] | sort_by(.[0]) as $p
        | ([$t.firstlba] + [$p[][1]]) as $inizi | ([$p[][0]] + [$t.lastlba + 1]) as $fini
        | [range(0; $inizi | length) | $fini[.] - $inizi[.]] | max')
    vero "c'è un tratto libero contiguo di almeno 400 MiB ($((${buco:-0} / 2048)) MiB)" test "${buco:-0}" -ge 819200
}

# ---- Lezione 03 ----------------------------------------------------------------------

p_03_1() {
    local u dev righe
    u=$(atteso UUID_FS)
    dev=$(blkid -c /dev/null -l -o device -t "UUID=$u")
    righe=$(fstab_per_punto /srv/archivio)
    uguale "in /etc/fstab c'è una sola riga per /srv/archivio" 1 "$(conta "$righe")"
    campi_fstab "$(head -1 <<<"$righe")"
    vero "la riga cerca il filesystem per UUID (ora: ${F1:-niente})" per_uuid "$F1" "$u"
    # Il ticket non chiede il tipo: va bene anche auto, che lo fa riconoscere a mount.
    vero "con il tipo giusto (ora: ${F3:-niente})" test "$F3" = xfs -o "$F3" = auto
    vero "con l'opzione noatime" ha_opzione "$F4" noatime
    vero "e findmnt --verify la trova corretta" verifica_riga "$(head -1 <<<"$righe")"
    montato_da "/srv/archivio è montato da quel filesystem" /srv/archivio "$dev"
    vero "con noatime già attivo" ha_opzione "$(opzioni_attive /srv/archivio)" noatime
    vero "systemd ha riletto /etc/fstab" systemd_aggiornato
    vero "e l'unità di /srv/archivio nasce da /etc/fstab" dalla_fstab "$(unita /srv/archivio mount)"
    vero "i dati sono intatti" controlla_manifest /srv/archivio "$STATO/l03/p1.manifest"
}

p_03_2() {
    local dati vecchi righe m=$PROVA/controllo
    dati=$(blkid -c /dev/null -l -o device -t UUID=9c3d4e5f-6071-4283-9495-b6c7d8e9f0a1)
    vecchi=$(blkid -c /dev/null -l -o device -t UUID=8b2c3d4e-5f60-4172-8384-a5b6c7d8e9f0)
    montato_da "/srv/dati è montato dal filesystem DATI" /srv/dati "$dati"
    vero "e mostra le fatture di novembre" controlla_manifest /srv/dati "$STATO/l03/p2-dati.manifest"
    righe=$(fstab_per_punto /srv/dati)
    uguale "in /etc/fstab c'è una sola riga per /srv/dati" 1 "$(conta "$righe")"
    campi_fstab "$(head -1 <<<"$righe")"
    vero "la riga trova il filesystem da qualcosa scritto sul disco (ora: ${F1:-niente})" stabile "$F1"
    uguale "e quel qualcosa porta proprio a DATI" "$dati" "$(sorgente_reale "$F1")"
    vero "findmnt --verify la trova corretta" verifica_riga "$(head -1 <<<"$righe")"
    vero "systemd ha riletto /etc/fstab" systemd_aggiornato
    vero "e l'unità di /srv/dati nasce da /etc/fstab" dalla_fstab "$(unita /srv/dati mount)"
    if [[ -n $(findmnt -n -S "$vecchi") ]]; then
        boccia "VECCHI non è montato" "è montato su: $(findmnt -n -o TARGET -S "$vecchi" | paste -sd' ' -)"
        return
    fi
    passa "VECCHI non è montato"
    uguale "VECCHI ha ancora etichetta e UUID" "VECCHI 8b2c3d4e-5f60-4172-8384-a5b6c7d8e9f0" "$(firma "$vecchi" LABEL) $(firma "$vecchi" UUID)"
    vero "VECCHI è integro (xfs_repair -n)" xfs_repair -n "$vecchi"
    mkdir -p "$m"
    if mount -o ro "$vecchi" "$m" 2>/dev/null; then
        vero "e il suo contenuto non è cambiato" controlla_manifest "$m" "$STATO/l03/p2-vecchi.manifest"
        umount "$m"
    else
        boccia "e il suo contenuto non è cambiato" "non riesco a montarlo in sola lettura"
    fi
}

p_03_3() {
    local u dev righe w q t
    u=$(atteso UUID_FS)
    dev=$(blkid -c /dev/null -l -o device -t "UUID=$u")
    righe=$(fstab_per_punto /srv/backup)
    uguale "in /etc/fstab c'è una sola riga per /srv/backup" 1 "$(conta "$righe")"
    campi_fstab "$(head -1 <<<"$righe")"
    vero "la riga cerca il filesystem per UUID (ora: ${F1:-niente})" per_uuid "$F1" "$u"
    vero "findmnt --verify la trova corretta" verifica_riga "$(head -1 <<<"$righe")"
    montato_da "/srv/backup è montato adesso da quel filesystem" /srv/backup "$dev"
    vero "systemd ha riletto /etc/fstab" systemd_aggiornato
    vero "e l'unità di /srv/backup nasce da /etc/fstab" dalla_fstab "$(unita /srv/backup mount)"
    w=" $(systemctl show -p Wants --value local-fs.target) "
    q=" $(systemctl show -p Requires --value local-fs.target) "
    vero "se il disco manca, l'avvio prosegue: local-fs.target lo vuole ma non lo richiede" \
        test "${w/ srv-backup.mount /}" != "$w" -a "${q/ srv-backup.mount /}" = "$q"
    t=$(systemctl show -p JobRunningTimeoutUSec --value -- "$(unita "/dev/disk/by-uuid/$u" device)")
    vero "e lo aspetta al massimo 10 secondi (ora: $t)" entro_10 "$(secondi "$t")"
}

p_03_4() {
    local u dev righe t=/srv/progetti a b
    u=$(atteso UUID_FS)
    dev=$(blkid -c /dev/null -l -o device -t "UUID=$u")
    righe=$(fstab_per_punto /srv/progetti)
    uguale "in /etc/fstab c'è una sola riga per /srv/progetti" 1 "$(conta "$righe")"
    campi_fstab "$(head -1 <<<"$righe")"
    vero "la riga cerca il filesystem per UUID (ora: ${F1:-niente})" per_uuid "$F1" "$u"
    vero "senza file di dispositivo (nodev) e senza setuid (nosuid)" ha_opzioni "$F4" nodev nosuid
    vero "findmnt --verify la trova corretta" verifica_riga "$(head -1 <<<"$righe")"
    montato_da "/srv/progetti è montato adesso da quel filesystem" "$t" "$dev"
    vero "con nodev e nosuid già attivi" ha_opzioni "$(opzioni_attive "$t")" nodev nosuid
    vero "systemd ha riletto /etc/fstab" systemd_aggiornato
    vero "e l'unità di /srv/progetti nasce da /etc/fstab" dalla_fstab "$(unita "$t" mount)"
    if [[ $(sorgente_di "$t") != "$dev" ]]; then
        boccia "le prove con gli utenti" "si fanno solo sul filesystem PROGETTI montato"
        return
    fi
    a=$t/.prova-anna-$$
    b=$t/.prova-cartella-$$
    vero "anna crea un file" runuser -u anna -- touch "$a"
    vero "e una cartella, con un file dentro" crea_con_file anna "$b"
    uguale "tutto appartiene al gruppo sviluppo, anche nella sottocartella" "sviluppo sviluppo sviluppo" \
        "$(stat -c %G "$a" "$b" "$b/dentro" 2>/dev/null | paste -sd' ' -)"
    vero "luca legge il file di anna" runuser -u luca -- cat "$a"
    vero "luca crea i suoi file" runuser -u luca -- touch "$t/.prova-luca-$$"
    vero "luca non può cancellare il file di anna" non_cancella luca "$a"
    vero "né rinominarlo" non_rinomina luca "$a"
    vero "marco non può elencare la cartella" non_elenca marco "$t"
    rm -rf "$a" "$a.x" "$b" "$t/.prova-luca-$$"
}

# ---- Lezione 04 ----------------------------------------------------------------------

GUID_SWAP=0657FD6D-A4AB-43C4-84E5-0933C84B4F4F

p_04_1() {
    local d p u righe
    d=$(disco D1)
    p=$(jpart "$d" 2)
    uguale "la partizione 2 inizia subito dopo la 1 ed è da 512 MiB" "2099200 1048576" "$(campo "$p" start) $(campo "$p" size)"
    uguale "con il tipo Linux swap" "$GUID_SWAP" "$(campo "$p" type)"
    p=$(parte "$d" 2)
    uguale "il kernel la vede" "2099200 1048576" "$(vista_kernel "$p")"
    uguale "contiene una swap" swap "$(firma "$p" TYPE)"
    u=$(firma "$p" UUID)
    uguale "la swap è attiva, con priorità 10" "partition 10" "$(swap_attiva "$p")"
    righe=$(fstab_swap_per "$p")
    uguale "in /etc/fstab c'è una riga per lei" 1 "$(conta "$righe")"
    campi_fstab "$(head -1 <<<"$righe")"
    vero "che la cerca per UUID (ora: ${F1:-niente})" per_uuid "$F1" "$u"
    vero "con priorità 10" ha_opzione "$F4" pri=10
    vero "findmnt --verify la trova corretta" verifica_riga "$(head -1 <<<"$righe")"
    vero "systemd ha riletto /etc/fstab" systemd_aggiornato
    vero "e l'unità della swap nasce da /etc/fstab" dalla_fstab "$(unita "/dev/disk/by-uuid/$u" swap)"
    vero "/srv/db non si è mai fermato (stesso processo)" servizio_intatto db
    vero "i dati del database sono intatti" controlla_manifest /srv/db "$STATO/l04/p1.manifest"
}

p_04_2() {
    local f=/srv/dati/swapfile b righe
    vero "il file esiste" test -f "$f"
    uguale "è di root, e solo root lo legge e lo scrive" "root 600" "$(stat -c '%U %a' "$f" 2>/dev/null)"
    uguale "è da 256 MiB esatti" 268435456 "$(stat -c %s "$f" 2>/dev/null)"
    b=$(stat -c '%b * %B' "$f" 2>/dev/null)
    vero "senza buchi: tutto lo spazio è già allocato" test "$((${b:-0}))" -ge 268435456
    uguale "è attivo come swap, con priorità 5" "file 5" "$(swap_attiva "$f")"
    righe=$(fstab_swap_per "$f")
    uguale "in /etc/fstab c'è una riga per lui" 1 "$(conta "$righe")"
    campi_fstab "$(head -1 <<<"$righe")"
    vero "con priorità 5" ha_opzione "$F4" pri=5
    vero "findmnt --verify la trova corretta" verifica_riga "$(head -1 <<<"$righe")"
    vero "systemd ha riletto /etc/fstab" systemd_aggiornato
    vero "e l'unità della swap nasce da /etc/fstab" dalla_fstab "$(unita "$f" swap)"
}

p_04_3() {
    local f=/srv/dati/swapfile d p usato
    d=$(disco D1)
    p=$(parte "$d" 2)
    uguale "il file di swap non è più attivo" "" "$(awk 'NR > 1 && $1 ~ /swapfile/ { print $1 }' /proc/swaps)"
    vero "e non esiste più" test ! -e "$f"
    usato=$(findmnt -J -b -o USED /srv/dati 2>/dev/null | jq -r '.filesystems[0].used // 0')
    vero "il suo spazio è tornato libero su /srv/dati ($((usato / MIB)) MiB usati)" test "$usato" -lt $((128 * MIB))
    uguale "/etc/fstab non lo cita più" 0 "$(righe_fstab | awk -v f="$f" '$1 == f' | grep -c .)"
    uguale "la swap sulla partizione resta attiva, con priorità 10" "partition 10" "$(swap_attiva "$p")"
    uguale "e resta in /etc/fstab" 1 "$(conta "$(fstab_swap_per "$p")")"
    uguale "vm.swappiness vale 10 adesso" 10 "$(sysctl -n vm.swappiness)"
    uguale "e varrà 10 a ogni avvio (ultimo valore nella configurazione di sysctl)" 10 \
        "$(/usr/lib/systemd/systemd-sysctl --cat-config 2>/dev/null | sed -n 's/^[[:space:]]*vm\.swappiness[[:space:]]*=[[:space:]]*\([0-9]*\).*/\1/p' | tail -1)"
    vero "systemd ha riletto /etc/fstab" systemd_aggiornato
}

# ---- Lezione 05 ----------------------------------------------------------------------

GUID_LVM=E6D6D379-F507-44C2-A23C-238F2A3DF928

p_05_1() {
    local a b p fine lvp
    a=$(disco D1)
    b=$(disco D2)
    p=$(jpart "$a" 1)
    uguale "il disco 1 ha una sola partizione, di tipo Linux LVM" "1 $GUID_LVM" "$(jt "$a" '.partitiontable.partitions | length') $(campo "$p" type)"
    fine=$(($(campo "$p" start) + $(campo "$p" size) - 1))
    vero "e arriva in fondo al disco" test "$fine" -ge $(($(settori "$a") - 34 - 2048))
    vero "il disco 2 non ha una tabella delle partizioni" test -z "$(tab "$b")"
    uguale "il VG vgdati ha extent da 8 MiB" 8388608 "$(vg_campo vgdati vg_extent_size)"
    uguale "e i due PV: la partizione del disco 1 e il disco 2 intero" "$(elenco "$(parte "$a" 1)" "$b")" "$(pv_del_vg vgdati)"
    uguale "il LV lvdb è da 2,5 GiB esatti" 2684354560 "$(lv_campo vgdati/lvdb lv_size)"
    uguale "e sta su entrambi i PV" "$(elenco "$(parte "$a" 1)" "$b")" "$(lv_dispositivi vgdati/lvdb)"
    lvp=$(lv_campo vgdati/lvdb lv_dm_path)
    uguale "contiene un XFS etichettato DB" "xfs DB" "$(firma "$lvp" TYPE) $(firma "$lvp" LABEL)"
    montato_da_fstab /srv/db vgdati lvdb
}

p_05_2() {
    local a b lvp fs
    a=$(disco D1)
    b=$(disco D2)
    uguale "lvdb è da 3 GiB esatti" 3221225472 "$(lv_campo vgdati/lvdb lv_size)"
    uguale "vgdati usa il disco di prima e quello nuovo, intero" "$(elenco "$a" "$b")" "$(pv_del_vg vgdati)"
    lvp=$(lv_campo vgdati/lvdb lv_dm_path)
    montato_da "/srv/db è montato da lvdb" /srv/db "$lvp"
    fs=$(dim_fs /srv/db)
    vero "il filesystem vede lo spazio nuovo ($((fs / MIB)) MiB)" test $((fs * 10)) -ge $((3221225472 * 9))
    vero "il servizio non si è mai fermato (stesso processo)" servizio_intatto db
    vero "i dati sono intatti" controlla_manifest /srv/db "$STATO/l05/p2.manifest"
}

p_05_3() {
    local a b c
    a=$(disco D1)
    b=$(disco D2)
    c=$(disco D3)
    uguale "vgdati sta sul disco rimasto e su quello nuovo" "$(elenco "$b" "$c")" "$(pv_del_vg vgdati)"
    uguale "lvdb non usa più il disco guasto" "$(elenco "$b" "$c")" "$(lv_dispositivi vgdati/lvdb)"
    vero "il disco guasto non ha più l'etichetta LVM" test -z "$(firma "$a" TYPE)"
    uguale "lvdb ha la dimensione di prima" 2684354560 "$(lv_campo vgdati/lvdb lv_size)"
    montato_da "/srv/db è montato da lvdb" /srv/db "$(lv_campo vgdati/lvdb lv_dm_path)"
    vero "il servizio non si è mai fermato (stesso processo)" servizio_intatto db
    vero "i dati sono intatti" controlla_manifest /srv/db "$STATO/l05/p3.manifest"
}

p_05_4() {
    local c
    c=$(disco D3)
    uguale "LVM vede vgvecchio" vgvecchio "$(vg_campo vgvecchio vg_name)"
    vero "e lo troverà anche al prossimo avvio: il disco è nel file dei dispositivi" test -n "$(righe_dispositivi_di "$c")"
    vero "lvdati è attivo" test "$(lv_campo vgvecchio/lvdati lv_active)" = active
    uguale "lvdati non è cambiato" "838860800 xfs 6e0f1a2b-3c4d-4e5f-8a6b-7c8d9e0f1a2b" \
        "$(lv_campo vgvecchio/lvdati lv_size) $(firma /dev/mapper/vgvecchio-lvdati TYPE) $(firma /dev/mapper/vgvecchio-lvdati UUID)"
    montato_da_fstab /srv/archivio vgvecchio lvdati
    vero "le pratiche ci sono tutte, identiche" controlla_manifest /srv/archivio "$STATO/l05/p4.manifest"
}

# ---- Lezione 06 ----------------------------------------------------------------------

p_06_1() {
    local s
    uguale "c'è lo snapshot lvapp-prima, con origine lvapp" "s lvapp" "$(lv_campo vgapp/lvapp-prima lv_attr | cut -c1) $(lv_campo vgapp/lvapp-prima origin)"
    s=$(lv_campo vgapp/lvapp-prima lv_size)
    vero "con almeno 300 MiB per le modifiche ($((${s:-0} / MIB)) MiB)" test "${s:-0}" -ge $((300 * MIB))
    montato_da "/srv/app-prima è montato dallo snapshot" /srv/app-prima "$(lv_campo vgapp/lvapp-prima lv_dm_path)"
    vero "in sola lettura" ha_opzione "$(opzioni_attive /srv/app-prima)" ro
    vero "e mostra i file di lvapp" ha_tutti_i_file /srv/app-prima "$STATO/l06/p1.manifest" "$(cat "$STATO/l06/p1.quanti")"
    uguale "non è in /etc/fstab: è temporaneo" 0 "$(conta "$(fstab_per_punto /srv/app-prima)")"
    montato_da "/srv/app è ancora montato da lvapp" /srv/app "$(lv_campo vgapp/lvapp lv_dm_path)"
    vero "e il servizio non si è mai fermato (stesso processo)" servizio_intatto app
}

p_06_2() {
    uguale "lo snapshot lvapp-prima non esiste più" "" "$(lv_campo vgapp/lvapp-prima lv_name)"
    vero "e non c'è un ritorno indietro rimasto in sospeso" test "$(lv_campo vgapp/lvapp lv_attr | cut -c1)" != O
    montato_da "/srv/app è montato da lvapp" /srv/app "$(lv_campo vgapp/lvapp lv_dm_path)"
    vero "e mostra i dati di prima dell'aggiornamento, senza un file in più né in meno" \
        ha_tutti_i_file /srv/app "$STATO/l06/p2.manifest" "$(cat "$STATO/l06/p2.quanti")"
}

p_06_3() {
    local a b
    a=$(disco D1)
    b=$(disco D2)
    vero "vgdati è completo: nessun PV mancante" test "$(vg_campo vgdati vg_attr | cut -c4)" = -
    uguale "con i suoi due dischi" "$(elenco "$a" "$b")" "$(pv_del_vg vgdati)"
    uguale "e il PV del disco cancellato ha la sua identità di prima" "$(atteso PVUUID)" "$(pv_campo "$b" pv_uuid)"
    uguale "lvdb ha la dimensione di prima" 2684354560 "$(lv_campo vgdati/lvdb lv_size)"
    vero "ed è attivo" test "$(lv_campo vgdati/lvdb lv_active)" = active
    montato_da "/srv/db è montato da lvdb" /srv/db "$(lv_campo vgdati/lvdb lv_dm_path)"
    vero "i dati sono intatti" controlla_manifest /srv/db "$STATO/l06/p3.manifest"
}

# ---- Lezione 07 ----------------------------------------------------------------------

avvio_attuale() { tr -d - </proc/sys/kernel/random/boot_id; }
riavviato() { [[ $(avvio_attuale) != "$(atteso BOOT_ID)" ]]; }
pid_journald() { systemctl show -p MainPID --value systemd-journald; }
# L'ultimo valore di una chiave nella configurazione di journald, file aggiunti compresi.
valore_journald() {
    systemd-analyze cat-config systemd/journald.conf 2>/dev/null |
        sed -n "s/^[[:space:]]*$1[[:space:]]*=[[:space:]]*//p" | tail -1
}
journal_su_disco() { find "/proc/$(pid_journald)/fd" -lname "/var/log/journal/$(cat /etc/machine-id)/*" 2>/dev/null | grep -q .; }
# Il limite che journald in esecuzione ha annunciato per il journal su disco.
limite_annunciato() {
    journalctl -q -b "_PID=$(pid_journald)" SYSLOG_IDENTIFIER=systemd-journald -o cat 2>/dev/null |
        sed -n 's|^System Journal (/var/log/journal/[^)]*) is .*, max \([^,]*\),.*|\1|p' | tail -1
}
salvato_su_disco() {
    local s
    s=$(valore_journald Storage)
    [[ $s == persistent || ($s == auto || -z $s) && -d /var/log/journal ]]
}

p_07_1() {
    local s m
    s=$(valore_journald Storage)
    vero "la configurazione salva il journal su disco (Storage=${s:-auto, il predefinito})" salvato_su_disco
    m=$(valore_journald SystemMaxUse)
    vero "e gli dà al massimo 200 MiB (SystemMaxUse=${m:-non impostato})" test "${m^^}" = 200M -o "${m^^}" = 200MIB -o "$m" = 209715200
    vero "journald sta già scrivendo in /var/log/journal" journal_su_disco
    uguale "e ha annunciato il limite nuovo all'ultimo avvio del servizio" 200.0M "$(limite_annunciato)"
}

# Un campo dell'intestazione di un ext4, come lo stampa dumpe2fs -h.
ext4_campo() { dumpe2fs -h "$1" 2>/dev/null | sed -n "s/^$2:[[:space:]]*//p"; }
controllato_dopo() { # DEV EPOCA: l'ultimo controllo completo è avvenuto dopo EPOCA
    local c
    c=$(ext4_campo "$1" 'Last checked')
    [[ -n $c ]] && (($(date -d "$c" +%s) >= $2))
}
vuota() { [[ -d $1 && -z $(ls -A "$1") ]]; }
quanti() { cat "$STATO/l$1/p$2.quanti" 2>/dev/null; }

# I controlli comuni a un filesystem su una partizione, montato da fstab su PUNTO.
montato_da_fstab_part() { # PUNTO DISPOSITIVO
    local righe
    montato_da "$1 è montato dalla partizione del disco dedicato" "$1" "$2"
    righe=$(fstab_per_punto "$1")
    uguale "in /etc/fstab c'è una sola riga per $1" 1 "$(conta "$righe")"
    campi_fstab "$(head -1 <<<"$righe")"
    vero "la riga trova la partizione per UUID o etichetta (ora: ${F1:-niente})" stabile "$F1"
    vero "e porta proprio lì" stessa_destinazione "$(sorgente_reale "$F1")" "$2"
    vero "findmnt --verify la trova corretta" verifica_riga "$(head -1 <<<"$righe")"
    vero "systemd ha riletto /etc/fstab" systemd_aggiornato
    vero "e l'unità di $1 nasce da /etc/fstab" dalla_fstab "$(unita "$1" mount)"
}

p_07_2() {
    local p f=/srv/archivio/fatture
    p=$(parte "$(disco D1)" 1)
    montato_da_fstab_part /srv/archivio "$p"
    vero "in lettura e scrittura" test -n "$(opzioni_attive /srv/archivio)" -a "$(opzioni_attive /srv/archivio | cut -d, -f1)" = rw
    uguale "il filesystem risulta pulito" clean "$(ext4_campo "$p" 'Filesystem state')"
    uguale "e senza errori registrati" "" "$(ext4_campo "$p" 'FS Error count')"
    vero "il controllo completo è stato fatto dopo il danno" controllato_dopo "$p" "$(atteso T_DANNO)"
    vero "lost+found è vuota" vuota /srv/archivio/lost+found
    uguale "la cartella fatture è di root, gruppo amministrazione, permessi 2770" "root amministrazione 2770" "$(stat -c '%U %G %a' "$f" 2>/dev/null)"
    vero "ci sono tutte le fatture, i contratti e i verbali, con il loro nome, identici" \
        ha_tutti_i_file /srv/archivio "$STATO/l07/p2.manifest" "$(quanti 07 2)"
}

p_07_3() {
    local p
    p=$(parte "$(disco D2)" 1)
    montato_da_fstab_part /srv/indici "$p"
    uguale "è lo stesso filesystem di prima (stesso UUID)" 9b3c4d5e-6f70-4b8c-8d9e-0f1a2b3c4d5e "$(firma "$p" UUID)"
    uguale "gli indici di stanotte ci sono tutti" 80 "$(find /srv/indici/stanotte -type f 2>/dev/null | wc -l)"
    vero "e tutti i file, storico compreso, sono identici" ha_tutti_i_file /srv/indici "$STATO/l07/p3.manifest" "$(quanti 07 3)"
}

mai_raggiunto() { [[ $(systemctl show -p ActiveEnterTimestampMonotonic --value "$1") == 0 ]]; }

p_07_4() {
    local p righe
    p=$(parte "$(disco D3)" 1)
    vero "la macchina è stata riavviata dopo la preparazione" riavviato
    vero "e quest'ultimo avvio non è passato dalla modalità di emergenza" mai_raggiunto emergency.target
    vero "né da quella di soccorso" mai_raggiunto rescue.target
    vero "l'avvio è arrivato fino in fondo (multi-user.target attivo)" test "$(systemctl is-active multi-user.target)" = active
    uguale "nessun montaggio né swap fallito" "" "$(systemctl --failed --type=mount,swap,automount --plain --no-legend 2>/dev/null | awk '{ print $1 }' | paste -sd' ' -)"
    uguale "local-fs.target è attivo" active "$(systemctl is-active local-fs.target)"
    montato_da_fstab_part /srv/dati "$p"
    righe=$(fstab_per_punto /srv/dati)
    campi_fstab "$(head -1 <<<"$righe")"
    vero "senza nofail: se il disco manca, la macchina se ne accorge" test -n "$F4" -a "$(ha_opzione "$F4" nofail && echo si)" != si
    # noauto, o un automount, aggirano «niente nofail»: l'avvio non lo monta, o non lo aspetta.
    vero "e lo monta l'avvio, che senza il disco si ferma (local-fs.target lo richiede)" \
        grep -qw local-fs.target <<<"$(systemctl show -P RequiredBy "$(unita /srv/dati mount)" 2>/dev/null)"
    vero "i dati sono intatti" ha_tutti_i_file /srv/dati "$STATO/l07/p4.manifest" "$(quanti 07 4)"
}

# ---- Lezione 08 ----------------------------------------------------------------------

VOCI=/boot/loader/entries
AVVIO=$BASE/avvio

opzioni_voce() { sed -n 's/^options[[:space:]]*//p' "$1"; }
ha_parola() { tr -s '[:space:]' '\n' <<<"$1" | grep -qxF -- "$2"; }
# Un valore di /etc/default/grub o di /etc/sysconfig/kernel, come lo legge chi li usa.
# shellcheck disable=SC1090
valore_di() { (set +u; . "$1" >/dev/null 2>&1; printf '%s' "${!2:-}"); }
voce_predefinita() { grub2-editenv list 2>/dev/null | sed -n 's/^saved_entry=//p'; }
voci_senza() { # PAROLA: le voci BLS che non hanno PAROLA fra le opzioni
    local v
    for v in "$VOCI"/*.conf; do
        [[ -f $v ]] || continue
        ha_parola "$(opzioni_voce "$v")" "$1" || basename "$v" .conf
    done
}
voci_con() {
    local v
    for v in "$VOCI"/*.conf; do
        [[ -f $v ]] || continue
        ha_parola "$(opzioni_voce "$v")" "$1" && basename "$v" .conf
    done
}
# Le opzioni che kernel-install darà al prossimo kernel (20-grub.install su Rocky 9).
opzioni_future() {
    if [[ -f /etc/kernel/cmdline ]]; then cat /etc/kernel/cmdline
    elif [[ -f /usr/lib/kernel/cmdline ]]; then cat /usr/lib/kernel/cmdline
    else cat /proc/cmdline
    fi
}
riga_grub() { printf '%s %s' "$(valore_di /etc/default/grub GRUB_CMDLINE_LINUX)" "$(valore_di /etc/default/grub GRUB_CMDLINE_LINUX_DEFAULT)"; }
attesa_menu() { grep -Eq "^[[:space:]]*set timeout=$1[[:space:]]*\$" /boot/grub2/grub.cfg; }

p_08_1() {
    uguale "il target predefinito è multi-user.target" multi-user.target "$(systemctl get-default)"
    uguale "graphical.target non è più attivo" inactive "$(systemctl is-active graphical.target)"
    uguale "multi-user.target è attivo" active "$(systemctl is-active multi-user.target)"
    uguale "sshd non si è fermato" "$(atteso SSHD)" "$(systemctl is-active sshd)"
    uguale "senza riavviare la macchina" "$(atteso BOOT_ID)" "$(avvio_attuale)"
    uguale "e senza riavviare sshd (stesso processo)" "$(atteso SSHD_PID)" "$(systemctl show -p MainPID --value sshd)"
}

# Avvii registrati dopo EPOCA, uno per riga: id, primo e ultimo istante (microsecondi).
avvii_dopo() {
    journalctl --list-boots -o json 2>/dev/null |
        jq -r --argjson t "$(($1 * 1000000))" '.[] | select(.last_entry >= $t) | "\(.boot_id) \(.first_entry) \(.last_entry)"'
}
riga_di_comando() { journalctl -q -b "$1" -k -o cat 2>/dev/null | sed -n 's/^Command line: //p' | head -1; }
chiede_soccorso() { tr ' ' '\n' <<<"$1" | grep -qxE 'systemd\.unit=rescue(\.target)?|rescue|single|s|S|1'; }
# Le voci BLS che chiedono il soccorso, in qualunque grafia.
voci_soccorso() {
    local v
    for v in "$VOCI"/*.conf; do
        [[ -f $v ]] || continue
        chiede_soccorso "$(opzioni_voce "$v")" && basename "$v" .conf
    done
    return 0
}
soccorso_raggiunto() {
    journalctl -q -b "$1" -u rescue.target -o json 2>/dev/null |
        jq -e -s 'any(.[]; .JOB_TYPE == "start" and .JOB_RESULT == "done")' >/dev/null
}

p_08_2() {
    local p id primo ultimo trovato="" controllo c
    p=$(parte "$(disco D1)" 1)
    if ! journal_su_disco; then
        boccia "il journal si salva su disco" "senza, il correttore non vede gli avvii precedenti: rilancia sudo ./prepara.sh 08 2"
        return
    fi
    while read -r id primo ultimo; do
        [[ -n $id && $id != "$(avvio_attuale)" ]] || continue
        chiede_soccorso "$(riga_di_comando "$id")" && soccorso_raggiunto "$id" && trovato="$id $primo $ultimo"
    done < <(avvii_dopo "$(atteso T0)")
    vero "dopo la preparazione c'è un avvio in modalità di soccorso, chiesto dalla riga del kernel" test -n "$trovato"
    read -r id primo ultimo <<<"${trovato:-- 0 0}"
    c=$(ext4_campo "$p" 'Last checked')
    controllo=$(date -d "${c:-@0}" +%s)
    vero "il controllo completo di /srv/dati è avvenuto durante quell'avvio" \
        test -n "$trovato" -a $((controllo * 1000000)) -ge "${primo:-0}" -a $((controllo * 1000000)) -le $((${ultimo:-0} + 1000000))
    vero "l'avvio di adesso è normale: la riga del kernel non chiede il soccorso" test -z "$(chiede_soccorso "$(cat /proc/cmdline)" && echo si)"
    uguale "e rescue.target non è attivo" inactive "$(systemctl is-active rescue.target)"
    uguale "il target predefinito non è cambiato" "$(cat "$AVVIO/target" 2>/dev/null)" "$(systemctl get-default)"
    uguale "nessuna voce del menu avvia in soccorso" "" "$(voci_soccorso | paste -sd' ' -)"
    vero "e nemmeno i kernel futuri" test -z "$(chiede_soccorso "$(opzioni_future)" && echo si)"
    vero "né /etc/default/grub, da cui grub2-mkconfig rifà le voci" test -z "$(chiede_soccorso "$(riga_grub)" && echo si)"
    montato_da_fstab_part /srv/dati "$p"
    vero "i dati sono intatti" ha_tutti_i_file /srv/dati "$STATO/l08/p2.manifest" "$(quanti 08 2)"
}

THP=transparent_hugepage=never

p_08_3() {
    uguale "ogni voce del menu ha $THP, soccorso compreso" "" "$(voci_senza "$THP" | paste -sd' ' -)"
    vero "i kernel che arriveranno lo avranno (le opzioni che userà kernel-install)" ha_parola "$(opzioni_future)" "$THP"
    vero "/etc/default/grub lo ha nella riga del kernel" ha_parola "$(riga_grub)" "$THP"
    uguale "/etc/default/grub fa aspettare il menu 10 secondi" 10 "$(valore_di /etc/default/grub GRUB_TIMEOUT)"
    vero "e /boot/grub2/grub.cfg è stato rigenerato con quel tempo" attesa_menu 10
    vero "la macchina è stata riavviata dopo la preparazione" riavviato
    vero "e il kernel in esecuzione ha ricevuto il parametro" ha_parola "$(cat /proc/cmdline)" "$THP"
    vero "le transparent huge pages sono disattivate" grep -q '\[never\]' /sys/kernel/mm/transparent_hugepage/enabled
}

p_08_4() {
    local buono finto
    buono=$(atteso KERNEL_BUONO)
    finto=$(atteso KERNEL_FINTO)
    vero "la macchina è stata riavviata dopo la preparazione" riavviato
    uguale "gira con il kernel di prima" "$buono" "$(uname -r)"
    uguale "che è il predefinito per GRUB" "$(atteso VOCE_BUONA)" "$(voce_predefinita)"
    uguale "e per grubby" "/boot/vmlinuz-$buono" "$(grubby --default-kernel 2>/dev/null)"
    uguale "GRUB sceglie ancora la voce salvata (GRUB_DEFAULT)" "$(valore_di "$AVVIO/grub" GRUB_DEFAULT)" "$(valore_di /etc/default/grub GRUB_DEFAULT)"
    vero "il kernel nuovo è ancora installato" test -f "/boot/vmlinuz-$finto" -a -f "/boot/initramfs-$finto.img"
    vero "e ha ancora la sua voce nel menu" test -f "$VOCI/$(atteso VOCE_FINTA).conf"
    uguale "un prossimo aggiornamento non cambierà il predefinito (UPDATEDEFAULT)" no "$(valore_di /etc/sysconfig/kernel UPDATEDEFAULT)"
}

p_08_pulizia() {
    local finto recente
    pulizia
    finto=$(atteso KERNEL_FINTO)
    vero "i file del kernel $finto non ci sono più" test ! -e "/boot/vmlinuz-$finto" -a ! -e "/boot/initramfs-$finto.img"
    vero "e nemmeno la sua voce nel menu" test ! -e "$VOCI/$(atteso VOCE_FINTA).conf"
    uguale "nessuna voce del menu ha più $THP" "" "$(voci_con "$THP" | paste -sd' ' -)"
    vero "né i kernel futuri" test -z "$(ha_parola "$(opzioni_future)" "$THP" && echo si)"
    vero "né /etc/default/grub" test -z "$(ha_parola "$(riga_grub)" "$THP" && echo si)"
    uguale "il menu aspetta di nuovo come prima" "$(valore_di "$AVVIO/grub" GRUB_TIMEOUT)" "$(valore_di /etc/default/grub GRUB_TIMEOUT)"
    vero "e grub.cfg è stato rigenerato" attesa_menu "$(valore_di "$AVVIO/grub" GRUB_TIMEOUT)"
    uguale "i kernel nuovi tornano predefiniti (UPDATEDEFAULT)" "$(valore_di "$AVVIO/kernel" UPDATEDEFAULT)" "$(valore_di /etc/sysconfig/kernel UPDATEDEFAULT)"
    recente=$(find /lib/modules -mindepth 1 -maxdepth 1 -printf '%f\n' | sort -V | tail -1)
    uguale "il predefinito è il kernel più recente installato" "/boot/vmlinuz-$recente" "$(grubby --default-kernel 2>/dev/null)"
}

# ---- Lezione 09 ----------------------------------------------------------------------

proprieta() { systemctl show -p "$2" --value -- "$1" 2>/dev/null; }
# La parola compare fra quelle separate da spazi (le liste di systemctl show).
fra() { tr ' ' '\n' <<<"$1" | grep -qxF -- "$2"; }
# L'unità di systemd che contiene il processo, dal suo cgroup.
unita_del_processo() { [[ -n $1 ]] && sed -n 's|^0::.*/||p' "/proc/$1/cgroup" 2>/dev/null; }
chi_ascolta() { ss -Hltnp "sport = :$1" 2>/dev/null | grep -o 'pid=[0-9]*' | head -1 | cut -d= -f2; }
utente_di() { ps -o user= -p "$1" 2>/dev/null | tr -d ' '; }
# Il file dell'unità sta dove sopravvive al riavvio: non in /run.
persistente() { [[ -n $1 && $1 != /run/* ]]; }
# aspetta SECONDI COMANDO...: riprova finché il comando riesce.
aspetta() {
    local fine=$((SECONDS + $1))
    shift
    until "$@" >/dev/null 2>&1; do
        ((SECONDS < fine)) || return 1
        sleep 0.5
    done
}

APP=lab-app.service

journal_di_lab_app() {
    journalctl -q -u "$APP" --since "@$(atteso T0)" -o cat 2>/dev/null | grep -q 'in ascolto sulla porta'
}
mano_finita() { local p; p=$(atteso PID_MANO); ! grep -qs lab-app "/proc/$p/cmdline"; }
# Il servizio dichiara di aver bisogno di /srv/app: lo vuole (Requires o BindsTo) e parte dopo.
vuole_il_disco() {
    { fra "$(proprieta "$APP" Requires)" srv-app.mount || fra "$(proprieta "$APP" BindsTo)" srv-app.mount; } &&
        fra "$(proprieta "$APP" After)" srv-app.mount
}
nuovo_processo() {
    local p
    p=$(proprieta "$APP" MainPID)
    [[ $p -gt 0 && $p != "$1" && $(systemctl is-active "$APP") == active ]]
}
risponde_app() { curl -sf -m 3 http://127.0.0.1:8088/ | grep -q 'lab-app ok'; }
rimetti_app() {
    if [[ -d $MONTAGGIO_IMPOSSIBILE ]]; then rm -rf "$MONTAGGIO_IMPOSSIBILE"; systemctl daemon-reload; fi
    systemctl reset-failed srv-app.mount 2>/dev/null
    systemctl start srv-app.mount 2>/dev/null
    systemctl reset-failed "$APP" 2>/dev/null
    systemctl restart "$APP" 2>/dev/null
    aspetta 20 risponde_app || true
}

prova_caduta() {
    local prima
    prima=$(proprieta "$APP" MainPID)
    if [[ ! $prima -gt 0 ]]; then boccia "ucciso con SIGKILL, riparte da solo" "il servizio non ha un processo principale"; return; fi
    kill -KILL "$prima"
    if aspetta 40 nuovo_processo "$prima"; then
        passa "ucciso con SIGKILL, systemd lo fa ripartire da solo"
    else
        boccia "ucciso con SIGKILL, systemd lo fa ripartire da solo" "dopo 40 secondi lab-app è $(systemctl is-active "$APP")"
        rimetti_app
    fi
}

# Senza /srv/app: avviato con il disco smontato lo rimonta; con il montaggio impossibile
# (per qualche secondo il montaggio ha una condizione che non può avverarsi) non parte.
MONTAGGIO_IMPOSSIBILE=/run/systemd/system/srv-app.mount.d
prova_disco() {
    local inizio
    systemctl stop "$APP" 2>/dev/null
    if ! systemctl stop srv-app.mount 2>/dev/null || findmnt -rn /srv/app >/dev/null; then
        boccia "avviato con /srv/app smontato, lo rimonta" "non riesco a smontare /srv/app per provarlo: lo usa qualcuno ($(fuser -m /srv/app 2>&1 | tr -s ' '))"
        rimetti_app
        return
    fi
    systemctl start "$APP" 2>/dev/null
    vero "avviato con /srv/app smontato, il servizio lo rimonta prima di partire" findmnt -rn /srv/app
    systemctl stop "$APP" 2>/dev/null
    systemctl stop srv-app.mount 2>/dev/null
    mkdir -p "$MONTAGGIO_IMPOSSIBILE"
    printf '[Unit]\nAssertPathExists=%s/disco-assente\n' "$PROVA" >"$MONTAGGIO_IMPOSSIBILE/lab-prova.conf"
    systemctl daemon-reload
    inizio=$(proprieta "$APP" ExecMainStartTimestampMonotonic)
    systemctl start "$APP" 2>/dev/null
    sleep 2
    vero "se /srv/app non si può montare, il servizio non parte nemmeno" \
        test "$(proprieta "$APP" ExecMainStartTimestampMonotonic)" = "$inizio" -a "$(systemctl is-active "$APP")" != active
    rimetti_app
}

p_09_1() {
    local pid
    uguale "lab-app.service è un'unità caricata" loaded "$(proprieta "$APP" LoadState)"
    vero "con il file in un posto che sopravvive al riavvio" persistente "$(proprieta "$APP" FragmentPath)"
    uguale "parte da sola all'avvio" enabled "$(systemctl is-enabled "$APP" 2>/dev/null)"
    vero "multi-user.target la vuole" fra "$(proprieta multi-user.target Wants)" "$APP"
    uguale "è attiva" active "$(systemctl is-active "$APP")"
    pid=$(proprieta "$APP" MainPID)
    uguale "gira come labapp" labapp "$(utente_di "$pid")"
    uguale "chi ascolta sulla porta 8088 è il processo del servizio" "$APP" "$(unita_del_processo "$(chi_ascolta 8088)")"
    vero "risponde" risponde_app
    vero "la copia lanciata a mano dal collega non gira più" mano_finita
    uguale "gira una copia sola di lab-app" 1 "$(pgrep -fc /opt/lab-app/lab-app)"
    vero "i suoi messaggi sono nel journal del servizio" journal_di_lab_app
    vero "dichiara di aver bisogno di /srv/app (e parte dopo il montaggio)" vuole_il_disco
    prova_caduta
    prova_disco
    uguale "alla fine è di nuovo attivo" active "$(systemctl is-active "$APP")"
}

CROND=crond.service

p_09_2() {
    local pid cg
    vero "il file dell'unità del pacchetto è intatto (rpm -V cronie)" test -z "$(rpm -V cronie 2>/dev/null | grep -F /usr/lib/systemd/system/crond.service)"
    uguale "systemd usa il file del pacchetto, non una copia" /usr/lib/systemd/system/crond.service "$(proprieta "$CROND" FragmentPath)"
    vero "c'è un ritocco locale (drop-in)" test -n "$(proprieta "$CROND" DropInPaths)"
    uguale "e nessuno sta in /run, che si svuota al riavvio" "" "$(tr ' ' '\n' <<<"$(proprieta "$CROND" DropInPaths)" | grep '^/run/' | paste -sd' ' -)"
    uguale "systemd ha riletto i file" no "$(proprieta "$CROND" NeedDaemonReload)"
    uguale "priorità per crond e i suoi lavori (Nice)" 10 "$(proprieta "$CROND" Nice)"
    uguale "limite di memoria per crond e i suoi lavori (MemoryMax)" 1073741824 "$(proprieta "$CROND" MemoryMax)"
    uguale "crond è attivo" active "$(systemctl is-active "$CROND")"
    pid=$(proprieta "$CROND" MainPID)
    uguale "il crond che gira adesso ha nice 10 (lo erediteranno i lavori)" 10 "$(ps -o ni= -p "$pid" 2>/dev/null | tr -d ' ')"
    cg=$(proprieta "$CROND" ControlGroup)
    uguale "e il suo cgroup ha il limite di 1 GiB" 1073741824 "$(cat "/sys/fs/cgroup$cg/memory.max" 2>/dev/null)"
}

REPORT=lab-report.service
TIMER=lab-report.timer

nuovo_report() { [[ -n $(find /var/lib/lab-report -type f -newer "$1" 2>/dev/null | head -1) ]]; }
finito() { [[ $(systemctl is-active "$REPORT") != activating ]]; }

prova_report() {
    local segno nuovo
    segno=$(mktemp)
    sleep 1
    timeout 60 systemctl start "$REPORT" 2>/dev/null
    aspetta 15 nuovo_report "$segno"
    nuovo=$(find /var/lib/lab-report -type f -newer "$segno" 2>/dev/null | head -1)
    rm -f "$segno"
    vero "lanciato a mano, il servizio scrive un report nuovo" test -n "$nuovo"
    uguale "come l'utente labapp" labapp "$(stat -c %U "$nuovo" 2>/dev/null)"
    # La prova non lascia il suo report: dopo l'ora del ricalcolo sembrerebbe il ricalcolo.
    [[ -n $nuovo ]] && rm -f -- "$nuovo"
    aspetta 15 finito
    uguale "e poi finisce: non resta attivo, così il timer lo può rilanciare" inactive "$(systemctl is-active "$REPORT")"
    uguale "e risulta riuscito" success "$(proprieta "$REPORT" Result)"
}

# Le prossime cinque partenze dopo BASE (secondi dall'epoca) dal lunedì al venerdì alle
# 07:00 di New York, calcolate senza systemd.
partenze_attese() {
    local base=$1 oggi i d t n=0
    oggi=$(TZ=America/New_York date -d "@$base" +%F)
    for i in $(seq 0 14); do
        d=$(TZ=America/New_York date -d "$oggi +$i day" +%F)
        (($(TZ=America/New_York date -d "$d" +%u) <= 5)) || continue
        t=$(TZ=America/New_York date -d "$d 07:00" +%s)
        ((t > base)) || continue
        date -u -d "@$t" '+%a %F %H:%M'
        n=$((n + 1))
        ((n == 5)) && break
    done | paste -sd, -
}
# Le prossime cinque partenze dopo BASE secondo le espressioni OnCalendar del timer.
partenze_del_timer() {
    local base=$1 spec q
    proprieta "$TIMER" TimersCalendar | grep -o 'OnCalendar=[^;]*' | sed 's/^OnCalendar=//; s/ *$//' |
        while IFS= read -r spec; do
            TZ=UTC systemd-analyze calendar --iterations=5 --base-time="@$base" "$spec" 2>/dev/null |
                sed -n -E 's/^ *(Next elapse|Iter\. #[0-9]+): //p' | while IFS= read -r q; do date -d "$q" +%s 2>/dev/null; done
        done | sort -n | uniq | head -5 | while read -r q; do date -u -d "@$q" '+%a %F %H:%M'; done | paste -sd, -
}

# Un'unità che lancia il report: il servizio stesso, systemctl che lo avvia, o lo script
# come labapp.
lancia_il_report() {
    local s cmd
    s=$(proprieta "$1" Unit)
    [[ $s == "$REPORT" ]] && return 0
    cmd=$(proprieta "$s" ExecStart)
    [[ $cmd == *systemctl* && $cmd == *lab-report* ]] && return 0
    [[ $cmd == */opt/lab-report/report.sh* && $(proprieta "$s" User) == labapp ]] && return 0
    return 1
}

straordinario() {
    local t u trovato="" quando
    t=$(atteso STRAORDINARIO)
    quando=$(date -d "@$t" '+%F %H:%M')
    if (($(date +%s) < t)); then
        for u in $(systemctl list-units --type=timer --all --plain --no-legend 2>/dev/null | awk '{ print $1 }'); do
            [[ $(proprieta "$u" FragmentPath) == /run/systemd/transient/* ]] || continue
            [[ $(systemctl show --timestamp=unix -p TimersCalendar --value "$u" 2>/dev/null) == *"next_elapse=@$t "* ]] || continue
            lancia_il_report "$u" && trovato=$u
        done
        vero "c'è un timer transitorio (in /run, niente in /etc) per il ricalcolo del $quando, che lancia il report come labapp" test -n "$trovato"
        if [[ -n $trovato ]]; then
            vero "e dopo quella volta non si ripete" test "$(TZ=UTC systemd-analyze calendar --iterations=3 \
                "$(proprieta "$trovato" TimersCalendar | grep -o 'OnCalendar=[^;]*' | head -1 | sed 's/^OnCalendar=//; s/ *$//')" 2>/dev/null | grep -c 'Iter\.')" = 0
        fi
    else
        vero "il ricalcolo straordinario del $quando è stato fatto (c'è un report di quei minuti)" \
            test -n "$(find /var/lib/lab-report -type f -newermt "@$t" ! -newermt "@$((t + 900))" 2>/dev/null | head -1)"
    fi
}

p_09_3() {
    local ora quattro otto
    uguale "lab-report.service è un'unità caricata" loaded "$(proprieta "$REPORT" LoadState)"
    vero "con il file in un posto che sopravvive al riavvio" persistente "$(proprieta "$REPORT" FragmentPath)"
    vero "il servizio da solo non parte all'avvio" test "$(systemctl is-enabled "$REPORT" 2>/dev/null)" != enabled
    prova_report
    uguale "lab-report.timer è un'unità caricata" loaded "$(proprieta "$TIMER" LoadState)"
    vero "con il file in un posto che sopravvive al riavvio" persistente "$(proprieta "$TIMER" FragmentPath)"
    uguale "il timer lancia lab-report.service" "$REPORT" "$(proprieta "$TIMER" Unit)"
    uguale "parte all'avvio" enabled "$(systemctl is-enabled "$TIMER" 2>/dev/null)"
    uguale "ed è attivo adesso" active "$(systemctl is-active "$TIMER")"
    ora=$(date +%s)
    quattro=$((ora + 120 * 86400))
    otto=$((ora + 240 * 86400))
    uguale "le prossime cinque partenze (UTC): lun-ven alle 07:00 di New York" "$(partenze_attese "$ora")" "$(partenze_del_timer "$ora")"
    uguale "anche fra quattro mesi, con l'ora legale o senza" "$(partenze_attese "$quattro")" "$(partenze_del_timer "$quattro")"
    uguale "e fra otto mesi" "$(partenze_attese "$otto")" "$(partenze_del_timer "$otto")"
    uguale "nessuna partenza legata all'avvio o al tempo trascorso" "" "$(proprieta "$TIMER" TimersMonotonic)"
    uguale "recupera la partenza persa a macchina spenta (Persistent)" yes "$(proprieta "$TIMER" Persistent)"
    uguale "parte in un momento a caso entro 15 minuti (RandomizedDelaySec)" 15min "$(proprieta "$TIMER" RandomizedDelayUSec)"
    straordinario
}

SINCRO=lab-sincro.service

sincronizzato_ora() {
    local avvio ultimo
    avvio=$(awk '$1 == "btime" { print $2 }' /proc/stat)
    ultimo=$(cat /var/lib/lab-sincro/ultimo 2>/dev/null)
    [[ -n $ultimo ]] && ((ultimo >= avvio))
}
# Quanto lab-sincro ha tenuto fermo l'avvio, in secondi.
durata_sincro() {
    local da a
    da=$(proprieta "$SINCRO" InactiveExitTimestampMonotonic)
    a=$(proprieta "$SINCRO" ActiveEnterTimestampMonotonic)
    if [[ $da -gt 0 && $a -gt 0 ]]; then echo $(((a - da) / 1000000)); else echo 999; fi
}

vuole_la_rete() { fra "$(proprieta "$SINCRO" Wants) $(proprieta "$SINCRO" Requires)" network-online.target; }

p_09_4() {
    local d
    vero "la macchina è stata riavviata dopo la preparazione" riavviato
    uguale "il file del fornitore è intatto" "$(atteso SHA_SINCRO)" "$(sha256sum /usr/lib/systemd/system/lab-sincro.service 2>/dev/null | cut -d' ' -f1)"
    uguale "systemd usa il file del fornitore, non una copia" /usr/lib/systemd/system/lab-sincro.service "$(proprieta "$SINCRO" FragmentPath)"
    uguale "lab-sincro parte ancora a ogni avvio" enabled "$(systemctl is-enabled "$SINCRO" 2>/dev/null)"
    uguale "in questo avvio è riuscito" "active success" "$(systemctl is-active "$SINCRO") $(proprieta "$SINCRO" Result)"
    vero "e ha sincronizzato in questo avvio" sincronizzato_ora
    uguale "non c'è più l'attesa a vuoto prima di partire" "" "$(proprieta "$SINCRO" ExecStartPre | grep -o 'sleep[^;]*')"
    d=$(durata_sincro)
    vero "ha tenuto fermo l'avvio meno di 15 secondi (questa volta: $d s)" test "$d" -lt 15
    vero "chiede la rete configurata (Wants o Requires network-online.target)" vuole_la_rete
    vero "e parte dopo che c'è (After)" fra "$(proprieta "$SINCRO" After)" network-online.target
    uguale "l'attesa della rete di NetworkManager è come prima" "$(atteso ATTESA_RETE)" "$(systemctl is-enabled NetworkManager-wait-online.service 2>/dev/null)"
}

p_09_pulizia() {
    local u d f resti=()
    pulizia
    for u in lab-app.service lab-report.service lab-report.timer; do
        uguale "systemd non conosce più $u (nemmeno come fallita)" "not-found inactive" "$(proprieta "$u" LoadState) $(systemctl is-active "$u")"
        for d in /etc/systemd/system /run/systemd/system /usr/local/lib/systemd/system; do
            [[ -e $d/$u || -d $d/$u.d ]] && resti+=("$d/$u")
        done
        while IFS= read -r f; do resti+=("$f"); done < <(find /etc/systemd/system -mindepth 2 -name "$u" 2>/dev/null)
    done
    uguale "nessun file delle tre unità, né collegamenti nei .wants" "" "${resti[*]}"
    uguale "crond: i ritocchi locali sono quelli di prima della lezione" "$(paste -sd' ' "$BASE/servizi/crond.locali" 2>/dev/null)" "$(ritocchi_crond | paste -sd' ' -)"
    uguale "systemd ha riletto i file" no "$(proprieta crond.service NeedDaemonReload)"
    uguale "il crond che gira adesso ha la priorità normale" 0 "$(ps -o ni= -p "$(proprieta crond.service MainPID)" 2>/dev/null | tr -d ' ')"
    uguale "e nessun limite di memoria" max "$(cat "/sys/fs/cgroup$(proprieta crond.service ControlGroup)/memory.max" 2>/dev/null)"
}
ritocchi_crond() {
    local d
    for d in /etc/systemd/system/crond.service /etc/systemd/system/crond.service.d \
        /etc/systemd/system.control/crond.service.d /run/systemd/system/crond.service \
        /run/systemd/system/crond.service.d /run/systemd/system.control/crond.service.d; do
        if [[ -d $d ]]; then find "$d" -type f; elif [[ -e $d ]]; then echo "$d"; fi
    done
}

# ---- Lezione 10 ----------------------------------------------------------------------

WEB=$BASE/web
SONDA=lab-sonda
ASCOLTATORI=()

codice_http() { curl -s -m 5 -o /dev/null -w '%{http_code}' "$1" 2>/dev/null; }
# La pagina risponde 200 con il contenuto atteso (hash sha256).
pagina_giusta() {
    local tmp c
    tmp=$(mktemp)
    c=$(curl -s -m 5 -o "$tmp" -w '%{http_code}' "$1" 2>/dev/null)
    [[ $c == 200 && $(sha256sum <"$tmp" | cut -d' ' -f1) == "$2" ]]
    c=$?
    rm -f "$tmp"
    return "$c"
}
zona_di_rete() {
    local i
    i=$(ip -4 route show default | awk '{ for (k = 1; k < NF; k++) if ($k == "dev") { print $(k + 1); exit } }')
    firewall-cmd --get-zone-of-interface="$i" 2>/dev/null || firewall-cmd --get-default-zone
}
zone_firewall() { firewall-cmd "$@" --list-all-zones 2>/dev/null | grep -v '^[[:space:]]*interfaces:' | sed -E 's/ \((active|default)\)//g'; }
firewall_coerente() { [[ $(zone_firewall) == "$(zone_firewall --permanent)" ]]; }
# aperto ZONA SERVIZIO PORTA [--permanent]: la zona fa passare il servizio, o la sua porta.
aperto() {
    firewall-cmd ${4:+"$4"} --zone="$1" --query-service="$2" >/dev/null 2>&1 ||
        firewall-cmd ${4:+"$4"} --zone="$1" --query-port="$3" >/dev/null 2>&1
}
chiuso() { ! aperto "$@"; }
ssh_aperto() { firewall-cmd -q --zone="$1" --query-service=ssh && firewall-cmd -q --permanent --zone="$1" --query-service=ssh; }
in_ascolto() { ss -Hltn "sport = :$1" 2>/dev/null | grep -q .; }
# Servizi e porte della zona, senza quelli del sito.
aperti_tranne_sito() {
    local s p
    s=$(firewall-cmd --permanent --zone="$1" --list-services | tr ' ' '\n' | grep -vx http | sort | paste -sd' ' -)
    p=$(firewall-cmd --permanent --zone="$1" --list-ports | tr ' ' '\n' | grep -vx 80/tcp | sort | paste -sd' ' -)
    echo "servizi: $s; porte: $p"
}

# La sonda: una rete finta dietro il firewall, in uno spazio dei nomi di rete, con due reti
# di partenza (192.0.2.0/24 e 198.51.100.0/24). Entra dalla stessa zona della scheda vera.
sonda_apri() {
    sonda_chiudi
    trap sonda_chiudi EXIT
    ip netns add "$SONDA" 2>/dev/null &&
        ip link add lab-s0 type veth peer name lab-s1 netns "$SONDA" 2>/dev/null &&
        ip addr add 192.0.2.1/24 dev lab-s0 && ip addr add 198.51.100.1/24 dev lab-s0 &&
        ip link set lab-s0 up &&
        ip -n "$SONDA" addr add 192.0.2.2/24 dev lab-s1 && ip -n "$SONDA" addr add 198.51.100.2/24 dev lab-s1 &&
        ip -n "$SONDA" link set lab-s1 up && ip -n "$SONDA" link set lo up &&
        firewall-cmd -q --zone="$1" --add-interface=lab-s0 2>/dev/null &&
        sleep 1
}
# Perché la sonda non è partita: senza firewalld la scheda finta non entra in nessuna zona.
sonda_non_parte() {
    if [[ $(systemctl is-active firewalld) != active ]]; then
        boccia "la prova da fuori" "firewalld è spento: la prova da fuori non si può fare"
    else
        boccia "la prova da fuori" "non riesco a preparare la rete di prova (ip netns, veth)"
    fi
}
sonda_chiudi() {
    local z p
    for p in "${ASCOLTATORI[@]}"; do kill "$p" 2>/dev/null; done
    ASCOLTATORI=()
    z=$(firewall-cmd --get-zone-of-interface=lab-s0 2>/dev/null) && firewall-cmd -q --zone="$z" --remove-interface=lab-s0 2>/dev/null
    ip link del lab-s0 2>/dev/null
    ip netns del "$SONDA" 2>/dev/null
    return 0
}
# arriva RETE PORTA: dalla rete (192.0.2 o 198.51.100) si apre una connessione TCP.
arriva() { ip netns exec "$SONDA" timeout 4 bash -c "exec 3<>/dev/tcp/$1.1/$2" 2>/dev/null; }
non_arriva() { ! arriva "$@"; }
ssh_da_entrambe() { arriva 192.0.2 22 && arriva 198.51.100 22; }
risponde_da() { [[ $(ip netns exec "$SONDA" curl -s -m 5 -o /dev/null -w '%{http_code}' "http://$1.1:$2/" 2>/dev/null) == 200 ]]; }
# Qualcuno in ascolto sulla porta, perché "chiusa" voglia dire chiusa dal firewall.
ascolta() {
    in_ascolto "$1" && return 0
    python3 -c 'import socket, sys, time
s = socket.socket()
s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
s.bind(("0.0.0.0", int(sys.argv[1])))
s.listen(8)
time.sleep(120)' "$1" 2>/dev/null &
    ASCOLTATORI+=($!)
    aspetta 5 in_ascolto "$1"
}

serve_lezione_10() { serve_comandi firewall-cmd semanage semodule matchpathcon restorecon getsebool curl ss ip python3; }

enforcing() {
    uguale "SELinux è enforcing adesso" Enforcing "$(getenforce)"
    uguale "e lo sarà dopo il riavvio (/etc/selinux/config)" enforcing "$(valore_di /etc/selinux/config SELINUX)"
    vero "e la riga del kernel non lo spegne" test -z "$(tr ' ' '\n' </proc/cmdline | grep -xE 'selinux=0|enforcing=0')"
}
moduli_nuovi() { semodule -lfull 2>/dev/null | awk '$1 == 400 { print $2 }' | grep -vxF -f "$WEB/selinux/moduli" | paste -sd' ' -; }
tipo_httpd() { ps -C httpd -o label= 2>/dev/null | cut -d: -f3 | sort -u | paste -sd' ' -; }
apache_confinato() {
    uguale "httpd è attivo" active "$(systemctl is-active httpd)"
    uguale "e gira confinato, nel dominio httpd_t" httpd_t "$(tipo_httpd)"
    uguale "nessun modulo di politica locale nuovo (audit2allow, domini permissive)" "" "$(moduli_nuovi)"
}
# Il tipo SELinux del file, e quello che la politica gli darebbe.
tipo_di() { stat -c %C "$1" 2>/dev/null | cut -d: -f3; }
tipo_previsto() { matchpathcon -n "$1" 2>/dev/null | cut -d: -f3; }
leggibile() { [[ $1 == httpd_sys_content_t || $1 == httpd_sys_ro_content_t || $1 == public_content_t ]]; }

p_10_1() {
    serve_lezione_10
    local z
    z=$(atteso ZONA)
    uguale "firewalld è attivo" active "$(systemctl is-active firewalld)"
    uguale "e parte all'avvio" enabled "$(systemctl is-enabled firewalld 2>/dev/null)"
    uguale "la zona predefinita non è cambiata" "$(atteso ZONA_PREDEFINITA)" "$(firewall-cmd --get-default-zone)"
    uguale "la scheda di rete è ancora nella zona $z" "$z" "$(zona_di_rete)"
    vero "configurazione attiva e permanente coincidono" firewall_coerente
    vero "il sito (http, 80/tcp) è aperto adesso" aperto "$z" http 80/tcp
    vero "e nella configurazione permanente" aperto "$z" http 80/tcp --permanent
    vero "la 3306 è chiusa adesso" chiuso "$z" mysql 3306/tcp
    vero "e nella configurazione permanente" chiuso "$z" mysql 3306/tcp --permanent
    vero "SSH è aperto adesso e nella configurazione permanente" ssh_aperto "$z"
    uguale "nient'altro di aperto: servizi e porte di prima, più il sito" "servizi: $(atteso SERVIZI); porte: $(atteso PORTE)" "$(aperti_tranne_sito "$z")"
    uguale "l'obiettivo della zona non è cambiato" "$(atteso OBIETTIVO)" "$(firewall-cmd --permanent --zone="$z" --get-target)"
    uguale "le regole ricche non sono cambiate" "$(atteso REGOLE)" "$(firewall-cmd --permanent --zone="$z" --list-rich-rules | sha256sum | cut -c1-16)"
    uguale "le sorgenti della zona non sono cambiate" "$(atteso SORGENTI)" "$(firewall-cmd --permanent --zone="$z" --list-sources)"
    if sonda_apri "$z"; then
        ascolta 3306
        vero "da fuori il sito risponde" risponde_da 192.0.2 80
        vero "da fuori la 3306 non si raggiunge (anche con qualcuno in ascolto)" non_arriva 192.0.2 3306
        vero "da fuori SSH si raggiunge" arriva 192.0.2 22
    else
        sonda_non_parte
    fi
    sonda_chiudi
}

p_10_2() {
    serve_lezione_10
    local h f male=() tipi=() d
    enforcing
    apache_confinato
    while read -r h f; do
        f=${f#./}
        pagina_giusta "http://127.0.0.1/$f" "$h" || male+=("$f")
    done <"$STATO/l10/p2.manifest"
    uguale "tutte le pagine rispondono 200, con il loro contenuto" "" "${male[*]}"
    while IFS= read -r f; do
        leggibile "$(tipo_di "$f")" || tipi+=("${f#/srv/web/sito/}:$(tipo_di "$f")")
    done < <(find /srv/web/sito 2>/dev/null)
    uguale "file e cartelle del sito hanno un tipo SELinux che Apache può leggere" "" "${tipi[*]}"
    d=/srv/web/sito/nuova/cartella/pagina.html
    vero "la politica lo dà anche ai file che arriveranno ($d: $(tipo_previsto "$d"))" leggibile "$(tipo_previsto "$d")"
    uguale "le etichette sono quelle della politica: restorecon non cambierebbe niente" "" "$(restorecon -R -n -v /srv/web 2>/dev/null)"
    uguale "niente di scrivibile da tutti" "" "$(find /srv/web/sito -perm -o+w 2>/dev/null | paste -sd' ' -)"
    uguale "niente di proprietà di apache, né scrivibile dal suo gruppo" "" "$(find /srv/web/sito \( -user apache -o -group apache -perm -g+w \) 2>/dev/null | paste -sd' ' -)"
}

# La porta ha il tipo http_port_t fra le personalizzazioni locali (semanage port -l -C).
porta_web() {
    semanage port -l -C 2>/dev/null | awk -v p="$1" '$1 == "http_port_t" && $2 == "tcp" {
        for (i = 3; i <= NF; i++) { v = $i; gsub(",", "", v); n = split(v, r, "-")
            if ((n == 1 && r[1] == p) || (n == 2 && p >= r[1] + 0 && p <= r[2] + 0)) ok = 1 } }
        END { exit !ok }'
}

p_10_3() {
    serve_lezione_10
    local z
    z=$(atteso ZONA)
    enforcing
    apache_confinato
    vero "ascolta sulla 80" in_ascolto 80
    vero "e sulla 8081" in_ascolto 8081
    uguale "il sito sulla 80 risponde" 200 "$(codice_http http://127.0.0.1/)"
    vero "la console sulla 8081 risponde con la sua pagina" pagina_giusta http://127.0.0.1:8081/ "$(awk '{ print $1; exit }' "$STATO/l10/p3.manifest")"
    vero "per la politica di SELinux la 8081 è una porta da server web (semanage port)" porta_web 8081
    uguale "firewalld è attivo" active "$(systemctl is-active firewalld)"
    uguale "e parte all'avvio" enabled "$(systemctl is-enabled firewalld 2>/dev/null)"
    vero "configurazione attiva e permanente coincidono" firewall_coerente
    if sonda_apri "$z"; then
        vero "dalla rete del monitoraggio la console risponde" risponde_da 192.0.2 8081
        vero "da un'altra rete la console non si raggiunge" non_arriva 198.51.100 8081
        vero "il sito sulla 80 risponde dalla rete del monitoraggio" risponde_da 192.0.2 80
        vero "e da un'altra rete" risponde_da 198.51.100 80
        vero "SSH si raggiunge da entrambe, come prima" ssh_da_entrambe
    else
        sonda_non_parte
    fi
    sonda_chiudi
}

BOOLEANI=""
# booleano NOME: valore adesso e valore permanente, come li mostra semanage.
booleano() {
    [[ -n $BOOLEANI ]] || BOOLEANI=$(semanage boolean -l 2>/dev/null)
    awk -v b="$1" '$1 == b { gsub(/[(),]/, " "); print $2, $3 }' <<<"$BOOLEANI"
}
# I booleani di Apache il cui valore di adesso sparirebbe al riavvio.
booleani_provvisori() {
    [[ -n $BOOLEANI ]] || BOOLEANI=$(semanage boolean -l 2>/dev/null)
    awk '$1 ~ /^httpd_/ { gsub(/[(),]/, " "); if ($2 != $3) print $1 }' <<<"$BOOLEANI" | paste -sd' ' -
}

p_10_4() {
    serve_lezione_10
    enforcing
    apache_confinato
    uguale "il backend è attivo" active "$(systemctl is-active lab-backend.service)"
    vero "/api/listino.json risponde attraverso Apache, con il listino" pagina_giusta http://127.0.0.1/api/listino.json "$(atteso SHA_LISTINO)"
    uguale "Apache non può collegarsi a porte qualsiasi (httpd_can_network_connect, adesso e permanente)" "off off" "$(booleano httpd_can_network_connect)"
    uguale "né ai database (httpd_can_network_connect_db)" "off off" "$(booleano httpd_can_network_connect_db)"
    uguale "nessun booleano di Apache cambiato solo fino al riavvio" "" "$(booleani_provvisori)"
}

# I booleani di Apache il cui valore, adesso o permanente, non è quello della fotografia.
booleani_cambiati() {
    [[ -n $BOOLEANI ]] || BOOLEANI=$(semanage boolean -l 2>/dev/null)
    awk 'NR == FNR { b[$1] = $3; next } $1 ~ /^httpd_/ && ($1 in b) { gsub(/[(),]/, " "); if ($2 != b[$1] || $3 != b[$1]) print $1 }' \
        "$WEB/selinux/booleani" - <<<"$BOOLEANI" | paste -sd' ' -
}

p_10_pulizia() {
    serve_lezione_10
    pulizia
    uguale "Apache acceso o spento come prima della lezione" "$(cat "$WEB/httpd/attivo" 2>/dev/null)" "$(systemctl is-active httpd)"
    uguale "e all'avvio come prima" "$(cat "$WEB/httpd/abilitato" 2>/dev/null)" "$(systemctl is-enabled httpd 2>/dev/null)"
    uguale "nessuna configurazione del sito in conf.d" "" "$(find /etc/httpd/conf.d -name 'lab-*.conf' | paste -sd' ' -)"
    uguale "lab-backend.service non c'è più" "not-found inactive" "$(proprieta lab-backend.service LoadState) $(systemctl is-active lab-backend.service)"
    vero "firewall: configurazione attiva e permanente coincidono" firewall_coerente
    if diff -q <(zone_firewall --permanent) "$STATO/l10/ppulizia.zone" >/dev/null 2>&1; then
        passa "la configurazione permanente del firewall è com'era prima della lezione"
    else
        boccia "la configurazione permanente del firewall è com'era prima della lezione" "$(diff "$STATO/l10/ppulizia.zone" <(zone_firewall --permanent) | grep '^[<>]' | head -8)"
    fi
    uguale "SELinux: regole delle etichette, porte e altre personalizzazioni come prima (semanage export)" "" \
        "$(diff <(grep -v '^boolean ' "$WEB/selinux/export") <(semanage export 2>/dev/null | grep -v '^boolean ') | grep '^[<>]' | paste -sd' ' -)"
    uguale "i booleani di Apache come prima, adesso e in modo permanente" "" "$(booleani_cambiati)"
    # G13: «sempre enforcing» vuol dire anche dopo il riavvio, come nella 10 2-4 e nella 11 1
    enforcing
}

# ---- Lezione 11: progetto finale ---------------------------------------------------------

avvio_senza_soccorso() { mai_raggiunto emergency.target && mai_raggiunto rescue.target; }
sezione() { printf '\n  — %s\n' "$1"; }
falliti() { systemctl list-units --failed --plain --no-legend 2>/dev/null | awk '{ print $1 }' | paste -sd' ' -; }
# Le righe di /etc/fstab che non trovano il loro dispositivo.
righe_orfane() {
    local f1 s
    righe_fstab | while read -r f1 _; do
        case ${f1//\"/} in
            UUID=* | LABEL=* | PARTUUID=* | PARTLABEL=* | /dev/*) ;;
            *) continue ;;
        esac
        s=$(sorgente_reale "$f1")
        [[ -n $s && -b $s ]] || echo "$f1"
    done | paste -sd' ' -
}
# La swap attiva che viene dai bersagli, in MiB. /proc/swaps non conta la prima pagina,
# che è l'intestazione della swap: una partizione da 512 MiB lì risulta 4 KiB in meno.
swap_sui_bersagli() {
    local dev kib d tot=0
    while read -r dev kib; do
        for d in $(tutti_i_bersagli); do
            if antenati "$dev" | grep -qx -- "$d"; then tot=$((tot + kib + 4)); break; fi
        done
    done < <(awk 'NR > 1 { print $1, $3 }' /proc/swaps)
    echo $((tot / 1024))
}
# Ogni swap attiva dai bersagli ha la sua riga in fstab.
swap_da_fstab() {
    local dev d
    while read -r dev; do
        for d in $(tutti_i_bersagli); do
            antenati "$dev" | grep -qx -- "$d" || continue
            [[ -n $(fstab_swap_per "$(realpath "$dev")") ]] || return 1
        done
    done < <(awk 'NR > 1 { print $1 }' /proc/swaps)
    return 0
}
# Il filesystem occupa almeno il 95% del volume.
fs_riempie_lv() {
    local fs lv
    fs=$(dim_fs /srv/dati)
    lv=$(lv_campo vgdati/dati lv_size)
    [[ $fs -gt 0 && $lv -gt 0 ]] && ((fs * 100 >= lv * 95))
}
avvio_precedente_salvato() {
    local id
    while read -r id _; do
        [[ -n $id && $id != "$(avvio_attuale)" ]] && return 0
    done < <(avvii_dopo "$(atteso T0)")
    return 1
}
pagine_sito() {
    local h f male=()
    while read -r h f; do
        f=${f#./}
        pagina_giusta "http://127.0.0.1/$f" "$h" || male+=("$f")
    done <"$STATO/l11/sito.manifest"
    echo "${male[*]}"
}

p_11_1() {
    local buono finto z d2 mib
    serve_lezione_10
    buono=$(atteso KERNEL_BUONO)
    finto=$(atteso KERNEL_FINTO)
    z=$(atteso ZONA)
    d2=$(parte "$(disco D2)" 1)

    sezione "L'avvio"
    vero "la macchina è stata riavviata dopo la preparazione" riavviato
    uguale "gira con il kernel di prima" "$buono" "$(uname -r)"
    uguale "che è il predefinito per GRUB" "$(atteso VOCE_BUONA)" "$(voce_predefinita)"
    uguale "e per grubby" "/boot/vmlinuz-$buono" "$(grubby --default-kernel 2>/dev/null)"
    vero "i file del kernel rotto non ci sono più" test ! -e "/boot/vmlinuz-$finto" -a ! -e "/boot/initramfs-$finto.img"
    vero "e nemmeno la sua voce nel menu" test ! -e "$VOCI/$(atteso VOCE_FINTA).conf"
    vero "questo avvio non è passato né da emergency né da rescue" avvio_senza_soccorso
    uguale "l'avvio è arrivato in fondo (systemctl is-system-running)" running "$(systemctl is-system-running 2>/dev/null)"
    uguale "nessuna unità fallita" "" "$(falliti)"

    sezione "I dischi"
    montato_da_fstab /srv/dati vgdati dati
    montato_da_fstab /srv/web vgdati web
    montato_da_fstab_part /srv/log "$d2"
    uguale "ogni riga di /etc/fstab trova il suo dispositivo" "" "$(righe_orfane)"
    vero "i dati di /srv/dati sono intatti" ha_tutti_i_file /srv/dati/archivio "$STATO/l11/dati.manifest" "$(cat "$STATO/l11/dati.quanti" 2>/dev/null)"
    vero "i log di /srv/log sono intatti" ha_tutti_i_file /srv/log "$STATO/l11/log.manifest" "$(cat "$STATO/l11/log.quanti" 2>/dev/null)"
    vero "il volume dei dati è ancora ingrandito" test "$(lv_campo vgdati/dati lv_size)" -ge "$(atteso LV_DATI)"
    vero "e /srv/dati ne usa tutto lo spazio ($(($(dim_fs /srv/dati) / MIB)) MiB su $(($(lv_campo vgdati/dati lv_size) / MIB)))" fs_riempie_lv

    sezione "La swap"
    mib=$(swap_sui_bersagli)
    vero "almeno 512 MiB di swap attiva da un disco dedicato (adesso: $mib MiB)" test "$mib" -ge 512
    vero "e ognuna è scritta in /etc/fstab, quindi torna a ogni avvio" swap_da_fstab

    sezione "I servizi"
    uguale "lab-app non è più mascherata" loaded "$(proprieta "$APP" LoadState)"
    uguale "parte a ogni avvio" enabled "$(systemctl is-enabled "$APP" 2>/dev/null)"
    uguale "è attiva" active "$(systemctl is-active "$APP")"
    vero "e risponde" risponde_app
    vero "il journal si salva su disco" journal_su_disco
    vero "e conserva l'avvio prima di questo" avvio_precedente_salvato

    sezione "Il sito"
    enforcing
    apache_confinato
    uguale "tutte le pagine rispondono 200, con il loro contenuto" "" "$(pagine_sito)"
    uguale "le etichette sono quelle della politica: restorecon non cambierebbe niente" "" "$(restorecon -R -n -v /srv/web 2>/dev/null)"
    vero "e la regola di /srv/web è ancora nella politica" leggibile "$(tipo_previsto /srv/web/sito/nuova-pagina.html)"
    vero "firewall: configurazione attiva e permanente coincidono" firewall_coerente
    vero "il sito è aperto nella configurazione permanente della zona $z" aperto "$z" http 80/tcp --permanent
    if sonda_apri "$z"; then
        vero "da fuori il sito risponde" risponde_da 192.0.2 80
        vero "da fuori SSH si raggiunge" arriva 192.0.2 22
    else
        sonda_non_parte
    fi
    sonda_chiudi
}

p_11_pulizia() {
    serve_lezione_10
    pulizia
    vero "lab-app è ferma" test "$(systemctl is-active "$APP")" != active
    vero "e non parte all'avvio" test "$(systemctl is-enabled "$APP" 2>/dev/null)" != enabled
    uguale "Apache acceso o spento come prima del progetto" "$(cat "$WEB/httpd/attivo" 2>/dev/null)" "$(systemctl is-active httpd)"
    uguale "e all'avvio come prima" "$(cat "$WEB/httpd/abilitato" 2>/dev/null)" "$(systemctl is-enabled httpd 2>/dev/null)"
    uguale "nessuna configurazione del sito in conf.d" "" "$(find /etc/httpd/conf.d -name 'lab-*.conf' | paste -sd' ' -)"
    vero "firewall: configurazione attiva e permanente coincidono" firewall_coerente
    if diff -q <(zone_firewall --permanent) "$STATO/l11/ppulizia.zone" >/dev/null 2>&1; then
        passa "la configurazione permanente del firewall è com'era prima del progetto"
    else
        boccia "la configurazione permanente del firewall è com'era prima del progetto" "$(diff "$STATO/l11/ppulizia.zone" <(zone_firewall --permanent) | grep '^[<>]' | head -8)"
    fi
    uguale "SELinux: regole delle etichette, porte e altre personalizzazioni come prima (semanage export)" "" \
        "$(diff <(grep -v '^boolean ' "$WEB/selinux/export") <(semanage export 2>/dev/null | grep -v '^boolean ') | grep '^[<>]' | paste -sd' ' -)"
    # G13: «sempre enforcing» vuol dire anche dopo il riavvio, come nella 10 2-4 e nella 11 1
    enforcing
}

# ---- Pulizia ---------------------------------------------------------------------------

pulizia() {
    local d t s
    for d in $(tutti_i_bersagli); do
        vero "$d non ha partizioni per il kernel" test -z "$(lsblk -nrpo NAME,TYPE "$d" | awk '$2 == "part"')"
        vero "$d non ha tabelle sul disco" test -z "$(tab "$d")"
        vero "$d non ha firme (blkid -p)" test -z "$(blkid -p -o export "$d" 2>/dev/null)"
        # blkid -p e sfdisk cercano la GPT solo se c'è il PMBR: dopo un dd sul primo MiB la riserva in fondo
        # al disco resta, e gdisk o parted la usano per rifare la tabella. wipefs la cerca anche senza PMBR.
        vero "$d non ha firme che wipefs vede (anche la GPT di riserva)" test -z "$(wipefs --noheadings "$d" 2>/dev/null)"
        vero "$d non ha volumi LVM attivi sopra" test -z "$(lsblk -nrpo NAME,TYPE "$d" | awk '$2 == "lvm"')"
    done
    local montati=()
    while read -r t s; do
        s=${s%%[*}
        [[ $s == /dev/* ]] || continue
        for d in $(tutti_i_bersagli); do antenati "$s" | grep -qx -- "$d" && montati+=("$t"); done
    done < <(findmnt -rn -o TARGET,SOURCE)
    uguale "niente di montato dai bersagli" "" "${montati[*]}"
    uguale "nessun servizio del kit attivo" "" "$(systemctl list-units --state=active --plain --no-legend 'lab-occupa-*' | awk '{ print $1 }' | paste -sd' ' -)"
    if diff -q <(grep -Ev '^[[:space:]]*(#|$)' "$BASE/fstab") <(grep -Ev '^[[:space:]]*(#|$)' /etc/fstab) >/dev/null; then
        passa "/etc/fstab è come al momento dell'inventario"
    else
        boccia "/etc/fstab è come al momento dell'inventario" "$(diff <(grep -Ev '^[[:space:]]*(#|$)' "$BASE/fstab") <(grep -Ev '^[[:space:]]*(#|$)' /etc/fstab))"
    fi
    local swap=() p
    while read -r s; do
        if [[ -b $s ]]; then
            for d in $(tutti_i_bersagli); do antenati "$s" | grep -qx -- "$d" && swap+=("$s"); done
        else
            for p in "${PUNTI_KIT[@]}"; do [[ $s == "$p"/* ]] && swap+=("$s"); done
        fi
    done < <(awk 'NR > 1 { print $1 }' /proc/swaps)
    uguale "nessuna swap attiva dai bersagli" "" "${swap[*]}"
    vero "systemd ha riletto /etc/fstab" systemd_aggiornato
    local pv=() v
    while read -r v; do
        [[ $v == /dev/* ]] || continue
        for d in $(tutti_i_bersagli); do antenati "$v" | grep -qx -- "$d" && pv+=("$v"); done
    done < <(pvs --devicesfile "" --noheadings -o pv_name 2>/dev/null)
    uguale "nessun PV di LVM sui bersagli" "" "${pv[*]}"
    local righe=()
    for d in $(tutti_i_bersagli); do
        [[ -n $(righe_dispositivi_di "$d") ]] && righe+=("$d")
    done
    uguale "LVM non cerca più i bersagli (file dei dispositivi)" "" "${righe[*]}"
    # G6: le firme restano dove stavano le partizioni anche senza tabella: rifatta la tabella,
    # il filesystem (o il PV) ricompare. prepara.sh ha annotato dove cominciavano.
    local n o rimaste=()
    for d in $(tutti_i_bersagli); do
        n=$(nome_bersaglio "$d")
        for o in $(atteso "INIZI_$n"); do
            [[ -z $(blkid -p -O $((o * 512)) -o export "$d" 2>/dev/null) ]] || rimaste+=("$d dal settore $o")
        done
    done
    uguale "nessuna firma dove stavano le partizioni (blkid -p -O)" "" "$(IFS=,; echo "${rimaste[*]}")"
    # G5: la swap del sistema non viene dai bersagli, e la pulizia la lascia accesa.
    local w spente=()
    for w in $(atteso SWAP_SISTEMA); do
        awk 'NR > 1 { print $1 }' /proc/swaps | xargs -r -n1 readlink -f -- | grep -qxF -- "$w" || spente+=("$w")
    done
    uguale "la swap del sistema è ancora accesa (il disco di sistema non si tocca)" "" "${spente[*]}"
}
p_01_pulizia() { pulizia; }
p_02_pulizia() { pulizia; }
p_03_pulizia() { pulizia; }
p_04_pulizia() { pulizia; }
p_05_pulizia() { pulizia; }
p_06_pulizia() { pulizia; }
p_07_pulizia() { pulizia; }

# ---- Avvio -----------------------------------------------------------------------------

registra() { printf '%s %s %s %s\n' "$1" "$2" "$3" "$(date +%F_%H:%M)" >>"$ESITI"; }

stato() {
    echo "Esiti registrati ($ESITI). ✅ passa  ❌ non passa  · mai verificato"
    local n p e riga
    for n in "${LEZIONI[@]}"; do
        riga=
        for p in $(declare -F | awk '{ print $3 }' | sed -n "s/^p_${n}_//p" | sort -V); do
            e=$(awk -v n="$n" -v p="$p" '$1 == n && $2 == p { e = $3 } END { print e }' "$ESITI" 2>/dev/null)
            case $e in passa) e=✅ ;; boccia) e=❌ ;; *) e=· ;; esac
            riga+=" $p$e"
        done
        printf '%s %s\n' "$n" "$riga"
    done
    echo "Preparato ora: $(corrente || echo nessuno)"
}

serve_root
serve_comandi lsblk findmnt blkid sfdisk losetup jq e2fsck debugfs tune2fs dumpe2fs unshare systemctl runuser systemd-escape systemd-analyze xfs_repair pvs vgs lvs lvmdevices \
    journalctl grubby grub2-editenv ss rpm
[[ -s $BERSAGLI ]] || { echo "Manca l'inventario: lancia prima sudo ./prepara.sh dischi" >&2; exit 2; }

if [[ ${1:-} == stato ]]; then stato; exit 0; fi
n=${1:-}
[[ -n $n ]] || { echo "Uso: sudo $0 NN [P] | NN pulizia | stato" >&2; exit 2; }

ricollega_loop
for b in $(bersagli_registrati); do
    p=$(percorso_bersaglio "$b")
    [[ -n $p ]] || { echo "Il bersaglio $b non è collegato." >&2; exit 2; }
    ammesso "$p"
done

read -r cl cp < <(corrente || echo "- -")
pr=${2:-$cp}
if ! declare -F "p_${n}_$pr" >/dev/null; then
    echo "Non c'è un problema $pr nella lezione $n." >&2
    exit 2
fi
if [[ $cl != "$n" || $cp != "$pr" ]]; then
    echo "Il problema preparato ora è «$cl $cp», non «$n $pr». Lancia prima: sudo ./prepara.sh $n $pr" >&2
    exit 2
fi

printf '\n== Lezione %s, problema %s ==\n' "$n" "$pr"
"p_${n}_$pr"
printf '\nPassate: %d   Non passate: %d\n' "$PASSATE" "$FALLITE"
if ((FALLITE == 0)); then registra "$n" "$pr" passa; exit 0; else registra "$n" "$pr" boccia; exit 1; fi
