---
tags:
  - init-servizi
  - nota
aliases:
  - systemd
---
# systemd

Ha dei **target**, ovvero obiettivi da raggiungere. Infatti si chiamano `.target`:

- `sysinit.target`: controlla lo stato dei dischi fissi e monta tutte le partizioni fondamentali.
- `basic.target`: con cui vengono avviati i servizi di base come la gestione dei log di sistema (`journald`) ecc.
- `network.target`: dove attiva la rete internet e il computer ottiene l'indirizzo IP.
- `multi-user.target`: vengono avviati servizi di rete tipo `sshd` e prompt di testo per fare login `agetty`.
- Se è in modalità desktop e non in modalità server → lanciato `graphical.target` che avvia il display manager.

Poi il display manager avvia la tua sessione grafica. Da questo momento in poi systemd svolge monitoraggio e gestione degli eventi:

- gestisce l'energia (sospensione processi quando si spegne lo schermo);
- gestisce servizi in background e quelli che crashano li riavvia in automatico;
- registra quello che succede nel log `journald`, così si possono consultare i problemi. Come vedo tutte le info loggate? Con `journalctl` → studiare il modo in cui filtrare i log!

## systemctl

`systemctl` è il comando da terminale principale utilizzato per controllare, gestire e monitorare systemd, ovvero il sistema di inizializzazione che governa l'intero sistema operativo Linux.

Puoi avviare, fermare o riavviare qualsiasi programma in background, configurare l'avvio automatico, cambiare il target (per esempio da multi-user a graphical), anche controllare l'alimentazione per spegnere o sospendere.

---

**Area:** [[mappa-init-servizi|Init e servizi]]  
**Vedi anche:** [[prima-di-systemd|Prima di systemd]] · [[journalctl|journalctl]] · [[initramfs|Initramfs]] · [[kernel|Kernel Linux]]
