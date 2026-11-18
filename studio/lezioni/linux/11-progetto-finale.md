---
tags:
  - lezione
  - linux
aliases:
  - Linux 11 — Progetto finale
---
# Linux 11 — Progetto finale: la macchina che non si avvia

Un collega ha fatto la manutenzione notturna di una macchina, l'ha riavviata ed è andato a casa. Stamattina la macchina non risponde. Ogni cosa che ha fatto ha lasciato un guasto, e ogni guasto si vede solo quando hai riparato il precedente.

Non c'è niente di nuovo da imparare: c'è tutto il percorso, dalla lezione 03 alla 10, da usare insieme e nell'ordine in cui la macchina si avvia. Gli appunti di partenza sono la mappa dell'avvio in [[mappa-hardware-boot|Hardware e boot]] e le lezioni precedenti.

```sh
cd formazione_sou/lab/linux
sudo ./prepara.sh 11
```

> [!warning] Prima di cominciare
> - **Una fotografia della VM**, a VM spenta: `VBoxManage snapshot lab-rocky take prima-di-11`. Qui si guastano insieme l'avvio, i dischi e i servizi.
> - **La password di root** (`sudo passwd -S root` deve dire `PS`): la macchina si fermerà in emergency mode.
> - **La finestra della VM** aperta per tutto il tempo: il menu di GRUB e la console di emergenza compaiono lì.
> - **Gli strumenti della lezione 10** (Apache, firewalld, `semanage`) installati.
> - **Un quaderno**: annota cosa vedi, cosa provi e cosa cambi, con l'ora. Ti serve per il resoconto.

## La mappa

| # | Problema | Stato |
|---|---|---|
| 1 | La macchina non è tornata su dopo la manutenzione | — |
| R | Il resoconto dell'incidente | — |
| P | Pulizia — dismettere la macchina dell'applicazione | — |

---

## Problema 1 — La macchina non è tornata su dopo la manutenzione

**Situazione.** Il verbale del collega elenca ciò che ha fatto: un kernel nuovo, i log spostati su un disco che prima ospitava la swap, il volume dei dati ingrandito, il sito ripristinato da una copia, lab-app fermata, il sito chiuso e poi riaperto agli uffici. Poi ha riavviato. Il ticket ti chiede una macchina che riparta da sola, senza nessuno alla console.

> [!info] Il contesto
> **Lo scenario.** Le finestre di manutenzione notturne sono il momento in cui si rompono più macchine: tante modifiche insieme, poco tempo, nessun riavvio di prova prima di andare a casa.
> - **Catena di avvio**: firmware, GRUB, kernel, initramfs, systemd, montaggi, servizi. Un guasto si vede nell'anello in cui si rompe, e nasconde quelli dopo.
> - **Verbale** (dal latino *verbum*, «parola»): il resoconto scritto di ciò che si è fatto. Dice cosa è stato toccato, non cosa si è rotto.
> - **Stato in memoria e stato salvato**: molte modifiche valgono fino al riavvio e poi spariscono; altre si salvano e si vedono solo al riavvio. È il tema di tutto il percorso.
> - **Riavvio di prova**: l'unico modo di sapere che la macchina riparte da sola.
>
> **Perché conta.** Ogni riparazione fatta a metà diventa il guasto del prossimo riavvio, magari tra sei mesi, con un altro sistemista alla console.

**Compito.** Esegui `palestra/l11/ticket-1.txt`. Il ticket ti fa riprodurre il riavvio di stanotte. Alla fine:

- il kernel di prima è il predefinito, e quello di prova è tolto del tutto;
- l'avvio arriva in fondo da solo, senza emergency mode e senza unità fallite;
- `/srv/dati`, `/srv/web` e `/srv/log` montati a ogni avvio, con i dati intatti, e `/srv/dati` con tutto lo spazio del volume;
- almeno 512 MiB di swap a ogni avvio, su un disco dedicato;
- lab-app in servizio, anche ai prossimi avvii;
- il sito risponde con SELinux enforcing, e si vede dagli uffici;
- il journal conserva gli avvii precedenti;
- un riavvio finale di prova, senza toccare niente dopo.

Criteri di accettazione, dopo il riavvio finale:

- `sudo ./verifica.sh 11 1` esce con 0;
- `systemctl is-system-running` stampa `running`;
- `journalctl --list-boots` mostra anche l'avvio prima di questo.

**Verifica.** `sudo ./verifica.sh 11 1`, dopo il riavvio finale. Il correttore guarda l'avvio, i dischi, la swap, i servizi, il sito e il firewall, anche da fuori come nella lezione 10.

> [!question]- Indizio 1
> Prima di riavviare: rileggi il verbale riga per riga. Per ogni cosa che ha fatto il collega, chiediti cosa potrebbe andare storto al prossimo avvio, e in quale lezione l'hai già visto.

> [!question]- Indizio 2
> La macchina si ferma subito dopo GRUB: cosa dicono le ultime righe sulla console? Ti ricordano la [[08-avvio-grub|lezione 08]]?

> [!question]- Indizio 3
> La console chiede la password di manutenzione. Prima di cambiare qualcosa: chi è fallito (`systemctl --failed`), e perché (`journalctl -xb`, cercando *Timed out* e *Dependency failed*)?

> [!question]- Indizio 4
> Un'unità aspetta un dispositivo che non arriva. Cosa cerca, esattamente, e cosa c'è davvero sui dischi? Confronta `/etc/fstab` con `lsblk -f`.

