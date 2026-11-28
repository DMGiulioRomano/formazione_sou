#!/usr/bin/env bash
# Prepara gli scenari delle lezioni Linux sui dischi dedicati della VM.
#
#   sudo ./prepara.sh dischi              inventario dei bersagli, una volta sola
#   sudo ./prepara.sh dischi --loop       bersagli su immagini e dispositivi loop
#   sudo ./prepara.sh NN [P]              azzera i bersagli e prepara il problema P (1 se manca)
#   sudo ./prepara.sh NN pulizia          la macchina com'è a fine lezione, da dismettere a mano
#   sudo ./prepara.sh azzera              riporta i bersagli a dischi vuoti
#   sudo ./prepara.sh stato               bersagli, problema preparato, cosa appartiene al kit
#
# Opzione: --a-secco stampa le scritture invece di eseguirle.
# Codici: 0 fatto, 1 non riuscito, 2 uso o prerequisiti, 3 rifiuto, 4 serve root.
#
# Il kit scrive solo sui bersagli. Prima di ogni scrittura la guardia (lib/comune.sh)
# controlla che il disco sia in inventario per seriale, sia un disco del laboratorio e
# non porti a nulla di montato fuori dai punti del kit. Se un controllo fallisce, si
# ferma con codice 3 senza toccare niente.
set -euo pipefail
shopt -s inherit_errexit

RADICE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=SCRIPTDIR/lib/comune.sh
source "$RADICE/lib/comune.sh"
# shellcheck source=SCRIPTDIR/lib/dati.sh
source "$RADICE/lib/dati.sh"
PALESTRA=${PALESTRA:-$RADICE/palestra}
LEZIONI=(01 02 03 04 05 06 07 08 09 10 11)
GUID_LINUX=0FC63DAF-8483-4772-8E79-3D69D8477DE4
GUID_DATI_MS=EBD0A0A2-B9E5-4433-87C0-68B6B72699C7

# ---- Inventario ---------------------------------------------------------------

mostra_bersagli() {
    local n tipo id p
    while read -r n tipo id; do
        p=$(percorso_bersaglio "$n")
        printf '  %s  %-8s %-24s oggi: %s\n' "$n" "$tipo" "$id" "${p:-(non collegato)}"
    done <"$BERSAGLI"
}

# Motivo per cui un disco candidato è usato dal sistema; nessun output se è libero.
uso_del_sistema() {
    local disco=$1 t s pv vg
    while read -r t s; do
        s=${s%%[*}
        [[ $s == /dev/* ]] || continue
        punto_del_kit "$t" && continue
        antenati "$s" | grep -qx -- "$disco" && { echo "porta a $t"; return; }
    done < <(findmnt -rn -o TARGET,SOURCE)
    while read -r s; do
        antenati "$s" | grep -qx -- "$disco" && { echo "contiene la swap $s"; return; }
    done < <(awk 'NR > 1 { print $1 }' /proc/swaps)
    if command -v pvs >/dev/null; then
        while read -r pv vg; do
            antenati "$pv" | grep -qx -- "$disco" && { echo "è un PV del VG ${vg:-(nessuno)}"; return; }
        done < <(pvs --devicesfile "" --noheadings -o pv_name,vg_name 2>/dev/null)
    fi
    return 0
}

fotografa_base() {
    mkdir -p "$BASE"
    cp -p /etc/fstab "$BASE/fstab"
    getent passwd | cut -d: -f1 | sort >"$BASE/utenti"
    getent group | cut -d: -f1 | sort >"$BASE/gruppi"
    ls /etc/sysctl.d >"$BASE/sysctl.d" 2>/dev/null || true
    cp -- /etc/sysctl.conf "$BASE/sysctl.conf" 2>/dev/null || true
    sysctl -n vm.swappiness >"$BASE/swappiness"
    if [[ -f $FILE_DISPOSITIVI ]]; then cp -p "$FILE_DISPOSITIVI" "$BASE/system.devices"; fi
}

inventario() {
    local loop=0 rifai=0 scelti="" arg
    for arg; do
        case $arg in
            --loop) loop=1 ;;
            --rifai) rifai=1 ;;
            --seriali=*) scelti=${arg#*=} ;;
            *) errore "Opzione sconosciuta: $arg"; exit 2 ;;
        esac
    done
    if [[ -s $BERSAGLI ]] && ((!rifai)); then
        echo "Inventario già fatto ($BERSAGLI):"
        mostra_bersagli
        echo "Per rifarlo: sudo ./prepara.sh azzera, poi sudo ./prepara.sh dischi --rifai"
        return 0
    fi
    serve_vm
    mkdir -p "$STATO" "$IMMAGINI"
    chmod 700 "$STATO"
    local nuovo=$STATO/bersagli.nuovo
    : >"$nuovo"
    if ((loop)); then
        local n img
        for n in 1 2 3; do
            img=$IMMAGINI/d$n.img
            [[ -f $img ]] || truncate -s 2G "$img"
            [[ -n $(losetup -nO NAME -j "$img") ]] || losetup -f -P "$img"
            echo "D$n loop $img" >>"$nuovo"
        done
    else
        local nome dim modello seriale tipo motivo i=0
        echo "Dischi che potrebbero essere bersagli (modello «$MODELLO», al massimo 16 GiB):"
        while read -r nome dim modello seriale tipo; do
            modello=${modello//_/ }
            [[ $tipo == disk && $modello == "$MODELLO" ]] || continue
            ((dim <= MAX_BYTE)) || { echo "  $nome: troppo grande, lo salto"; continue; }
            motivo=$(uso_del_sistema "$nome")
            if [[ -n $motivo ]]; then
                echo "  $nome  $seriale  di sistema: $motivo. Lo salto."
                continue
            fi
            echo "  $nome  $((dim / MIB)) MiB  seriale $seriale"
            lsblk -no NAME,FSTYPE,LABEL,SIZE "$nome" | sed 's/^/      /'
            if [[ -n $scelti ]]; then
                [[ ,$scelti, == *",$seriale,"* ]] || continue
            else
                local risposta
                read -r -p "      Ultime 4 cifre del seriale per usarlo (tutto verrà cancellato), invio per saltarlo: " risposta </dev/tty
                [[ -n $risposta && $seriale == *"$risposta" ]] || { echo "      saltato"; continue; }
            fi
            i=$((i + 1))
            echo "D$i seriale $seriale" >>"$nuovo"
        done < <(lsblk -J -d -b -p -o NAME,SIZE,MODEL,SERIAL,TYPE | jq -r '.blockdevices[]
            | [.name, (.size | tostring), ((.model // "-") | sub(" +$"; "") | gsub(" "; "_")), (.serial // "-"), .type] | join(" ")')
        if ((i < 2)); then
            rm -f "$nuovo"
            errore "Servono almeno due bersagli (tre per le lezioni su LVM). Aggiungi i dischi alla VM: lab/vm/aggiungi-dischi.sh."
            exit 2
        fi
    fi
    mv "$nuovo" "$BERSAGLI"
    fotografa_base
    echo "Inventario salvato:"
    mostra_bersagli
}

# ---- Azzerare ------------------------------------------------------------------

unita_del_kit() { systemctl list-units --all --plain --no-legend 'lab-occupa-*' 2>/dev/null | awk '{ print $1 }'; }

# Toglie da fstab le righe che citano i bersagli o i punti del kit.
# La riga di fstab con questa sorgente (primo campo) monta qualcosa che non è del kit?
# Vero se la sorgente porta oggi a un dispositivo fuori dai bersagli, se è un filesystem
# senza dispositivo (tmpfs, NFS…) o un bind da fuori dai punti del kit. Una sorgente che
# non porta a niente è il resto di un esercizio: non è di nessuno.
fstab_altrui() {
    local f1=${1//\"/} dev x p
    case $f1 in
        UUID=* | LABEL=* | PARTUUID=* | PARTLABEL=* | /dev/*)
            if [[ $f1 == /dev/* ]]; then
                [[ -b $f1 ]] && dev=$(realpath -- "$f1")
            else
                dev=$(findfs "$f1" 2>/dev/null) || dev=
            fi
            [[ -n $dev ]] || return 1
            for x in $(disco_di "$dev"); do e_bersaglio "$x" || return 0; done
            return 1 ;;
        /*)
            for p in "${PUNTI_KIT[@]}"; do [[ $f1 == "$p"/* ]] && return 1; done
            return 0 ;;
        *) return 0 ;;
    esac
}

# Le righe di fstab su un punto del kit che montano qualcosa di non suo: azzera non le
# toglie (L00 promette di togliere solo le righe del kit e quelle che citano i bersagli),
# ma il kit ha bisogno di quel punto. Si controlla prima di toccare qualsiasi cosa.
fstab_sui_punti_del_kit() {
    local riga f1 f2 altrui=()
    while IFS= read -r riga || [[ -n $riga ]]; do
        [[ $riga =~ ^[[:space:]]*(#|$) ]] && continue
        read -r f1 f2 _ <<<"$riga"
        if punto_del_kit "$f2" && fstab_altrui "$f1"; then altrui+=("$riga"); fi
    done </etc/fstab
    ((${#altrui[@]} == 0)) && return 0
    errore "RIFIUTO: in /etc/fstab ci sono righe tue su punti che servono al kit (${PUNTI_KIT[*]}):"
    printf '    %s\n' "${altrui[@]}" >&2
    errore "Spostale su un altro punto (o commentale) e rilancia. Non ho toccato niente."
    exit 3
}

pulisci_fstab() {
    local id_file=$1 riga f1 f2 tolte=0 nuovo
    nuovo=$(mktemp)
    while IFS= read -r riga || [[ -n $riga ]]; do
        if [[ $riga =~ ^[[:space:]]*(#|$) ]]; then printf '%s\n' "$riga" >>"$nuovo"; continue; fi
        read -r f1 f2 _ <<<"$riga"
        local via=0 chiave valore reale
        # Una riga che il kit ha scritto, ma solo se non porta a un dispositivo fuori dai
        # bersagli: un fstab-kit rovinato (l'UUID di /boot) non toglie righe del sistema.
        if [[ -s $FSTAB_KIT ]] && grep -qxF -- "$f1" "$FSTAB_KIT" && ! fstab_altrui "$f1"; then via=1; fi
        case $f1 in
            UUID=* | PARTUUID=*)
                chiave=${f1%%=*} valore=${f1#*=} valore=${valore//\"/}
                grep -qixF -- "$chiave=$valore" "$id_file" && via=1 ;;
            LABEL=* | PARTLABEL=*)
                # Le etichette distinguono le maiuscole: «backup» non è «BACKUP».
                chiave=${f1%%=*} valore=${f1#*=} valore=${valore//\"/}
                grep -qxF -- "$chiave=$valore" "$id_file" && via=1 ;;
            /dev/*)
                reale=$(realpath -q -- "$f1" || echo "$f1")
                grep -qxF -- "DEV=$reale" "$id_file" && via=1
                grep -qxF -- "DEV=$f1" "$id_file" && via=1 ;;
            /*)
                local p
                for p in "${PUNTI_KIT[@]}"; do [[ $f1 == "$p"/* ]] && via=1; done ;;
        esac
        # Su un punto del kit va via anche la riga che non porta più a niente (il resto di
        # un esercizio); quella che monta qualcosa di altrui resta (vedi fstab_sui_punti_del_kit).
        if ((!via)) && punto_del_kit "$f2" && ! fstab_altrui "$f1"; then via=1; fi
        if ((via)); then
            echo "  tolgo da /etc/fstab: $riga"
            tolte=$((tolte + 1))
        else
            printf '%s\n' "$riga" >>"$nuovo"
        fi
    done </etc/fstab
    if ((tolte > 0)); then
        if ((A_SECCO)); then
            echo "+ (a secco) /etc/fstab non modificato"
        else
            cp -p /etc/fstab "$STATO/fstab.prima-di-azzera.$(date +%Y%m%d-%H%M%S)"
            # Le copie si tengono, ma solo le venti più recenti.
            find "$STATO" -maxdepth 1 -name 'fstab.prima-di-azzera.*' | sort -r | tail -n +21 | xargs -r rm -f
            cat "$nuovo" >/etc/fstab
            systemctl daemon-reload
        fi
    fi
    rm -f "$nuovo"
    if ! diff -q <(grep -Ev '^[[:space:]]*(#|$)' "$BASE/fstab") <(grep -Ev '^[[:space:]]*(#|$)' /etc/fstab) >/dev/null; then
        echo "  Attenzione: /etc/fstab è diverso da quello dell'inventario ($BASE/fstab):"
        diff <(grep -Ev '^[[:space:]]*(#|$)' "$BASE/fstab") <(grep -Ev '^[[:space:]]*(#|$)' /etc/fstab) | sed 's/^/    /' || true
    fi
}

# Utenti e gruppi degli scenari: si tolgono solo quelli registrati dal kit e assenti
# al momento dell'inventario.
COMMENTO_UTENTI="Utente di prova del kit Linux"

# Il file utenti-kit si può rovinare (a mano, copiato da un'altra VM, spento a metà): prima
# di togliere un utente o un gruppo si controlla che abbia la forma di quelli del kit.
# Un nome (non un numero, che getent leggerebbe come UID o GID), assente alla fotografia,
# con un UID o GID da utente normale e, per gli utenti, il commento che il kit gli dà.
id_minimo() { awk -v k="$1" '$1 == k { print $2 }' /etc/login.defs 2>/dev/null | tail -1; }
utente_del_kit() {
    local riga uid commento minimo
    [[ $1 =~ ^[a-z_][a-z0-9_-]*$ ]] || return 1
    ! grep -qxF -- "$1" "$BASE/utenti" 2>/dev/null || return 1
    riga=$(getent passwd "$1") || return 1
    IFS=: read -r _ _ uid _ commento _ <<<"$riga"
    minimo=$(id_minimo UID_MIN)
    [[ $uid =~ ^[0-9]+$ ]] && ((uid >= ${minimo:-1000})) && [[ $commento == "$COMMENTO_UTENTI" ]]
}
gruppo_del_kit() {
    local riga gid minimo
    [[ $1 =~ ^[a-z_][a-z0-9_-]*$ ]] || return 1
    ! grep -qxF -- "$1" "$BASE/gruppi" 2>/dev/null || return 1
    riga=$(getent group "$1") || return 1
    IFS=: read -r _ _ gid _ <<<"$riga"
    minimo=$(id_minimo GID_MIN)
    [[ $gid =~ ^[0-9]+$ ]] && ((gid >= ${minimo:-1000}))
}

# I processi degli utenti del kit (l'applicazione lanciata a mano della lezione 09) tengono
# occupati i punti del kit: si fermano prima di smontare.
ferma_processi_del_kit() {
    [[ -s $UTENTI_KIT ]] || return 0
    local tipo nome
    while read -r tipo nome; do
        [[ $tipo == utente ]] || continue
        getent passwd "$nome" >/dev/null || continue
        utente_del_kit "$nome" || continue  # lo dice togli_utenti_del_kit
        pgrep -u "$nome" >/dev/null || continue
        echo "  fermo i processi dell'utente $nome"
        fai pkill -KILL -u "$nome" || true
        ((A_SECCO)) || sleep 1
    done <"$UTENTI_KIT"
}

togli_utenti_del_kit() {
    [[ -s $UTENTI_KIT ]] || return 0
    local tipo nome
    ferma_processi_del_kit
    while read -r tipo nome; do
        [[ $tipo == utente ]] || continue
        getent passwd "$nome" >/dev/null || continue
        if utente_del_kit "$nome"; then
            echo "  tolgo l'utente $nome"; fai userdel -f "$nome"
        else
            echo "  non tocco l'utente $nome: non ha la forma di un utente del kit"
        fi
    done <"$UTENTI_KIT"
    while read -r tipo nome; do
        [[ $tipo == gruppo ]] || continue
        getent group "$nome" >/dev/null || continue
        if gruppo_del_kit "$nome"; then
            echo "  tolgo il gruppo $nome"; fai groupdel "$nome"
        else
            echo "  non tocco il gruppo $nome: non ha la forma di un gruppo del kit"
        fi
    done <"$UTENTI_KIT"
    ((A_SECCO)) || rm -f "$UTENTI_KIT"
}

gruppo_kit() {
    if getent group "$1" >/dev/null; then
        grep -qxF -- "gruppo $1" "$UTENTI_KIT" 2>/dev/null || rifiuta "esiste già un gruppo $1 che non è del kit."
        return 0
    fi
    fai groupadd "$1"
    ((A_SECCO)) || echo "gruppo $1" >>"$UTENTI_KIT"
}

utente_kit() { # NOME [GRUPPO]
    if getent passwd "$1" >/dev/null; then
        grep -qxF -- "utente $1" "$UTENTI_KIT" 2>/dev/null || rifiuta "esiste già un utente $1 che non è del kit."
        return 0
    fi
    fai useradd -M -s /sbin/nologin -c "$COMMENTO_UTENTI" ${2:+-G "$2"} "$1"
    ((A_SECCO)) || echo "utente $1" >>"$UTENTI_KIT"
}

# La swappiness torna al valore dell'inventario; i file di /etc/sysctl.d creati dopo
# l'inventario che impostano solo vm.swappiness (quelli della lezione 04) si tolgono.
riporta_sysctl() {
    [[ -s $BASE/swappiness && -f $BASE/sysctl.d ]] || return 0
    local f
    for f in /etc/sysctl.d/*.conf; do
        [[ -f $f ]] || continue
        grep -qxF -- "${f##*/}" "$BASE/sysctl.d" && continue
        # Solo se imposta davvero vm.swappiness, e nient'altro: un file di soli commenti è dell'utente.
        if grep -Eq '^[[:space:]]*vm\.swappiness[[:space:]]*=' "$f" &&
            ! grep -Ev '^[[:space:]]*([#;]|$)' "$f" | grep -Evq '^[[:space:]]*vm\.swappiness[[:space:]]*='; then
            echo "  tolgo $f: imposta solo vm.swappiness ed è nato dopo l'inventario"
            fai rm -f "$f"
        fi
    done
    # M20: anche /etc/sysctl.conf, perché /etc/sysctl.d/99-sysctl.conf è un link a lui. Via le
    # righe di vm.swappiness nate dopo l'inventario; il resto è dell'utente e non si tocca.
    # Gli inventari di prima non lo hanno: lo fotografo adesso.
    if [[ -f /etc/sysctl.conf && ! -f $BASE/sysctl.conf ]] && ((!A_SECCO)); then cp -- /etc/sysctl.conf "$BASE/sysctl.conf"; fi
    if [[ -f $BASE/sysctl.conf && -f /etc/sysctl.conf ]]; then
        local t
        t=$(mktemp)
        awk 'NR == FNR { foto[$0] = 1; next }
             !($0 in foto) && /^[[:space:]]*vm\.swappiness[[:space:]]*=/ { print "  tolgo da /etc/sysctl.conf: " $0 > "/dev/stderr"; next }
             { print }' "$BASE/sysctl.conf" /etc/sysctl.conf >"$t" &&
            ! cmp -s "$t" /etc/sysctl.conf && fai cp -- "$t" /etc/sysctl.conf
        rm -f -- "$t"
    fi
    fai sysctl -q -w vm.swappiness="$(cat "$BASE/swappiness")"
}

# ---- Journal e avvio (lezioni 07 e 08) ------------------------------------------------
#
# Le lezioni 07 e 08 cambiano anche la configurazione del journal e dell'avvio. La
# fotografia si fa la prima volta che serve, prima di qualsiasi modifica, e azzera
# riporta indietro solo ciò che fotografa: i file nati dopo, i valori cambiati, il kernel
# finto del kit. I kernel veri installati nel frattempo restano.

# Le parti della macchina fuori dai bersagli che una lezione cambia: «avvio» (il journal,
# il target, GRUB, il kernel finto), «servizi» (crond), «web» (Apache, firewalld, SELinux).
# Ogni parte si fotografa al primo prepara di una lezione che la usa, e azzera la riporta
# alla fotografia solo se da allora è stato preparato un problema di una di quelle lezioni:
# chi configura la macchina per conto suo nelle altre lezioni non perde niente.
DA_RIPORTARE=$STATO/da-riportare   # le parti toccate dai problemi preparati dall'ultimo azzera
parti_della_lezione() {
    case $1 in
        07 | 08) echo avvio ;;
        09) echo servizi ;;
        10) echo avvio web ;;  # la 10 tocca anche il journal
        11) echo avvio servizi web ;;
    esac
}
# Le parti da riportare adesso: quelle registrate, più quelle del problema preparato ora
# (un kit di prima di questo registro non le ha scritte).
parti_da_riportare() {
    local c
    {
        cat "$DA_RIPORTARE" 2>/dev/null || true
        if c=$(corrente); then parti_della_lezione "${c%% *}"; fi
    } | tr ' ' '\n' | sed '/^$/d' | sort -u | paste -sd' ' -
}

# Prima di togliere o sovrascrivere un file fuori dai bersagli, azzera ne tiene una copia,
# con il percorso intero, in $COPIE/<data>/ (le venti più recenti).
COPIE=$STATO/copie
COPIA_ORA=
copia_di_sicurezza() { # [FILE O CARTELLA...]
    ((A_SECCO)) && return 0
    local f
    if [[ -z $COPIA_ORA ]]; then
        COPIA_ORA=$COPIE/$(date +%Y%m%d-%H%M%S)
        mkdir -p "$COPIA_ORA"
        echo "  copia di ciò che tolgo o cambio: $COPIA_ORA"
        find "$COPIE" -mindepth 1 -maxdepth 1 -type d | sort -r | tail -n +21 | xargs -r rm -rf
    fi
    for f; do
        if [[ -e $f || -L $f ]]; then cp -a --parents -- "$f" "$COPIA_ORA/"; fi
    done
    return 0
}

AVVIO=$BASE/avvio
FINTO=$STATO/kernel-finto      # i file del kernel finto della lezione 08, uno per riga
VOCI=/boot/loader/entries
DROPIN_JOURNAL=/etc/systemd/journald.conf.d

