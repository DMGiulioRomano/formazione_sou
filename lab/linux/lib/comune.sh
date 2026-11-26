# shellcheck shell=bash
# Le variabili sono usate dagli script che caricano questo file.
# shellcheck disable=SC2034
# Libreria comune del kit Linux, caricata da prepara.sh e verifica.sh.
#
# Il kit tocca solo i "bersagli": i dischi dedicati della VM, registrati per seriale
# con `prepara.sh dischi`, oppure immagini collegate a dispositivi loop. Ogni funzione
# che scrive o ispeziona un disco passa prima da `ammesso`, che rifà i controlli da zero
# a ogni chiamata e, se qualcosa non torna, ferma tutto con codice 3.
#
# Codici di uscita comuni: 0 riuscito, 1 non riuscito, 2 uso o prerequisiti,
# 3 rifiuto (dispositivo o ambiente non previsto), 4 serve root.

STATO=/var/lib/lab-linux
BERSAGLI=$STATO/bersagli      # righe "D1 seriale VB..." oppure "D1 loop /var/lib/lab-linux/immagini/d1.img"
IMMAGINI=$STATO/immagini
BASE=$STATO/base              # fotografia del sistema al momento dell'inventario
CORRENTE=$STATO/corrente      # "NN P": lezione e problema preparati ora
ESITI=$STATO/esiti            # una riga per ogni verifica: lezione, problema, esito, data
PROVA=/run/lab-linux          # montaggi temporanei del kit e del correttore
MODELLO=${LAB_MODELLO:-VBOX HARDDISK}
MAX_BYTE=$((16 * 1024 * 1024 * 1024))
GIB=$((1024 * 1024 * 1024))
MIB=$((1024 * 1024))

# Punti di montaggio che appartengono al kit: tutto ciò che è montato altrove è del sistema.
PUNTI_KIT=(/srv/archivio /srv/app /srv/log /srv/indici /srv/posta /srv/scambio
    /srv/dati /srv/backup /srv/progetti /srv/db /srv/app-prima /srv/www /srv/web)
FILE_DISPOSITIVI=/etc/lvm/devices/system.devices  # l'elenco dei dischi che LVM usa (Rocky 9)
# LVM avvisa dei descrittori ereditati dalle sostituzioni di processo: qui sono innocui.
export LVM_SUPPRESS_FD_WARNINGS=1

# Le righe del file dei dispositivi di LVM che riguardano DISCO: per seriale nel nome
# stabile (IDNAME), per file dell'immagine se è un loop, o per nome attuale del dispositivo
# o di una sua partizione, ma solo se il nome è l'identità (IDTYPE=devname).
righe_dispositivi_di() {
    local disco=$1 s img riga tipo idn nome
    s=$(lsblk -dno SERIAL "$disco" 2>/dev/null | sed 's/ *$//')
    img=$(losetup -nO BACK-FILE "$disco" 2>/dev/null)
    lvmdevices 2>/dev/null | grep '^ *Device ' | while read -r riga; do
        tipo=$(sed -n 's/.* IDTYPE=\([^ ]*\).*/\1/p' <<<"$riga")
        idn=$(sed -n 's/.* IDNAME=\([^ ]*\).*/\1/p' <<<"$riga")
        nome=$(sed -n 's/.* DEVNAME=\([^ ]*\).*/\1/p' <<<"$riga")
        # DEVNAME è solo un suggerimento: dopo un riavvio con i dischi scambiati resta il nome
        # vecchio, che oggi può essere quello di un bersaglio. Conta l'identità stabile.
        if [[ -n $s && $idn == *"$s" ]] || [[ -n $img && $idn == "$img" ]] ||
            { [[ $tipo == devname && -n $nome && -b $nome ]] && antenati "$nome" | grep -qx -- "$disco"; }; then
            echo "$riga"
        fi
    done
}
UTENTI_KIT=$STATO/utenti-kit  # utenti e gruppi creati dagli scenari: righe "utente NOME" o "gruppo NOME"

errore() { printf '%s\n' "$*" >&2; }

rifiuta() {
    errore "RIFIUTO: $*"
    errore "Non ho toccato niente. Controlla con: lsblk -o NAME,SIZE,MODEL,SERIAL,MOUNTPOINTS"
    exit 3
}

serve_root() {
    ((EUID == 0)) || { errore "Serve root: rilancia con sudo."; exit 4; }
}

