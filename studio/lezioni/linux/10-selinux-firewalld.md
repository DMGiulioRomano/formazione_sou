---
tags:
  - lezione
  - linux
aliases:
  - Linux 10 — SELinux e firewalld
---
# Linux 10 — SELinux e firewalld

Un servizio acceso non basta. Deve passare il firewall, e SELinux deve permettergli di leggere i suoi file, di ascoltare sulla sua porta e di collegarsi agli altri servizi. In questa lezione:

- apri il sito alla rete senza aprire altro;
- rimetti SELinux in enforcing senza rompere il sito;
- fai ripartire Apache su una porta nuova, raggiungibile da una rete sola;
- sblocchi un proxy con il minimo dei permessi.

Non ci sono ancora appunti su SELinux e sul firewall: li scrivi tu, a lezione finita, partendo da ciò che hai scoperto. Il servizio da proteggere è Apache (il pacchetto `httpd`, *HTTP daemon*), il server web delle distribuzioni Red Hat. Il kit lo configura per te: tu ti occupi di ciò che gli sta intorno.

```sh
cd formazione_sou/lab/linux
sudo ./prepara.sh 10        # problema 1; poi sudo ./prepara.sh 10 2, e così via
```

> [!warning] Prima di cominciare
> - **Gli strumenti**, se mancano: `sudo dnf install -y httpd firewalld policycoreutils-python-utils setroubleshoot-server`.
> - **Una fotografia della VM**, a VM spenta: `VBoxManage snapshot lab-rocky take prima-di-10`. Qui si toccano il firewall e SELinux della macchina.
> - **La finestra della VM** a portata di mano: se una regola sbagliata chiude SSH, dalla console si rientra.
> - **Una porta di VirtualBox verso Apache**, per provare dal Mac come farebbe un ufficio. A VM accesa:
>
>   ```sh
>   VBoxManage controlvm lab-rocky natpf1 "web,tcp,127.0.0.1,8080,,80"
>   curl http://127.0.0.1:8080/                                         # dal Mac
>   VBoxManage controlvm lab-rocky natpf1 delete web                    # a fine lezione
>   ```
>
> **Cosa riporta indietro il kit.** `prepara.sh` fotografa Apache, firewalld e SELinux la prima volta che li trova installati, in `/var/lib/lab-linux/base/web/`. Ogni `prepara.sh` successivo riporta indietro:
> - i file di Apache nati dopo la fotografia che non sono di un pacchetto;
> - `/etc/firewalld` e la configurazione attiva del firewall;
> - le personalizzazioni di SELinux (`semanage`), i booleani, la modalità e i moduli locali nati dopo.
>
> Per SELinux ci vuole qualche decina di secondi.

## La mappa

| # | Problema | Stato |
|---|---|---|
| 1 | Il sito interno non si vede dagli uffici | — |
| 2 | SELinux in permissive | — |
| 3 | Apache non riparte | — |
| 4 | /api/ risponde 503 | — |
| P | Pulizia — dismettere il sito interno | — |

---

## Problema 1 — Il sito interno non si vede dagli uffici

**Situazione.** Sulla macchina il sito interno risponde, dagli uffici no. Ieri un collega ha fatto delle prove sul firewall e ha lasciato aperta la porta del database «per un test veloce».

> [!info] Il contesto
> **Lo scenario.** «In locale va, da fuori no» è la frase più comune dei ticket di rete. La prima cosa da guardare è il firewall della macchina.
> - **Firewall** (inglese, «muro tagliafuoco»): il filtro che decide quali connessioni entrano. Su Rocky lo gestisce **firewalld** (la *d* finale sta per *daemon*, «demone»), che traduce le sue regole per il filtro del kernel, nftables.
> - **Zona** (*zone*): un insieme di regole che vale per una scheda di rete, o per chi arriva da certe reti.
> - **Configurazione attiva** (*runtime*) e **permanente** (*permanent*): quella che vale adesso, e quella che firewalld rilegge quando riparte. Sono separate: si possono cambiare l'una senza l'altra.
> - **Servizio di firewalld**: un nome per un gruppo di porte, come `ssh`. Le definizioni stanno in `/usr/lib/firewalld/services/`.
>
> **Perché conta.** Una regola solo attiva sparisce al riavvio, e il sito torna invisibile di notte. Una regola provvisoria salvata per sbaglio lascia il database esposto per mesi.

**Compito.** Esegui `palestra/l10/ticket-1.txt`:

- il sito raggiungibile dalla rete sulla porta 80, adesso e dopo ogni riavvio;
- la 3306 di nuovo chiusa, adesso e dopo ogni riavvio;
- il firewall acceso, SSH raggiungibile, nient'altro di aperto rispetto a prima.

