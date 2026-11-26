---
tags:
  - shell
  - nota
aliases:
  - Da dove vengono gli utenti
---
# Da dove vengono gli utenti

`/etc/passwd` non è l'unica fonte degli utenti. I programmi chiedono alla libreria C, che sceglie le fonti secondo `/etc/nsswitch.conf`. Nato dal «Dopo» del problema 1 della [[02-decisioni|lezione 02]]. Gli argomenti da approfondire sono raccolti nell'[issue #5](https://github.com/DMGiulioRomano/formazione_sou/issues/5).

## NSS

- **Nome:** *Name Service Switch*, «commutatore dei servizi di nomi»: il deviatore che decide a quale fonte chiedere.
- **Cosa fa:** un programma non apre `/etc/passwd`, chiama una funzione della libreria C (`getpwnam`, `getgrnam`, …), che legge `nsswitch.conf` e interroga le fonti in ordine.
- **Fonti:** ognuna è un modulo `libnss_<nome>.so.2` (in Rocky, `/usr/lib64/`).

## Come si legge `nsswitch.conf`

Ogni riga attiva è `database: fonte1 fonte2 …`. Il database è il tipo di informazione, le fonti si interrogano da sinistra; vince la prima che trova la voce.

| Database | Domanda |
|---|---|
| `passwd` | chi è un utente (nome, UID, home, shell) |
| `shadow` | la password cifrata |
| `group` | i gruppi e i loro membri |
| `hosts` | l'IP di un nome di macchina |
| `services` | la porta di un servizio |

| Fonte | Dove guarda |
|---|---|
| `files` | i file in `/etc` (`passwd`, `group`, `hosts`) |
| `sss` | SSSD, che parla con LDAP o Active Directory |
| `systemd` | gli utenti dinamici dei servizi (`DynamicUser=`) |
| `dns` | il DNS, per `hosts` |
| `myhostname` | il nome della macchina stessa |

Nella VM Rocky: `passwd: sss files systemd`. SSSD è installato ma `inactive`, quindi `sss` non risponde e si passa a `files`. Rocky mette `sss` per primo di serie: basta configurare SSSD perché compaiano gli utenti aziendali. `shadow` è solo `files`: con LDAP l'autenticazione passa per PAM, non per questa riga.

## Utenti di rete

- **LDAP** (*Lightweight Directory Access Protocol*): il protocollo delle directory centrali di account. **Active Directory** è quella di Microsoft, **FreeIPA** quella di Red Hat.
- **SSSD** (*System Security Services Daemon*): il demone locale che interroga la directory e tiene una cache, così il login funziona anche se la rete cade per un po'.
- Gli utenti di rete fanno login e possiedono file, ma in `/etc/passwd` non ci sono.

## `getent`

*get entries*, «prendi le voci»: fa la domanda come un programma, passando da NSS. La risposta ha il formato di `/etc/passwd` qualunque sia la fonte.

| Codice | Significato |
|---|---|
| 0 | trovato |
| 1 | argomenti sbagliati o database sconosciuto |
| 2 | chiave non trovata (non 1, come per `grep`) |
| 3 | elenco completo non supportato dalla fonte |

## Perché conta in uno script

Uno script che legge `/etc/passwd` con `grep` o `cut`, su una macchina collegata a LDAP, dice «non esiste» per un collega che esiste: un **falso negativo**, che sembra una risposta normale. Per l'uso reale si chiede a NSS con `getent passwd "$nome"`; leggere un file serve solo a provare con dati finti.

---

↑ [[mappa-shell|Mappa della shell]]