serve_comandi() {
    local c mancano=()
    for c; do command -v "$c" >/dev/null || mancano+=("$c"); done
    if ((${#mancano[@]} > 0)); then
        errore "Mancano questi comandi: ${mancano[*]}"
        errore "Vedi «Preparare la macchina» in studio/lezioni/linux/00-percorso-linux.md."
        exit 2
    fi
}

# Il kit gira solo dentro una macchina virtuale: su un computer vero rifiuta.
serve_vm() {
    local tipo
    tipo=$(systemd-detect-virt --vm 2>/dev/null) || rifiuta "non sono in una macchina virtuale (systemd-detect-virt: ${tipo:-none})."
}

punto_del_kit() {
    local t=$1 p
    [[ $t == "$PROVA" || $t == "$PROVA"/* ]] && return 0
    for p in "${PUNTI_KIT[@]}"; do [[ $t == "$p" ]] && return 0; done
    return 1
}

# Il dispositivo e tutti i suoi antenati (partizione → disco, LV → PV → disco).
antenati() { lsblk -nrspo NAME "$1" 2>/dev/null | awk '!visto[$1]++'; }

# Il disco (o il loop) in cima a un dispositivo.
disco_di() {
    lsblk -nrspo NAME,TYPE "$1" 2>/dev/null | awk '$2 == "disk" || $2 == "loop" { print $1 }' | sort -u
}

bersagli_registrati() { [[ -s $BERSAGLI ]] && awk '{ print $1 }' "$BERSAGLI"; }

# Percorso attuale di un bersaglio: i nomi come sdb possono cambiare a ogni avvio,
# il seriale e il file d'origine no.
percorso_bersaglio() {
    local tipo id
    read -r _ tipo id < <(awk -v n="$1" '$1 == n' "$BERSAGLI")
    case ${tipo:-} in
        seriale) lsblk -dnpo NAME,SERIAL | awk -v s="$id" '$2 == s { print $1 }' ;;
        loop) losetup -nO NAME -j "$id" 2>/dev/null | head -1 ;;
    esac
}

seriale_di() { lsblk -dno SERIAL "$1" 2>/dev/null | sed 's/ *$//'; }

tutti_i_bersagli() {
    local n
    for n in $(bersagli_registrati); do percorso_bersaglio "$n"; done
}

# Nome (D1, D2, ...) del bersaglio che oggi si chiama DISCO.
nome_bersaglio() {
    local n
    for n in $(bersagli_registrati); do
        [[ $(percorso_bersaglio "$n") == "$1" ]] && { echo "$n"; return 0; }
    done
    return 1
}

e_bersaglio() { nome_bersaglio "$1" >/dev/null; }

# Dopo un riavvio i loop spariscono: li ricollega, se l'inventario li prevede.
ricollega_loop() {
    local n tipo id
    [[ -s $BERSAGLI ]] || return 0
    while read -r n tipo id; do
        [[ $tipo == loop ]] || continue
        [[ -n $(losetup -nO NAME -j "$id" 2>/dev/null) ]] && continue
        [[ -f $id ]] || rifiuta "manca l'immagine $id di $n: rifai l'inventario con prepara.sh dischi --loop."
        losetup -f -P "$id"
    done <"$BERSAGLI"
    udevadm settle 2>/dev/null || true
}

# ammesso DEV: il kit può toccare DEV? Lo stato si rilegge ogni volta, niente cache.
ammesso() {
    local dev=$1 disco nome tipo id riga vg pv
    [[ -b $dev ]] || rifiuta "$dev non è un dispositivo a blocchi."
    serve_vm
    for disco in $(disco_di "$dev"); do
        nome=$(nome_bersaglio "$disco") || rifiuta "$dev sta su $disco, che non è fra i bersagli dell'inventario."
        read -r _ tipo id < <(awk -v n="$nome" '$1 == n' "$BERSAGLI")
        if [[ $tipo == seriale ]]; then
            [[ $(lsblk -dno MODEL "$disco" | sed 's/ *$//') == "$MODELLO" ]] || rifiuta "$disco non ha il modello «$MODELLO»."
            (($(lsblk -dbno SIZE "$disco") <= MAX_BYTE)) || rifiuta "$disco è più grande di 16 GiB: non sembra un disco del laboratorio."
            [[ $(seriale_di "$disco") == "$id" ]] || rifiuta "il seriale di $disco non è quello registrato."
        fi
        # Nessun filesystem del disco può essere montato fuori dai punti del kit.
        while read -r riga; do
            local t=${riga%% *} s=${riga#* }
            s=${s%%[*}
            [[ $s == /dev/* ]] || continue
            punto_del_kit "$t" && continue
            if antenati "$s" | grep -qx -- "$disco"; then
                rifiuta "$disco porta a $t (montato da $s), che non è un punto del kit: è in uso dal sistema o da te."
            fi
        done < <(findmnt -rn -o TARGET,SOURCE)
        # Un VG che usa questo disco deve stare tutto sui bersagli.
        if command -v pvs >/dev/null; then
            while read -r pv vg; do
                [[ -n $vg ]] || continue
                antenati "$pv" | grep -qx -- "$disco" || continue
                local altro
                for altro in $(pvs --devicesfile "" --noheadings -o pv_name -S "vg_name=$vg" 2>/dev/null); do
                    local da
                    for da in $(disco_di "$altro"); do
                        e_bersaglio "$da" || rifiuta "il VG $vg usa $disco ma anche $da, che non è un bersaglio."
                    done
                done
            done < <(pvs --devicesfile "" --noheadings -o pv_name,vg_name 2>/dev/null)
        fi
    done
    return 0
}

# fai COMANDO...: esegue, o con --a-secco stampa soltanto. Tutte le scritture passano da qui.
A_SECCO=0
fai() {
    if ((A_SECCO)); then
        printf '+ %s\n' "$*"
        return 0
    fi
    "$@"
}

# Partizione numero N del disco, come la vede il kernel.
parte() {
    local p
    for p in $(lsblk -nrpo NAME,TYPE "$1" | awk '$2 == "part" { print $1 }'); do
        [[ $(cat "/sys/class/block/${p##*/}/partition" 2>/dev/null) == "$2" ]] && { echo "$p"; return 0; }
    done
    return 1
}

# Dimensione in byte di un dispositivo.
byte_di() { blockdev --getsize64 "$1"; }

# Lezione e problema preparati ora.
corrente() { [[ -s $CORRENTE ]] && cat "$CORRENTE"; }

# Utente che ha lanciato sudo, per lasciargli la proprietà della palestra.
utente_vero() { echo "${SUDO_USER:-root}"; }