Criteri di accettazione:

- `sudo ./verifica.sh 10 1` esce con 0;
- dal Mac, con l'inoltro di VirtualBox verso la 80, il sito risponde.

**Verifica.** `sudo ./verifica.sh 10 1`. Il correttore prova anche da fuori. Crea una piccola rete finta, uno **spazio dei nomi di rete** (*network namespace*, `ip netns`), collegata alla macchina nella stessa zona della scheda vera, e si collega da lì.

> [!question]- Indizio 1
> `firewall-cmd --get-active-zones`, poi `firewall-cmd --list-all`: cosa è aperto adesso? E con `--permanent` davanti?

> [!question]- Indizio 2
> La 3306: dove sta, nella configurazione attiva o in quella permanente? Cosa le succederebbe se firewalld ripartisse?

> [!question]- Indizio 3
> In `man firewall-cmd` cerca *permanent* e *reload*: cosa fa ciascuno alla configurazione attiva?

> [!question]- Indizio 4
> Nella stessa pagina cerca *runtime-to-permanent*: cosa salverebbe, se lo lanciassi adesso?

**Dopo.** Dove scrive firewalld la configurazione permanente (`/etc/firewalld/zones/`)? Perché si preferisce `--add-service=http` a `--add-port=80/tcp`? Cosa c'è sotto, nel kernel (`nft list ruleset`)? Che differenza c'è fra rifiutare (*reject*) e scartare (*drop*) un pacchetto, e cosa vede chi prova a collegarsi?

---

## Problema 2 — SELinux in permissive

**Situazione.** Il controllo periodico ha trovato SELinux in modalità permissive. Un collega ce l'ha messo quando ha spostato il sito su un disco nuovo, «perché altrimenti Apache dava errore». E il listino dà 403 da quando c'è il disco nuovo.

