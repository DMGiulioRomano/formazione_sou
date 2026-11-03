---
tags:
  - comandi
  - nota
aliases:
  - Leggere ss
---
# Leggere `ss`

**`ss`** sta per *socket statistics*: mostra i socket, cioè i punti di connessione aperti dai programmi. Fa parte di *iproute2* e sostituisce `netstat`.

```sh
ss -tln
```

- **`t`**: solo TCP.
- **`l`**: solo in ascolto (*listening*).
- **`n`**: indirizzi e porte in numeri (*numeric*).

Se lo schermo taglia l'output:

```sh
ss -tln | awk '{print $1, $4}'
```

## Colonne su una porta in ascolto

- **`State`**: `LISTEN`, in attesa di connessioni.
- **`Recv-Q`**: connessioni arrivate e non ancora accettate dal programma.
- **`Send-Q`**: massimo di connessioni che possono restare in coda.
- **`Local Address:Port`**: dove il programma ascolta.

## Leggere l'indirizzo

| Indirizzo | Da dove è raggiungibile |
|---|---|
| `0.0.0.0` | tutti gli indirizzi IPv4 della macchina |
| `[::]` | tutti gli indirizzi IPv6 della macchina |
| `127.0.0.1`, `127.0.0.53` | solo dalla macchina stessa |

## Esempio: Arch con `sshd` e `systemd-resolved`

```text
LISTEN 127.0.0.53%lo:53
LISTEN 127.0.0.54:53
LISTEN 0.0.0.0:5355
LISTEN [::]:5355
LISTEN 0.0.0.0:22
LISTEN [::]:22
```

- **`:22`**: `sshd`.
- **`:53`**: DNS di `systemd-resolved`, solo locale. `%lo` indica l'interfaccia di loopback.
- **`:5355`**: LLMNR (*Link-Local Multicast Name Resolution*), risoluzione dei nomi nella rete locale, sempre di `systemd-resolved`.

---

↑ [[mappa-comandi|Comandi]] · [[00-home|Home]]
