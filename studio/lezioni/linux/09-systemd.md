---
tags:
  - lezione
  - linux
aliases:
  - Linux 09 — systemd
---
# Linux 09 — systemd

systemd non serve solo ad avviare la macchina: tiene in vita i servizi, li riavvia quando cadono, decide con quali risorse girano e quando partono. In questa lezione:

- trasformi in servizio un programma lanciato a mano;
- ritocchi un servizio del pacchetto senza toccarne il file;
- metti un lavoro sotto un timer che conosce i fusi orari;
- togli un'attesa inutile dall'avvio.

Gli appunti di partenza sono [[systemd|systemd]], [[journalctl|journalctl]], [[prima-di-systemd|Prima di systemd]], [[namespaces-cgroups|Namespaces e cgroups]] e [[nice-renice|nice e renice]]. I timer li hai già incontrati nello [[10-automazione|scripting, lezione 10]]: qui si va oltre.

```sh
cd formazione_sou/lab/linux
sudo ./prepara.sh 09        # problema 1; poi sudo ./prepara.sh 09 2, e così via
```

> [!warning] Prima di cominciare
> - **Una fotografia della VM**, a VM spenta: `VBoxManage snapshot lab-rocky take prima-di-09`. Il problema 4 cambia l'avvio e va provato con un riavvio.
> - **Cosa riporta indietro il kit.** `prepara.sh` fotografa i ritocchi locali di `crond` la prima volta che lo lanci con questa versione del kit, in `/var/lib/lab-linux/base/servizi/`. Ogni `prepara.sh` successivo riporta indietro:
>   - le unità della lezione (`lab-app`, `lab-report`, `lab-sincro`), dovunque tu le abbia scritte;
>   - i ritocchi di `crond` nati dopo la fotografia;
>   - i programmi del kit in `/opt`.

## La mappa

| # | Problema | Stato |
|---|---|---|
| 1 | L'applicazione gira in una sessione aperta | — |
| 2 | I lavori notturni rallentano il database | — |
| 3 | Il report per l'ufficio di New York | — |
| 4 | La macchina è pronta più di un minuto dopo | — |
| P | Pulizia — dismettere i servizi della casa | — |

---

## Problema 1 — L'applicazione gira in una sessione aperta

**Situazione.** Un collega ha lanciato a mano lab-app, l'applicazione interna del gruppo applicazioni, dalla sua sessione, prima di andare in ferie. Se la macchina si riavvia o il programma cade, nessuno la rimette su.

> [!info] Il contesto
> **Lo scenario.** Programmi lanciati «per adesso» con `nohup`, dentro `tmux` o da una sessione SSH rimasta aperta: diventano produzione senza che nessuno lo decida.
> - **Unità** (*unit*): ogni cosa che systemd gestisce, descritta da un file. Il nome finisce con il tipo: `.service`, `.mount`, `.timer`, `.target`.
> - **Servizio** (dal latino *servitium*, «servitù»): l'unità di un processo che systemd avvia, sorveglia e, se serve, fa ripartire.
> - **Utente di servizio**: un utente senza password né shell di login, che esiste solo per far girare un programma con i permessi minimi.
> - **Scope** («ambito»): l'unità in cui systemd mette i processi che non ha avviato lui, per esempio quelli di una sessione di login.
>
> **Perché conta.** Un programma senza servizio sparisce al primo riavvio, e se gira come root un suo errore diventa un errore di root.

**Compito.** Esegui `palestra/l09/ticket-1.txt`:

- lab-app diventa `lab-app.service`, parte da sola a ogni avvio e gira come `labapp`;
- se cade, systemd la fa ripartire;
- se `/srv/app` non è montato lo monta, e senza disco non parte;
- i suoi messaggi finiscono nel journal;
- alla fine gira una copia sola, quella del servizio.

Criteri di accettazione:

- `sudo ./verifica.sh 09 1` esce con 0;
- `systemctl is-enabled lab-app` stampa `enabled`;
- `curl -s http://127.0.0.1:8088/` risponde `lab-app ok`.

**Verifica.** `sudo ./verifica.sh 09 1`. Il correttore uccide il processo del servizio per vedere se riparte, e smonta `/srv/app` per vedere come reagisce il servizio. Alla fine rimette tutto com'era.

> [!question]- Indizio 1
> Chi ascolta sulla porta 8088 adesso? `ss -ltnp` te lo dice. Da quale unità viene quel processo? Prova `systemctl status` con il suo PID.

