# shellcheck shell=bash
# Dati finti ma ripetibili: stesso seme, stessi file, stesso manifest.

# genera_file CARTELLA PREFISSO QUANTI BYTE_MEDI SEME
# Crea QUANTI file di testo, lunghi intorno a BYTE_MEDI, con un generatore scritto qui.
genera_file() {
    mkdir -p "$1"
    awk -v dir="$1" -v pre="$2" -v n="$3" -v dim="$4" -v seme="$5" '
    function rnd(m) { seme = (seme * 16807) % 2147483647; return seme % m }
    BEGIN {
        split("rapporto ordine fattura avviso nota verbale richiesta conferma", tipo, " ")
        for (i = 1; i <= n; i++) {
            f = sprintf("%s/%s%05d.txt", dir, pre, i)
            t = tipo[rnd(8) + 1]
            printf "Oggetto: %s n. %d\nDa: servizio%02d@esempio.it\n\n", t, i, rnd(40) > f
            lun = int(dim / 2) + rnd(dim)
            riga = ""
            while (length(riga) < lun) riga = riga sprintf("%s %d; ", t, rnd(100000))
            print riga > f
            close(f)
        }
    }'
}

# genera_grande FILE MIB SEME: un file grande, ripetibile, senza leggere /dev/urandom.
genera_grande() {
    # yes finisce per SIGPIPE quando head ha letto abbastanza: con pipefail non è un errore.
    { yes "blocco di prova $3: il contenuto conta solo perché il suo hash non cambi" || true; } |
        head -c "$(($2 * 1024 * 1024))" >"$1"
}

# manifest CARTELLA FILE: hash di ogni file, con percorsi relativi.
manifest() {
    (cd "$1" && find . -type f ! -path './lost+found/*' -print0 | LC_ALL=C sort -z | xargs -0 -r sha256sum) >"$2"
}

# controlla_manifest CARTELLA FILE: 0 se ogni file c'è ed è identico.
controlla_manifest() {
    [[ -d $1 && -s $2 ]] || return 1
    (cd "$1" && sha256sum --quiet --strict -c "$2" >/dev/null 2>&1)
}
