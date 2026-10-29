---
tags:
  - storia
  - nota
aliases:
  - Software libero e GNU/Linux
  - Revolution OS
---
# Software libero e GNU/Linux

Appunti dal documentario *Revolution OS*: come nascono il Free Software, GNU, il kernel Linux e il movimento Open Source.

## Stallman e il Free Software

Richard Stallman, il padre del Free Software, lavorava al MIT su un sistema operativo condiviso. Quando al MIT vollero introdurre le password, lui si oppose: quella scelta presupponeva un amministratore che controllasse tutti gli utenti.

Fra gli anni '70 e '80 nasce il software proprietario, e Microsoft ne è uno dei pionieri: i contratti di licenza obbligano gli utenti a non condividere il software con nessuno. Nel 1975 un gruppo di hobbisti fonda l'Homebrew Computer Club. Stallman non accetta il modello proprietario e vuole creare e mantenere una comunità.

## GNU

Nel 1984 Stallman avvia **GNU**, acronimo ricorsivo di "GNU's Not Unix". UNIX era proprietario e non si poteva usare liberamente: l'idea era un sistema simile, ma libero.

Il kernel UNIX apparteneva ad AT&T, società di telecomunicazioni fondata nel 1885 come sussidiaria della Bell Telephone Company. Alcuni ingegneri di Berkeley, in base ad accordi con AT&T, svilupparono **BSD** (Berkeley Software Distribution), software libero basato su UNIX.

Quando GNU viene rilasciato come software libero, in molti lo scaricano. Per proteggere la comunità nasce il **copyleft**: la licenza **GNU GPL** garantisce le libertà dell'utente e ne spiega la filosofia, e impedisce che il codice venga chiuso. Nascono anche aziende che fanno dell'assistenza sul software libero il proprio core business; col software proprietario, invece, l'assistenza era un monopolio di chi possedeva il software.

GNU parte dagli strumenti di base del sistema operativo (il toolkit GNU), ma manca ancora un kernel che lo renda indipendente da UNIX.

## Il kernel Linux

Linus Torvalds scrive un kernel: **Linux**. È un **kernel monolitico**, cioè un unico programma che gira in kernel space. L'alternativa è il **microkernel**, un insieme di server separati che comunicano tramite un protocollo comune.

GNU/Linux è l'unione del sistema operativo GNU con il kernel Linux, anche se oggi quasi tutti chiamano erroneamente "Linux" l'intero sistema.

| Termine | Cos'è |
|---|---|
| **Linux** | il kernel: gestisce l'hardware ed espone ai programmi in user space un'interfaccia di system call |
| **GNU** | il sistema operativo, o *userland*: shell, compilatori, librerie, utility, editor |
| **Distro** | il pacchetto installabile: prende kernel e userland, li compila in pacchetti di un formato specifico (`.deb`, `.rpm`…), li organizza in repository e li consegna con una policy di aggiornamento e dei default |

## Apache e l'Open Source

**Apache HTTP Server** è stata l'applicazione che ha fatto decollare GNU/Linux. È un software libero e open che fa da server web: è il programma che, sul server, risponde alle richieste HTTP/HTTPS del browser, elabora contenuti statici o dinamici e restituisce la risposta all'utente. Linux più Apache era il connubio perfetto in termini di portabilità e flessibilità.

**Free Software e Open Source non sono la stessa cosa:**

- il **Free Software** parla della libertà del software e di una società fondata sulla comunità;
- l'**Open Source** si concentra sui vantaggi pratici di una comunità di utenti che collaborano scambiandosi e migliorando il software. I suoi principi sono raccolti nella **Open Source Definition**.

---

**Area:** [[mappa-storia|Storia]]  
**Vedi anche:** [[kernel|Kernel Linux]] · [[tipi-di-shell|Tipi di shell]] · [[mappa-pacchetti-librerie|Pacchetti e librerie]] · [[dpkg-apt|dpkg e apt]] · [[rpm-yum-dnf-zypper|rpm, yum, dnf, zypper]] · [[storia-virtualizzazione-kubernetes|Dal mainframe a Kubernetes]]
