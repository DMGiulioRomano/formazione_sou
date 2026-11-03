---
tags:
  - comandi
  - nota
aliases:
  - Come funziona SSH
---
# Come funziona SSH

**SSH** (*Secure Shell*) permette di usare il terminale di un'altra macchina attraverso la rete, con il traffico cifrato. Ciò che scrivo viaggia verso l'altra macchina, e l'output torna indietro.

Servono due programmi:

- **`sshd`**, il server: gira sulla macchina a cui ci si collega e aspetta.
- **`ssh`**, il client: gira sulla macchina da cui ci si collega e apre la connessione.

## L'accesso è lo stesso del login

Davanti alla macchina, il login chiede due cose:

```text
arch-lab login: giulio
Password:
```

SSH chiede le stesse due cose, a distanza:

- **Nome utente**: con quale account della macchina remota entrare. Ogni processo su Linux gira a nome di un utente, quindi `sshd` deve sapere con quale avviare la shell. Da quell'utente dipendono home e permessi.
- **Password**: la prova che quell'account è mio. È la password dell'utente sulla macchina remota, non quella della macchina da cui mi collego.

## Cosa succede con `ssh giulio@host`

1. `ssh` contatta `sshd` su `host`.
2. Le due parti stabiliscono la cifratura.
3. `sshd` verifica l'utente `giulio`, per esempio con la password.
4. `sshd` avvia una shell a nome di `giulio`.
5. Da qui in poi ciò che scrivo arriva a quella shell, e l'output torna al mio terminale.

## Le chiavi al posto della password

Una chiave SSH è una coppia di file generati insieme:

- **Privata** (`id_ed25519`): resta sulla mia macchina e non si condivide mai.
- **Pubblica** (`id_ed25519.pub`): si può copiare ovunque.

Ciò che la privata firma, solo la pubblica corrispondente lo può verificare, e dalla pubblica non si ricava la privata. Questo modello si chiama crittografia **asimmetrica**, perché le due chiavi hanno ruoli diversi.

All'accesso:

1. `ssh` dichiara quale chiave vuole usare.
2. `sshd` controlla se quella pubblica sta in `~/.ssh/authorized_keys` dell'utente.
3. `ssh` firma con la privata i dati di quella connessione.
4. `sshd` verifica la firma con la pubblica e apre la shell.

La chiave privata non viaggia mai, quindi non può essere intercettata. Ogni firma vale solo per quella connessione.

**`ed25519`** è l'algoritmo: *EdDSA* sulla curva *Curve25519*, dal numero primo 2²⁵⁵ − 19.

---

↑ [[mappa-comandi|Comandi]] · [[00-home|Home]]