fotografa_avvio() {
    [[ -d $AVVIO ]] && return 0
    ((A_SECCO)) && return 0
    mkdir -p "$AVVIO/voci"
    cp -p /etc/systemd/journald.conf "$AVVIO/journald.conf"
    ls "$DROPIN_JOURNAL" >"$AVVIO/journald.d" 2>/dev/null || : >"$AVVIO/journald.d"
    systemctl get-default >"$AVVIO/target"
    cp -p /etc/default/grub "$AVVIO/grub"
    if [[ -f /etc/sysconfig/kernel ]]; then cp -p /etc/sysconfig/kernel "$AVVIO/kernel"; fi
    if [[ -f /etc/kernel/cmdline ]]; then cp -p /etc/kernel/cmdline "$AVVIO/cmdline"; fi
    cp -p /boot/grub2/grub.cfg "$AVVIO/grub.cfg"
    grub2-editenv list >"$AVVIO/grubenv"
    cp -p "$VOCI"/*.conf "$AVVIO/voci/"
}

# Il journal: i file di journald.conf.d nati dopo la fotografia si tolgono, il file
# principale torna com'era, e journald riparte solo se è cambiato qualcosa.
riporta_journald() {
    [[ -f $AVVIO/journald.d ]] || return 0
    local f cambiato=0
    for f in "$DROPIN_JOURNAL"/*.conf; do
        [[ -f $f ]] || continue
        grep -qxF -- "${f##*/}" "$AVVIO/journald.d" && continue
        echo "  tolgo $f: è nato dopo la fotografia del journal"
        copia_di_sicurezza "$f"
        fai rm -f "$f"
        cambiato=1
    done
    if ! cmp -s /etc/systemd/journald.conf "$AVVIO/journald.conf"; then
        echo "  /etc/systemd/journald.conf torna com'era"
        copia_di_sicurezza /etc/systemd/journald.conf
        fai cp -p "$AVVIO/journald.conf" /etc/systemd/journald.conf
        cambiato=1
    fi
    if ((cambiato)); then fai systemctl restart systemd-journald; fi
    return 0
}

# Un file di configurazione torna com'era nella fotografia, o sparisce se allora non c'era.
riporta_file() { # FILE COPIA
    if [[ -f $2 ]]; then
        cmp -s "$1" "$2" && return 1
        echo "  $1 torna com'era"
        copia_di_sicurezza "$1"
        fai cp -p "$2" "$1"
    else
        [[ -e $1 ]] || return 1
        echo "  tolgo $1: alla fotografia non c'era"
        copia_di_sicurezza "$1"
        fai rm -f "$1"
    fi
    return 0
}

voce_del_kernel() { # VERSIONE → file della voce BLS che lo avvia
    awk -v v="$1" '$1 == "linux" && ($2 == "/vmlinuz-" v || $2 == "/boot/vmlinuz-" v) { print FILENAME; exit }' "$VOCI"/*.conf 2>/dev/null
}

# Il kernel installato più recente, fra quelli con i moduli: il kernel finto non ne ha.
kernel_piu_recente() { find /lib/modules -mindepth 1 -maxdepth 1 -printf '%f\n' | sort -V | tail -1; }

riporta_avvio() {
    [[ -d $AVVIO ]] || return 0
    local f v voce base_voce attuale base_target id
    # Il kernel finto della lezione 08.
    if [[ -s $FINTO ]]; then
        echo "  tolgo il kernel finto della lezione 08"
        # Solo file con la forma di quelli del kernel finto: un elenco rovinato non cancella altro.
        while read -r f; do
            case $f in
                /boot/vmlinuz-*[!/] | /boot/initramfs-*.img | "$VOCI"/*.conf)
                    v=$(dirname -- "$f")
                    [[ $f != *..* && ($v == /boot || $v == "$VOCI") ]] && { fai rm -f -- "$f"; continue; } ;;
            esac
            echo "  non tolgo $f: non ha la forma di un file del kernel finto"
        done <"$FINTO"
        ((A_SECCO)) || rm -f "$FINTO"
    fi
    # Il target predefinito, e quello attivo se la lezione l'ha cambiato.
    base_target=$(cat "$AVVIO/target")
    if [[ $(systemctl get-default) != "$base_target" ]]; then
        echo "  il target predefinito torna $base_target"
        fai systemctl set-default -q "$base_target"
    fi
    if [[ $base_target != graphical.target && $(systemctl is-active graphical.target) == active ]]; then
        echo "  torno a $base_target: graphical.target è attivo"
        fai systemctl isolate "$base_target"
    fi
    # Le opzioni delle voci BLS: quelle fotografate tornano com'erano; dalle voci nate dopo
    # (kernel installati nel frattempo) si tolgono solo i parametri delle lezioni.
    for voce in "$VOCI"/*.conf; do
        [[ -f $voce ]] || continue
        base_voce=$AVVIO/voci/${voce##*/}
        if [[ -f $base_voce ]]; then
            if [[ $(grep '^options' "$voce") != "$(grep '^options' "$base_voce")" ]]; then
                echo "  le opzioni di ${voce##*/} tornano com'erano"
                copia_di_sicurezza "$voce"
                if ((!A_SECCO)); then
                    local tmp
                    tmp=$(mktemp)
                    awk -v o="$(grep '^options' "$base_voce")" '/^options/ { print o; next } { print }' "$voce" >"$tmp"
                    cat "$tmp" >"$voce"
                    rm -f "$tmp"
                fi
            fi
        elif grep -Eq '^options.*[[:space:]](transparent_hugepage=never|systemd\.unit=rescue\.target)([[:space:]]|$)' "$voce"; then
            v=$(awk '$1 == "linux" { sub(".*/vmlinuz-", "", $2); print $2 }' "$voce")
            echo "  tolgo i parametri delle lezioni dalla voce di $v"
            copia_di_sicurezza "$voce"
            fai sed -i -E 's/[[:space:]](transparent_hugepage=never|systemd\.unit=rescue\.target)([[:space:]]|$)/\2/g' "$voce"
        fi
    done
    riporta_file /etc/kernel/cmdline "$AVVIO/cmdline" || true
    riporta_file /etc/sysconfig/kernel "$AVVIO/kernel" || true
    riporta_file /etc/default/grub "$AVVIO/grub" || true
    if ! cmp -s /boot/grub2/grub.cfg "$AVVIO/grub.cfg"; then
        echo "  rigenero /boot/grub2/grub.cfg da /etc/default/grub"
        fai grub2-mkconfig -o /boot/grub2/grub.cfg >/dev/null 2>&1 || errore "  grub2-mkconfig non è riuscito: controlla a mano"
    fi
    # La voce predefinita: torna quella della fotografia se adesso manca o punta a una voce
    # che non c'è più (il kernel finto); i kernel scelti a mano o installati dopo restano.
    attuale=$(grub2-editenv list | sed -n 's/^saved_entry=//p')
    id=$(sed -n 's/^saved_entry=//p' "$AVVIO/grubenv")
    if [[ ! -f $VOCI/$attuale.conf ]] && [[ -n $attuale || -n $id ]]; then
        if [[ -z $id || ! -f $VOCI/$id.conf ]]; then
            voce=$(voce_del_kernel "$(kernel_piu_recente)")
            id=$(basename "$voce" .conf)
        fi
        echo "  la voce predefinita di GRUB torna $id"
        fai grub2-editenv - set "saved_entry=$id"
    fi
    return 0
}

# ---- Servizi, Apache, firewall e SELinux (lezioni 09 e 10) -------------------------------
#
# Le lezioni 09 e 10 toccano unità di systemd, crond, Apache, firewalld e SELinux. Come per
# l'avvio, la fotografia si fa la prima volta che serve, una parte alla volta (Apache solo
# quando è installato, e così via), e azzera riporta indietro solo ciò che fotografa o che
# il kit ha creato. Le unità del kit si riconoscono per nome; i file creati dal kit fuori
# dai bersagli sono elencati in $FILE_KIT.

SERVIZI=$BASE/servizi
WEB=$BASE/web
FILE_KIT=$STATO/file-kit
UNITA_KIT=(lab-app.service lab-report.service lab-report.timer lab-sincro.service lab-backend.service)
DIR_UNITA=(/etc/systemd/system /run/systemd/system /usr/local/lib/systemd/system
    /etc/systemd/system.control /run/systemd/system.control)
# Dove può stare un ritocco locale di crond: drop-in, copie intere, impostazioni di set-property.
DROPIN_CROND=(/etc/systemd/system/crond.service /etc/systemd/system/crond.service.d
    /etc/systemd/system.control/crond.service.d /run/systemd/system/crond.service
    /run/systemd/system/crond.service.d /run/systemd/system.control/crond.service.d)
CROND_FORNITORE=/usr/lib/systemd/system/crond.service

file_kit() { ((A_SECCO)) || echo "$1" >>"$FILE_KIT"; }

# Solo questi percorsi possono essere file del kit. Il percorso deve essere già in forma
# normale (niente «..», «.» o «//») e i nomi con l'asterisco devono stare proprio in quella
# cartella: «/etc/httpd/conf.d/lab-x/../../conf/httpd.conf» non passa.
percorso_del_kit() {
    [[ $1 == "$(realpath -m -s -- "$1")" ]] || return 1
    case $1 in
        /opt/lab-app | /opt/lab-report | /opt/lab-sincro | /opt/lab-backend) return 0 ;;
        /etc/lab-app.conf | /var/lib/lab-report | /var/lib/lab-sincro | /var/lib/lab-backend) return 0 ;;
        /usr/lib/systemd/system/lab-sincro.service | /usr/lib/systemd/system/lab-app.service) return 0 ;;
    esac
    case ${1%/*} in
        /etc/systemd/system) [[ ${1##*/} == lab-*.service || ${1##*/} == lab-*.timer ]] && return 0 ;;
        /etc/httpd/conf.d) [[ ${1##*/} == lab-*.conf ]] && return 0 ;;
    esac
    return 1
}

togli_file_kit() {
    [[ -s $FILE_KIT ]] || return 0
    local f
    while read -r f; do
        if ! percorso_del_kit "$f"; then errore "  non tolgo $f: non è un percorso del kit"; continue; fi
        [[ -e $f || -L $f ]] || continue
        echo "  tolgo $f"
        fai rm -rf -- "$f"
    done < <(sort -u "$FILE_KIT")
    ((A_SECCO)) || rm -f "$FILE_KIT"
    fai systemctl daemon-reload
}

crond_locali() { # i file dei ritocchi locali di crond che ci sono adesso
    local d
    for d in "${DROPIN_CROND[@]}"; do
        if [[ -d $d ]]; then find "$d" -type f; elif [[ -e $d ]]; then echo "$d"; fi
    done
}

fotografa_servizi() {
    [[ -d $SERVIZI ]] && return 0
    ((A_SECCO)) && return 0
    mkdir -p "$SERVIZI"
    crond_locali >"$SERVIZI/crond.locali"
    if [[ -f $CROND_FORNITORE ]]; then cp -p "$CROND_FORNITORE" "$SERVIZI/crond.service"; fi
    systemctl is-active crond >"$SERVIZI/crond.attivo" 2>/dev/null || true
}

# Le connessioni attive di NetworkManager, una per riga: UUID, scheda e zona (vuota = la
# predefinita). Il loopback non ha zona.
zone_delle_connessioni() {
    local uuid dev
    nmcli -t -g UUID,DEVICE connection show --active 2>/dev/null | while IFS=: read -r uuid dev; do
        [[ -n $uuid && $dev != lo ]] || continue
        printf '%s\t%s\t%s\n' "$uuid" "$dev" "$(nmcli -g connection.zone connection show "$uuid" 2>/dev/null)"
    done
}

fotografa_web() {
    ((A_SECCO)) && return 0
    if [[ ! -d $WEB/httpd && -f /etc/httpd/conf/httpd.conf ]]; then
        mkdir -p "$WEB/httpd"
        cp -p /etc/httpd/conf/httpd.conf "$WEB/httpd/httpd.conf"
        ls /etc/httpd/conf.d >"$WEB/httpd/conf.d"
        systemctl is-enabled httpd >"$WEB/httpd/abilitato" 2>/dev/null || true
        systemctl is-active httpd >"$WEB/httpd/attivo" 2>/dev/null || true
    fi
    if [[ ! -d $WEB/firewalld && -d /etc/firewalld ]] && command -v firewall-cmd >/dev/null; then
        mkdir -p "$WEB/firewalld"
        cp -a /etc/firewalld "$WEB/firewalld/etc"
        systemctl is-enabled firewalld >"$WEB/firewalld/abilitato" 2>/dev/null || true
        systemctl is-active firewalld >"$WEB/firewalld/attivo" 2>/dev/null || true
    fi
    # M27: la zona di una scheda gestita da NetworkManager sta nel profilo della connessione,
    # non in /etc/firewalld. Nelle fotografie di prima manca: la prendo adesso.
    if [[ -d $WEB/firewalld && ! -f $WEB/firewalld/zone-nm ]] && command -v nmcli >/dev/null; then
        zone_delle_connessioni >"$WEB/firewalld/zone-nm"
    fi
    if [[ ! -d $WEB/selinux ]] && command -v semanage >/dev/null && selinuxenabled 2>/dev/null; then
        echo "Fotografo la configurazione di SELinux: ci vuole qualche secondo."
        mkdir -p "$WEB/selinux.nuova"
        semanage export >"$WEB/selinux.nuova/export"
        getenforce >"$WEB/selinux.nuova/modo"
        cp -p /etc/selinux/config "$WEB/selinux.nuova/config"
        getsebool -a >"$WEB/selinux.nuova/booleani"
        semodule -lfull | awk '$1 == 400 { print $2 }' >"$WEB/selinux.nuova/moduli"
        mv "$WEB/selinux.nuova" "$WEB/selinux"
    fi
}

# Le unità del kit e le unità transitorie del report: si fermano, si disabilitano e i loro
# file spariscono, dovunque li abbia messi chi ha risolto i problemi.
togli_unita_del_kit() {
    local u d f file trovato=0
    for f in /run/systemd/transient/*; do
        if [[ ! -f $f ]] || ! grep -q 'lab-report' "$f"; then continue; fi
        # M28: il timer che la avvia può avere una descrizione sua, senza «lab-report», e resterebbe attivo.
        for u in $(systemctl show -p TriggeredBy --value "${f##*/}" 2>/dev/null); do
            [[ $(systemctl is-active "$u" 2>/dev/null) == active ]] || continue
            echo "  fermo $u: è il timer che avvia ${f##*/}"
            fai systemctl stop "$u" 2>/dev/null || true
        done
        echo "  fermo ${f##*/}: è un'unità transitoria che lancia il report"
        fai systemctl stop "${f##*/}" 2>/dev/null || true
        trovato=1
    done
    for u in "${UNITA_KIT[@]}"; do
        if [[ $(systemctl is-active "$u" 2>/dev/null) != inactive ]]; then
            echo "  fermo $u"
            fai systemctl stop "$u" 2>/dev/null || true
            trovato=1
        fi
        file=()
        for d in "${DIR_UNITA[@]}"; do
            [[ -e $d/$u || -L $d/$u ]] && file+=("$d/$u")
            [[ -d $d/$u.d ]] && file+=("$d/$u.d")
        done
        while IFS= read -r f; do file+=("$f"); done < <(find /etc/systemd/system -mindepth 2 -name "$u" -type l 2>/dev/null)
        for f in "${file[@]}"; do
            echo "  tolgo $f"
            fai rm -rf -- "$f"
            trovato=1
        done
    done
    # La prova del correttore della lezione 09, se si è interrotta a metà.
    if [[ -d /run/systemd/system/srv-app.mount.d ]]; then
        fai rm -rf /run/systemd/system/srv-app.mount.d
        trovato=1
    fi
    if ((trovato)); then
        fai systemctl daemon-reload
        fai systemctl reset-failed "${UNITA_KIT[@]}" 2>/dev/null || true
    fi
    return 0
}

# crond: i ritocchi locali nati dopo la fotografia si tolgono, il file del pacchetto torna
# com'era, e crond riparte solo se è cambiato qualcosa.
riporta_crond() {
    [[ -f $SERVIZI/crond.locali ]] || return 0
    local f cambiato=0
    while IFS= read -r f; do
        grep -qxF -- "$f" "$SERVIZI/crond.locali" && continue
        echo "  tolgo $f: è un ritocco di crond nato dopo la fotografia"
        copia_di_sicurezza "$f"
        fai rm -f -- "$f"
        cambiato=1
    done < <(crond_locali)
    if [[ -f $SERVIZI/crond.service ]] && ! cmp -s "$CROND_FORNITORE" "$SERVIZI/crond.service"; then
        echo "  $CROND_FORNITORE torna com'era"
        copia_di_sicurezza "$CROND_FORNITORE"
        fai cp -p "$SERVIZI/crond.service" "$CROND_FORNITORE"
        cambiato=1
    fi
    if ((cambiato)); then fai systemctl daemon-reload; fi
    if [[ $(cat "$SERVIZI/crond.attivo" 2>/dev/null) == active ]]; then
        if ((cambiato)) || [[ $(systemctl is-active crond) != active ]]; then riaccendi restart crond; fi
    fi
    return 0
}

# Apache: i file di conf.d nati dopo la fotografia e che non sono di un pacchetto si
# tolgono, httpd.conf torna com'era, e il servizio torna acceso o spento come allora.
riporta_httpd() {
    [[ -d $WEB/httpd ]] || return 0
    local f cambiato=0
    for f in /etc/httpd/conf.d/*; do
        [[ -f $f ]] || continue
        grep -qxF -- "${f##*/}" "$WEB/httpd/conf.d" && continue
        rpm -qf -- "$f" >/dev/null 2>&1 && continue
        echo "  tolgo $f: è nato dopo la fotografia di Apache e non è di un pacchetto"
        copia_di_sicurezza "$f"
        fai rm -f -- "$f"
        cambiato=1
    done
    if riporta_file /etc/httpd/conf/httpd.conf "$WEB/httpd/httpd.conf"; then cambiato=1; fi
    if [[ $(cat "$WEB/httpd/abilitato") == enabled ]]; then
        [[ $(systemctl is-enabled httpd 2>/dev/null) == enabled ]] || { echo "  httpd torna a partire all'avvio"; fai systemctl enable -q httpd; }
    elif [[ $(systemctl is-enabled httpd 2>/dev/null) == enabled ]]; then
        echo "  httpd non parte più all'avvio, come prima"
        fai systemctl disable -q httpd
    fi
    if [[ $(cat "$WEB/httpd/attivo") == active ]]; then
        if ((cambiato)) || [[ $(systemctl is-active httpd) != active ]]; then
            riaccendi restart httpd || errore "  httpd non riparte: controlla a mano (systemctl status httpd)"
        fi
    elif [[ $(systemctl is-active httpd) != inactive ]]; then
        echo "  fermo httpd, che prima era spento"
        fai systemctl stop httpd
        fai systemctl reset-failed httpd 2>/dev/null || true
    fi
    return 0
}

# Le zone come le vede firewalld, senza le interfacce (le assegna NetworkManager) e senza
# i segni di zona attiva: così si confrontano configurazione attiva e permanente.
zone_firewall() { # [--permanent]
    firewall-cmd "$@" --list-all-zones 2>/dev/null | grep -v '^[[:space:]]*interfaces:' | sed -E 's/ \((active|default)\)//g'
}
firewall_coerente() { [[ $(zone_firewall) == "$(zone_firewall --permanent)" ]]; }

# firewalld: /etc/firewalld torna com'era, il servizio acceso o spento come allora, e
# la configurazione attiva si ricarica da quella permanente se le due sono diverse.
# M27: ogni connessione torna nella zona della fotografia. Su una connessione attiva
# NetworkManager passa la zona nuova a firewalld subito.
riporta_zone_nm() {
    [[ -f $WEB/firewalld/zone-nm ]] && command -v nmcli >/dev/null || return 0
    local uuid dev zona ora
    while IFS=$'\t' read -r uuid dev zona; do
        ora=$(nmcli -g connection.zone connection show "$uuid" 2>/dev/null) || continue
        [[ $ora == "$zona" ]] && continue
        echo "  la connessione di $dev torna nella zona «${zona:-predefinita}» (era «$ora», nel profilo di NetworkManager)"
        fai nmcli connection modify "$uuid" connection.zone "$zona"
    done <"$WEB/firewalld/zone-nm"
}

riporta_firewalld() {
    [[ -d $WEB/firewalld ]] || return 0
    local cambiato=0
    if ! diff -qr "$WEB/firewalld/etc" /etc/firewalld >/dev/null 2>&1; then
        echo "  /etc/firewalld torna com'era"
        if ((A_SECCO)); then
            echo "+ (a secco) /etc/firewalld non modificato"
        else
            copia_di_sicurezza /etc/firewalld
            rm -rf /etc/firewalld.kit
            cp -a "$WEB/firewalld/etc" /etc/firewalld.kit
            rm -rf /etc/firewalld
            mv /etc/firewalld.kit /etc/firewalld
            restorecon -R /etc/firewalld 2>/dev/null || true
        fi
        cambiato=1
    fi
    riporta_zone_nm
    if [[ $(cat "$WEB/firewalld/abilitato") == enabled ]]; then
        [[ $(systemctl is-enabled firewalld 2>/dev/null) == enabled ]] || { echo "  firewalld torna a partire all'avvio"; fai systemctl enable -q firewalld; }
    elif [[ $(systemctl is-enabled firewalld 2>/dev/null) == enabled ]]; then
        echo "  firewalld non parte più all'avvio, come prima"
        fai systemctl disable -q firewalld
    fi
    if [[ $(cat "$WEB/firewalld/attivo") == active ]]; then
        if [[ $(systemctl is-active firewalld) != active ]]; then
            echo "  riaccendo firewalld"
            riaccendi start firewalld
        elif ((cambiato)) || ! firewall_coerente; then
            echo "  firewalld ricarica la configurazione permanente"
            fai firewall-cmd -q --reload
        fi
    elif [[ $(systemctl is-active firewalld) == active ]]; then
        echo "  spengo firewalld, che prima era spento"
        fai systemctl stop firewalld
    fi
    return 0
}

