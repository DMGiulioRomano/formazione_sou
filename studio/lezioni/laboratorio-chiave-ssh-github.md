---
tags:
  - lezione
  - laboratorio
aliases:
  - Laboratorio — Chiave ssh dalla VM a GitHub
---
# Laboratorio — Chiave ssh dalla VM a GitHub

Configurare la VM `lab-rocky` per fare `git push` su GitHub con una chiave ssh, così da committare dalla VM gli script di `lab/scripting/palestra/`. Ogni passo risponde a tre domande: **cosa** fa il comando, **perché** serve in quel momento, **come** si chiama e da dove viene il nome.

## La mappa

| # | Passo | Stato |
|---|---|---|
| 0 | Capire chiave pubblica e privata | ✅ |
| 1 | Controllare cosa c'è già (`~/.ssh`, versione di ssh) | ✅ |
| 2 | Generare la coppia di chiavi (`ssh-keygen`) | ✅ |
| 3 | Aggiungere la chiave pubblica su GitHub | ✅ |
| 4 | Primo collegamento e `known_hosts` | ✅ |
| 5 | Passare il remote da HTTPS a ssh | ✅ |
| 6 | Identità git (`user.name`, `user.email`) e primo push | ✅ |

---

## 0. Chiave pubblica e privata

> **D1.** Cos'è una chiave ssh, e quale delle due va su GitHub?
> **R.** Sono due chiavi: la **privata** resta nella VM e non viaggia mai sulla rete, la **pubblica** va su GitHub. Prima risposta con i ruoli invertiti; corretta al secondo tentativo partendo dai nomi (*privatus*, «di uno solo»; *publicus*, «di tutti»). ✅

Il repo è pubblico: leggerlo (`clone`, `pull`) è aperto a chiunque, scriverci (`push`) richiede di dimostrare chi sei.

## 1. Cosa c'è già

```bash
ls -la ~/.ssh; ssh -V
```

- In `~/.ssh` c'è solo `authorized_keys`: le chiavi **pubbliche** autorizzate a entrare **nella** VM (quella del Mac, per `ssh -p 2222`). È la direzione opposta: per uscire verso GitHub serve una coppia nuova, della VM.
- Permessi `drwx------` (700) sulla cartella e `-rw-------` (600) sul file: solo il proprietario. ssh rifiuta chiavi leggibili da altri. Il `.` finale indica un contesto SELinux.
- `ssh -v` (minuscolo) è *verbose*, la diagnostica; `ssh -V` (maiuscolo) è *version*. OpenSSH 9.9 supporta le chiavi Ed25519.

## 2. Generare la coppia di chiavi

> **D2.** A cosa serve la passphrase, se la chiave privata non lascia mai la VM?
> **R.** Protegge la chiave se qualcuno copia il file: senza la frase, il file rubato non si può usare. ✅

```bash
ssh-keygen -t ed25519 -C "remoto@lab-rocky"
```

- `ssh-keygen`: *ssh key generator*, il generatore di chiavi.
- `-t ed25519` (*type*): l'algoritmo. Ed25519 è una firma su curva ellittica (Edwards, campo con primo 2²⁵⁵ − 19), più corta e più veloce di RSA.
- `-C` (*comment*): un'etichetta in fondo alla chiave pubblica, per riconoscerla su GitHub.
- Crea `~/.ssh/id_ed25519` (privata, 600) e `~/.ssh/id_ed25519.pub` (pubblica). `id` sta per *identity*.
- La passphrase si chiede a ogni uso; `ssh-agent` la tiene in memoria per la sessione.

Risultato: `id_ed25519` con permessi 600 (`-rw-------`) e `id_ed25519.pub` con 644 (`-rw-r--r--`), leggibile da tutti perché è pubblica. Fingerprint `SHA256:5UYY…AWw`: l'hash SHA-256 della chiave pubblica, in base64. Fingerprint e randomart si possono mostrare: vengono dalla pubblica.

## 3. La chiave pubblica su GitHub

