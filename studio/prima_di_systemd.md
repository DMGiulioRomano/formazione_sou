# PRIMA DI SYSTEMD

Upstart e SysVinit (System V Init) sono i due importanti sistemi di inizializzazione che venivano usati in Linux prima dell'invenzione di systemd.

Rappresentano la storia e l'evoluzione di come Linux svegliava i servizi dopo la fase di initramfs. Nella nostra metafora della staffetta, prima di systemd, il ruolo di PID 1 era ricoperto da uno di questi due sistemi.

Ecco cosa sono nel dettaglio e come funzionavano:

## 1. SysVinit (Il passato antico e sequenziale)

Prende il nome dal sistema operativo Unix System V degli anni '80 ed è stato lo standard assoluto su Linux per oltre vent'anni.

- **Come funzionava**: si basava interamente sui **Runlevel** (i livelli numerici da 0 a 6 di cui abbiamo parlato) e su una serie di script testuali scritti in Bash situati nella cartella `/etc/init.d/`.

- **Il limite principale (La lentezza)**: SysVinit era strettamente **sequenziale**. Avviava un servizio alla volta seguendo un ordine numerico rigido. Ad esempio, lo script `S10network` doveva attivarsi e terminare del tutto prima che potesse partire `S20ssh`. Se un servizio si bloccava o era lento, l'intero avvio del computer si congelava in attesa. Inoltre, non capiva se un hardware veniva rimosso o inserito a PC acceso (non era dinamico).

## 2. Upstart (La transizione guidata dagli eventi)

Creato da Ubuntu (Canonical) nel 2006, Upstart nacque proprio per superare la lentezza e la rigidità di SysVinit. È stato il sistema di default di Ubuntu per molti anni (da Ubuntu 6.10 fino alla 14.14) e adottato per un periodo anche da Fedora e Red Hat.

- **La rivoluzione (Asincrono e basato su eventi)**: Upstart ha eliminato la sequenza rigida introducendo i concetti di **Eventi** e **Job** (lavori). Invece di aspettare un ordine numerico, i servizi partivano reagendo a ciò che accadeva nell'hardware o nel sistema.

- **Come funzionava**: un servizio diceva: "Avviami quando viene rilevato l'evento 'rete-pronta'". Non appena il kernel notificava la presenza della rete, Upstart lanciava quel servizio. Questo permetteva di avviare molti programmi in parallelo, rendendo il boot straordinariamente più veloce rispetto a SysVinit.

## Perché alla fine ha vinto systemd?

Nonostante Upstart fosse un ottimo passo avanti, presentava un problema: gestire la ragnatela di eventi hardware e software era diventato estremamente complesso e incline a bug (potevano crearsi situazioni di stallo in cui il servizio A aspettava l'evento B, che a sua volta aspettava l'evento A).

Intorno al 2010 è nato systemd, che ha fuso le idee migliori di entrambi:

- Ha mantenuto il parallelismo e la velocità di Upstart.
- Ha sostituito la complessa logica a eventi con un più solido **grafo matematico delle dipendenze** (i Target e i Service stile GNU Make).

Entro il 2015, quasi tutte le principali distribuzioni Linux (inclusa la stessa Ubuntu) hanno abbandonato sia SysVinit che Upstart per adottare systemd come standard universale.

Con Upstart e SysVinit abbiamo completato l'albero genealogico dell'avvio di Linux! C'è qualche aspetto di questa evoluzione che ti incuriosisce particolarmente, o vuoi vedere come systemd riesce ancora a digerire i vecchi script di SysVinit per compatibilità?

---