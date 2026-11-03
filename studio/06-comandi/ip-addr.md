---
tags:
  - comandi
  - nota
aliases:
  - Leggere ip addr
---
# Leggere `ip addr`

**`ip`** fa parte della suite *iproute2*, che sostituisce `ifconfig`. **`addr`** è l'oggetto su cui lavora: gli indirizzi delle interfacce. **`-br`** sta per *brief*: una riga per interfaccia.

```sh
ip -br addr
```

```text
lo        UNKNOWN  127.0.0.1/8 ::1/128
enp0s3    UP       10.0.2.15/24 metric 1024 fd17:625c:f037:...
```

Non ha intestazione. Le colonne sono: **interfaccia**, **stato**, **indirizzi**.

## Interfaccia

- **`lo`**: *loopback*, la scheda virtuale con cui la macchina parla con se stessa. Non esce mai in rete.
- **`enp0s3`**: nome prevedibile. `en` = Ethernet, `p0` = bus PCI 0, `s3` = slot 3.

## Stato

- **`UP`**: l'interfaccia è operativa.
- **`DOWN`**: spenta o senza collegamento.
- **`UNKNOWN`**: il driver non riporta lo stato. Su `lo` è normale.

## Indirizzi

- **`127.0.0.1/8`** e **`::1/128`**: loopback in IPv4 e IPv6.
- **`10.0.2.15/24`**: indirizzo IPv4 e rete. `/24` è la notazione CIDR (*Classless Inter-Domain Routing*): i primi 24 bit indicano la rete, gli altri l'host. La rete è quindi `10.0.2.0`.
- **`metric 1024`**: priorità della rotta associata. Vince il numero più basso.
- **`fd17:...`**: IPv6 locale (*unique local address*, prefisso `fd`), valido solo nella rete privata.

## Cosa controllare

1. La scheda è `UP`.
2. Ha un indirizzo IPv4 diverso da `127.0.0.1`.
3. Se manca l'indirizzo, il problema è nella configurazione o nel DHCP. Se c'è e la rete non funziona, si guarda oltre: rotte e DNS.

## In VirtualBox con NAT

`10.0.2.15` è l'indirizzo predefinito dell'ospite. Il gateway è `10.0.2.2`, il DNS `10.0.2.3`. VirtualBox traduce il traffico in uscita, ma il Mac non può raggiungere direttamente quell'indirizzo: per entrare serve un inoltro di porta.

---

↑ [[mappa-comandi|Comandi]] · [[00-home|Home]]
