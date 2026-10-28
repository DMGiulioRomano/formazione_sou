---
tags:
  - shell
  - nota
aliases:
  - Tipi di shell e su
---
# Tipi di shell e su

Avere e utilizzare più shell sul computer serve a personalizzare l'ambiente di lavoro, migliorare la produttività con funzionalità avanzate e garantire la compatibilità con script e server diversi.

Per cambiare la tua shell predefinita in Zsh, ad esempio, useresti il comando:

```bash
chsh -s /bin/zsh
```

(Il sistema ti chiederà la password del computer per confermare il cambio).

## 1. Shell di Login vs Non di Login

- **Shell di Login**: viene avviata quando accedi al sistema per la prima volta. Ad esempio, quando ti colleghi a un server remoto tramite SSH o quando accedi in modalità testuale (TTY) premendo `Ctrl+Alt+F3` su Linux.
- Le altre sono **shell non di login**.

## 2. Shell Interattiva vs Non Interattiva

- **Shell Interattiva**: è il terminale con cui interagisci direttamente. Mostra un prompt (es. `user@computer:~$`), attende che tu digiti un comando, lo esegue e ti mostra il risultato. Gestisce la cronologia dei comandi e ti permette di usare le frecce direzionali.
- **Shell Non Interattiva**: viene avviata dal sistema per eseguire uno script automatizzato (un file `.sh`). Non mostra alcun prompt, non accetta input dalla tastiera in tempo reale e si chiude automaticamente non appena lo script ha finito di girare.

## Differenza tra shell di login iniziale e shell aperta con `su`

La differenza principale tra una shell di login iniziale (quella che si avvia quando accedi al computer o al server) e una shell aperta tramite il comando `su` sta tutta nel modo in cui l'ambiente viene ereditato e configurato.

Anche se in entrambi i casi puoi ritrovarti a usare l'utente root, il punto di partenza e il passaggio dei dati cambiano radicalmente.

### 1. La shell di login iniziale (es. accesso SSH o TTY)

Quando ti colleghi a un server via SSH o inserisci la password nella modalità testuale di Linux, il sistema avvia una shell di login da zero.

- **Ambiente pulito**: non c'è alcuna sessione precedente. Il sistema operativo crea un ambiente completamente nuovo, azzerando qualsiasi variabile precedente.
- **Caricamento file**: legge i file globali (`/etc/profile`) e poi i file specifici dell'utente (`~/.bash_profile`, `~/.bash_login`, o `~/.profile`).
- **Chi sei?** Sei l'utente che ha effettuato l'accesso fin dal primo istante.

### 2. La shell in cui usi il comando `su`

Quando usi `su` (o `su -`), ti trovi già all'interno di una shell attiva (es. come utente normale) e decidi di aprirne una nuova sopra di essa per cambiare identità. Qui il comportamento si sdoppia a seconda di come usi il comando:

#### Scenario A: comando semplice (`su root`)

Questa viene definita una **shell interattiva NON di login**.

- **Eredità totale**: la nuova shell di root eredita tutto l'ambiente dell'utente normale da cui sei partito. Rimarrai nella stessa cartella in cui ti trovavi e manterrai le variabili d'ambiente dell'utente precedente.
- **File letti**: NON legge i file di profilo globali o di login di root. Legge solo il file `~/.bashrc` (o `~/.zshrc`) di root.
- **Problema tipico**: poiché erediti il `PATH` (la lista delle cartelle in cui il sistema cerca i comandi) dell'utente normale, se provi a digitare comandi amministrativi come `reboot` o `fdisk`, il terminale ti risponderà "comando non trovato", perché non sta guardando nelle cartelle di sistema come `/usr/sbin`.

#### Scenario B: comando con il trattino (`su -` o `su - root`)

Questo comando forza il sistema ad avviare una **shell di login a tutti gli effetti** dentro la sessione corrente.

- **Simulazione di un login reale**: anche se sei già dentro il terminale, l'ambiente precedente dell'utente normale viene quasi interamente cancellato e sostituito con quello di root.
- **File letti**: si comporta esattamente come la shell di login iniziale. Legge `/etc/profile` e il file `~/.bash_profile` (o `~/.zprofile`) di root.
- **Risultato**: ti sposta automaticamente nella cartella Home di root (`/root`) e imposta il `PATH` corretto con tutti i comandi amministrativi pronti all'uso.

### Confronto diretto

| Caratteristica | Shell di Login Iniziale | Shell con `su` (Semplice) | Shell con `su -` (Consigliata) |
|---|---|---|---|
| Tipo di shell | Di login | Non di login | Di login |
| Cartella di partenza | Home dell'utente | Resta dove eri prima | Home dell'utente d'arrivo (`/root`) |
| Variabili d'ambiente (`PATH`, ecc.) | Pulite e native dell'utente | Ereditate dall'utente precedente | Pulite e native dell'utente d'arrivo |
| File di configurazione letti | `~/.bash_profile` o `~/.profile` | `~/.bashrc` o `~/.zshrc` | `~/.bash_profile` o `~/.profile` |

---

**Area:** [[mappa-shell|Shell]]  
**Vedi anche:** [[variabili-opzioni|Variabili e opzioni della shell]] · [[path|PATH]] · [[alias-history|Alias e history]]