> [!question]- Indizio 2
> In `man systemd.exec`: come si sceglie l'utente con cui gira un servizio? In `man systemd.service`: cosa decide se un servizio riparte da solo?

> [!question]- Indizio 3
> In `man systemd.unit` cerca un'opzione che parli di *mount* e di percorsi. Cosa aggiunge alle dipendenze del servizio? `systemctl show lab-app -p Requires,After` lo mostra.

> [!question]- Indizio 4
> Dove si mettono le unità scritte dall'amministratore? Cosa deve succedere perché systemd veda un file nuovo? E cosa fa partire un servizio all'avvio? Cerca la sezione `[Install]`.

**Dopo.** Cosa succede a un servizio con `Restart=on-failure` se lo fermi con `systemctl stop`? Che differenza c'è con `Restart=always`? Cosa fanno `StartLimitBurst` e `StartLimitIntervalSec` quando il programma cade dieci volte di fila? Perché i messaggi di lab-app sono nel journal senza che tu abbia fatto niente? In quale scope stava la copia lanciata a mano, e cosa le sarebbe successo con `KillUserProcesses=yes` in `logind.conf`? Cosa avrebbe dato `DynamicUser=yes`?

---

## Problema 2 — I lavori notturni rallentano il database

**Situazione.** Di notte i lavori di cron si prendono CPU e memoria, e il database sulla stessa macchina rallenta. Tutto ciò che lancia cron deve girare con priorità bassa e, tutto insieme, con al massimo 1 GiB di memoria. Il file dell'unità che arriva con il pacchetto non si tocca.

> [!info] Il contesto
> **Lo scenario.** Un servizio del sistema va adattato alla macchina: più memoria, meno priorità, un'attesa in più. Il file del pacchetto lo riscrive il prossimo aggiornamento.
> - **Drop-in** (inglese, «che si lascia cadere dentro»): un frammento in una cartella `NOME.service.d/` che aggiunge o cambia impostazioni di un'unità senza toccarne il file.
> - **nice** (inglese, «gentile»): la priorità di CPU di un processo, da -20 a 19. Più è alto, più il processo cede il posto agli altri ([[nice-renice|nice e renice]]).
> - **cgroup** (*control group*, «gruppo di controllo»): il gruppo di processi con cui il kernel conta e limita le risorse ([[namespaces-cgroups|Namespaces e cgroups]]). Ogni servizio ha il suo, e i processi figli ci restano dentro.
> - **`rpm -V`** (*verify*, «verifica»): confronta i file installati con quelli del pacchetto e segnala quelli cambiati.
>
> **Perché conta.** Un ritocco fatto nel file del pacchetto sparisce al primo aggiornamento, e nessuno ricorda di rifarlo.

**Compito.** `sudo ./prepara.sh 09 2`, poi esegui `palestra/l09/ticket-2.txt`:

- crond e i suoi lavori girano con nice 10 e, tutti insieme, con al massimo 1 GiB di memoria;
- il file dell'unità del pacchetto `cronie` non si tocca e non si copia;
- vale per i lavori che partono da adesso, e dopo ogni riavvio.

Criteri di accettazione:

- `sudo ./verifica.sh 09 2` esce con 0;
- `rpm -V cronie` non elenca il file dell'unità di crond.

**Verifica.** `sudo ./verifica.sh 09 2`

> [!question]- Indizio 1
> `systemctl cat crond`: di quanti file è fatta l'unità, e in che ordine li legge systemd?

> [!question]- Indizio 2
> In `man systemd.unit` cerca *drop-in*: dove vanno quei file? Se due impostano la stessa cosa, chi vince?

> [!question]- Indizio 3
> La priorità sta in `man systemd.exec`, la memoria in `man systemd.resource-control`. `systemctl show crond -p Nice,MemoryMax` dice cosa ha capito systemd.

> [!question]- Indizio 4
> `systemctl show crond -p Nice` dice una cosa, `ps -o ni= -p` sul PID di crond un'altra? Quale delle due vale per i lavori che partono adesso, e perché?

**Dopo.** Cosa fa `systemctl edit crond`, e dove scrive? E `systemctl set-property crond MemoryMax=1G`? Riavviando crond, che fine fanno i lavori in corso? Guarda `KillMode` in `systemctl cat crond`. Cosa succede a un lavoro che supera il limite di memoria, e dove lo vedi (`memory.events` nel cgroup di crond, `journalctl -k`)? Che differenza c'è fra `MemoryMax` e `MemoryHigh`?

---