# SELinux: via i moduli locali nati dopo la fotografia (audit2allow, semanage permissive),
# le personalizzazioni di semanage come allora, i booleani anche in memoria, la modalità e
# /etc/selinux/config come prima.
riporta_selinux() {
    [[ -d $WEB/selinux ]] || return 0
    selinuxenabled 2>/dev/null || return 0
    local m modo cambi=()
    for m in $(semodule -lfull | awk '$1 == 400 { print $2 }'); do
        grep -qxF -- "$m" "$WEB/selinux/moduli" && continue
        echo "  tolgo il modulo SELinux $m: è un modulo locale nato dopo la fotografia"
        if ((!A_SECCO)); then
            copia_di_sicurezza
            mkdir -p "$COPIA_ORA/selinux"
            (cd "$COPIA_ORA/selinux" && semodule -X 400 -E "$m" >/dev/null 2>&1) || true
        fi
        fai semodule -X 400 -r "$m"
    done
    if [[ $(semanage export) != "$(cat "$WEB/selinux/export")" ]]; then
        echo "  le personalizzazioni di SELinux (semanage) tornano com'erano: ci vuole qualche secondo"
        if ((!A_SECCO)); then
            copia_di_sicurezza
            mkdir -p "$COPIA_ORA/selinux"
            semanage export >"$COPIA_ORA/selinux/semanage.export"
        fi
        fai semanage import -f "$WEB/selinux/export"
    fi
    mapfile -t cambi < <(getsebool -a | awk 'NR == FNR { b[$1] = $3; next } ($1 in b) && b[$1] != $3 { print $1 "=" b[$1] }' "$WEB/selinux/booleani" -)
    if ((${#cambi[@]} > 0)); then
        echo "  i booleani di SELinux tornano come prima: ${cambi[*]}"
        if ((!A_SECCO)); then
            copia_di_sicurezza
            mkdir -p "$COPIA_ORA/selinux"
            getsebool -a >"$COPIA_ORA/selinux/booleani"
        fi
        fai setsebool "${cambi[@]}"
    fi
    riporta_file /etc/selinux/config "$WEB/selinux/config" || true
    modo=$(cat "$WEB/selinux/modo")
    if [[ $modo != Disabled && $(getenforce) != "$modo" ]]; then
        echo "  SELinux torna $modo"
        fai setenforce "$modo"
    fi
    return 0
}

riporta_web() {
    riporta_httpd
    riporta_firewalld
    riporta_selinux
}

# La configurazione di LVM (M25). Una soluzione della 05 4 può spegnere il file dei dispositivi
# (use_devicesfile = 0): LVM lo rinomina allora in system.devices-unused.<data>, e senza file
# il problema 4 non si prepara più. Si riaccende solo se c'era alla fotografia.
riporta_lvm() {
    [[ -f $BASE/system.devices ]] && command -v lvmconfig >/dev/null || return 0
    local u
    if [[ $(lvmconfig --typeconfig full devices/use_devicesfile 2>/dev/null) == *=0 ]]; then
        echo "  riaccendo il file dei dispositivi di LVM (use_devicesfile = 0 in /etc/lvm/lvm.conf)"
        if ((!A_SECCO)); then
            copia_di_sicurezza /etc/lvm/lvm.conf
            sed -i 's/^\([[:space:]]*\)use_devicesfile[[:space:]]*=[[:space:]]*0\b/\1# use_devicesfile = 1/' /etc/lvm/lvm.conf
            [[ $(lvmconfig --typeconfig full devices/use_devicesfile 2>/dev/null) == *=1 ]] ||
                errore "  use_devicesfile vale ancora 0: guarda /etc/lvm/lvm.conf e /etc/lvm/lvmlocal.conf"
        fi
    fi
    if [[ ! -f $FILE_DISPOSITIVI ]]; then
        u=$(find /etc/lvm/devices -maxdepth 1 -name 'system.devices-unused.*' -printf '%T@ %p\n' 2>/dev/null | sort -rn | awk 'NR == 1 { print $2 }')
        echo "  rimetto il file dei dispositivi di LVM (da ${u:-la fotografia})"
        if [[ -n $u ]]; then fai mv -- "$u" "$FILE_DISPOSITIVI"; else fai cp -p -- "$BASE/system.devices" "$FILE_DISPOSITIVI"; fi
        fai restorecon -- "$FILE_DISPOSITIVI" 2>/dev/null || true
    fi
}

# LVM sui bersagli: prima i VG (anche parziali), poi le etichette dei PV rimasti, poi le
# righe del file dei dispositivi. Si guarda con --devicesfile "" per vedere anche i PV
# che il file non elenca; i VG che usano dischi estranei li ha già fermati la guardia.
togli_lvm() {
    command -v pvs >/dev/null || return 0
    local d pv vg riga pvid nome tipo idn
    local -A vg_da_togliere=()
    while read -r pv vg; do
        [[ $pv == /dev/* && -n ${vg:-} ]] || continue
        for d; do antenati "$pv" | grep -qx -- "$d" && vg_da_togliere[$vg]=1; done
    done < <(pvs --devicesfile "" --noheadings -o pv_name,vg_name 2>/dev/null)
    local lvp
    for vg in "${!vg_da_togliere[@]}"; do
        echo "  tolgo il VG $vg"
        # Un filesystem dentro un LV resta sul disco anche dopo aver tolto il LV, e
        # ricomparirebbe in una partizione che inizia nello stesso punto: si cancella prima.
        fai vgchange -q -ay --activationmode partial --devicesfile "" "$vg" >/dev/null 2>&1 || true
        for lvp in $(lvs --devicesfile "" --noheadings -o lv_path "$vg" 2>/dev/null); do
            if [[ -b $lvp ]]; then fai wipefs -q -a -f "$lvp" 2>/dev/null || true; fi
        done
        fai vgchange -an --devicesfile "" "$vg" >/dev/null 2>&1 || true
        fai vgremove -ff -y --devicesfile "" "$vg" >/dev/null
    done
    while read -r pv; do
        [[ $pv == /dev/* ]] || continue
        for d; do
            if antenati "$pv" | grep -qx -- "$d"; then
                echo "  tolgo l'etichetta LVM da $pv"
                fai pvremove -ff -y --devicesfile "" "$pv" >/dev/null
            fi
        done
    done < <(pvs --devicesfile "" --noheadings -o pv_name 2>/dev/null)
    # Volumi rimasti accesi senza più un VG (etichette cancellate a forza): il
    # device-mapper tiene ancora occupati i dischi. Si tolgono a giri, cominciando da
    # quelli che nessun altro volume usa.
    local giro resto dm k
    for giro in 1 2 3 4 5 6; do
        resto=0
        for d; do
            for dm in $(lsblk -nrpo NAME,TYPE "$d" | awk '$2 == "lvm" { print $1 }' | sort -u); do
                resto=1
                k=$(basename "$(realpath "$dm")")
                if [[ -z $(ls -A "/sys/block/$k/holders" 2>/dev/null) ]]; then
                    echo "  tolgo dal device-mapper il volume orfano $dm (giro $giro)"
                    fai dmsetup remove "$(cat "/sys/block/$k/dm/name")" || true
                fi
            done
        done
        ((resto)) || break
    done
    [[ -f $FILE_DISPOSITIVI ]] || return 0
    for d; do
        while read -r riga; do
            [[ -n $riga ]] || continue
            pvid=$(sed -n 's/.* PVID=\([^ ]*\).*/\1/p' <<<"$riga")
            nome=$(sed -n 's/.* DEVNAME=\([^ ]*\).*/\1/p' <<<"$riga")
            tipo=$(sed -n 's/.* IDTYPE=\([^ ]*\).*/\1/p' <<<"$riga")
            idn=$(sed -n 's/.* IDNAME=\([^ ]*\).*/\1/p' <<<"$riga")
            echo "  tolgo dal file dei dispositivi di LVM: ${nome:-?} ($tipo $idn)"
            if [[ -n $pvid && $pvid != none ]]; then
                fai lvmdevices -y --delpvid "$pvid" >/dev/null 2>&1 || true
            elif [[ -n $nome && -b $nome ]] && antenati "$nome" | grep -qx -- "$d"; then
                fai lvmdevices -y --deldev "$nome" >/dev/null 2>&1 || true
            else
                # Il nome vecchio può essere oggi quello di un altro disco: si toglie per identità.
                fai lvmdevices -y --deldev "$idn" --deviceidtype "$tipo" >/dev/null 2>&1 || true
            fi
        done < <(righe_dispositivi_di "$d")
    done
}

# Una riga in /etc/fstab scritta dallo scenario, con systemd subito aggiornato.
# Le righe del kit che citano un UUID si ricordano: una riga può puntare a un dispositivo
# che non c'è più (la swap del progetto finale), e azzera la deve togliere lo stesso.
FSTAB_KIT=$STATO/fstab-kit
# In emergency mode avviare un servizio tira su sysinit.target, che ferma la shell di
# emergenza (e questo script con lei): i servizi si riaccendono al prossimo avvio (M6).
in_emergenza() { systemctl is-active -q emergency.target 2>/dev/null; }
riaccendi() { # start|restart UNITÀ, ma non in emergency mode
    if in_emergenza; then echo "  emergency mode: $2 si riaccende al prossimo avvio"; return 0; fi
    fai systemctl "$@"
}

riga_fstab() {
    if ((A_SECCO)); then echo "+ aggiungo a /etc/fstab: $*"; return 0; fi
    local f1
    # Se l'ultima riga non finisce con un a capo, la riga del kit le si attaccherebbe (M8).
    [[ ! -s /etc/fstab || -z $(tail -c 1 /etc/fstab) ]] || printf '\n' >>/etc/fstab
    printf '%s\n' "$*" >>/etc/fstab
    read -r f1 _ <<<"$*"
    if [[ $f1 == UUID=* ]]; then echo "$f1" >>"$FSTAB_KIT"; fi
    systemctl daemon-reload
}

azzera() {
    local d dischi=() u
    ricollega_loop
    mapfile -t dischi < <(tutti_i_bersagli)
    ((${#dischi[@]} > 0)) || { errore "Nessun bersaglio collegato: lancia prima sudo ./prepara.sh dischi"; exit 2; }
    # Tutti i controlli prima di qualsiasi scrittura.
    for d in "${dischi[@]}"; do ammesso "$d"; done
    fstab_sui_punti_del_kit

    for u in $(unita_del_kit); do fai systemctl stop "$u"; fai systemctl reset-failed "$u" 2>/dev/null || true; done
    # Le unità del kit e Apache possono tenere occupati i punti del kit: si fermano prima
    # di smontare. Apache torna acceso alla fine, se lo era alla fotografia.
    togli_unita_del_kit
    ferma_processi_del_kit
    local httpd_fermato=0
    if [[ $(systemctl is-active httpd 2>/dev/null) == active ]] && grep -rqsE '/srv/(www|web)' /etc/httpd/conf /etc/httpd/conf.d; then
        echo "  fermo httpd: usa i punti del kit"
        fai systemctl stop httpd
        httpd_fermato=1
    fi

    # Identificatori da togliere da fstab, raccolti prima di cancellare le firme.
    local ids dev
    ids=$(mktemp)
    for d in "${dischi[@]}"; do
        for dev in $(lsblk -nrpo NAME "$d"); do
            {
                echo "DEV=$dev"
                echo "DEV=$(realpath "$dev")"
                # blkid esce con 2 quando non trova firme: non è un errore.
                { blkid -p -o export "$dev" 2>/dev/null || true; } | sed -n -e 's/^UUID=/UUID=/p' -e 's/^LABEL=/LABEL=/p' \
                    -e 's/^PART_ENTRY_UUID=/PARTUUID=/p' -e 's/^PART_ENTRY_NAME=/PARTLABEL=/p'
            } >>"$ids"
        done
    done

    # Prima le swap: un file di swap attivo tiene occupato il filesystem che lo contiene.
    local t s p
    while read -r s; do
        if [[ -b $s ]]; then
            for d in "${dischi[@]}"; do antenati "$s" | grep -qx -- "$d" && { echo "  tolgo la swap $s"; fai swapoff "$s"; }; done
        else
            for p in "${PUNTI_KIT[@]}"; do [[ $s == "$p"/* ]] && { echo "  tolgo la swap $s"; fai swapoff "$s"; }; done
        fi
    done < <(awk 'NR > 1 { print $1 }' /proc/swaps)

    # Smontare, dal punto più profondo al più alto.
    while read -r t; do
        echo "  smonto $t"
        if ! fai umount "$t"; then
            errore "Non riesco a smontare $t: qualcuno lo sta usando (una tua shell dentro la cartella?)."
            fuser -vm "$t" 2>&1 | sed 's/^/    /' >&2 || true
            rm -f "$ids"
            exit 1
        fi
    done < <(findmnt -rn -o TARGET,SOURCE | while read -r t s; do
        s=${s%%[*}
        [[ $s == /dev/* ]] || continue
        for d in "${dischi[@]}"; do antenati "$s" | grep -qx -- "$d" && { echo "$t"; break; }; done
    done | awk '{ print length($0), $0 }' | sort -rn | cut -d' ' -f2-)

    # M12: un automount (x-systemd.automount) resta come autofs anche senza la riga di fstab,
    # e la preparazione dopo monterebbe sopra di lui. Si ferma dopo aver smontato il disco.
    local a
    for p in "${PUNTI_KIT[@]}"; do
        a=$(systemd-escape -p --suffix=automount "$p")
        [[ $(systemctl is-active "$a" 2>/dev/null) == inactive ]] && ! findmnt -rn -t autofs "$p" >/dev/null && continue
        echo "  fermo l'automount di $p"
        fai systemctl stop "$a" 2>/dev/null || true
        if findmnt -rn -t autofs "$p" >/dev/null; then fai umount "$p" 2>/dev/null || true; fi
    done

    # Loop che il kit ha costruito sopra un bersaglio.
    local l
    for d in "${dischi[@]}"; do
        for l in $(losetup -nO NAME -j "$d" 2>/dev/null); do fai losetup -d "$l"; done
    done

    riporta_lvm
    togli_lvm "${dischi[@]}"

    pulisci_fstab "$ids"
    rm -f "$ids"
    ((A_SECCO)) || rm -f "$FSTAB_KIT"

    # Cancellare firme e tabelle: prima le partizioni, poi il disco, poi i primi 4 MiB
    # (GPT e inizio del primo PV) e l'ultimo, dove sta la copia di riserva della GPT.
    local p dim
    for d in "${dischi[@]}"; do
        for p in $(lsblk -nrpo NAME,TYPE "$d" | awk '$2 == "part" { print $1 }' | sort -r); do
            fai wipefs -q -a "$p" 2>/dev/null || true
        done
        fai wipefs -q -a "$d"
        dim=$(byte_di "$d")
        fai dd if=/dev/zero of="$d" bs=1M count=4 conv=fsync status=none
        fai dd if=/dev/zero of="$d" bs=1M count=1 seek=$((dim / MIB - 1)) conv=fsync status=none
        fai blockdev --rereadpt "$d" 2>/dev/null || fai partx -d "$d" 2>/dev/null || true
    done
    udevadm settle 2>/dev/null || true

    # Cartelle dei punti del kit, solo se vuote.
    for p in "${PUNTI_KIT[@]}"; do
        if [[ -d $p ]]; then fai rmdir "$p" 2>/dev/null || true; fi
    done
    togli_utenti_del_kit
    riporta_sysctl
    local parti
    parti=" $(parti_da_riportare) "
    if [[ $parti == *" avvio "* ]]; then
        riporta_journald
        riporta_avvio
    fi
    if [[ $parti == *" servizi "* ]]; then riporta_crond; fi
    togli_file_kit
    if [[ $parti == *" web "* ]]; then
        riporta_web
    elif ((httpd_fermato)); then
        echo "  riaccendo httpd"
        riaccendi start httpd || errore "  httpd non riparte: controlla a mano (systemctl status httpd)"
    fi
    ((A_SECCO)) || rm -f "$CORRENTE" "$DA_RIPORTARE"
    echo "Bersagli azzerati: ${dischi[*]}"
}

# ---- Strumenti per gli scenari --------------------------------------------------

# bersaglio Dn: percorso attuale, già passato dalla guardia.
bersaglio() {
    local p
    p=$(percorso_bersaglio "$1")
    [[ -n $p ]] || { errore "Il bersaglio $1 non è collegato."; exit 2; }
    ammesso "$p"
    echo "$p"
}

# Il disco che ha il nome del kernel più basso, cioè quello che un principiante usa per primo.
primo_e_secondo() {
    local a b
    a=$(bersaglio D1)
    b=$(bersaglio D2)
    if [[ $a < $b ]]; then echo "$a $b"; else echo "$b $a"; fi
}

nome_del_disco() { nome_bersaglio "$1"; }

partiziona() {
    local d=$1
    fai sfdisk -q --wipe always "$d"
    fai udevadm settle
}

atteso() { echo "$1=$2" >>"$ATTESO"; }

occupa() {
    local nome=$1 dir=$2
    fai systemd-run -q --unit="lab-occupa-$nome" -p WorkingDirectory="$dir" sleep infinity
    ((A_SECCO)) || atteso "PID_$nome" "$(systemctl show -p MainPID --value "lab-occupa-$nome")"
}

monta() {
    fai mkdir -p "$2"
    fai mount "$1" "$2"
}

# Identificatore leggibile di un disco nel ticket: seriale o file d'origine.
come_riconoscerlo() {
    local s
    s=$(seriale_di "$1")
    if [[ -n $s ]]; then echo "seriale $s"; else echo "loop con origine $(losetup -nO BACK-FILE "$1")"; fi
}

ticket() {
    local f=$PALESTRA/l$LEZIONE/ticket-$PROBLEMA.txt
    if ((A_SECCO)); then cat; return; fi
    cat >"$f"
    chown "$(utente_vero)" "$f" 2>/dev/null || true
    echo
    sed 's/^/  │ /' "$f"
    echo
    echo "Il ticket è anche in $f"
}

# ---- Lezione 01: dischi e partizioni ---------------------------------------------

UUID_COLLEGA=2f1c9e4a-6b3d-4f8e-9a71-0c5d2e8b4a13

l01_p1() {
    local primo secondo
    local coppia
    coppia=$(primo_e_secondo)
    read -r primo secondo <<<"$coppia"
    # Il disco con il nome più basso sembra vuoto, ma ha un ext4 su tutto il disco.
    fai mkfs.ext4 -q -F -L collega -U "$UUID_COLLEGA" "$primo"
    if ((!A_SECCO)); then
        monta "$primo" "$PROVA/collega"
        printf 'Disco di Sara per il nuovo monitoraggio. Non formattare.\n' >"$PROVA/collega/LEGGIMI.txt"
        genera_file "$PROVA/collega/metriche" m 40 300 101
        umount "$PROVA/collega"
    fi
    atteso COLLEGA "$(nome_del_disco "$primo")"
    atteso NUOVO "$(nome_del_disco "$secondo")"
    ticket <<EOF
TICKET 4711 — Disco per il database
Da: Sara (gruppo database)

Ciao, sulla macchina sono arrivati dei dischi nuovi da 2 GiB. Quello per il database
è quello con $(come_riconoscerlo "$secondo"). Quello con $(come_riconoscerlo "$primo")
è mio, per il monitoraggio: ci ho già messo dei dati, non toccarlo. Gli altri non
servono.

Sul disco del database mi serve:
- una tabella delle partizioni GPT;
- una sola partizione da 1 GiB esatto, che inizi a 1 MiB dall'inizio del disco;
- nome della partizione (GPT) «dati-db», tipo «Linux filesystem»;
- il resto del disco libero: lo useremo più avanti.
Niente filesystem: lo creo io.

Prima di chiudere il ticket: sudo ./verifica.sh 01 1 deve uscire con 0.
EOF
}

l01_p2() {
    local d
    d=$(bersaglio D1)
    atteso DISCO D1
    ticket <<EOF
TICKET 4720 — Disco per l'apparato di misura
Da: ufficio tecnico

Il disco con $(come_riconoscerlo "$d") va consegnato a un vecchio apparato che parte da BIOS
e legge solo la tabella MBR (detta anche «DOS»). Il fornitore chiede questo schema,
con le partizioni nell'ordine indicato e la prima a 1 MiB dall'inizio:

  1  256 MiB  Linux              avviabile (attiva)
  2  256 MiB  Linux swap
  3  512 MiB  Linux
  4  tutto lo spazio rimanente, come contenitore per le partizioni successive
  5  256 MiB  Linux LVM
  6  256 MiB  Linux

Niente filesystem. Il kernel deve vedere tutte le partizioni.

Prima di chiudere il ticket: sudo ./verifica.sh 01 2 deve uscire con 0.
EOF
}

UUID_ARCHIVIO=5d3a7c1e-2b4f-4e6a-8c9d-0e1f2a3b4c5d
DISCO_GUID_P3=6E1A0B2C-3D4E-4F50-8A61-72839405A6B7
PART_GUID_P3=9B2C4D6E-8F01-4A23-B456-789ABCDEF012

l01_p3() {
    local d p1
    d=$(bersaglio D2)
    fai sfdisk -q --wipe always "$d" <<EOF
label: gpt
label-id: $DISCO_GUID_P3
start=2048, size=1048576, type=$GUID_LINUX, uuid=$PART_GUID_P3, name="archivio"
EOF
    fai udevadm settle
    if ((!A_SECCO)); then
        p1=$(parte "$d" 1)
        mkfs.ext4 -q -F -L ARCHIVIO -U "$UUID_ARCHIVIO" "$p1"
        monta "$p1" /srv/archivio
        genera_file /srv/archivio/2025 fattura 300 600 303
        genera_file /srv/archivio/2026 fattura 200 600 304
        mkdir -p "$STATO/l01"
        manifest /srv/archivio "$STATO/l01/p3.manifest"
    fi
    occupa archivio /srv/archivio
    atteso DISCO D2
    ticket <<EOF
TICKET 4733 — Spazio per gli indici dell'archivio
Da: gruppo applicazioni

Il disco con $(come_riconoscerlo "$d") ha una partizione «archivio» montata su /srv/archivio,
usata giorno e notte dal servizio lab-occupa-archivio. Ci serve una seconda partizione:

- da 1 GiB esatto, subito dopo la prima (primo settore allineato al MiB);
- nome GPT «indici», tipo «Linux filesystem»;
- il kernel deve vederla subito: un collega la formatta appena chiudi il ticket.

Vincoli: niente fermi. /srv/archivio resta montato e il servizio non si ferma né si
riavvia. La prima partizione non deve cambiare in niente, nemmeno nell'identità:
l'applicazione la cerca per PARTUUID, e il disco per il suo GUID.

Prima di chiudere il ticket: sudo ./verifica.sh 01 3 deve uscire con 0.
EOF
}

l01_p4() {
    atteso DISCO nessuno
    ticket <<EOF
TICKET 4750 — Lo stesso schema su tutti i dischi gemelli
Da: responsabile dell'infrastruttura

Su ogni server nuovo prepariamo dischi gemelli con lo stesso schema di partizioni
(per esempio due dischi in mirror). Lo facciamo a mano, e ogni tanto sbagliamo.
Serve uno script, in palestra/l01/clona-schema.sh:

  clona-schema.sh SORGENTE DESTINAZIONE

- copia su DESTINAZIONE lo schema di SORGENTE, GPT o MBR: stesse partizioni con lo
  stesso inizio, dimensione, tipo, nome e flag;
- gli identificatori (GUID del disco e di ogni partizione, o l'identificativo MBR)
  devono essere nuovi: due dischi nella stessa macchina non possono avere lo stesso;
- su un disco più grande della sorgente, l'area utilizzabile arriva alla fine del
  disco: la copia di riserva della GPT sta sempre in fondo.

Codici di uscita:
  0  schema copiato
  2  uso sbagliato: argomenti mancanti o in più, non dispositivi a blocchi,
     sorgente uguale alla destinazione, sorgente senza tabella delle partizioni
  3  destinazione non sicura: contiene già una tabella o un filesystem, o ha
     qualcosa di montato. Non si scrive niente.
  4  destinazione troppo piccola per l'ultima partizione. Non si scrive niente.
  1  qualsiasi altro errore

Il correttore lo prova solo su dischi di prova (loop), in una gabbia che non vede
gli altri dischi.

Prima di chiudere il ticket: sudo ./verifica.sh 01 4 deve uscire con 0.
EOF
}

# ---- Lezione 02: filesystem -------------------------------------------------------

DISCO_GUID_L02=7A2B3C4D-5E6F-4071-8293-A4B5C6D7E8F9

l02_p1() {
    local d
    d=$(bersaglio D1)
    fai sfdisk -q --wipe always "$d" <<EOF
label: gpt
label-id: $DISCO_GUID_L02
start=2048, size=1638400, type=$GUID_LINUX, uuid=11111111-2222-4333-8444-000000000001, name="app"
start=1640448, size=1228800, type=$GUID_LINUX, uuid=11111111-2222-4333-8444-000000000002, name="log"
start=2869248, size=409600, type=$GUID_DATI_MS, uuid=11111111-2222-4333-8444-000000000003, name="scambio"
EOF
    fai udevadm settle
    # Una partizione riciclata: sulla prima resta la firma di un vecchio ext4.
    ((A_SECCO)) || mkfs.ext4 -q -F -L vecchio "$(parte "$d" 1)"
    atteso DISCO D1
    ticket <<EOF
TICKET 4802 — Filesystem per il nuovo server applicativo
Da: gruppo applicazioni

Il disco con $(come_riconoscerlo "$d") è già partizionato (lo vedi con lsblk). Formattalo così:

  partizione  nome      filesystem  etichetta  note
  1           app       XFS         APPDATI    la prima partizione arriva da un server
                                               dismesso: controlla cosa contiene
  2           log       ext4        LOG        è un volume di dati: lo spazio riservato
                                               all'amministratore deve essere l'1%,
                                               non il valore predefinito
  3           scambio   FAT32       SCAMBIO    la legge il firmware di un apparato
                                               che riconosce solo FAT32

Non serve montarli.

Prima di chiudere il ticket: sudo ./verifica.sh 02 1 deve uscire con 0.
EOF
}

UUID_POSTA=3c4d5e6f-7081-4293-a4b5-c6d7e8f90a1b

l02_p2() {
    local d p1 liberi
    d=$(bersaglio D1)
    fai sfdisk -q --wipe always "$d" <<EOF
label: gpt
label-id: $DISCO_GUID_L02
start=2048, size=524288, type=$GUID_LINUX, uuid=11111111-2222-4333-8444-000000000021, name="posta"
EOF
    fai udevadm settle
    if ((!A_SECCO)); then
        p1=$(parte "$d" 1)
        mkfs.ext4 -q -F -b 4096 -i 65536 -L POSTA -U "$UUID_POSTA" "$p1"
        monta "$p1" /srv/posta
        mkdir -p /srv/posta/maildrop
        liberi=$(stat -f -c %d /srv/posta)
        genera_file /srv/posta/maildrop msg "$liberi" 300 202
        # Come in una coda di Postfix: messaggi dell'utente postfix (89) e del gruppo postdrop (90),
        # non leggibili da tutti, scritti nei giorni scorsi. Una copia che li perde si vede (G4).
        local k
        chown -R 89:90 /srv/posta/maildrop
        find /srv/posta/maildrop -type f -print0 | xargs -0 -r chmod 0640
        find /srv/posta/maildrop -type f -name 'msg*[05].txt' -print0 | xargs -0 -r chmod 0600
        for k in 0 1 2 3; do
            find /srv/posta/maildrop -type f -name "msg*[$k$((k + 4))].txt" -print0 |
                xargs -0 -r touch -d "2026-0$((k + 6))-1$k 0$k:2$k:00"
        done
        mkdir -p "$STATO/l02"
        manifest /srv/posta "$STATO/l02/p2.manifest"
        manifest_meta /srv/posta "$STATO/l02/p2.meta"
    fi
    atteso DISCO D1
    ticket <<EOF
TICKET 4815 — La posta non parte più
Da: centralino del supporto

Da stamattina i messaggi restano bloccati. Nel log del servizio di posta:

  postdrop: warning: mail_queue_enter: create file maildrop/2771.1793680211: No space left on device

Eppure df -h dice che /srv/posta (disco $(come_riconoscerlo "$d")) è pieno solo per metà.

Cosa serve:
- /srv/posta deve poter contenere almeno 50.000 messaggi come quelli che ci sono, con
  almeno 45.000 posti liberi a fine lavoro;
- nessun messaggio va perso: devono restare tutti, identici, nella stessa cartella;
- stesso punto di montaggio, etichetta POSTA, sullo stesso disco;
- il disco non si può ingrandire.

Prima di chiudere il ticket: sudo ./verifica.sh 02 2 deve uscire con 0.
EOF
}

UUID_APP=4d5e6f70-8192-43a4-b5c6-d7e8f90a1b2c
PART_GUID_APP=22222222-3333-4444-8555-000000000031

l02_p3() {
    local d l p1
    d=$(bersaglio D2)
    # Il disco "era" da 1 GiB: lo schema si scrive attraverso una vista ridotta, così la
    # copia di riserva della GPT resta a metà del disco, come dopo un ampliamento vero.
    if ((A_SECCO)); then
        echo "+ losetup --sizelimit 1GiB su $d, GPT e XFS dentro la vista ridotta"
    else
        l=$(losetup -f --show -P --sizelimit "$GIB" "$d")
        sfdisk -q --wipe always "$l" <<EOF
label: gpt
label-id: $DISCO_GUID_L02
start=2048, type=$GUID_LINUX, uuid=$PART_GUID_APP, name="app"
EOF
        udevadm settle
        mkfs.xfs -q -f -L APPDATI -m uuid="$UUID_APP" "${l}p1"
        losetup -d "$l"
        blockdev --rereadpt "$d"
        udevadm settle
        p1=$(parte "$d" 1)
        monta "$p1" /srv/app
        genera_file /srv/app/clienti scheda 400 900 305
        genera_grande /srv/app/indice.bin 64 305
        mkdir -p "$STATO/l02"
        manifest /srv/app "$STATO/l02/p3.manifest"
    fi
    occupa app /srv/app
    atteso DISCO D2
    ticket <<EOF
TICKET 4840 — Il disco è stato ingrandito, ora tocca a te
Da: gruppo virtualizzazione

Su richiesta del gruppo applicazioni abbiamo portato il disco con
$(come_riconoscerlo "$d") da 1 a 2 GiB, dalla console dell'hypervisor, a macchina accesa.
Dentro la VM /srv/app vede ancora 1 GiB.

Cosa serve:
- /srv/app deve usare tutto il disco;
- online: /srv/app resta montato e il servizio lab-occupa-app non si ferma;
- la partizione non cambia identità (l'applicazione la cerca per PARTUUID) e non si
  sposta: stesso primo settore;
- nessun dato perso.

Prima di chiudere il ticket: sudo ./verifica.sh 02 3 deve uscire con 0.
EOF
}

UUID_LOG=5e6f7081-92a3-44b5-86d7-e8f90a1b2c3d
UUID_INDICI=6f708192-a3b4-45c6-97e8-f90a1b2c3d4e

l02_p4() {
    local d p1 p2
    d=$(bersaglio D1)
    fai sfdisk -q --wipe always "$d" <<EOF
label: gpt
label-id: $DISCO_GUID_L02
start=2048, size=2097152, type=$GUID_LINUX, uuid=33333333-4444-4555-8666-000000000041, name="log"
start=2099200, size=1843200, type=$GUID_LINUX, uuid=33333333-4444-4555-8666-000000000042, name="indici"
EOF
    fai udevadm settle
    if ((!A_SECCO)); then
        p1=$(parte "$d" 1)
        p2=$(parte "$d" 2)
        mkfs.ext4 -q -F -L LOG -U "$UUID_LOG" "$p1"
        mkfs.xfs -q -f -L INDICI -m uuid="$UUID_INDICI" "$p2"
        monta "$p1" /srv/log
        monta "$p2" /srv/indici
        # Come su un disco usato da tempo, una parte dei dati sta oltre i 600 MiB:
        # un riempitivo occupa l'inizio mentre si scrivono i file, poi sparisce.
        fallocate -l 700M /srv/log/.riempitivo
        genera_file /srv/log/2026-11 accessi 300 2000 401
        genera_grande /srv/log/archivio-ottobre.log 16 401
        rm -f /srv/log/.riempitivo
        genera_file /srv/indici/clienti idx 300 1500 402
        genera_grande /srv/indici/globale.idx 16 402
        mkdir -p "$STATO/l02"
        manifest /srv/log "$STATO/l02/p4-log.manifest"
        manifest /srv/indici "$STATO/l02/p4-indici.manifest"
    fi
    atteso DISCO D1
    ticket <<EOF
TICKET 4866 — Fare posto sul disco dei log
Da: gruppo applicazioni

Sul disco con $(come_riconoscerlo "$d") ci sono due partizioni:
  1  «log», ext4 LOG, montata su /srv/log, 1 GiB, piena per poco
  2  «indici», XFS INDICI, montata su /srv/indici, 900 MiB, piena per poco

Ci serve spazio per una nuova partizione da 400 MiB, quindi:
- la partizione 1 scende a 600 MiB esatti, la 2 a 500 MiB esatti;
- ognuna resta dov'è (stesso primo settore) e con la sua identità (PARTUUID);
- ogni filesystem occupa la sua partizione, senza sprecare spazio (al MiB);
- tipi, etichette e punti di montaggio di prima; nessun dato perso;
- alla fine entrambi montati; deve restare un tratto libero contiguo di almeno 400 MiB.
Puoi fermare i servizi: entrambe le cartelle possono restare smontate per un po'.

Prima di chiudere il ticket: sudo ./verifica.sh 02 4 deve uscire con 0.
EOF
}

# ---- Lezione 03: mount, fstab e UUID ------------------------------------------------

UUID_ARCHIVIO3=7a1b2c3d-4e5f-4061-8273-94a5b6c7d8e9
UUID_VECCHI=8b2c3d4e-5f60-4172-8384-a5b6c7d8e9f0
UUID_DATI=9c3d4e5f-6071-4283-9495-b6c7d8e9f0a1
UUID_BACKUP=0d4e5f60-7182-4394-a5a6-c7d8e9f0a1b2
UUID_PROGETTI=1e5f6071-8293-44a5-b6b7-d8e9f0a1b2c3

# Un disco con una sola partizione grande quanto lui.
una_partizione() { # DISCO NOME
    fai sfdisk -q --wipe always "$1" <<EOF
label: gpt
start=2048, type=$GUID_LINUX, name="$2"
EOF
    fai udevadm settle
}

l03_p1() {
    local d p1
    d=$(bersaglio D1)
    una_partizione "$d" archivio
    if ((!A_SECCO)); then
        p1=$(parte "$d" 1)
        mkfs.xfs -q -f -L ARCHIVIO -m uuid="$UUID_ARCHIVIO3" "$p1"
        monta "$p1" /srv/archivio
        genera_file /srv/archivio/2026 verbale 300 800 601
        mkdir -p "$STATO/l03"
        manifest /srv/archivio "$STATO/l03/p1.manifest"
    fi
    atteso UUID_FS "$UUID_ARCHIVIO3"
    ticket <<EOF
TICKET 5102 — L'archivio sparisce a ogni riavvio
Da: gruppo applicazioni

Dopo il riavvio di stanotte l'applicazione non trovava più i suoi file: /srv/archivio
era una cartella vuota. L'avevano montato a mano mesi fa. L'ho rimontato io
(il filesystem è sul disco con $(come_riconoscerlo "$d")), ma va sistemato per sempre:

- /srv/archivio deve essere montato a ogni avvio, con il filesystem cercato per UUID,
  non per nome del dispositivo;
- con l'opzione noatime: l'archivio si legge molto e non vogliamo una scrittura a ogni
  lettura. Deve essere attiva già adesso, non solo dal prossimo avvio;
- il sistema di avvio deve usare già la configurazione nuova, senza riavviare;
- nessun dato perso.

Criteri di accettazione:
  sudo ./verifica.sh 03 1          esce con 0
  findmnt --verify                 esce con 0
EOF
}

l03_p2() {
    local primo secondo pv pd
    local coppia
    coppia=$(primo_e_secondo)
    read -r primo secondo <<<"$coppia"
    una_partizione "$primo" vecchi
    una_partizione "$secondo" dati
    if ((!A_SECCO)); then
        pv=$(parte "$primo" 1)
        pd=$(parte "$secondo" 1)
        mkfs.xfs -q -f -L VECCHI -m uuid="$UUID_VECCHI" "$pv"
        mkfs.xfs -q -f -L DATI -m uuid="$UUID_DATI" "$pd"
        mkdir -p "$STATO/l03"
        monta "$pv" "$PROVA/vecchi"
        genera_file "$PROVA/vecchi/fatture" fattura-2026-05- 200 700 701
        manifest "$PROVA/vecchi" "$STATO/l03/p2-vecchi.manifest"
        umount "$PROVA/vecchi"
        monta "$pd" "$PROVA/dati"
        genera_file "$PROVA/dati/fatture" fattura-2026-11- 250 700 702
        manifest "$PROVA/dati" "$STATO/l03/p2-dati.manifest"
        umount "$PROVA/dati"
        # Fino a ieri il disco dei dati si chiamava come oggi si chiama l'altro.
        riga_fstab "$pv  /srv/dati  xfs  defaults  0 0"
        mkdir -p /srv/dati
        mount /srv/dati
    fi
    ticket <<EOF
TICKET 5117 — /srv/dati mostra fatture vecchie di mesi
Da: amministrazione

Stanotte avete aggiunto un disco alla macchina e l'avete riavviata. Da allora in
/srv/dati ci sono le fatture di maggio e quelle di novembre sono sparite. Il disco
con le fatture buone è ancora sulla macchina: il suo filesystem si chiama DATI.

Cosa serve:
- /srv/dati deve mostrare di nuovo il filesystem DATI;
- la riga di /etc/fstab deve trovarlo da qualcosa che sta scritto sul disco stesso,
  così non succede più, qualunque nome prendano i dischi al prossimo avvio;
- l'altro filesystem (VECCHI, una copia del vecchio server) non va modificato né
  lasciato montato;
- il sistema di avvio deve usare già la configurazione nuova.

Criteri di accettazione:
  sudo ./verifica.sh 03 2          esce con 0
  findmnt --verify                 esce con 0
EOF
}

l03_p3() {
    local d p1
    d=$(bersaglio D3)
    una_partizione "$d" backup
    if ((!A_SECCO)); then
        p1=$(parte "$d" 1)
        mkfs.ext4 -q -F -L BACKUP -U "$UUID_BACKUP" "$p1"
        monta "$p1" "$PROVA/backup"
        genera_file "$PROVA/backup/copie" copia 50 900 801
        umount "$PROVA/backup"
    fi
    atteso UUID_FS "$UUID_BACKUP"
    ticket <<EOF
TICKET 5130 — Il disco di backup che va e viene
Da: responsabile dei backup

Il disco con $(come_riconoscerlo "$d") è il nostro disco di backup esterno: il venerdì lo
scolleghiamo e lo portiamo fuori sede, il lunedì torna. Ora è collegato.

- Va montato su /srv/backup a ogni avvio quando c'è, con il filesystem cercato per UUID.
- Quando non c'è, la macchina deve avviarsi lo stesso, senza fermarsi ad aspettarlo:
  al massimo 10 secondi di attesa per quel disco.
- Montalo adesso, e il sistema di avvio deve usare già la configurazione nuova.

Criteri di accettazione:
  sudo ./verifica.sh 03 3          esce con 0
  findmnt --verify                 esce con 0
EOF
}

l03_p4() {
    local d p1
    d=$(bersaglio D1)
    gruppo_kit sviluppo
    utente_kit anna sviluppo
    utente_kit luca sviluppo
    utente_kit marco
    una_partizione "$d" progetti
    ((A_SECCO)) || mkfs.xfs -q -f -L PROGETTI -m uuid="$UUID_PROGETTI" "$(parte "$d" 1)"
    # Il lavoro di un collega, fatto sulla cartella vuota del disco di sistema.
    fai mkdir -p /srv/progetti
    fai chgrp sviluppo /srv/progetti
    fai chmod 2770 /srv/progetti
    atteso UUID_FS "$UUID_PROGETTI"
    ticket <<EOF
TICKET 5144 — La cartella condivisa del gruppo sviluppo
Da: responsabile del gruppo sviluppo

Il gruppo sviluppo (anna e luca) avrà una cartella condivisa su un disco suo, quello con
$(come_riconoscerlo "$d"): il filesystem PROGETTI è già pronto. Un collega ha cominciato e
ha già sistemato i permessi di /srv/progetti. Manca il resto:

- montarlo su /srv/progetti a ogni avvio, cercato per UUID, e adesso;
- è un volume di dati: i file di dispositivo e i bit setuid che ci finissero sopra non
  devono avere effetto;
- anna e luca creano file e cartelle, e vedono quelli dell'altro;
- tutto ciò che nasce lì dentro, anche nelle sottocartelle, appartiene al gruppo sviluppo;
- nessuno può cancellare o rinominare i file degli altri;
- chi non è del gruppo (per esempio marco) non può nemmeno elencare la cartella;
- il sistema di avvio deve usare già la configurazione nuova.

Criteri di accettazione:
  sudo ./verifica.sh 03 4          esce con 0
  findmnt --verify                 esce con 0
EOF
}

# ---- Lezione 04: swap ------------------------------------------------------------

UUID_DB=2a6b7c8d-9e0f-4a1b-8c2d-3e4f5a6b7c8d
UUID_DATI4=3b7c8d9e-0f1a-4b2c-9d3e-4f5a6b7c8d9e
UUID_SWAP4=4c8d9e0f-1a2b-4c3d-8e4f-5a6b7c8d9e0f
GUID_SWAP=0657FD6D-A4AB-43C4-84E5-0933C84B4F4F

l04_p1() {
    local d p1
    d=$(bersaglio D1)
    fai sfdisk -q --wipe always "$d" <<EOF
label: gpt
start=2048, size=2097152, type=$GUID_LINUX, name="db"
EOF
    fai udevadm settle
    if ((!A_SECCO)); then
        p1=$(parte "$d" 1)
        mkfs.xfs -q -f -L DB -m uuid="$UUID_DB" "$p1"
        monta "$p1" /srv/db
        genera_file /srv/db/tabelle t 200 1500 901
        mkdir -p "$STATO/l04"
        manifest /srv/db "$STATO/l04/p1.manifest"
    fi
    occupa db /srv/db
    ticket <<EOF
TICKET 5201 — Il database ucciso di notte
Da: gruppo database

Stanotte il database si è fermato. Nel log del kernel:

  Out of memory: Killed process 4242 (postgres) total-vm:2214820kB, anon-rss:1693004kB

La macchina non ha swap. Sul disco con $(come_riconoscerlo "$d") c'è la partizione del
database, montata su /srv/db e in uso, e dopo di lei spazio libero.

- Crea una partizione di swap da 512 MiB esatti subito dopo quella del database
  (tipo «Linux swap»), senza fermare /srv/db.
- Deve essere attiva adesso, con priorità 10.
- E a ogni avvio, cercata per UUID, con la stessa priorità.
- Il sistema di avvio deve usare già la configurazione nuova.

Criteri di accettazione:
  sudo ./verifica.sh 04 1          esce con 0
  swapon --show                    la mostra con priorità 10
EOF
}

l04_dati() { # una partizione dati montata su /srv/dati da fstab
    local d=$1 p1
    if ((!A_SECCO)); then
        p1=$(parte "$d" 1)
        mkfs.xfs -q -f -L DATI -m uuid="$UUID_DATI4" "$p1"
        riga_fstab "UUID=$UUID_DATI4  /srv/dati  xfs  defaults  0 0"
        mkdir -p /srv/dati
        mount /srv/dati
        genera_file /srv/dati/report r 100 1500 902
    fi
}

l04_p2() {
    local d
    d=$(bersaglio D1)
    una_partizione "$d" dati
    l04_dati "$d"
    ticket <<EOF
TICKET 5214 — Swap subito, e non c'è spazio da partizionare
Da: gruppo applicazioni

Il server ha poca memoria e un job notturno la esaurisce. Il disco con
$(come_riconoscerlo "$d") è tutto occupato dalla partizione dei dati, montata su /srv/dati,
e non possiamo fermare niente. Serve swap adesso:

- un file /srv/dati/swapfile da 256 MiB esatti, usato come swap;
- attivo adesso con priorità 5, e a ogni avvio con la stessa priorità;
- è memoria dei processi: solo root deve poterlo leggere e scrivere;
- il sistema di avvio deve usare già la configurazione nuova.

Criteri di accettazione:
  sudo ./verifica.sh 04 2          esce con 0
  swapon --show                    lo mostra con priorità 5
EOF
}

l04_p3() {
    local d p2
    d=$(bersaglio D1)
    fai sfdisk -q --wipe always "$d" <<EOF
label: gpt
start=2048, size=2097152, type=$GUID_LINUX, name="dati"
start=2099200, size=1048576, type=$GUID_SWAP, name="swap"
EOF
    fai udevadm settle
    l04_dati "$d"
    if ((!A_SECCO)); then
        p2=$(parte "$d" 2)
        mkswap -U "$UUID_SWAP4" "$p2" >/dev/null
        fallocate -l 256M /srv/dati/swapfile
        chmod 600 /srv/dati/swapfile
        mkswap /srv/dati/swapfile >/dev/null
        riga_fstab "UUID=$UUID_SWAP4  none  swap  pri=10  0 0"
        riga_fstab "/srv/dati/swapfile  none  swap  pri=5  0 0"
        swapon -a
    fi
    ticket <<EOF
TICKET 5230 — Niente swap su file
Da: fornitore del database

Sulla macchina ci sono due swap: la partizione sul disco con $(come_riconoscerlo "$d") e
un file /srv/dati/swapfile. Per il nostro supporto:

- il file di swap va tolto, adesso e per sempre, e il suo spazio deve tornare libero
  su /srv/dati;
- la swap sulla partizione resta attiva com'è, con priorità 10;
- il kernel deve ricorrere alla swap il meno possibile: il parametro vm.swappiness va
  portato a 10, adesso e a ogni avvio;
- senza riavviare, e il sistema di avvio deve usare già la configurazione nuova.

Criteri di accettazione:
  sudo ./verifica.sh 04 3          esce con 0
  cat /proc/sys/vm/swappiness      stampa 10
EOF
}

# ---- Lezione 05: LVM ------------------------------------------------------------------

UUID_DB5=5d9e0f1a-2b3c-4d4e-9f5a-6b7c8d9e0f1a
UUID_ARCH5=6e0f1a2b-3c4d-4e5f-8a6b-7c8d9e0f1a2b

# vg_con_lv VG LV DIMENSIONE ETICHETTA UUID PUNTO DISCHI...: PV sui dischi interi, un VG,
# un LV con un XFS montato da fstab su un punto del kit.
vg_con_lv() {
    local vg=$1 lv=$2 dim=$3 et=$4 u=$5 punto=$6
    shift 6
    fai pvcreate -q -y "$@"
    fai vgcreate -q "$vg" "$@"
    fai lvcreate -q -y -L "$dim" -n "$lv" "$vg"
    if ((!A_SECCO)); then
        mkfs.xfs -q -f -L "$et" -m uuid="$u" "/dev/$vg/$lv"
        riga_fstab "UUID=$u  $punto  xfs  defaults  0 0"
        mkdir -p "$punto"
        mount "$punto"
    fi
}

dati_db() {
    ((A_SECCO)) && return 0
    genera_file /srv/db/tabelle t 300 2000 1001
    genera_grande /srv/db/indice.bin 24 1001
    mkdir -p "$STATO/l$LEZIONE"
    manifest /srv/db "$STATO/l$LEZIONE/p$PROBLEMA.manifest"
}

l05_p1() {
    local a b
    a=$(bersaglio D1)
    b=$(bersaglio D2)
    # Il secondo disco arriva da un server dismesso, con la sua vecchia tabella.
    fai sfdisk -q --wipe always "$b" <<EOF
label: gpt
start=2048, size=1048576, type=$GUID_LINUX, name="vecchio"
EOF
    fai udevadm settle
    ((A_SECCO)) || mkfs.ext4 -q -F -L vecchio-server "$(parte "$b" 1)"
    ticket <<EOF
TICKET 5301 — Un volume da 2,5 GiB per il database
Da: gruppo database

Il database nuovo vuole 2,5 GiB in un solo filesystem, ma i dischi sono da 2 GiB:
con LVM ne mettiamo insieme due.

- Disco con $(come_riconoscerlo "$a"): una sola partizione su tutto il disco, di tipo
  «Linux LVM», usata come PV.
- Disco con $(come_riconoscerlo "$b"): usato intero come PV, senza tabella delle
  partizioni. Arriva da un server dismesso: quello che c'è sopra non serve più.
- Un VG vgdati con i due PV, ed extent da 8 MiB.
- Un LV lvdb da 2,5 GiB esatti, con un XFS etichettato DB.
- Montato su /srv/db a ogni avvio e adesso; il sistema di avvio usa già la
  configurazione nuova.

Criteri di accettazione:
  sudo ./verifica.sh 05 1          esce con 0
  sudo vgs vgdati                  mostra 2 PV
EOF
}

l05_p2() {
    local a b
    a=$(bersaglio D1)
    b=$(bersaglio D2)
    vg_con_lv vgdati lvdb 1.5G DB "$UUID_DB5" /srv/db "$a"
    dati_db
    occupa db /srv/db
    ticket <<EOF
TICKET 5315 — /srv/db è al 92%
Da: gruppo database

Il database cresce più del previsto. lvdb deve arrivare a 3 GiB esatti, oggi.
In vgdati non c'è abbastanza spazio: è arrivato un disco nuovo, quello con
$(come_riconoscerlo "$b"), da usare intero.

- lvdb a 3 GiB esatti, e il filesystem deve vedere tutto lo spazio;
- a caldo: /srv/db resta montato e lab-occupa-db non si ferma;
- nessun dato perso.

Criteri di accettazione:
  sudo ./verifica.sh 05 2          esce con 0
  df -h /srv/db                    mostra circa 3 GiB
EOF
}

l05_p3() {
    local a b c
    a=$(bersaglio D1)
    b=$(bersaglio D2)
    c=$(bersaglio D3)
    vg_con_lv vgdati lvdb 2.5G DB "$UUID_DB5" /srv/db "$a" "$b"
    dati_db
    occupa db /srv/db
    ticket <<EOF
TICKET 5330 — Il disco che sta per rompersi
Da: monitoraggio

Stanotte smartd ha scritto:

  smartd[812]: Device: $a [SAT], 8 Currently unreadable (pending) sectors

Il disco con $(come_riconoscerlo "$a") fa parte di vgdati e va sostituito domani.
Prima va svuotato:

- tutto ciò che sta su quel disco va spostato sul disco nuovo con $(come_riconoscerlo "$c");
- poi il disco guasto esce da vgdati e perde la sua etichetta LVM;
- a caldo: lvdb non cambia dimensione, /srv/db resta montato e lab-occupa-db non si ferma;
- nessun dato perso.

Criteri di accettazione:
  sudo ./verifica.sh 05 3          esce con 0
  sudo pvs                         non mostra più il disco guasto
EOF
}

l05_p4() {
    local c
    c=$(bersaglio D3)
    if [[ ! -f $FILE_DISPOSITIVI ]]; then
        if [[ $(lvmconfig --typeconfig full devices/use_devicesfile 2>/dev/null) == *=0 ]]; then
            errore "LVM ha il file dei dispositivi spento: use_devicesfile = 0 (in /etc/lvm/lvm.conf o lvmlocal.conf)."
            errore "Il file di prima di solito è ancora lì, rinominato: ls /etc/lvm/devices/"
        else
            errore "Questa VM non usa il file dei dispositivi di LVM ($FILE_DISPOSITIVI): il problema 4 non ha senso qui."
            errore "Le installazioni di Rocky 9 dalla ISO lo creano; leggi la nota nella lezione."
        fi
        exit 2
    fi
    fai pvcreate -q -y "$c"
    fai vgcreate -q vgvecchio "$c"
    fai lvcreate -q -y -L 800M -n lvdati vgvecchio
    if ((!A_SECCO)); then
        mkfs.xfs -q -f -L ARCHIVIO -m uuid="$UUID_ARCH5" /dev/vgvecchio/lvdati
        monta /dev/vgvecchio/lvdati "$PROVA/vecchio"
        genera_file "$PROVA/vecchio/2016" pratica 200 1200 1004
        genera_file "$PROVA/vecchio/2021" pratica 200 1200 1005
        mkdir -p "$STATO/l05"
        manifest "$PROVA/vecchio" "$STATO/l05/p4.manifest"
        umount "$PROVA/vecchio"
    fi
    # Il disco arriva da un'altra macchina: il file dei dispositivi di questa non lo conosce.
    fai vgchange -q -an vgvecchio
    fai lvmdevices -y --deldev "$c"
    ticket <<EOF
TICKET 5344 — Il disco del vecchio server di archivio
Da: gruppo infrastruttura

Abbiamo spostato su questa macchina il disco del vecchio server di archivio, quello con
$(come_riconoscerlo "$c"). Dentro c'è un VG vgvecchio con un LV lvdati: dieci anni di
pratiche. Su questa macchina LVM non lo vede.

- Rendi vgvecchio visibile e attivo, senza toccarne il contenuto.
- Monta lvdati su /srv/archivio a ogni avvio, e adesso.
- Anche dopo un riavvio LVM deve trovarlo da solo.
- Il sistema di avvio usa già la configurazione nuova.

Criteri di accettazione:
  sudo ./verifica.sh 05 4          esce con 0
  sudo vgs vgvecchio               esce con 0
EOF
}

# ---- Lezione 06: snapshot LVM ---------------------------------------------------------

UUID_APP6=7f1a2b3c-4d5e-4f6a-8b7c-8d9e0f1a2b3c

app_su_lvm() {
    local a b
    a=$(bersaglio D1)
    b=$(bersaglio D2)
    vg_con_lv vgapp lvapp 1G APP "$UUID_APP6" /srv/app "$a" "$b"
    if ((!A_SECCO)); then
        genera_file /srv/app/clienti scheda 400 1500 1101
        genera_file /srv/app/config conf 40 400 1102
        genera_grande /srv/app/catalogo.db 20 1101
        mkdir -p "$STATO/l06"
        manifest /srv/app "$STATO/l06/p$PROBLEMA.manifest"
        find /srv/app -type f ! -path '*/lost+found/*' | wc -l >"$STATO/l06/p$PROBLEMA.quanti"
    fi
}

l06_p1() {
    app_su_lvm
    occupa app /srv/app
    ticket <<EOF
TICKET 5402 — La fotografia prima dell'aggiornamento
Da: gruppo applicazioni

Stasera aggiorniamo l'applicazione, che riscrive i suoi dati in /srv/app (lvapp, in
vgapp). Prima vogliamo una fotografia del volume, da tenere fino a domani:

- uno snapshot di lvapp che si chiami lvapp-prima, con almeno 300 MiB per le modifiche;
- montato in sola lettura su /srv/app-prima, così il gruppo può confrontare i file;
- è temporaneo: non va montato all'avvio;
- lvapp resta montato e lab-occupa-app non si ferma.

Criteri di accettazione:
  sudo ./verifica.sh 06 1          esce con 0
  sudo lvs vgapp                   mostra lvapp-prima con origine lvapp
EOF
}

l06_p2() {
    app_su_lvm
    fai lvcreate -q -y -s -L 500M -n lvapp-prima vgapp/lvapp
    if ((!A_SECCO)); then
        # L'aggiornamento: file tolti, cambiati, aggiunti.
        find /srv/app/clienti -name 'scheda000[1-4]*' -delete
        local f
        for f in /srv/app/config/conf000*.txt; do echo "versione=2.0 # migrazione fallita" >>"$f"; done
        genera_file /srv/app/clienti-v2 scheda 120 1500 1103
        genera_grande /srv/app/catalogo.db 30 1104
    fi
    occupa app /srv/app
    ticket <<EOF
TICKET 5417 — L'aggiornamento è andato male
Da: gruppo applicazioni

L'aggiornamento di stasera ha rovinato i dati di /srv/app: schede sparite, configurazioni
riscritte, un catalogo che l'applicazione non legge più. Prima di cominciare avevamo
fatto lo snapshot lvapp-prima.

- Riporta lvapp esattamente com'era al momento dello snapshot.
- Il servizio si può fermare per il tempo necessario: sudo systemctl stop lab-occupa-app
  (non serve farlo ripartire).
- Alla fine /srv/app è montato come prima e lo snapshot non esiste più.

Criteri di accettazione:
  sudo ./verifica.sh 06 2          esce con 0
  sudo lvs vgapp                   non mostra più lvapp-prima
EOF
}

l06_p3() {
    local a b
    a=$(bersaglio D1)
    b=$(bersaglio D2)
    vg_con_lv vgdati lvdb 2.5G DB "$UUID_DB5" /srv/db "$a" "$b"
    dati_db
    if ((!A_SECCO)); then
        atteso PVUUID "$(pvs --noheadings -o pv_uuid "$b" | tr -d ' ')"
        # L'errore del collega: l'etichetta LVM del disco giusto, cancellata.
        umount /srv/db
        vgchange -q -an vgdati
        wipefs -q -a "$b"
    fi
    ticket <<EOF
TICKET 5430 — Il collega ha cancellato il disco sbagliato
Da: gruppo infrastruttura

Stamattina un collega doveva cancellare le firme di un disco vuoto e l'ha fatto sul
disco con $(come_riconoscerlo "$b"), che fa parte di vgdati. Il disco è sano: è stata
cancellata solo l'etichetta LVM. Da allora vgdati è incompleto, lvdb non si attiva e
/srv/db non è montato.

- Recupera vgdati com'era, con i suoi due PV, senza perdere niente.
- lvdb attivo e /srv/db montato, come da /etc/fstab.

Criteri di accettazione:
  sudo ./verifica.sh 06 3          esce con 0
  sudo vgs vgdati                  senza avvisi su dispositivi mancanti
EOF
}

# ---- Lezione 07: fsck ed emergency mode -------------------------------------------------

UUID_ARCHIVIO7=8a2b3c4d-5e6f-4a7b-9c8d-9e0f1a2b3c4d
UUID_INDICI7=9b3c4d5e-6f70-4b8c-8d9e-0f1a2b3c4d5e
UUID_DATI7=ac4d5e6f-7081-4c9d-9eaf-1a2b3c4d5e6f
UUID_DATI7_SCRITTO=ac4d5e6f-7081-4c9d-9eaf-1a2b3c4d5e9f # come l'ha copiato il collega

# Identificatore dell'avvio in corso, nella forma che usa journalctl.
boot_id() { tr -d - </proc/sys/kernel/random/boot_id; }

# In modalità di soccorso e di emergenza systemd chiede la password di root.
serve_password_root() {
    [[ $(passwd -S root 2>/dev/null | awk '{ print $2 }') == PS ]] && return 0
    errore "Questo problema passa dalla console di soccorso o di emergenza, che chiede la password di root:"
    errore "root non ne ha una utilizzabile. Impostala e annotala (sudo passwd root), poi rilancia."
    exit 2
}

# journald sta scrivendo in /var/log/journal?
journal_su_disco() {
    local pid
    pid=$(systemctl show -p MainPID --value systemd-journald)
    find "/proc/$pid/fd" -lname '/var/log/journal/*' 2>/dev/null | grep -q .
}

conta_file() { find "$1" -type f ! -path '*/lost+found/*' | wc -l; }

# fotografa_dati CARTELLA: manifest e numero di file, per il correttore.
fotografa_dati() {
    mkdir -p "$STATO/l$LEZIONE"
    manifest "$1" "$STATO/l$LEZIONE/p$PROBLEMA.manifest"
    conta_file "$1" >"$STATO/l$LEZIONE/p$PROBLEMA.quanti"
}

# genera_fatture CARTELLA QUANTE SEME: il nome di ogni fattura è il numero scritto nella
# prima riga. I numeri non sono consecutivi, così l'ordine non basta a ritrovarli.
genera_fatture() {
    mkdir -p "$1"
    awk -v dir="$1" -v n="$2" -v seme="$3" '
    function rnd(m) { seme = (seme * 16807) % 2147483647; return seme % m }
    BEGIN {
        for (i = 1; i <= n; i++) {
            num = sprintf("2025-%04d", 3 * i + rnd(3))
            f = dir "/" num ".txt"
            printf "Fattura n. %s\nCliente: cliente%03d\nImporto: %d,%02d EUR\n", num, rnd(500), rnd(9000) + 100, rnd(100) > f
            close(f)
        }
    }'
}

l07_p1() {
    fai mkdir -p "$DROPIN_JOURNAL"
    if ((A_SECCO)); then
        echo "+ scrivo $DROPIN_JOURNAL/10-spazio.conf (Storage=volatile)"
    else
        cat >"$DROPIN_JOURNAL/10-spazio.conf" <<'EOF'
# Ticket 3120: /var era piccola, il journal si tiene solo in memoria.
[Journal]
Storage=volatile
RuntimeMaxUse=64M
EOF
    fi
    fai systemctl restart systemd-journald
    ticket <<EOF
TICKET 5502 — I log di ieri non ci sono
Da: gruppo applicazioni

Stanotte il servizio si è fermato e la macchina è stata riavviata. Stamattina volevamo
capire perché, ma journalctl non mostra niente di prima del riavvio. Serve:

- il journal si salva su disco e sopravvive ai riavvii;
- su disco occupa al massimo 200 MiB, perché /var non è grande;
- la configurazione nuova è già attiva adesso, senza riavviare la macchina.

Criteri di accettazione:
  sudo ./verifica.sh 07 1          esce con 0
  journalctl --list-boots          dopo il prossimo riavvio mostra anche questo avvio
EOF
}

l07_p2() {
    local d p1 ino
    d=$(bersaglio D1)
    una_partizione "$d" archivio
    gruppo_kit amministrazione
    if ((!A_SECCO)); then
        p1=$(parte "$d" 1)
        mkfs.ext4 -q -F -L ARCHIVIO -U "$UUID_ARCHIVIO7" "$p1"
        riga_fstab "UUID=$UUID_ARCHIVIO7  /srv/archivio  ext4  defaults,errors=remount-ro  0 2"
        mkdir -p /srv/archivio
        mount /srv/archivio
        genera_fatture /srv/archivio/fatture 40 1201
        chown -R root:amministrazione /srv/archivio/fatture
        chmod 2770 /srv/archivio/fatture
        chmod 640 /srv/archivio/fatture/*
        genera_file /srv/archivio/contratti contratto 30 1200 1202
        genera_file /srv/archivio/verbali verbale 20 800 1203
        fotografa_dati /srv/archivio
        # Il danno: l'inode della cartella delle fatture azzerato, come dopo una scrittura
        # interrotta a metà. Poi l'applicazione ci inciampa e il kernel, per l'opzione
        # errors=remount-ro, rimonta il filesystem in sola lettura.
        ino=$(stat -c %i /srv/archivio/fatture)
        umount /srv/archivio
        debugfs -w -R "clri <$ino>" "$p1" >/dev/null 2>&1
        mount /srv/archivio
        ls /srv/archivio/fatture >/dev/null 2>&1 || true
        atteso T_DANNO "$(date +%s)"
    fi
    occupa archivio /srv/archivio
    ticket <<EOF
TICKET 5517 — Structure needs cleaning
Da: gruppo amministrazione

L'applicazione dell'archivio dà «Structure needs cleaning» quando legge
/srv/archivio/fatture, e da stamattina non riesce più a scrivere da nessuna parte in
/srv/archivio. Il disco è quello con $(come_riconoscerlo "$d"). Serve:

- il filesystem riparato, e di nuovo montato in lettura e scrittura come da /etc/fstab;
- nessuna fattura persa: tutte di nuovo in /srv/archivio/fatture, ognuna con il suo
  nome, che è il numero scritto nella prima riga più .txt (per esempio 2025-0007.txt);
- la cartella fatture com'era: di root, gruppo amministrazione, permessi 2770;
- contratti e verbali intatti.

Il servizio si può fermare per il tempo necessario: sudo systemctl stop lab-occupa-archivio
(non serve farlo ripartire).

Criteri di accettazione:
  sudo ./verifica.sh 07 2          esce con 0
  ls /srv/archivio/lost+found      non mostra niente
EOF
}

l07_p3() {
    local d p1
    d=$(bersaglio D2)
    una_partizione "$d" indici
    if ((!A_SECCO)); then
        p1=$(parte "$d" 1)
        mkfs.xfs -q -f -L INDICI -m uuid="$UUID_INDICI7" "$p1"
        riga_fstab "UUID=$UUID_INDICI7  /srv/indici  xfs  defaults  0 0"
        mkdir -p /srv/indici
        mount /srv/indici
        genera_file /srv/indici/storico indice 300 2000 1301
        # Lo storico arriva al suo posto sul disco: congelare il filesystem svuota il log.
        fsfreeze -f /srv/indici
        fsfreeze -u /srv/indici
        # Gli indici di stanotte arrivano solo nel log, poi la macchina "si spegne".
        genera_file /srv/indici/stanotte indice 80 1500 1302
        fotografa_dati /srv/indici
        sync
        xfs_io -x -c shutdown /srv/indici
        umount /srv/indici
    fi
    ticket <<EOF
TICKET 5531 — Il disco tornato dal guasto
Da: gruppo ricerca

Stanotte, durante l'indicizzazione, la macchina si è spenta di colpo. Al riavvio il
collega di turno ha smontato /srv/indici (disco con $(come_riconoscerlo "$d")) e ha
lanciato il controllo del filesystem, che si è fermato con un errore e gli ha suggerito
un'opzione per forzarlo. Non l'ha usata e ci ha passato il ticket. Serve:

- /srv/indici di nuovo montato, come da /etc/fstab, con lo stesso filesystem;
- non si perde niente: né lo storico, né gli indici scritti stanotte in
  /srv/indici/stanotte.

Criteri di accettazione:
  sudo ./verifica.sh 07 3          esce con 0
EOF
}

l07_p4() {
    local d p1
    serve_password_root
    d=$(bersaglio D3)
    una_partizione "$d" dati
    if ((!A_SECCO)); then
        p1=$(parte "$d" 1)
        mkfs.xfs -q -f -L DATI -m uuid="$UUID_DATI7" "$p1"
        mkdir -p /srv/dati
        mount "$p1" /srv/dati
        genera_file /srv/dati/tabelle tabella 200 2000 1401
        fotografa_dati /srv/dati
        # La riga scritta a mano dal collega, con un UUID copiato male.
        riga_fstab "UUID=$UUID_DATI7_SCRITTO  /srv/dati  xfs  defaults  0 0"
        atteso BOOT_ID "$(boot_id)"
    fi
    ticket <<EOF
TICKET 5560 — La macchina non riparte
Da: reperibile di turno

Venerdì un collega ha spostato i dati del database sul disco con $(come_riconoscerlo "$d"):
ha montato il disco a mano su /srv/dati e ha aggiunto la riga in /etc/fstab, scrivendo
l'UUID a mano. Stanotte la macchina si è riavviata per gli aggiornamenti e non è più
tornata in rete.

Per riprodurre il riavvio di stanotte, con la console della VM aperta:
  sudo systemctl reboot

Serve:
- la macchina si avvia da sola fino in fondo, con /srv/dati montato come da /etc/fstab
  e i dati intatti;
- /srv/dati è del database: se un giorno il disco mancasse, la macchina non deve
  partire come se niente fosse (niente nofail);
- prova che la correzione regge: alla fine un riavvio pulito, senza passare dalla
  modalità di emergenza.

Criteri di accettazione:
  sudo ./verifica.sh 07 4                      esce con 0, dopo il riavvio finale
  systemctl --failed --type=mount              non elenca niente
EOF
}

# ---- Lezione 08: avvio e GRUB --------------------------------------------------------------

UUID_DATI8=bd5e6f70-8192-4dae-8fb0-2b3c4d5e6f70

l08_p1() {
    if ((!A_SECCO)); then
        atteso SSHD "$(systemctl is-active sshd)"
        atteso SSHD_PID "$(systemctl show -p MainPID --value sshd)"
        atteso BOOT_ID "$(boot_id)"
    fi
    fai systemctl set-default -q graphical.target
    fai systemctl isolate graphical.target
    ticket <<EOF
TICKET 5601 — Parte in modalità grafica, e non serve
Da: responsabile dell'infrastruttura

Questa macchina è nata con l'ambiente grafico, poi tolto. Parte ancora in modalità
grafica e il controllo di conformità la segnala: un server deve partire nella modalità
multi-utente senza grafica (rete, servizi, login da console e da SSH). Serve:

- da ora in poi la macchina parte in quella modalità;
- ci passa subito, senza riavviare, e i servizi che girano già (sshd per esempio)
  non si fermano.

Criteri di accettazione:
  sudo ./verifica.sh 08 1          esce con 0
  systemctl get-default            stampa multi-user.target
EOF
}

l08_p2() {
    local d p1
    serve_password_root
    d=$(bersaglio D1)
    una_partizione "$d" dati
    if ((!A_SECCO)); then
        p1=$(parte "$d" 1)
        mkfs.ext4 -q -F -L DATI -U "$UUID_DATI8" "$p1"
        riga_fstab "UUID=$UUID_DATI8  /srv/dati  ext4  defaults  0 2"
        mkdir -p /srv/dati
        mount /srv/dati
        genera_file /srv/dati/tabelle tabella 200 2000 1501
        fotografa_dati /srv/dati
        if ! journal_su_disco; then
            echo "Il journal non si salva su disco: lo attivo per questo problema (serve a leggere gli avvii precedenti)."
            mkdir -p "$DROPIN_JOURNAL"
            printf '# Creato da prepara.sh 08 2: azzera lo toglie.\n[Journal]\nStorage=persistent\n' >"$DROPIN_JOURNAL/90-lab-linux.conf"
            systemctl restart systemd-journald
        fi
        atteso T0 "$(date +%s)"
        atteso BOOT_ID "$(boot_id)"
    fi
    ticket <<EOF
TICKET 5620 — Un avvio di manutenzione
Da: fornitore dello storage

Per il nostro supporto serve un controllo completo del filesystem di /srv/dati (disco
con $(come_riconoscerlo "$d")), forzato anche se il filesystem risulta pulito, fatto
con la macchina avviata in modalità di soccorso (rescue): niente servizi, niente rete,
solo root in console.

- Un solo avvio in quella modalità, scelto a mano all'avvio: non deve diventare il
  modo di partire della macchina, né restare scritto nella configurazione.
- Dopo il controllo la macchina riparte normale, con /srv/dati montato come da
  /etc/fstab e i dati intatti.

Criteri di accettazione:
  sudo ./verifica.sh 08 2          esce con 0, dopo l'avvio normale
EOF
}

l08_p3() {
    ((A_SECCO)) || atteso BOOT_ID "$(boot_id)"
    ticket <<EOF
TICKET 5640 — I parametri del fornitore
Da: fornitore del database

Il nostro database vuole le transparent huge pages disattivate dal kernel fin
dall'avvio, con il parametro transparent_hugepage=never. Serve:

- il parametro su tutti i kernel installati, compreso quello di soccorso, e su quelli
  che arriveranno con gli aggiornamenti;
- e anche se un giorno qualcuno rigenera la configurazione di GRUB dalle impostazioni
  di sistema;
- il menu di GRUB resta visibile 10 secondi, perché chi è in console faccia in tempo a
  scegliere;
- il riavvio è concordato: alla fine la macchina gira già con il parametro.

Criteri di accettazione:
  sudo ./verifica.sh 08 3                  esce con 0, dopo il riavvio
  cat /sys/kernel/mm/transparent_hugepage/enabled   mostra [never]
EOF
}

# crea_kernel_finto: un "aggiornamento" del kernel più recente, con l'initramfs troncato
# come quando /boot si riempie a metà. Il kernel stesso è una copia di quello buono.
# Mette in KERNEL_BUONO, KERNEL_FINTO e VOCE_FINTA i nomi, e registra i file in $FINTO.
crea_kernel_finto() {
    local voce base
    KERNEL_BUONO=$(kernel_piu_recente)
    voce=$(voce_del_kernel "$KERNEL_BUONO")
    [[ -n $voce && -f /boot/vmlinuz-$KERNEL_BUONO && -f /boot/initramfs-$KERNEL_BUONO.img ]] ||
        { errore "Non trovo la voce di GRUB o i file del kernel $KERNEL_BUONO in /boot."; exit 2; }
    [[ $KERNEL_BUONO =~ ^([0-9.]+)-([0-9]+)(.*)$ ]] || { errore "Versione del kernel inattesa: $KERNEL_BUONO"; exit 2; }
    KERNEL_FINTO="${BASH_REMATCH[1]}-$((BASH_REMATCH[2] + 1))${BASH_REMATCH[3]}"
    [[ ! -e /boot/vmlinuz-$KERNEL_FINTO && ! -d /lib/modules/$KERNEL_FINTO ]] ||
        { errore "Esiste già un kernel $KERNEL_FINTO: non preparo il problema."; exit 2; }
    base=${voce##*/}
    VOCE_FINTA=$VOCI/${base/"$KERNEL_BUONO"/"$KERNEL_FINTO"}
    if ((A_SECCO)); then
        echo "+ kernel finto $KERNEL_FINTO, voce $VOCE_FINTA"
        return 0
    fi
    printf '%s\n' "/boot/vmlinuz-$KERNEL_FINTO" "/boot/initramfs-$KERNEL_FINTO.img" "$VOCE_FINTA" >"$FINTO"
    cp "/boot/vmlinuz-$KERNEL_BUONO" "/boot/vmlinuz-$KERNEL_FINTO"
    head -c $((1024 * 1024)) "/boot/initramfs-$KERNEL_BUONO.img" >"/boot/initramfs-$KERNEL_FINTO.img"
    local testo
    testo=$(cat "$voce")
    printf '%s\n' "${testo//"$KERNEL_BUONO"/"$KERNEL_FINTO"}" >"$VOCE_FINTA"
    chmod --reference="$voce" "$VOCE_FINTA"
    restorecon -q "/boot/vmlinuz-$KERNEL_FINTO" "/boot/initramfs-$KERNEL_FINTO.img" "$VOCE_FINTA" 2>/dev/null || true
    atteso KERNEL_BUONO "$KERNEL_BUONO"
    atteso KERNEL_FINTO "$KERNEL_FINTO"
    atteso VOCE_BUONA "$(basename "$voce" .conf)"
    atteso VOCE_FINTA "$(basename "$VOCE_FINTA" .conf)"
}

l08_p4() {
    crea_kernel_finto
    # Come fa l'aggiornamento con UPDATEDEFAULT=yes: il kernel nuovo diventa il predefinito.
    fai grubby --set-default "/boot/vmlinuz-$KERNEL_FINTO" >/dev/null
    ((A_SECCO)) || atteso BOOT_ID "$(boot_id)"
    ticket <<EOF
TICKET 5655 — Il kernel nuovo non parte
Da: reperibile di turno

Stanotte gli aggiornamenti hanno installato il kernel $KERNEL_FINTO
e lo hanno reso il predefinito. Al riavvio la macchina non è più partita.

Per riprodurre il riavvio di stanotte, con la console della VM aperta:
  sudo systemctl reboot
(se la macchina si blocca, nel menu di VirtualBox: Macchina → Ripristina)

Il fornitore indaga. Nel frattempo serve:
- la macchina parte con il kernel di prima, $KERNEL_BUONO, anche ai
  prossimi riavvii, senza che nessuno debba sceglierlo dal menu;
- il kernel nuovo resta installato e nel menu: il fornitore ci farà le sue prove;
- finché non arriva la correzione, un altro aggiornamento del kernel non deve cambiare
  il kernel predefinito.

Criteri di accettazione:
  sudo ./verifica.sh 08 4          esce con 0
  uname -r                         stampa $KERNEL_BUONO
EOF
}

# ---- Lezione 09: systemd --------------------------------------------------------------------

UUID_APP9=ce6f7081-92a3-4ebf-80c1-3c4d5e6f7081

# scrivi FILE MODO: scrive il testo che arriva da stdin.
scrivi() {
    if ((A_SECCO)); then echo "+ scrivo $1"; cat >/dev/null; return 0; fi
    cat >"$1"
    chmod "$2" "$1"
}

installa_lab_app() {
    utente_kit labapp
    fai mkdir -p /opt/lab-app
    file_kit /opt/lab-app
    file_kit /etc/lab-app.conf
    scrivi /opt/lab-app/lab-app 755 <<'EOF'
#!/usr/bin/python3
# lab-app: il servizio interno del gruppo applicazioni (versione del kit Linux, lezione 09).
# Risponde su HTTP e scrive un battito nella cartella dei dati. Legge /etc/lab-app.conf.
import configparser, http.server, os, signal, sys, threading, time

conf = configparser.ConfigParser()
conf.read('/etc/lab-app.conf')
porta = conf.getint('app', 'porta', fallback=8088)
dati = conf.get('app', 'dati', fallback='/srv/app/dati')


def di(messaggio):
    print('lab-app: ' + messaggio, flush=True)


if os.geteuid() == 0:
    di('non giro come root: avviami con il mio utente')
    sys.exit(1)
if not os.path.isdir(dati) or not os.access(dati, os.W_OK):
    di('non trovo la cartella dei dati %s, o non posso scriverci' % dati)
    sys.exit(1)


class Risposta(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        corpo = ('lab-app ok pid=%d\n' % os.getpid()).encode()
        self.send_response(200)
        self.send_header('Content-Type', 'text/plain; charset=utf-8')
        self.send_header('Content-Length', str(len(corpo)))
        self.end_headers()
        self.wfile.write(corpo)

    def log_message(self, formato, *argomenti):
        di('richiesta da %s: %s' % (self.address_string(), formato % argomenti))


def battito():
    while True:
        with open(os.path.join(dati, 'battito'), 'w') as f:
            f.write('%d %d\n' % (time.time(), os.getpid()))
        time.sleep(5)


def fermati(numero, quadro):
    di('ricevuto SIGTERM, mi fermo')
    sys.exit(0)


signal.signal(signal.SIGTERM, fermati)
try:
    server = http.server.HTTPServer(('', porta), Risposta)
except OSError as e:
    di('non riesco ad ascoltare sulla porta %d: %s' % (porta, e.strerror))
    sys.exit(1)
threading.Thread(target=battito, daemon=True).start()
di('in ascolto sulla porta %d, dati in %s' % (porta, dati))
server.serve_forever()
EOF
    scrivi /etc/lab-app.conf 644 <<'EOF'
# Configurazione di lab-app.
[app]
# La porta HTTP.
porta = 8088
# La cartella dei dati, sul disco dedicato montato in /srv/app.
dati = /srv/app/dati
EOF
    fai restorecon -R /opt/lab-app /etc/lab-app.conf
}

# Il disco dei dati dell'applicazione, montato su /srv/app da fstab.
disco_app() {
    local p1
    DISCO_APP=$(bersaglio D1)
    una_partizione "$DISCO_APP" app
    ((A_SECCO)) && return 0
    p1=$(parte "$DISCO_APP" 1)
    mkfs.xfs -q -f -L APP -m uuid="$UUID_APP9" "$p1"
    riga_fstab "UUID=$UUID_APP9  /srv/app  xfs  defaults  0 0"
    mkdir -p /srv/app
    mount /srv/app
    mkdir -p /srv/app/dati
    chown labapp: /srv/app/dati
}

l09_p1() {
    local pid="" i
    installa_lab_app
    disco_app
    if ((!A_SECCO)); then
        # Come l'ha lanciata il collega: a mano, da /srv/app, staccata dal terminale.
        (cd /srv/app && setsid -f setpriv --reuid=labapp --regid=labapp --init-groups \
            /opt/lab-app/lab-app >>/srv/app/nohup.out 2>&1 </dev/null)
        for ((i = 0; i < 40; i++)); do
            pid=$(pgrep -u labapp -f /opt/lab-app/lab-app | head -1 || true)
            [[ -n $pid ]] && break
            sleep 0.5
        done
        [[ -n $pid ]] || { errore "lab-app non è partita: guarda /srv/app/nohup.out"; exit 1; }
        atteso PID_MANO "$pid"
        atteso T0 "$(date +%s)"
    fi
    ticket <<EOF
TICKET 5701 — L'applicazione gira in una sessione aperta
Da: gruppo applicazioni

lab-app (/opt/lab-app/lab-app, configurazione in /etc/lab-app.conf) per ora l'ha
lanciata a mano un collega, dalla sua sessione, prima di andare in ferie. Se la
macchina si riavvia o il programma cade, resta giù finché qualcuno non se ne accorge.
Serve:

- lab-app diventa il servizio lab-app.service, che parte da solo a ogni avvio;
- gira come l'utente labapp, mai come root;
- se cade, systemd lo fa ripartire da solo;
- ha bisogno del disco dei dati, /srv/app (il disco con $(come_riconoscerlo "${DISCO_APP:-}")):
  se non è montato lo monta, e senza il disco non parte;
- i suoi messaggi finiscono nel journal;
- alla fine gira una copia sola dell'applicazione: quella del servizio.

Criteri di accettazione:
  sudo ./verifica.sh 09 1                  esce con 0
  systemctl is-enabled lab-app             stampa enabled
  curl -s http://127.0.0.1:8088/           risponde lab-app ok
EOF
}

l09_p2() {
    fai mkdir -p /etc/systemd/system/crond.service.d
    scrivi /etc/systemd/system/crond.service.d/ticket-4410.conf 644 <<'EOF'
# Ticket 4410 (2024): i report del mattino erano in ritardo, crond con più priorità.
[Service]
Nice=-5
EOF
    fai systemctl daemon-reload
    fai systemctl restart crond
    ticket <<EOF
TICKET 5720 — I lavori notturni rallentano il database
Da: amministratori del database

Di notte i lavori di cron (report, pulizie, copie) si prendono CPU e memoria, e il
database sulla stessa macchina rallenta. Serve:

- tutto ciò che lancia cron gira con priorità bassa: nice 10;
- tutti insieme, i lavori di cron non usano più di 1 GiB di memoria;
- il file dell'unità di crond che arriva con il pacchetto cronie non si tocca, e non se
  ne fa una copia al suo posto: gli aggiornamenti del pacchetto devono continuare ad
  arrivare;
- vale già per i lavori che partono da adesso, e dopo ogni riavvio.

Criteri di accettazione:
  sudo ./verifica.sh 09 2                  esce con 0
  rpm -V cronie                            non elenca il file dell'unità di crond
EOF
}

installa_report() {
    utente_kit labapp
    fai mkdir -p /opt/lab-report /var/lib/lab-report
    file_kit /opt/lab-report
    file_kit /var/lib/lab-report
    scrivi /opt/lab-report/report.sh 755 <<'EOF'
#!/bin/bash
# Il report delle vendite per l'ufficio di New York (versione del kit Linux, lezione 09).
set -eu
if [[ $(id -u) == 0 ]]; then
    echo "report: non giro come root" >&2
    exit 1
fi
dir=/var/lib/lab-report
file=$dir/report-$(date +%Y%m%d-%H%M%S)-$$.txt
{
    echo "Report vendite, generato il $(date -R) da $(id -un)"
    echo "A New York sono le $(TZ=America/New_York date '+%H:%M del %F')"
} >"$file"
echo "report: scritto $file"
EOF
    fai chown labapp: /var/lib/lab-report
    fai chmod 750 /var/lib/lab-report
    fai restorecon -R /opt/lab-report /var/lib/lab-report
}

l09_p3() {
    local t quando
    installa_report
    # Il ricalcolo straordinario: stasera alle 22:30, o domani se manca meno di un'ora.
    t=$(date -d 22:30 +%s)
    if ((t - $(date +%s) < 3600)); then t=$(date -d 'tomorrow 22:30' +%s); fi
    quando=$(date -d "@$t" '+%F alle %H:%M')
    ((A_SECCO)) || atteso STRAORDINARIO "$t"
    ticket <<EOF
TICKET 5740 — Il report per l'ufficio di New York
Da: ufficio vendite

Lo script /opt/lab-report/report.sh prepara il report delle vendite in
/var/lib/lab-report. Finora l'abbiamo lanciato a mano. Serve:

- che giri come servizio lab-report.service, con l'utente labapp;
- dal lunedì al venerdì alle 07:00 di New York (America/New_York), qualunque sia il
  fuso orario della macchina;
- se a quell'ora la macchina è spenta, il report si fa appena riparte;
- le trenta macchine che lo lanciano interrogano lo stesso database: ognuna parte in un
  momento a caso entro 15 minuti dall'ora fissata;
- a lanciarlo è solo il timer lab-report.timer: il servizio da solo non parte all'avvio;
- in più, una volta sola, il ricalcolo chiesto dalla direzione: il $quando,
  ora della macchina, con un timer di systemd che non lascia file in /etc e non si
  ripete.

Criteri di accettazione:
  sudo ./verifica.sh 09 3                  esce con 0
  systemctl list-timers                    mostra lab-report.timer e il ricalcolo
EOF
}

l09_p4() {
    fai mkdir -p /opt/lab-sincro
    file_kit /opt/lab-sincro
    file_kit /var/lib/lab-sincro
    file_kit /usr/lib/systemd/system/lab-sincro.service
    scrivi /opt/lab-sincro/sincro.sh 755 <<'EOF'
#!/bin/bash
# Client di sincronizzazione del catalogo (fornitore; versione del kit Linux, lezione 09).
# Senza un indirizzo e una rotta verso il server del fornitore non può lavorare.
if ! ip -4 route show default | grep -q .; then
    echo "lab-sincro: la rete non è pronta, nessuna rotta predefinita" >&2
    exit 1
fi
if ! ip -4 -o addr show scope global | grep -q .; then
    echo "lab-sincro: la rete non è pronta, nessun indirizzo" >&2
    exit 1
fi
mkdir -p /var/lib/lab-sincro
date +%s >/var/lib/lab-sincro/ultimo
echo "lab-sincro: catalogo sincronizzato"
EOF
    scrivi /usr/lib/systemd/system/lab-sincro.service 644 <<'EOF'
# Unità del pacchetto lab-sincro 2.3 (fornitore). Non modificare: gli aggiornamenti la
# sovrascrivono.
[Unit]
Description=Sincronizzazione del catalogo del fornitore
After=network.target

[Service]
Type=oneshot
# All'avvio la rete non è subito pronta: aspettiamo un po' prima di sincronizzare.
ExecStartPre=/usr/bin/sleep 75
ExecStart=/opt/lab-sincro/sincro.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF
    fai restorecon -R /opt/lab-sincro /usr/lib/systemd/system/lab-sincro.service
    fai systemctl daemon-reload
    fai systemctl enable -q lab-sincro.service
    if ((!A_SECCO)); then
        atteso SHA_SINCRO "$(sha256sum /usr/lib/systemd/system/lab-sincro.service | cut -d' ' -f1)"
        atteso ATTESA_RETE "$(systemctl is-enabled NetworkManager-wait-online.service 2>/dev/null || true)"
        atteso BOOT_ID "$(boot_id)"
    fi
    ticket <<EOF
TICKET 5760 — La macchina è pronta più di un minuto dopo
Da: gruppo automazione

Da quando il fornitore ha installato il suo servizio di sincronizzazione, lab-sincro,
a ogni riavvio la nostra automazione aspetta più di un minuto in più prima di
considerare pronta la macchina: aspetta che systemctl is-system-running dica running.
Serve:

- l'avvio non aspetta più senza motivo;
- lab-sincro gira ancora a ogni avvio, e riesce: gli servono la rete configurata, con
  l'indirizzo e la rotta;
- il file dell'unità del fornitore (/usr/lib/systemd/system/lab-sincro.service) non si
  tocca, e non se ne fa una copia al suo posto: il prossimo aggiornamento lo riscrive;
- tutto provato con un riavvio.

Per vedere il problema, prima di tutto riavvia una volta: sudo systemctl reboot

Criteri di accettazione:
  sudo ./verifica.sh 09 4                  esce con 0, dopo un riavvio
  systemd-analyze blame | head -3          lab-sincro non è più fra i primi
EOF
}

# ---- Lezione 10: SELinux e firewalld --------------------------------------------------------

UUID_WWW=df708192-a3b4-4cc0-91d2-4d5e6f708192
UUID_WEB=e0819203-b4c5-4dd1-a2e3-5e6f70819203

serve_web() {
    local c mancano=()
    for c in httpd firewall-cmd semanage restorecon matchpathcon getsebool curl; do
        command -v "$c" >/dev/null || mancano+=("$c")
    done
    if ((${#mancano[@]} > 0)); then
        errore "Per la lezione 10 mancano: ${mancano[*]}"
        errore "Installa Apache, firewalld e gli strumenti di SELinux:"
        errore "  sudo dnf install -y httpd firewalld policycoreutils-python-utils setroubleshoot-server"
        exit 2
    fi
    selinuxenabled || { errore "SELinux è disattivato (vedi /etc/selinux/config): la lezione 10 lo vuole attivo."; exit 2; }
    ((A_SECCO)) && return 0
    fotografa_web
    [[ -d $WEB/httpd && -d $WEB/firewalld && -d $WEB/selinux ]] ||
        { errore "Manca la fotografia di Apache, firewalld o SELinux in $WEB: rilancia prepara.sh."; exit 2; }
    if [[ $(systemctl is-active firewalld) != active ]]; then
        echo "Accendo firewalld: azzera lo spegnerà di nuovo, com'era."
        systemctl start firewalld
    fi
    if [[ $(getenforce) != Enforcing ]]; then
        echo "Metto SELinux in enforcing: azzera lo riporterà com'era."
        setenforce 1
    fi
}

# La zona di firewalld dell'interfaccia che porta alla rotta predefinita.
zona_di_rete() {
    local i
    i=$(ip -4 route show default | awk '{ for (k = 1; k < NF; k++) if ($k == "dev") { print $(k + 1); exit } }')
    firewall-cmd --get-zone-of-interface="$i" 2>/dev/null || firewall-cmd --get-default-zone
}

# Le pagine del sito interno, sempre le stesse.
genera_sito() {
    local dir=$1 p titolo
    mkdir -p "$dir/documenti" "$dir/listino"
    while read -r p titolo; do
        printf '<!doctype html>\n<html lang="it"><head><meta charset="utf-8"><title>%s</title></head>\n<body><h1>%s</h1>\n<p>Pagina %s del sito interno.</p>\n</body></html>\n' \
            "$titolo" "$titolo" "$p" >"$dir/$p"
    done <<'EOF'
index.html Sito interno
chi-siamo.html Chi siamo
contatti.html Contatti
documenti/orari.html Orari degli uffici
documenti/regolamento.html Regolamento interno
listino/index.html Listino
listino/prezzi-2026.html Prezzi 2026
EOF
}

# elenco_pagine CARTELLA: l'elenco per chi risolve, il manifest per il correttore.
elenco_pagine() {
    fotografa_dati "$1"
    (cd "$1" && find . -type f -printf '%P\n' | LC_ALL=C sort) >"$PALESTRA/l$LEZIONE/pagine-$PROBLEMA.txt"
    chown "$(utente_vero)" "$PALESTRA/l$LEZIONE/pagine-$PROBLEMA.txt" 2>/dev/null || true
}

conf_sito() { # RADICE [RIGHE IN PIÙ]
    file_kit /etc/httpd/conf.d/lab-sito.conf
    scrivi /etc/httpd/conf.d/lab-sito.conf 644 <<EOF
# Il sito interno, sul disco dedicato (kit Linux, lezione 10).
<VirtualHost *:80>
    ServerName lab-rocky
    DocumentRoot $1/sito
    <Directory $1/sito>
        Require all granted
    </Directory>
${2:-}</VirtualHost>
EOF
}

# Il sito interno su /srv/www, da fstab, con le etichette che la politica prevede lì.
sito_www() {
    local p1
    DISCO_WEB=$(bersaglio D1)
    una_partizione "$DISCO_WEB" www
    if ((!A_SECCO)); then
        p1=$(parte "$DISCO_WEB" 1)
        mkfs.xfs -q -f -L WWW -m uuid="$UUID_WWW" "$p1"
        riga_fstab "UUID=$UUID_WWW  /srv/www  xfs  defaults  0 0"
        mkdir -p /srv/www
        mount /srv/www
        genera_sito /srv/www/sito
    fi
    conf_sito /srv/www "${1:-}"
}

# apri_sito ZONA: il sito sulla porta 80 aperto nel firewall, adesso e in modo permanente.
apri_sito() {
    fai firewall-cmd -q --permanent --zone="$1" --add-service=http
    fai firewall-cmd -q --zone="$1" --add-service=http
}

# Come era la zona prima del tuo intervento: il correttore la confronta con la fine.
fotografa_zona() {
    ((A_SECCO)) && return 0
    atteso ZONA "$1"
    atteso ZONA_PREDEFINITA "$(firewall-cmd --get-default-zone)"
    atteso SERVIZI "$(firewall-cmd --permanent --zone="$1" --list-services | tr ' ' '\n' | sort | paste -sd' ' -)"
    atteso PORTE "$(firewall-cmd --permanent --zone="$1" --list-ports | tr ' ' '\n' | sort | paste -sd' ' -)"
    atteso OBIETTIVO "$(firewall-cmd --permanent --zone="$1" --get-target)"
    atteso REGOLE "$(regole_tranne_sito "$1" | sha256sum | cut -c1-16)"
    atteso SORGENTI "$(firewall-cmd --permanent --zone="$1" --list-sources)"
}

l10_p1() {
    local z
    serve_web
    sito_www
    fai restorecon -R /srv/www
    fai systemctl enable -q httpd
    fai systemctl restart httpd
    z=$(zona_di_rete)
    # Il punto di partenza: il sito chiuso, e la porta del database aperta solo in memoria.
    fai firewall-cmd -q --permanent --zone="$z" --remove-service=http 2>/dev/null || true
    fai firewall-cmd -q --permanent --zone="$z" --remove-port=80/tcp 2>/dev/null || true
    fai firewall-cmd -q --permanent --zone="$z" --remove-port=3306/tcp 2>/dev/null || true
    fai firewall-cmd -q --reload
    fotografa_zona "$z"
    fai firewall-cmd -q --zone="$z" --add-port=3306/tcp
    ticket <<EOF
TICKET 5801 — Il sito interno non si vede dagli uffici
Da: helpdesk

Il sito interno (Apache, in /srv/www) sulla macchina risponde: curl http://127.0.0.1/
va. Dagli uffici invece il browser non si collega. Ieri un collega ha fatto delle prove
sul firewall e ha lasciato aperta la porta del database, la 3306, «per un test veloce».
Serve:

- il sito raggiungibile dalla rete sulla porta 80, adesso e dopo ogni riavvio;
- la porta 3306 di nuovo chiusa, adesso e dopo ogni riavvio;
- il firewall resta acceso e SSH resta raggiungibile;
- nient'altro di aperto rispetto a prima.

La zona del firewall della scheda di rete è $z.

Criteri di accettazione:
  sudo ./verifica.sh 10 1                  esce con 0
  dal Mac, con un inoltro di porta di VirtualBox verso la 80, il sito risponde
EOF
}

l10_p2() {
    local p1
    serve_web
    utente_kit marco
    DISCO_WEB=$(bersaglio D1)
    una_partizione "$DISCO_WEB" web
    if ((!A_SECCO)); then
        p1=$(parte "$DISCO_WEB" 1)
        mkfs.xfs -q -f -L WEB -m uuid="$UUID_WEB" "$p1"
        riga_fstab "UUID=$UUID_WEB  /srv/web  xfs  defaults  0 0"
        mkdir -p /srv/web
        mount /srv/web
        genera_sito /srv/web/sito
        # Il listino l'ha copiato marco dalla sua cartella, con i permessi che aveva là.
        chown -R marco: /srv/web/sito/listino
        chmod 700 /srv/web/sito/listino
        chmod 600 /srv/web/sito/listino/*
        restorecon -R /srv/web
        elenco_pagine /srv/web/sito
    fi
    conf_sito /srv/web
    apri_sito "$(zona_di_rete)"
    # Come l'ha lasciata il collega: SELinux in permissive, adesso e nella configurazione.
    fai setenforce 0
    fai sed -i -E 's/^SELINUX=.*/SELINUX=permissive/' /etc/selinux/config
    fai systemctl enable -q httpd
    fai systemctl restart httpd
    ticket <<EOF
TICKET 5820 — SELinux in permissive
Da: gruppo sicurezza

Il controllo periodico ha trovato SELinux in modalità permissive: un collega ce l'ha
messo quando ha spostato il sito interno sul disco nuovo (/srv/web, il disco con
$(come_riconoscerlo "${DISCO_WEB:-}")), «perché altrimenti Apache dava errore». E
l'helpdesk segnala che le pagine del listino danno 403 da quando c'è il disco nuovo.
Serve:

- SELinux in modalità enforcing, adesso e dopo ogni riavvio;
- tutte le pagine del sito rispondono, listino compreso: l'elenco è in
  palestra/l10/pagine-2.txt;
- le etichette giuste restano anche se un giorno qualcuno rietichetta i file, o
  l'intera macchina: la regola sta nella politica di SELinux;
- Apache legge il sito ma non può scriverci: niente scrivibile da tutti, niente di
  proprietà di apache.

Criteri di accettazione:
  sudo ./verifica.sh 10 2                  esce con 0
  getenforce                               stampa Enforcing
EOF
}

l10_p3() {
    local z
    serve_web
    sito_www
    if ((!A_SECCO)); then
        mkdir -p /srv/www/stato
        printf '<!doctype html>\n<html lang="it"><head><meta charset="utf-8"><title>Stato</title></head>\n<body><h1>Console di monitoraggio</h1>\n<p>Tutti i servizi rispondono.</p>\n</body></html>\n' >/srv/www/stato/index.html
        fotografa_dati /srv/www/stato
    fi
    fai restorecon -R /srv/www
    file_kit /etc/httpd/conf.d/lab-stato.conf
    scrivi /etc/httpd/conf.d/lab-stato.conf 644 <<'EOF'
# Console di monitoraggio, per il gruppo che gestisce il monitoraggio (ticket 5832).
Listen 8081
<VirtualHost *:8081>
    DocumentRoot /srv/www/stato
    <Directory /srv/www/stato>
        Require all granted
    </Directory>
</VirtualHost>
EOF
    z=$(zona_di_rete)
    apri_sito "$z"
    fotografa_zona "$z"
    fai systemctl enable -q httpd
    # Il riavvio del collega, che non riesce.
    fai systemctl restart httpd 2>/dev/null || true
    ticket <<EOF
TICKET 5840 — Apache non riparte
Da: reperibile di turno

Ieri sera un collega ha aggiunto la console di monitoraggio di Apache sulla porta 8081
(/etc/httpd/conf.d/lab-stato.conf) e ha riavviato Apache. Da allora Apache non parte,
e anche il sito interno sulla porta 80 è giù. Serve:

- Apache di nuovo su, con il sito sulla porta 80 e la console sulla 8081;
- la console raggiungibile da fuori solo dalla rete del monitoraggio, 192.0.2.0/24;
  il sito sulla 80 e SSH raggiungibili da tutti, come prima;
- SELinux resta enforcing per tutti i processi, Apache compreso;
- tutto vale anche dopo un riavvio.

La zona del firewall della scheda di rete è $z.

Criteri di accettazione:
  sudo ./verifica.sh 10 3                  esce con 0
  curl -s http://127.0.0.1:8081/           risponde la console
EOF
}

installa_backend() {
    fai mkdir -p /var/lib/lab-backend
    file_kit /var/lib/lab-backend
    file_kit /etc/systemd/system/lab-backend.service
    scrivi /var/lib/lab-backend/listino.json 644 <<'EOF'
{"listino": "2026", "articoli": [{"codice": "A-100", "prezzo": 12.5}, {"codice": "B-220", "prezzo": 7.9}]}
EOF
    scrivi /etc/systemd/system/lab-backend.service 644 <<'EOF'
# Il backend del listino (kit Linux, lezione 10): risponde solo in locale, sulla 8080.
[Unit]
Description=Backend del listino

[Service]
DynamicUser=yes
ExecStart=/usr/bin/python3 -m http.server 8080 --bind 127.0.0.1 --directory /var/lib/lab-backend
EOF
    fai restorecon -R /var/lib/lab-backend /etc/systemd/system/lab-backend.service
    if ((!A_SECCO)); then atteso SHA_LISTINO "$(sha256sum /var/lib/lab-backend/listino.json | cut -d' ' -f1)"; fi
    fai systemctl daemon-reload
    fai systemctl start lab-backend.service
}

PROXY_API="    ProxyPass        /api/ http://127.0.0.1:8080/
    ProxyPassReverse /api/ http://127.0.0.1:8080/
"

l10_p4() {
    serve_web
    sito_www "$PROXY_API"
    fai restorecon -R /srv/www
    installa_backend
    apri_sito "$(zona_di_rete)"
    # Il punto di partenza: Apache non può collegarsi ad altri servizi.
    fai setsebool httpd_can_network_relay=off httpd_can_network_connect=off
    fai systemctl enable -q httpd
    fai systemctl restart httpd
    ticket <<EOF
TICKET 5860 — /api/ risponde 503
Da: gruppo applicazioni

Apache fa da proxy per il backend del listino: http://lab-rocky/api/ passa a
http://127.0.0.1:8080/. Il backend funziona (curl http://127.0.0.1:8080/listino.json
risponde), ma attraverso Apache /api/listino.json dà 503 Service Unavailable. Serve:

- /api/listino.json risponde attraverso Apache;
- SELinux resta enforcing, e tutto vale anche dopo un riavvio;
- dalla politica di sicurezza: Apache può collegarsi ai servizi web e ai proxy, ma non
  a porte qualsiasi né ai database;
- niente moduli di politica scritti a mano: si usano le impostazioni che SELinux
  prevede già.

Criteri di accettazione:
  sudo ./verifica.sh 10 4                  esce con 0
  curl -s http://127.0.0.1/api/listino.json   risponde il listino
EOF
}

# ---- Lezione 11: progetto finale -------------------------------------------------------------

UUID_DATI11=f1920314-c5d6-4ee2-b3f4-6f7081920314
UUID_WEB11=02a31425-d6e7-4ff3-84a5-708192031425
UUID_LOG11=24c53647-f809-4b15-a6b7-92a3b4253647
UUID_SWAP11=13b42536-e7f8-4a04-95b6-8192a3142536 # la swap di D2, cancellata dal collega
GUID_LVM=E6D6D379-F507-44C2-A23C-238F2A3DF928
DROPIN_SPAZIO=$DROPIN_JOURNAL/50-spazio.conf

# La macchina com'era prima della manutenzione: vgdati su D1 con i dati e il sito, Apache
# con la regola di SELinux per /srv/web e il sito aperto agli uffici, lab-app in servizio.
macchina_in_servizio() {
    local d1 p z
    d1=$(bersaglio D1)
    fai sfdisk -q --wipe always "$d1" <<EOF
label: gpt
start=2048, type=$GUID_LVM, name="pv-dati"
EOF
    fai udevadm settle
    if ((A_SECCO)); then p=${d1}1; else p=$(parte "$d1" 1); fi
    vg_con_lv vgdati dati 1G DATI "$UUID_DATI11" /srv/dati "$p"
    fai lvcreate -q -y -L 384M -n web vgdati
    if ((!A_SECCO)); then
        mkfs.xfs -q -f -L WEB -m uuid="$UUID_WEB11" /dev/vgdati/web
        riga_fstab "UUID=$UUID_WEB11  /srv/web  xfs  defaults  0 0"
        mkdir -p /srv/web
        mount /srv/web
        genera_file /srv/dati/archivio pratica 150 2000 1101
        genera_sito /srv/web/sito
        mkdir -p "$STATO/l11"
        manifest /srv/dati/archivio "$STATO/l11/dati.manifest"
        conta_file /srv/dati/archivio >"$STATO/l11/dati.quanti"
        manifest /srv/web/sito "$STATO/l11/sito.manifest"
    fi
    # lab-app, dal suo pacchetto, con i dati su /srv/dati.
    installa_lab_app
    fai sed -i 's|^dati = .*|dati = /srv/dati/app|' /etc/lab-app.conf
    fai mkdir -p /srv/dati/app
    fai chown labapp: /srv/dati/app
    file_kit /usr/lib/systemd/system/lab-app.service
    scrivi /usr/lib/systemd/system/lab-app.service 644 <<'EOF'
# Unità del pacchetto lab-app 1.4.
[Unit]
Description=lab-app, il servizio interno del gruppo applicazioni
RequiresMountsFor=/srv/dati

[Service]
User=labapp
ExecStart=/opt/lab-app/lab-app
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
    fai restorecon /usr/lib/systemd/system/lab-app.service
    fai systemctl daemon-reload
    fai systemctl enable -q --now lab-app.service
    # Il sito, con la regola delle etichette che c'è da quando il sito sta su /srv/web.
    echo "Preparo la regola di SELinux per /srv/web: ci vuole qualche secondo."
    fai semanage fcontext -a -t httpd_sys_content_t '/srv/web(/.*)?'
    fai restorecon -R /srv/web
    conf_sito /srv/web
    z=$(zona_di_rete)
    apri_sito "$z"
    fai systemctl enable -q httpd
    fai systemctl restart httpd
}

l11_p1() {
    local d2 d3 p z
    serve_password_root
    serve_web
    d2=$(bersaglio D2)
    d3=$(bersaglio D3)
    macchina_in_servizio
    z=$(zona_di_rete)
    # La manutenzione, nell'ordine del verbale.
    # 1. Il kernel nuovo, che diventa il predefinito: è rotto.
    crea_kernel_finto
    fai grubby --set-default "/boot/vmlinuz-$KERNEL_FINTO" >/dev/null
    # 2. I log sul disco che ospitava la swap: la swap sparisce, la sua riga in fstab resta,
    #    e l'etichetta del filesystem nuovo non è quella scritta in fstab.
    riga_fstab "UUID=$UUID_SWAP11  none  swap  defaults  0 0"
    una_partizione "$d2" log
    if ((!A_SECCO)); then
        p=$(parte "$d2" 1)
        mkfs.xfs -q -f -L LOG -m uuid="$UUID_LOG11" "$p"
        riga_fstab "LABEL=LOGS  /srv/log  xfs  defaults  0 0"
        mkdir -p /srv/log
        mount "$p" /srv/log
        genera_file /srv/log/lab-app registro 60 3000 1102
        manifest /srv/log "$STATO/l11/log.manifest"
        conta_file /srv/log >"$STATO/l11/log.quanti"
    fi
    # 3. Il volume dei dati più grande, ma il filesystem no.
    fai lvextend -q -L +512M vgdati/dati
    # 4. Il sito ripristinato da una copia in /root, con le etichette di là. Per vederlo
    #    funzionare, SELinux in permissive: solo fino al riavvio.
    fai chcon -R -t admin_home_t /srv/web/sito
    fai setenforce 0
    # 5. lab-app fermata, e che non riparta.
    fai systemctl stop lab-app.service
    fai systemctl mask -q lab-app.service
    # 6. Il journal solo in memoria, per risparmiare spazio su /var.
    fai mkdir -p "$DROPIN_JOURNAL"
    scrivi "$DROPIN_SPAZIO" 644 <<'EOF'
# Manutenzione di stanotte: /var si riempiva, il journal resta in memoria.
[Journal]
Storage=volatile
EOF
    fai systemctl restart systemd-journald
    # 7. Il sito chiuso agli uffici durante il ripristino, e riaperto solo fino al riavvio.
    fai firewall-cmd -q --permanent --zone="$z" --remove-service=http
    fai firewall-cmd -q --reload
    fai firewall-cmd -q --zone="$z" --add-service=http
    if ((!A_SECCO)); then
        atteso ZONA "$z"
        atteso T0 "$(date +%s)"
        atteso BOOT_ID "$(boot_id)"
        atteso LV_DATI "$(lvs --noheadings --units b --nosuffix -o lv_size vgdati/dati | tr -d ' ')"
    fi
    ticket <<EOF
TICKET 5901 — La macchina non è tornata su dopo la manutenzione
Da: responsabile dell'infrastruttura

Stanotte un collega ha fatto la manutenzione programmata di questa macchina, l'ha
riavviata ed è andato a casa. Stamattina non risponde. Dal suo verbale:

- ha installato a mano il kernel $KERNEL_FINTO, che il fornitore gli
  aveva mandato da provare;
- ha spostato i log dell'applicazione sul disco con $(come_riconoscerlo "$d2"),
  che prima ospitava la swap: l'ha formattato e montato in /srv/log;
- ha ingrandito di 512 MiB il volume dei dati (/srv/dati), per la crescita prevista;
- ha ripristinato il sito interno (/srv/web) da una copia che teneva in /root;
- durante il lavoro sui dati ha fermato lab-app, e si è assicurato che non ripartisse;
- durante il ripristino ha chiuso il sito agli uffici; alla fine l'ha riaperto e ha
  controllato che si vedesse.

Il disco con $(come_riconoscerlo "$d3") è libero.

Per riprodurre il riavvio di stanotte, con la console della VM aperta:
  sudo systemctl reboot
(se la macchina si blocca, nel menu di VirtualBox: Macchina → Ripristina)

Serve una macchina che riparte da sola, senza nessuno alla console:
- il kernel di prima, $KERNEL_BUONO, è il predefinito; il kernel di
  prova non è un pacchetto: va tolto del tutto, file e voce del menu;
- l'avvio arriva fino in fondo senza fermarsi e senza unità fallite;
- /srv/dati, /srv/web e /srv/log montati a ogni avvio, con i dati intatti;
- /srv/dati con tutto lo spazio del volume ingrandito;
- almeno 512 MiB di swap attiva a ogni avvio, su un disco dedicato;
- lab-app di nuovo in servizio, anche ai prossimi avvii;
- il sito risponde con SELinux enforcing, ed è raggiungibile dagli uffici;
- il journal conserva gli avvii precedenti: il fornitore vuole vedere i prossimi guasti;
- alla fine, un riavvio di prova, senza toccare niente.

Criteri di accettazione, dopo il riavvio finale:
  sudo ./verifica.sh 11 1                  esce con 0
  systemctl is-system-running              stampa running
  journalctl --list-boots                  mostra anche l'avvio prima di questo
EOF
}

# ---- Pulizia: la macchina come la lascia la lezione, da dismettere a mano ----------

l01_ppulizia() {
    local a b p1
    a=$(bersaglio D1)
    b=$(bersaglio D2)
    fai sfdisk -q --wipe always "$a" <<EOF
label: gpt
start=2048, size=2097152, type=$GUID_LINUX, name="dati-db"
EOF
    fai sfdisk -q --wipe always "$b" <<EOF
label: dos
start=2048, size=524288, type=83, bootable
start=526336, size=524288, type=82
EOF
    fai udevadm settle
    if ((!A_SECCO)); then
        p1=$(parte "$a" 1)
        mkfs.ext4 -q -F -L DATIDB "$p1"
        monta "$p1" /srv/archivio
        genera_file /srv/archivio/prove p 20 300 999
    fi
    occupa archivio /srv/archivio
    ticket <<EOF
TICKET 4790 — Restituire i dischi
Da: responsabile dell'infrastruttura

La lezione è finita: i due dischi dedicati tornano in magazzino e devono uscire puliti,
come nuovi. Su questa macchina qualcuno li sta ancora usando.

- Niente di montato dai dischi dedicati, nessun servizio che li tenga occupati.
- Nessuna firma: né tabelle delle partizioni, né filesystem.
- Il disco di sistema non si tocca.

Prima di chiudere il ticket: sudo ./verifica.sh 01 pulizia deve uscire con 0.
EOF
}

l02_ppulizia() {
    local d p
    d=$(bersaglio D1)
    fai sfdisk -q --wipe always "$d" <<EOF
label: gpt
start=2048, size=1638400, type=$GUID_LINUX, name="app"
start=1640448, size=1228800, type=$GUID_LINUX, name="log"
start=2869248, size=409600, type=$GUID_DATI_MS, name="scambio"
EOF
    fai udevadm settle
    if ((!A_SECCO)); then
        p=$(parte "$d" 1)
        mkfs.xfs -q -f -L APPDATI "$p"
        monta "$p" /srv/app
        p=$(parte "$d" 2)
        mkfs.ext4 -q -F -m 1 -L LOG "$p"
        monta "$p" /srv/log
        p=$(parte "$d" 3)
        mkfs.vfat -F 32 -n SCAMBIO "$p" >/dev/null
        monta "$p" /srv/scambio
        genera_file /srv/log/oggi l 30 500 998
    fi
    occupa log /srv/log
    ticket <<EOF
TICKET 4890 — Dismettere il server applicativo
Da: responsabile dell'infrastruttura

Il server applicativo viene spento per sempre. Prima, il suo disco dati (quello con
$(come_riconoscerlo "$d")) va restituito pulito: niente di montato, nessun servizio che lo
usi, nessuna firma di tabelle o filesystem. Il disco di sistema non si tocca.

Prima di chiudere il ticket: sudo ./verifica.sh 02 pulizia deve uscire con 0.
EOF
}

l03_ppulizia() {
    local a b c p
    a=$(bersaglio D1)
    b=$(bersaglio D2)
    c=$(bersaglio D3)
    una_partizione "$a" archivio
    una_partizione "$b" dati
    una_partizione "$c" backup
    if ((!A_SECCO)); then
        p=$(parte "$a" 1)
        mkfs.xfs -q -f -L ARCHIVIO -m uuid="$UUID_ARCHIVIO3" "$p"
        p=$(parte "$b" 1)
        mkfs.xfs -q -f -L DATI -m uuid="$UUID_DATI" "$p"
        p=$(parte "$c" 1)
        mkfs.ext4 -q -F -L BACKUP -U "$UUID_BACKUP" "$p"
        mkdir -p /srv/archivio /srv/dati /srv/backup
        riga_fstab "UUID=$UUID_ARCHIVIO3  /srv/archivio  xfs   noatime  0 0"
        riga_fstab "LABEL=DATI  /srv/dati  xfs  defaults  0 0"
        riga_fstab "UUID=$UUID_BACKUP  /srv/backup  ext4  nofail,x-systemd.device-timeout=10s  0 2"
        mount /srv/archivio
        mount /srv/dati
        mount /srv/backup
    fi
    ticket <<EOF
TICKET 5190 — Restituire i dischi, e che la macchina riparta
Da: responsabile dell'infrastruttura

I tre dischi dedicati tornano in magazzino. Vanno restituiti puliti: niente di montato,
nessuna firma di tabelle o filesystem. E la macchina deve continuare ad avviarsi senza
di loro: /etc/fstab torna com'era prima della lezione, e il sistema di avvio deve usare
già la configurazione nuova. Il disco di sistema non si tocca.

Prima di chiudere il ticket: sudo ./verifica.sh 03 pulizia deve uscire con 0.
EOF
}

l04_ppulizia() {
    local d p2
    d=$(bersaglio D1)
    fai sfdisk -q --wipe always "$d" <<EOF
label: gpt
start=2048, size=2097152, type=$GUID_LINUX, name="dati"
start=2099200, size=1048576, type=$GUID_SWAP, name="swap"
EOF
    fai udevadm settle
    l04_dati "$d"
    if ((!A_SECCO)); then
        p2=$(parte "$d" 2)
        mkswap -U "$UUID_SWAP4" "$p2" >/dev/null
        fallocate -l 128M /srv/dati/swapfile
        chmod 600 /srv/dati/swapfile
        mkswap /srv/dati/swapfile >/dev/null
        riga_fstab "UUID=$UUID_SWAP4  none  swap  pri=10  0 0"
        riga_fstab "/srv/dati/swapfile  none  swap  pri=5  0 0"
        swapon -a
    fi
    ticket <<EOF
TICKET 5290 — Restituire il disco dati
Da: responsabile dell'infrastruttura

Il disco con $(come_riconoscerlo "$d") torna in magazzino. Ci stanno sopra una partizione
dati montata, una partizione di swap e un file di swap, tutti attivi e tutti in
/etc/fstab. Va restituito pulito: niente di montato, nessuna swap attiva da lì, nessuna
firma. /etc/fstab torna com'era prima della lezione e il sistema di avvio deve usare
già la configurazione nuova. Il disco di sistema non si tocca.

Prima di chiudere il ticket: sudo ./verifica.sh 04 pulizia deve uscire con 0.
EOF
}

l05_ppulizia() {
    local a b c
    a=$(bersaglio D1)
    b=$(bersaglio D2)
    c=$(bersaglio D3)
    vg_con_lv vgdati lvdb 2.5G DB "$UUID_DB5" /srv/db "$a" "$b"
    vg_con_lv vgvecchio lvdati 800M ARCHIVIO "$UUID_ARCH5" /srv/archivio "$c"
    ticket <<EOF
TICKET 5390 — Restituire i dischi del volume
Da: responsabile dell'infrastruttura

I tre dischi dedicati tornano in magazzino. Sopra ci sono due VG, vgdati e vgvecchio,
con i loro volumi montati e scritti in /etc/fstab. Vanno restituiti puliti:

- niente di montato, nessun VG e nessun PV sui dischi dedicati, nessuna firma;
- LVM non deve più cercarli all'avvio;
- /etc/fstab com'era prima della lezione, già riletto dal sistema di avvio;
- il disco di sistema, e il suo VG, non si toccano.

Prima di chiudere il ticket: sudo ./verifica.sh 05 pulizia deve uscire con 0.
EOF
}

l06_ppulizia() {
    app_su_lvm
    fai lvcreate -q -y -s -L 300M -n lvapp-prima vgapp/lvapp
    if ((!A_SECCO)); then
        mkdir -p /srv/app-prima
        mount -o ro,nouuid /dev/vgapp/lvapp-prima /srv/app-prima
    fi
    ticket <<EOF
TICKET 5490 — Restituire i dischi dell'applicazione
Da: responsabile dell'infrastruttura

L'applicazione è stata migrata altrove. vgapp occupa due dischi dedicati: c'è lvapp,
montato su /srv/app, e il suo snapshot lvapp-prima, montato su /srv/app-prima.
Vanno restituiti puliti:

- niente di montato, nessun VG e nessun PV sui dischi dedicati, nessuna firma;
- LVM non deve più cercarli all'avvio;
- /etc/fstab com'era prima della lezione, già riletto dal sistema di avvio;
- il disco di sistema, e il suo VG, non si toccano.

Prima di chiudere il ticket: sudo ./verifica.sh 06 pulizia deve uscire con 0.
EOF
}

l07_ppulizia() {
    local a b c p
    a=$(bersaglio D1)
    b=$(bersaglio D2)
    c=$(bersaglio D3)
    una_partizione "$a" archivio
    una_partizione "$b" indici
    una_partizione "$c" dati
    if ((!A_SECCO)); then
        p=$(parte "$a" 1)
        mkfs.ext4 -q -F -L ARCHIVIO -U "$UUID_ARCHIVIO7" "$p"
        riga_fstab "UUID=$UUID_ARCHIVIO7  /srv/archivio  ext4  defaults,errors=remount-ro  0 2"
        p=$(parte "$b" 1)
        mkfs.xfs -q -f -L INDICI -m uuid="$UUID_INDICI7" "$p"
        riga_fstab "UUID=$UUID_INDICI7  /srv/indici  xfs  defaults  0 0"
        p=$(parte "$c" 1)
        mkfs.xfs -q -f -L DATI -m uuid="$UUID_DATI7" "$p"
        riga_fstab "UUID=$UUID_DATI7  /srv/dati  xfs  defaults  0 0"
        mkdir -p /srv/archivio /srv/indici /srv/dati
        mount /srv/archivio
        mount /srv/indici
        mount /srv/dati
        genera_fatture /srv/archivio/fatture 40 1201
        genera_file /srv/indici/storico indice 100 2000 1301
        genera_file /srv/dati/tabelle tabella 100 2000 1401
    fi
    occupa archivio /srv/archivio
    ticket <<EOF
TICKET 5590 — Restituire i dischi dopo il guasto
Da: responsabile dell'infrastruttura

Archivio, indici e database sono stati spostati su un'altra macchina. I tre dischi
dedicati tornano in magazzino: sopra ci sono /srv/archivio (ext4), /srv/indici e
/srv/dati (XFS), tutti montati e scritti in /etc/fstab, e l'archivio è ancora in uso
da lab-occupa-archivio. Vanno restituiti puliti:

- niente di montato e nessuna firma sui dischi dedicati;
- /etc/fstab com'era prima della lezione, già riletto dal sistema di avvio, così il
  prossimo riavvio non si ferma in emergenza;
- il disco di sistema non si tocca.

Prima di chiudere il ticket: sudo ./verifica.sh 07 pulizia deve uscire con 0.
EOF
}

l08_ppulizia() {
    local d p1 attesa
    d=$(bersaglio D1)
    una_partizione "$d" dati
    if ((!A_SECCO)); then
        p1=$(parte "$d" 1)
        mkfs.ext4 -q -F -L DATI -U "$UUID_DATI8" "$p1"
        riga_fstab "UUID=$UUID_DATI8  /srv/dati  ext4  defaults  0 2"
        mkdir -p /srv/dati
        mount /srv/dati
        genera_file /srv/dati/tabelle tabella 100 2000 1501
    fi
    # Come lo lasciano i problemi 3 e 4: il parametro del fornitore ovunque, il menu a
    # 10 secondi, il kernel finto installato ma non predefinito, UPDATEDEFAULT=no.
    crea_kernel_finto
    fai grubby --update-kernel=ALL --args=transparent_hugepage=never
    fai sed -i -E 's/^GRUB_TIMEOUT=.*/GRUB_TIMEOUT=10/' /etc/default/grub
    fai grub2-mkconfig -o /boot/grub2/grub.cfg
    fai sed -i -E 's/^UPDATEDEFAULT=.*/UPDATEDEFAULT=no/' /etc/sysconfig/kernel
    fai grubby --set-default "/boot/vmlinuz-$KERNEL_BUONO" >/dev/null
    attesa=$(sed -n 's/^GRUB_TIMEOUT=//p' "$AVVIO/grub" 2>/dev/null || true)
    ticket <<EOF
TICKET 5690 — Riportare l'avvio allo standard
Da: responsabile dell'infrastruttura

Il fornitore ha chiuso il caso e il database è stato spostato. La macchina torna alla
configurazione standard dei server:

- il kernel $KERNEL_FINTO non serve più: non era un pacchetto, era una
  copia di prova, quindi si tolgono i suoi file in /boot e la sua voce nel menu;
- il parametro transparent_hugepage=never sparisce da tutti i kernel e dalla
  configurazione, compresa quella per i kernel futuri;
- il menu di GRUB torna ad aspettare ${attesa:-5} secondi;
- i prossimi aggiornamenti del kernel tornano a renderlo il predefinito, e il
  predefinito adesso è il kernel più recente installato;
- il disco dedicato con /srv/dati torna in magazzino: niente di montato, nessuna firma,
  /etc/fstab com'era prima della lezione.

Non serve riavviare. Prima di chiudere il ticket: sudo ./verifica.sh 08 pulizia deve
uscire con 0.
EOF
}

l09_ppulizia() {
    installa_lab_app
    disco_app
    # Come la lasciano i problemi: lab-app come servizio, il report col suo timer, crond
    # con i limiti.
    scrivi /etc/systemd/system/lab-app.service 644 <<'EOF'
[Unit]
Description=lab-app, il servizio interno del gruppo applicazioni
RequiresMountsFor=/srv/app

[Service]
User=labapp
ExecStart=/opt/lab-app/lab-app
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
    installa_report
    scrivi /etc/systemd/system/lab-report.service 644 <<'EOF'
[Unit]
Description=Report delle vendite per New York

[Service]
Type=oneshot
User=labapp
ExecStart=/opt/lab-report/report.sh
EOF
    scrivi /etc/systemd/system/lab-report.timer 644 <<'EOF'
[Unit]
Description=Report delle vendite per New York, nei giorni feriali

[Timer]
OnCalendar=Mon..Fri 07:00 America/New_York
Persistent=true
RandomizedDelaySec=15min

[Install]
WantedBy=timers.target
EOF
    fai mkdir -p /etc/systemd/system/crond.service.d
    scrivi /etc/systemd/system/crond.service.d/limiti.conf 644 <<'EOF'
[Service]
Nice=10
MemoryMax=1G
EOF
    fai restorecon -R /etc/systemd/system
    fai systemctl daemon-reload
    fai systemctl enable -q --now lab-app.service lab-report.timer
    fai systemctl restart crond
    ticket <<EOF
TICKET 5790 — Dismettere i servizi della casa
Da: responsabile dell'infrastruttura

lab-app e il report di New York si spostano su un'altra macchina, e il database se ne
va con loro. Qui vanno dismessi, senza lasciare tracce:

- lab-app.service, lab-report.service e lab-report.timer fermi, disabilitati e
  cancellati, e systemd non li conosce più, nemmeno come falliti;
- crond torna come lo vuole il pacchetto: niente ritocchi locali, e il crond che gira
  adesso non ha più i limiti;
- il disco dedicato con /srv/app torna in magazzino: niente di montato, nessuna firma,
  /etc/fstab com'era prima della lezione;
- l'utente labapp e i programmi in /opt restano: li toglie il kit.

Prima di chiudere il ticket: sudo ./verifica.sh 09 pulizia deve uscire con 0.
EOF
}

l10_ppulizia() {
    local z prima_s prima_p p1 attivo abilitato
    serve_web
    z=$(zona_di_rete)
    # Com'era il firewall prima della lezione: azzera l'ha appena riportato lì.
    if ((!A_SECCO)); then
        mkdir -p "$STATO/l10"
        zone_firewall --permanent >"$STATO/l10/ppulizia.zone"
    fi
    prima_s=$(firewall-cmd --permanent --zone="$z" --list-services)
    prima_p=$(firewall-cmd --permanent --zone="$z" --list-ports)
    attivo=$(cat "$WEB/httpd/attivo" 2>/dev/null || true)
    abilitato=$(cat "$WEB/httpd/abilitato" 2>/dev/null || true)
    # Il sito con la console e il proxy su /srv/www, il sito spostato su /srv/web.
    sito_www "$PROXY_API"
    if ((!A_SECCO)); then
        mkdir -p /srv/www/stato
        echo '<h1>Console di monitoraggio</h1>' >/srv/www/stato/index.html
    fi
    fai restorecon -R /srv/www
    local d2
    d2=$(bersaglio D2)
    una_partizione "$d2" web
    if ((!A_SECCO)); then
        p1=$(parte "$d2" 1)
        mkfs.xfs -q -f -L WEB -m uuid="$UUID_WEB" "$p1"
        riga_fstab "UUID=$UUID_WEB  /srv/web  xfs  defaults  0 0"
        mkdir -p /srv/web
        mount /srv/web
        genera_sito /srv/web/sito
    fi
    file_kit /etc/httpd/conf.d/lab-stato.conf
    scrivi /etc/httpd/conf.d/lab-stato.conf 644 <<'EOF'
Listen 8081
<VirtualHost *:8081>
    DocumentRoot /srv/www/stato
    <Directory /srv/www/stato>
        Require all granted
    </Directory>
</VirtualHost>
EOF
    file_kit /etc/httpd/conf.d/lab-web.conf
    scrivi /etc/httpd/conf.d/lab-web.conf 644 <<'EOF'
Alias /web /srv/web/sito
<Directory /srv/web/sito>
    Require all granted
</Directory>
EOF
    installa_backend
    echo "Preparo le personalizzazioni di SELinux: ci vuole qualche decina di secondi."
    fai semanage fcontext -a -t httpd_sys_content_t '/srv/web(/.*)?'
    fai restorecon -R /srv/web
    fai semanage port -a -t http_port_t -p tcp 8081
    fai setsebool -P httpd_can_network_relay on
    apri_sito "$z"
    fai firewall-cmd -q --permanent --zone="$z" --add-rich-rule='rule family="ipv4" source address="192.0.2.0/24" port port="8081" protocol="tcp" accept'
    fai firewall-cmd -q --reload
    fai systemctl enable -q httpd
    fai systemctl restart httpd
    ticket <<EOF
TICKET 5890 — Dismettere il sito interno
Da: responsabile dell'infrastruttura

Il sito interno, la console di monitoraggio e il backend del listino sono passati su
un'altra macchina. Questa torna com'era prima della lezione:

- Apache: prima della lezione era «${attivo:-?}» e all'avvio «${abilitato:-?}»; torna
  così, senza le configurazioni del sito, della console e del proxy (i file lab-*.conf
  in /etc/httpd/conf.d);
- lab-backend.service fermo e cancellato;
- il firewall della zona $z torna com'era: servizi «$prima_s», porte «$prima_p»,
  nessuna regola per la console; adesso e in modo permanente;
- SELinux: via la regola delle etichette di /srv/web, l'etichetta della porta 8081 e il
  booleano del proxy, tornati come li prevede la politica; resta enforcing,
  anche dopo un riavvio;
- i due dischi dedicati, con /srv/www e /srv/web, tornano in magazzino: niente di
  montato, nessuna firma, /etc/fstab com'era prima della lezione.

Prima di chiudere il ticket: sudo ./verifica.sh 10 pulizia deve uscire con 0.
EOF
}

UUID_SWAP11_NUOVA=35d64758-091a-4c26-b7c8-a3b4c5364758

l11_ppulizia() {
    local d2 d3 p z prima_s prima_p attivo abilitato
    serve_web
    z=$(zona_di_rete)
    # Com'era il firewall prima del progetto: azzera l'ha appena riportato lì.
    if ((!A_SECCO)); then
        mkdir -p "$STATO/l11"
        zone_firewall --permanent >"$STATO/l11/ppulizia.zone"
    fi
    prima_s=$(firewall-cmd --permanent --zone="$z" --list-services)
    prima_p=$(firewall-cmd --permanent --zone="$z" --list-ports)
    attivo=$(cat "$WEB/httpd/attivo" 2>/dev/null || true)
    abilitato=$(cat "$WEB/httpd/abilitato" 2>/dev/null || true)
    d2=$(bersaglio D2)
    d3=$(bersaglio D3)
    macchina_in_servizio
    # Come la lascia il progetto riparato: i log su D2, la swap su D3, il volume dei dati
    # ingrandito con il suo filesystem.
    una_partizione "$d2" log
    fai sfdisk -q --wipe always "$d3" <<EOF
label: gpt
start=2048, size=1048576, type=$GUID_SWAP, name="swap"
EOF
    fai udevadm settle
    if ((!A_SECCO)); then
        p=$(parte "$d2" 1)
        mkfs.xfs -q -f -L LOG -m uuid="$UUID_LOG11" "$p"
        riga_fstab "LABEL=LOG  /srv/log  xfs  defaults  0 0"
        mkdir -p /srv/log
        mount /srv/log
        genera_file /srv/log/lab-app registro 60 3000 1102
        p=$(parte "$d3" 1)
        mkswap -U "$UUID_SWAP11_NUOVA" "$p" >/dev/null
        riga_fstab "UUID=$UUID_SWAP11_NUOVA  none  swap  defaults  0 0"
        swapon "$p"
    fi
    fai lvextend -q -r -L +512M vgdati/dati
    ticket <<EOF
TICKET 5990 — Dismettere la macchina dell'applicazione
Da: responsabile dell'infrastruttura

lab-app, i suoi dati e il sito interno passano su una macchina nuova. Questa torna
com'era prima del progetto:

- lab-app ferma e disabilitata (il suo pacchetto, in /usr/lib, lo toglie il kit);
- Apache: prima del progetto era «${attivo:-?}» e all'avvio «${abilitato:-?}»; torna
  così, senza la configurazione del sito (/etc/httpd/conf.d/lab-sito.conf);
- il firewall della zona $z torna com'era: servizi «$prima_s», porte «$prima_p»,
  adesso e in modo permanente;
- SELinux: via la regola delle etichette di /srv/web, tornate come le prevede la
  politica; resta enforcing, anche dopo un riavvio;
- la swap sul disco con $(come_riconoscerlo "$d3") spenta;
- i tre dischi dedicati in magazzino: niente di montato, nessuna firma, nessun PV,
  e LVM non deve più cercarli all'avvio, come nella lezione 05;
  /etc/fstab com'era prima del progetto.

Prima di chiudere il ticket: sudo ./verifica.sh 11 pulizia deve uscire con 0.
EOF
}

# Per il correttore delle pulizie: dove cominciano le partizioni dei bersagli (le firme
# restano lì anche dopo aver cancellato la tabella, G6) e quali swap del sistema sono
# accese (la pulizia non le deve spegnere, G5).
ricorda_per_la_pulizia() {
    local n p q s o swap=()
    for n in $(bersagli_registrati); do
        p=$(percorso_bersaglio "$n")
        [[ -n $p ]] || continue
        atteso "INIZI_$n" "$(lsblk -nrpo NAME,TYPE "$p" | awk '$2 == "part" { print $1 }' |
            while read -r q; do cat "/sys/class/block/${q##*/}/start"; done | paste -sd' ' -)"
    done
    while read -r s; do
        if [[ -b $s ]]; then o=$s; else o=$(findmnt -n -o SOURCE -T "$s" 2>/dev/null || true); fi
        for n in $(tutti_i_bersagli); do antenati "$o" | grep -qx -- "$n" && continue 2; done
        swap+=("$(readlink -f -- "$s")")
    done < <(awk 'NR > 1 { print $1 }' /proc/swaps)
    atteso SWAP_SISTEMA "${swap[*]}"
}

# ---- Avvio ------------------------------------------------------------------------

prepara() {
    LEZIONE=$1 PROBLEMA=${2:-1}
    declare -F "l${LEZIONE}_p$PROBLEMA" >/dev/null || {
        errore "Problema sconosciuto: lezione $LEZIONE, problema $PROBLEMA (lezioni: ${LEZIONI[*]})"
        exit 2
    }
    [[ -s $BERSAGLI ]] || { errore "Manca l'inventario: lancia prima sudo ./prepara.sh dischi"; exit 2; }
    local parti x
    parti=" $(parti_della_lezione "$LEZIONE") "
    if [[ $parti == *" avvio "* ]]; then fotografa_avvio; fi
    if [[ $parti == *" servizi "* ]]; then fotografa_servizi; fi
    if [[ $parti == *" web "* ]]; then fotografa_web; fi
    azzera
    # Da qui lo scenario può cambiare queste parti: il prossimo azzera le riporterà.
    if ((!A_SECCO)); then for x in $parti; do echo "$x" >>"$DA_RIPORTARE"; done; fi
    mkdir -p "$PALESTRA/l$LEZIONE" "$PROVA"
    chown "$(utente_vero)" "$PALESTRA" "$PALESTRA/l$LEZIONE" 2>/dev/null || true
    ATTESO=$STATO/atteso
    ((A_SECCO)) || : >"$ATTESO"
    "l${LEZIONE}_p$PROBLEMA"
    ((A_SECCO)) || [[ $PROBLEMA != pulizia ]] || ricorda_per_la_pulizia
    ((A_SECCO)) || echo "$LEZIONE $PROBLEMA" >"$CORRENTE"
    echo "Pronto: lezione $LEZIONE, problema $PROBLEMA."
}

ARGOMENTI=()
for a; do
    if [[ $a == --a-secco ]]; then A_SECCO=1; else ARGOMENTI+=("$a"); fi
done
set -- "${ARGOMENTI[@]}"

case ${1:-} in
    "" | -h | --help)
        sed -n '2,14p' "$0"
        [[ -n ${1:-} ]]
        ;;
    dischi)
        serve_root
        serve_comandi lsblk findmnt blkid sfdisk wipefs losetup jq systemd-detect-virt
        shift
        inventario "$@"
        ;;
    azzera)
        serve_root
        azzera
        ;;
    stato)
        serve_root
        [[ -s $BERSAGLI ]] || { echo "Nessun inventario."; exit 0; }
        echo "Bersagli:"
        mostra_bersagli
        echo "Preparato ora: $(corrente || echo nessuno)"
        echo "Unità del kit attive: $(unita_del_kit | paste -sd' ' -)"
        ;;
    [0-9][0-9])
        serve_root
        serve_comandi lsblk findmnt blkid sfdisk wipefs losetup jq mkfs.ext4 mkfs.xfs mkfs.vfat mkswap swapon fallocate useradd groupadd systemd-run udevadm pvcreate vgcreate lvcreate lvmdevices \
            debugfs xfs_io fsfreeze grubby grub2-editenv grub2-mkconfig journalctl restorecon setpriv pgrep
        prepara "$@"
        ;;
    *)
        errore "Uso: sudo $0 dischi | NN [P] | azzera | stato   (lezioni: ${LEZIONI[*]})"
        exit 2
        ;;
esac