> [!question]- Indizio 5
> La macchina è su, ma `systemctl is-system-running` non dice `running`? Rileggi il verbale: cosa c'era sul disco dei log prima che il collega lo formattasse, e chi lo cerca ancora?

> [!question]- Indizio 6
> lab-app non parte nemmeno a mano? Leggi bene cosa risponde `systemctl status lab-app` nella riga *Loaded*.

> [!question]- Indizio 7
> Il sito si vedeva, stanotte. Cosa è cambiato con il riavvio, per SELinux e per il firewall? Confronta ciò che vale adesso con ciò che è salvato, come nella [[10-selinux-firewalld|lezione 10]].

> [!question]- Indizio 8
> `lvs` e `df -h /srv/dati` dicono la stessa dimensione? Cosa ha ingrandito il collega, e cosa no? Rileggi la [[05-lvm|lezione 05]].

> [!question]- Indizio 9
> `journalctl --list-boots`: quanti avvii vedi, e perché? Dopo averlo sistemato: l'avvio di adesso, journald lo sta scrivendo su disco o ancora in memoria? Il problema 1 della [[07-fsck-emergency|lezione 07]] controllava proprio questo. Se resta in memoria, dopo il riavvio finale `journalctl -b -1` non lo troverà.

> [!question]- Indizio 10
> Prima del riavvio finale, ripercorri la catena: GRUB, kernel, montaggi, swap, servizi, firewall. Per ognuno: quello che hai sistemato vale anche dopo un riavvio, o solo adesso?

**Dopo.** Quali guasti avrebbe scoperto il collega con un riavvio di prova prima di andare a casa, e quali no? Quali modifiche valevano solo in memoria e sono sparite al riavvio, e quali erano salvate ma sbagliate? Cosa controlla `findmnt --verify`, e quali guasti di stanotte avrebbe trovato? Perché il collega ha mascherato lab-app invece di disabilitarla, e cosa cambia? Perché l'avvio della riparazione poteva sparire dal journal anche dopo aver tolto il ritocco del collega? Se avessi potuto aggiungere un solo controllo alla procedura di manutenzione, quale sarebbe stato?

---

## Il resoconto dell'incidente

**Situazione.** Il responsabile vuole un resoconto dell'incidente (*post-mortem*, «dopo la morte»), da leggere alla riunione di lunedì. Non cerca un colpevole: vuole capire cosa è successo e come evitarlo.

> [!info] Il contesto
> **Lo scenario.** Dopo un guasto serio, in molte aziende si scrive un resoconto *senza colpe* (*blameless post-mortem*): i fatti, nell'ordine in cui sono successi, e le modifiche alla procedura perché non succeda più.
> - **Cronologia** (*timeline*): cosa è successo e quando, dal verbale ai log.
> - **Causa** e **sintomo**: il sintomo è ciò che si vede (la macchina ferma in emergency), la causa è ciò che l'ha provocato (una riga di `/etc/fstab`).
> - **Azione correttiva**: cosa cambia nella procedura, non solo sulla macchina.
>
> **Perché conta.** Una macchina riparata senza resoconto si rompe di nuovo alla prossima manutenzione, nello stesso modo.

**Compito.** Scrivi `palestra/l11/resoconto.md` con:

- la cronologia, dal verbale del collega al riavvio finale;
- per ogni guasto: il sintomo, la causa, la correzione, la lezione del percorso che lo spiegava;
- tre azioni correttive per la procedura di manutenzione.

**Verifica.** Il resoconto non ha un correttore: lo rileggiamo insieme. Ti faccio domande, non lo riscrivo.

---

## Pulizia — Dismettere la macchina dell'applicazione

**Situazione.** lab-app, i suoi dati e il sito passano su una macchina nuova. Questa torna com'era prima del progetto: dischi, swap, Apache, firewall, SELinux.

> [!info] Il contesto
> **Lo scenario.** Dismettere una macchina che ha avuto un incidente è l'ultima occasione per controllare di aver capito tutto ciò che ci si era sopra.
> - **Dismissione** (*decommissioning*): togliere un servizio da una macchina senza lasciare niente di attivo, di montato o di aperto.
>
> **Perché conta.** Un VG rimasto su un disco che torna in magazzino ricompare sulla prossima macchina che lo monta, con il suo nome e i suoi dati.

**Compito.** `sudo ./prepara.sh 11 pulizia`, poi esegui `palestra/l11/ticket-pulizia.txt`:

- lab-app ferma e disabilitata;
- Apache come prima del progetto, senza la configurazione del sito;
- il firewall come prima, adesso e in modo permanente;
- SELinux senza la regola di `/srv/web`, e sempre enforcing;
- la swap spenta, e i tre dischi in magazzino: niente di montato, nessuna firma, nessun PV, `/etc/fstab` com'era prima del progetto.

Criteri di accettazione: `sudo ./verifica.sh 11 pulizia` esce con 0.

**Verifica.** `sudo ./verifica.sh 11 pulizia`

> [!question]- Indizio 1
> In che ordine si smonta una pila di LVM? Rileggi la pulizia della [[05-lvm|lezione 05]].

**Dopo.** Cosa avresti dimenticato più facilmente, e cosa te lo avrebbe ricordato?

---

## Diario

Domande numerate, risposte, correzioni ed errori di questa lezione, guasto per guasto.

## Sintesi

Da scrivere insieme a lezione finita, partendo dalle mie parole: cosa ho imparato in tutto il percorso.

---

↑ [[00-percorso-linux|Il percorso]] · ← [[10-selinux-firewalld|Lezione 10]]