> **D3.** Chiave nell'account (*SSH keys*) o nel repository (*Deploy keys*)?
> **R.** La *deploy key* vale solo per quel repo: se la VM viene compromessa, il danno resta lì. Scelta: deploy key. ✅

Repo → *Settings* → *Deploy keys* → *Add deploy key*: titolo, contenuto di `id_ed25519.pub`, spunta **Allow write access** (di base una deploy key è solo in lettura). *Deploy* (francese antico *desployer*, «spiegare, schierare»): il rilascio del codice su un server, che di solito deve solo leggere il repo.

Fatto dal Mac con `gh`, senza installarlo nella VM (un token d'account nella VM annullerebbe il vantaggio della deploy key):

```bash
ssh -p 2222 remoto@127.0.0.1 cat .ssh/id_ed25519.pub > /tmp/lab-rocky.pub
gh repo deploy-key add /tmp/lab-rocky.pub --allow-write --title lab-rocky -R DMGiulioRomano/formazione_sou
```

Controllo con l'API: `read_only=false`.

## 4. Primo collegamento e `known_hosts`

> **D4.** Perché la VM deve verificare chi è GitHub?
> **R.** Per evitare che qualcuno si finga GitHub (attacco *man in the middle*). ✅

```bash
ssh -T git@github.com
```

- `-T`: niente terminale (*TTY*): GitHub non dà una shell, risponde con un saluto e chiude.
- `git@`: su GitHub tutti si collegano come utente `git`; chi sei lo decide la chiave.
- Al primo collegamento ssh mostra il fingerprint del server: si confronta con quello pubblicato da GitHub (*GitHub's SSH key fingerprints*), Ed25519 `SHA256:+DiY3wvvV6TuJJhbpZisF/zLDA0zPMSvHdkr4UvCOqU`. Accettato, finisce in `~/.ssh/known_hosts`: le volte dopo ssh confronta in silenzio e blocca se cambia. È il modello *TOFU*, *trust on first use*.

Risultato: fingerprint uguale a quello pubblicato, `github.com` aggiunto a `known_hosts`, saluto `Hi DMGiulioRomano/formazione_sou!`: col nome del **repo** e non dell'utente, perché è una deploy key. Nessuna passphrase richiesta: la chiave è senza passphrase.

## 5. Il remote da HTTPS a ssh

> **D5.** Con il remote in HTTPS, `git push` userebbe la chiave?
> **R.** No: il protocollo lo decide l'URL; con HTTPS chiederebbe utente e password (che GitHub non accetta più dal 2021: servirebbe un token). ✅

```bash
cd ~/formazione_sou
git remote set-url origin git@github.com:DMGiulioRomano/formazione_sou.git
git remote -v
```

- *remote*: il repo «lontano» con cui il clone si sincronizza; `origin` è il nome predefinito di quello da cui si è clonato.
- `git@github.com:percorso` è la sintassi «alla scp»: utente `git`, host, poi `:` e il percorso. Equivale a `ssh://git@github.com/percorso`.

## 6. Identità git e primo push

> **D6.** Da dove prende git l'autore di un commit?
> **R.** Da `git config` (`user.name`, `user.email`); senza, ne inventa uno da utente e hostname (`remoto@lab-rocky`). La chiave ssh autorizza il push, non firma l'autore: autenticazione e autorialità sono separate. ✅

```bash
git config --global user.name "DMGiulioRomano"
git config --global user.email "166540742+DMGiulioRomano@users.noreply.github.com"
git config --global --list
```

`--global` scrive in `~/.gitconfig` e vale per tutti i repo dell'utente `remoto`. GitHub collega il commit al profilo tramite l'email. Scelto l'indirizzo `noreply` di GitHub (`ID+utente@users.noreply.github.com`), per non pubblicare l'email vera nei commit.

Primo push dalla VM: commit `c0a939b` con gli script di `lab/scripting/palestra/`. Regola: `git pull` prima di cominciare, `git push` alla fine; i file non tracciati non vengono toccati dal pull. `git status` confronta con `origin/main` locale, aggiornato solo da `fetch`.

## Sintesi

Da scrivere a lezione finita.