## Problema 3 — Il report per l'ufficio di New York

**Situazione.** Uno script prepara il report delle vendite per l'ufficio di New York. Deve partire dal lunedì al venerdì alle 07:00 di New York, qualunque sia il fuso della macchina. Se la macchina è spenta, deve recuperare. Trenta macchine lo lanciano contro lo stesso database. In più, stasera, serve un ricalcolo straordinario, una volta sola.

> [!info] Il contesto
> **Lo scenario.** Lavori pianificati per un ufficio in un altro continente, su server che di solito tengono l'ora universale.
> - **Timer** («temporizzatore»): l'unità che avvia un'altra unità a un'ora o dopo un tempo. È l'alternativa di systemd a cron.
> - **UTC** (*Coordinated Universal Time*, tempo universale coordinato) e **fuso orario** (*time zone*): New York è indietro di 5 ore d'inverno e di 4 d'estate, per l'**ora legale** (*daylight saving time*).
> - **Effetto gregge** (*thundering herd*, «mandria che tuona»): tante macchine che fanno la stessa cosa nello stesso secondo, contro lo stesso server.
> - **Unità transitoria** (*transient unit*): creata al volo con un comando, vive in `/run` e sparisce quando ha finito.
>
> **Perché conta.** Un'ora convertita a mano in UTC è giusta metà dell'anno. Il giorno del cambio d'ora il report arriva con un'ora di ritardo, e nessuno capisce perché.

**Compito.** `sudo ./prepara.sh 09 3`, poi esegui `palestra/l09/ticket-3.txt`:

- `lab-report.service` gira come `labapp`;
- `lab-report.timer` lo lancia dal lunedì al venerdì alle 07:00 di New York, con un ritardo a caso fino a 15 minuti;
- se a quell'ora la macchina è spenta, il report si fa appena riparte;
- da solo, il servizio non parte all'avvio;
- il ricalcolo straordinario all'ora del ticket, con un timer che non lascia file in `/etc` e non si ripete.

Criteri di accettazione:

- `sudo ./verifica.sh 09 3` esce con 0;
- `systemctl list-timers` mostra `lab-report.timer` e il ricalcolo.

**Verifica.** `sudo ./verifica.sh 09 3`. Il correttore lancia una volta il report a mano e controlla le partenze di adesso, di fra quattro mesi e di fra otto, con l'ora legale e senza.

> [!question]- Indizio 1
> Rileggi lo [[10-automazione|scripting 10]]: quanti file servono per un lavoro pianificato con systemd, e quale dei due si abilita?

> [!question]- Indizio 2
> In `man systemd.time`, sezione *CALENDAR EVENTS*: si può scrivere un fuso orario in un'espressione? Prova la tua con `systemd-analyze calendar --iterations=5`, e poi con `--base-time` in una data d'estate.

> [!question]- Indizio 3
> In `man systemd.timer`: quale opzione recupera le partenze perse a macchina spenta? Quale le sparpaglia nel tempo?

> [!question]- Indizio 4
> Per il ricalcolo, in `man systemd-run` cerca *timer*. Cosa succede se dai al timer transitorio il nome di un'unità che esiste già?

**Dopo.** Perché un servizio lanciato da un timer non ha bisogno della sezione `[Install]`? Cosa succederebbe con `RemainAfterExit=yes` nel servizio, la seconda volta che il timer scatta? Dove ricorda systemd l'ultima partenza, per `Persistent=` (guarda in `/var/lib/systemd/timers/`)? Che differenza c'è fra `RandomizedDelaySec` e `AccuracySec`? Come avresti fatto con cron (`CRON_TZ` in `man 5 crontab`), e cosa avresti perso?

---

## Problema 4 — La macchina è pronta più di un minuto dopo

**Situazione.** Da quando il fornitore ha installato il suo servizio di sincronizzazione, l'automazione aspetta più di un minuto in più a ogni riavvio prima di considerare pronta la macchina. Il servizio deve continuare a girare e a riuscire, e il file del fornitore non si tocca.

> [!info] Il contesto
> **Lo scenario.** Un `sleep` messo per «aspettare la rete» è un classico dei pacchetti dei fornitori: rallenta ogni macchina e non garantisce niente.
> - **Ordine e dipendenza**: in systemd sono due cose diverse. Una dice «parti dopo quell'unità», l'altra «porta su anche quell'unità». Nessuna delle due implica l'altra.
> - **Rete configurata**: la scheda ha un indirizzo e una rotta. Non coincide con il momento in cui parte il programma che gestisce la rete.
> - **Catena critica** (*critical chain*): la fila di unità che, una dopo l'altra, ha deciso quanto è durato l'avvio.
>
> **Perché conta.** Una macchina che ci mette un minuto in più a ogni riavvio rallenta ogni aggiornamento, ogni emergenza, ogni automazione che la aspetta.

