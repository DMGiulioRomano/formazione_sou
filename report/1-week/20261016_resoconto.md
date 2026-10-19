# Resoconto giornate

Resoconto prima settimana.

## Giovedì 15

Predisposizione del computer aziendale. 
Purtroppo per via della deprecazione  degli OS di Macos, Homebrew non viene piu fornito. 
Nonostante le varie prove per installarlo in modo da installare poi git o altri tool di sviluppo, non sono riuscito. 
Presa visione di ciò ho provveduto a sviluppare una visione d'insieme del materiale fornitoci per il corso. Ho preso visione del ppt di Giosuè Manzo fornitoci nelle linee guida.
Dopo la pausa pranzo mi sono allontanato per un appuntamento preso precedentemente e concordato e specificato con la HR Maristella (avvisando anche il tutor presente in sede).

## Venerdì 16

Presa visione dei video delle cartelle google drive "1. introduzione" e "2. 101" e realizzato il test finale con risultato 80/100 dimenticando purtroppo di annotare l'errore che avevo fatto. Purtroppo non ho saputo ritrovare la compilazione del form google.  

### 1. Introduzione

ho visto tutti i video. 
ho installato virtualbox. 
Ho perduto tempo a scaricare il file di ubuntu poiché la connessione continuava a interrompersi e il download si annullava.
Inizialmente ho scaricato la veriosne di ubuntu 26 ma mi sono reso conto che, una volta caricato l'iso dentro la virtual machine, continuava a crashare. 
Cercando su internet ho scoperto che probabilmente la versione di ubuntu 26 aveva bisogno di almeno 6gb di allocazione della RAM mentre ne avevo allocati solo 4gb. 
Invece ho visto che la versione di ubuntu 24.04 ne necessita teoricamente solo 4gb. 
Così l'ho scaricata e sono riuscito a lanciare il file di installazione ma purtroppo si interrompe ogni volta che premo la spunta di downloads di driver aggiuntivi (come il driver della scheda di rete per il wifi che non viene letta). 
Non sono riuscito ancora a completare l'installazione perché continua a bloccarsi.

### 2. 101

Ho visto tutti i video. 
Poi ho deciso di andare più in profondità su quale è la logica che sta alla base dell'avviamento del computer fino ad arrivare al display manager. 
Ho così studiato come funzionano i firmware BIOS/UEFI (quindi le funzioni POST, inizializzazione, CMOS e bootstrap), come funziona il processo di bootstrap (qui ho visto in breve il bootloader GRUB, lo stage 1, ipotetici stage intermedi e lo stage 2), come funziona initramfs e l'init di vmlinuz. 
A questo punto mi sono studiato i target di systemd e ho scoperto che sono molto simili ai target di GNU make... ovvero vanno al contrario avendo dei prerequisiti. poi ho cercato di capire cosa fa systemd dopo l'avvio del display manager  e ho cercato di intendere come funzionano le system call ma con scarsi risultati.

Mi ha un po' confuso la correlazione tra sysvinit, upstart e systemd. Probabilmente sarà piu comprensibile quando avrò a disposizione sistemi piu vecchi con cui fare la comparazione. 

Ammetto di essermi servito dell'intelligenza artificiale della ricerca google per chiedere cose che non riuscivo a comprendere bene come per esempio la differenza tra il termine bootloader e bootstrap o cose del genere. Trovo la possibilità di riformulare infinite volte e in parole diverse lo stesso concetto un modo assai prolifico per comprendere elementi astratti. 

Ho infine cercato di capire le varie sotto cartelle della cartella proc/ e i filtri di journalctl 

