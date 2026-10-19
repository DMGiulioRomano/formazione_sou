# JOURNALCTL

## 3. Filtrare per "Contesto" (L'Avvio o il Servizio)

Frugare in milioni di righe è inutile. Puoi dire a `journalctl` di isolare solo i pezzi del grafo che ti interessano [🎨]:

- `journalctl -b` (boot): mostra solo i log generati dall'avvio corrente del PC, ignorando la cronologia dei giorni passati [🎨].
- `journalctl -b -1`: mostra i log dell'avvio precedente (utilissimo se il PC è crashato e vuoi capire cosa è successo prima del riavvio). Puoi risalire indietro usando `-2`, `-3`, ecc.
- `journalctl --list-boots`: ti mostra l'elenco di tutti i riavvii storici salvati in memoria, ognuno con la sua data e il suo codice identificativo (ID).
- `journalctl -u <nome_servizio>`: isola i messaggi inviati da una specifica unità di systemd (es. `journalctl -u sshd` per vedere i tentativi di accesso remoti) [🎨].

## 4. Filtrare per Tempo (La precisione millimetrica)

Grazie all'indicizzazione di `journald`, puoi fare domande temporali in linguaggio quasi naturale [🎨]:

- `journalctl --since today`: mostra solo i log scritti da mezzanotte a adesso [🎨].
- `journalctl --since yesterday`: mostra i log da ieri a oggi.
- `journalctl --since "2026-10-15 14:00:00"`: cerca a partire da una data e un orario estremamente precisi.
- `journalctl --since "2 hours ago"`: isola solo quello che è successo nelle ultime due ore [🎨].
- `journalctl --since "1 day ago" --until "2 hours ago"`: combina i filtri per analizzare una finestra temporale precisa.

## 5. Filtrare per Gravità (I Livelli di Priorità)

I log in Linux sono categorizzati per importanza tramite i livelli dello standard POSIX (da 0 a 7, dove 0 è un disastro totale e 7 è il debug avanzato). Puoi usare il flag `-p` (priority) per scartare le notifiche inutili [🎨]:

- `journalctl -p err -b`: mostra solo gli Errori (`err`) dell'avvio attuale (`-b`) [🎨].
- `journalctl -p warning`: mostra gli avvisi che indicano potenziali problemi futuri.

I livelli più usati: `crit` (critico), `err` (errore), `warning` (avviso), `info` (informazione normale).

## 6. Filtrare per Hardware (Il Kernel)

Se stai studiando come si comporta il kernel Linux, i suoi moduli (`lsmod`) o i driver quando colleghi una periferica USB, puoi isolare i messaggi interni [🎨]:

- `journalctl -k` (kernel): mostra solo i messaggi emessi dal kernel (sostituisce il vecchio comando storico `dmesg`) [🎨].
- `journalctl -k -b`: solo i messaggi del kernel legati all'ultimo avvio del PC [🎨].

## 7. Manutenzione dello Spazio: Quanto occupa il diario?

Visto che `journald` gestisce da solo la rotazione e la pulizia dei file binari per non riempire il disco, puoi controllarlo o forzare una pulizia [🎨]:

- `journalctl --disk-usage`: ti dice quanti Megabyte o Gigabyte stanno occupando i log sul tuo hard disk in questo momento.
- `sudo journalctl --vacuum-size=1G`: ordina a `journald` di fare pulizia immediata cancellando i log più vecchi fino a far scendere lo spazio occupato sotto il limite di 1 Gigabyte.
- `sudo journalctl --vacuum-time=2weeks`: elimina tutti i log più vecchi di due settimane.

---