**Compito.** `sudo ./prepara.sh 09 4`, poi esegui `palestra/l09/ticket-4.txt`. Prima di tutto riavvia una volta, per vedere il problema. Alla fine:

- l'avvio non aspetta più senza motivo;
- lab-sincro gira a ogni avvio e riesce, con la rete configurata;
- il file del fornitore resta com'è, senza copie al suo posto;
- il tutto è provato con un riavvio.

Criteri di accettazione:

- dopo un riavvio, `sudo ./verifica.sh 09 4` esce con 0;
- `systemd-analyze blame | head -3` non mette più lab-sincro fra i primi.

**Verifica.** `sudo ./verifica.sh 09 4`, dopo il riavvio.

> [!question]- Indizio 1
> Dopo il riavvio: cosa dicono `systemd-analyze`, `systemd-analyze blame` e `systemd-analyze critical-chain`? Chi ha aspettato chi?

> [!question]- Indizio 2
> `systemctl cat lab-sincro`: perché il fornitore ha messo quell'attesa? Rileggi la frase su `network.target` nell'appunto [[systemd|systemd]]: è vera? Controllala in `man systemd.special`.

> [!question]- Indizio 3
> In `man systemd.unit`: cosa fa `Wants=` da solo, e cosa fa `After=` da solo?

> [!question]- Indizio 4
> Hai scritto il drop-in, ma `systemctl show lab-sincro -p ExecStartPre` mostra ancora l'attesa? In `man systemd.service` cerca cosa succede quando si assegna una stringa vuota a un'impostazione che è una lista.

**Dopo.** Correggi nell'appunto [[systemd|systemd]] la frase su `network.target`, con le tue parole. Perché `multi-user.target` aspettava lab-sincro, se nessuno gli aveva scritto `After=`? Cerca *Default Dependencies* in `man systemd.target`. Cosa risponde `systemctl is-system-running` durante l'avvio? Chi fa sì che `network-online.target` voglia dire qualcosa (`systemctl cat NetworkManager-wait-online`)? Quando un servizio *non* dovrebbe aspettare la rete configurata?

---

## Pulizia — Dismettere i servizi della casa

**Situazione.** lab-app e il report di New York si spostano su un'altra macchina. Qui restano il servizio, il timer, i limiti di crond e il disco dedicato con `/srv/app`.

> [!info] Il contesto
> **Lo scenario.** Un servizio dismesso a metà lascia dietro un'unità fallita che fa suonare il monitoraggio ogni notte, o un timer che lancia uno script che non c'è più.
> - **Unità fallita** (*failed*): systemd la ricorda finché qualcuno non la azzera, anche se il file non c'è più.
>
> **Perché conta.** `systemctl --failed` è una delle prime cose che il monitoraggio guarda.

**Compito.** `sudo ./prepara.sh 09 pulizia`, poi esegui `palestra/l09/ticket-pulizia.txt`:

- `lab-app.service`, `lab-report.service` e `lab-report.timer` fermi, disabilitati, cancellati, e sconosciuti a systemd, nemmeno come falliti;
- crond com'era nel pacchetto, e il crond che gira adesso senza limiti;
- il disco dedicato restituito pulito, `/etc/fstab` com'era prima della lezione.

Criteri di accettazione: `sudo ./verifica.sh 09 pulizia` esce con 0.

**Verifica.** `sudo ./verifica.sh 09 pulizia`

> [!question]- Indizio 1
> Hai cancellato i file, ma `systemctl status lab-app` risponde ancora? Cosa deve succedere perché systemd se ne accorga, e cosa resta di un'unità fallita?

**Dopo.** In che ordine conviene fare le cose (fermare, disabilitare, cancellare, rileggere), e cosa va storto se le inverti? Cosa fa `systemctl disable --now`?

---

## Diario

Domande numerate, risposte, correzioni ed errori di questa lezione, problema per problema.

## Sintesi

Da scrivere insieme a lezione finita, partendo dalle mie parole.

---

↑ [[00-percorso-linux|Il percorso]] · ← [[08-avvio-grub|Lezione 08]] · → [[10-selinux-firewalld|Lezione 10]]