> [!info] Il contesto
> **Lo scenario.** SELinux spento «per far funzionare le cose» è la non conformità più comune sui server Red Hat. Riaccenderlo senza capire cosa bloccava rompe il servizio, e lo si rispegne.
> - **SELinux** (*Security-Enhanced Linux*, «Linux con la sicurezza rafforzata»), nato all'NSA americana: ogni processo e ogni file ha un'**etichetta** (*security context*), e una **politica** (*policy*) dice quali etichette possono fare cosa.
> - **Tipo** (*type*): la parte dell'etichetta che conta di più, quella che finisce in `_t`. `ls -Z` e `ps -Z` la mostrano.
> - **Enforcing** («che fa rispettare») e **permissive** («che permette»): nel primo SELinux blocca, nel secondo lascia fare e registra soltanto.
> - **DAC** e **MAC** (*discretionary* e *mandatory access control*, controllo dell'accesso a discrezione e obbligatorio): i permessi Unix li decide il proprietario del file, quelli di SELinux la politica. Devono essere d'accordo tutti e due.
> - **AVC** (*access vector cache*): il nome del messaggio con cui SELinux registra un divieto, nel registro di audit.
>
> **Perché conta.** Un 403 può venire dai permessi Unix o da SELinux. Si ripara solo sapendo quale dei due, e un'etichetta messa a mano sparisce alla prima rietichettatura.

**Compito.** `sudo ./prepara.sh 10 2`, poi esegui `palestra/l10/ticket-2.txt`:

- SELinux in enforcing, adesso e dopo ogni riavvio;
- tutte le pagine dell'elenco in `palestra/l10/pagine-2.txt` rispondono, listino compreso;
- le etichette giuste restano anche dopo una rietichettatura dei file o dell'intera macchina;
- Apache legge il sito ma non può scriverci: niente scrivibile da tutti, niente di proprietà di `apache`.

Criteri di accettazione:

- `sudo ./verifica.sh 10 2` esce con 0;
- `getenforce` stampa `Enforcing`.

**Verifica.** `sudo ./verifica.sh 10 2`

> [!question]- Indizio 1
> Prima di cambiare modalità: in permissive SELinux registra ciò che avrebbe bloccato. Cosa c'è in `ausearch -m avc -ts today`, o in `journalctl -t setroubleshoot`?

> [!question]- Indizio 2
> Il listino dà 403 anche in permissive. Allora chi lo blocca? `namei -l /srv/web/sito/listino/prezzi-2026.html` mostra i permessi di ogni cartella sul percorso.

> [!question]- Indizio 3
> `ls -Z /srv/web/sito` e `ls -Zd /var/www/html`: che tipo hanno? Quale si aspetta Apache?

> [!question]- Indizio 4
> In `man semanage-fcontext`, gli esempi in fondo: come si scrive una regola che vale per una cartella e per tutto ciò che contiene? La regola cambia i file che ci sono già, o serve qualcuno che la applichi?

> [!question]- Indizio 5
> Le modalità: `man setenforce` per adesso, `/etc/selinux/config` per i prossimi avvii.

**Dopo.** Perché un sito in `/srv/www` non avrebbe avuto bisogno di nessuna regola? Cerca `srv` in `semanage fcontext -l`. Che differenza c'è fra `chcon` e una regola con `restorecon`? Cosa fa `touch /.autorelabel`? Perché passare da *disabled* a enforcing è più delicato che da permissive? Cosa dicono `sealert -a /var/log/audit/audit.log` e `audit2why` sui divieti di prima? Cosa vuol dire `s0` alla fine dell'etichetta?

---

## Problema 3 — Apache non riparte

**Situazione.** Ieri sera un collega ha aggiunto la console di monitoraggio di Apache sulla porta 8081 e ha riavviato Apache. Da allora Apache non parte, e anche il sito sulla porta 80 è giù. La console deve essere raggiungibile solo dalla rete del monitoraggio.

> [!info] Il contesto
> **Lo scenario.** Spostare un servizio standard su una porta non standard è un classico: SELinux sa su quali porte può ascoltare ogni servizio, e se la porta nuova non è fra quelle il servizio non parte.
> - **Dominio** (*domain*): il tipo di un processo. Apache gira nel dominio `httpd_t`.
> - **Tipo di porta** (*port type*): anche le porte hanno un tipo, e la politica dice in quali tipi di porta può ascoltare ogni dominio.
> - **Rete di provenienza** (*source*): firewalld può decidere non solo in base alla porta, ma anche in base a chi si collega.
>
> **Perché conta.** Un errore nella configurazione di una console secondaria ha spento anche il sito principale: Apache o parte con tutte le sue porte, o non parte.

**Compito.** `sudo ./prepara.sh 10 3`, poi esegui `palestra/l10/ticket-3.txt`:

- Apache di nuovo su, con il sito sulla 80 e la console sulla 8081;
- la console raggiungibile da fuori solo dalla rete 192.0.2.0/24, il sito e SSH da tutti, come prima;
- SELinux enforcing per tutti i processi, Apache compreso;
- tutto vale anche dopo un riavvio.

Criteri di accettazione:

- `sudo ./verifica.sh 10 3` esce con 0;
- `curl -s http://127.0.0.1:8081/` risponde la console.

**Verifica.** `sudo ./verifica.sh 10 3`. La rete finta del correttore si collega da due reti: 192.0.2.0/24, quella del monitoraggio, e 198.51.100.0/24, un'altra. Sono due reti riservate agli esempi e alla documentazione.

> [!question]- Indizio 1
> `systemctl status httpd` e `journalctl -u httpd -n 20`: cosa non riesce a fare Apache, e su quale indirizzo?

> [!question]- Indizio 2
> `ausearch -m avc -ts recent`: cosa è stato negato, a quale dominio, su quale oggetto?

> [!question]- Indizio 3
> `semanage port -l | grep -w 8081`: la porta ha già un tipo? Con quale tipo sono etichettate le porte su cui Apache ascolta di solito?

> [!question]- Indizio 4
> Per il firewall: in `man firewalld.zones` e `man firewall-cmd`, cosa c'è, oltre a servizi e porte, per dire «solo da questa rete»?

> [!question]- Indizio 5
> Se hai legato la rete del monitoraggio a un'altra zona: cosa può fare quella rete nella zona nuova, a parte la console?

**Dopo.** Cosa mostrano `semanage port -l -C` e `semanage export`? Sulle versioni più vecchie `semanage port -a` su una porta che ha già un tipo falliva con *already defined*: cosa fa oggi, e quale opzione dice esplicitamente «modifica»? Cosa farebbe `semanage permissive -a httpd_t`, e perché è peggio di quello che hai fatto? Cosa vedi con `nft list ruleset | grep -B2 -A2 8081`?

---

## Problema 4 — /api/ risponde 503

**Situazione.** Apache fa da proxy per il backend del listino: `/api/` passa a `http://127.0.0.1:8080/`. Il backend risponde, ma attraverso Apache `/api/listino.json` dà 503. La politica di sicurezza dice: Apache si collega ai servizi web e ai proxy, non a porte qualsiasi né ai database.

> [!info] Il contesto
> **Lo scenario.** Apache davanti a un'applicazione è l'architettura più comune, e il caso più comune di SELinux che «rompe» qualcosa che in permissive funzionava.
> - **Proxy inverso** (*reverse proxy*): il server che riceve le richieste dal pubblico e le passa a un altro, dietro di sé.
> - **503** (*Service Unavailable*, «servizio non disponibile»): Apache c'è, ma non riesce a ottenere la risposta da chi sta dietro.
> - **Booleano** (dal matematico George Boole): un interruttore della politica, acceso o spento, che abilita un gruppo di permessi già scritti e collaudati.
> - **Minimo privilegio** (*least privilege*): dare a un programma solo i permessi che gli servono, così un suo errore fa meno danni.
> - **Modulo di politica**: regole aggiunte alla politica. `audit2allow` ne scrive uno a partire dai divieti registrati.
>
> **Perché conta.** Con l'interruttore sbagliato Apache può collegarsi a tutto, database compresi. Un modulo scritto in fretta permette anche ciò che nessuno voleva permettere.

**Compito.** `sudo ./prepara.sh 10 4`, poi esegui `palestra/l10/ticket-4.txt`:

- `/api/listino.json` risponde attraverso Apache;
- SELinux enforcing, e tutto vale anche dopo un riavvio;
- Apache non può collegarsi a porte qualsiasi né ai database;
- niente moduli di politica scritti a mano.

Criteri di accettazione:

- `sudo ./verifica.sh 10 4` esce con 0;
- `curl -s http://127.0.0.1/api/listino.json` risponde il listino.

**Verifica.** `sudo ./verifica.sh 10 4`

> [!question]- Indizio 1
> `curl -v http://127.0.0.1/api/listino.json`, poi le ultime righe di `/var/log/httpd/error_log`: cosa dice Apache del backend?

> [!question]- Indizio 2
> `ausearch -m avc -ts recent`: quale permesso manca, e verso quale tipo di porta?

> [!question]- Indizio 3
> Passa quel divieto a `audit2why`, o leggi cosa propone `sealert`: quali interruttori lo permetterebbero?

> [!question]- Indizio 4
> `semanage boolean -l | grep httpd_can_network`: cosa permette ciascuno, e quale apre di meno? In `man setsebool`: come si fa sopravvivere un interruttore al riavvio?

**Dopo.** Cosa permettono, esattamente, i due interruttori? Lo dice `sesearch -A -s httpd_t -b NOME`, nel pacchetto `setools-console`. Il backend sulla 8080 va: andrebbe anche sulla 3000? Perché? Cosa avrebbe scritto `audit2allow`, e perché va letto prima di caricarlo? Cosa sono le regole *dontaudit*, e quando serve `semodule -DB` per vederle?

---

## Pulizia — Dismettere il sito interno

**Situazione.** Il sito, la console e il backend sono passati su un'altra macchina. Questa torna com'era prima della lezione: Apache, firewall, SELinux e i due dischi dedicati.

> [!info] Il contesto
> **Lo scenario.** Le eccezioni di sicurezza si chiudono quando il servizio se ne va: una porta etichettata o un interruttore acceso senza più un motivo sono un permesso in più per chiunque arrivi dopo.
> - **Personalizzazioni locali**: ciò che l'amministratore ha aggiunto alla politica di SELinux. `semanage export` le elenca tutte.
>
> **Perché conta.** Un'eccezione dimenticata non dà nessun errore. La trova un attaccante, o un controllo di conformità.

**Compito.** `sudo ./prepara.sh 10 pulizia`, poi esegui `palestra/l10/ticket-pulizia.txt`:

- Apache acceso o spento come prima della lezione, senza le configurazioni del sito;
- `lab-backend.service` fermo e cancellato;
- firewall come prima, adesso e in modo permanente;
- SELinux senza la regola di `/srv/web`, l'etichetta della 8081 e l'interruttore del proxy, e sempre enforcing;
- i due dischi dedicati restituiti puliti, `/etc/fstab` com'era prima della lezione.

Criteri di accettazione: `sudo ./verifica.sh 10 pulizia` esce con 0.

**Verifica.** `sudo ./verifica.sh 10 pulizia`

> [!question]- Indizio 1
> Ogni opzione di `semanage` che aggiunge ha la sua che toglie: cercala in `man semanage-fcontext` e `man semanage-port`. E un interruttore, come torna al valore della politica?

**Dopo.** Cosa mostra `semanage export` alla fine, e perché un interruttore rimesso al suo valore con `setsebool -P` compare ancora? Cosa toglie `semanage boolean -D`, e perché non conviene usarlo su una macchina che non conosci?

---

## Diario

Domande numerate, risposte, correzioni ed errori di questa lezione, problema per problema.

## Sintesi

Da scrivere insieme a lezione finita, partendo dalle mie parole.

---

↑ [[00-percorso-linux|Il percorso]] · ← [[09-systemd|Lezione 09]] · → [[11-progetto-finale|Lezione 11]]
