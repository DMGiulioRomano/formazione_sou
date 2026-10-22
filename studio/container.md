
# differenza VM vs container

la macchina virtuale ha al proprio interno il proprio sistema operativo.
ma quale è il problema? che la macchina virtuale proprio perché ha il proprio sistema operativo... con disco rigido necessario, ram occupata, cpu.... occupa diverse risorse. c'è inoltre una duplicazione di file ridondanti che spesso non utilizziamo. 

i container sono molto piu leggeri. quello che fanno è appoggiarsi al sistema operativo già present nella nostra macchina. posso costruirli molto facilemte con un semplice file di configurazione. 



Le virtual machines hanno:
- un hypervisor è il software che si occupa di creare la virtualizzazione utilizzando 
- l'hardware e organizzarlo.

i conainers hanno:
- l'hadrware in fondo, 
- poi il kernel, 
- poi il sistema operativo che da da host
- per i vari container. 


quando ho un server io posso usare piu virtual machines e quindi virtualizzare molti computer su un solo server.

nei container nella parte del kernel abbiamo possibilità di usare namespaces e cgroups.

e portability e flexibility?
- container basta un semplice file...

I **namespaces** e i **cgroups** sono due meccanismi fondamentali del kernel Linux che, lavorando insieme, costituiscono la base dei **container** (come Docker o LXC). Insieme permettono la cosiddetta "virtualizzazione leggera", un'alternativa ai hypervisor di cui abbiamo parlato prima.

Mentre un hypervisor virtualizza l'hardware per eseguire kernel separati, namespaces e cgroups partizionano un **singolo kernel Linux** per creare ambienti isolati per gruppi di processi.

Ecco le loro funzioni principali:

###  Namespaces

I namespaces si occupano di **cosa i processi possono vedere**. Ogni namespace avvolge una risorsa di sistema globale in un'astrazione, facendo credere ai processi al suo interno di avere la propria istanza privata e isolata di quella risorsa.

In pratica, offrono a un gruppo di processi una "vista" limitata del sistema. Ecco i namespace principali:

*   **Mount (`mnt`)**: Isola i punti di mount e i filesystem. Un processo vede solo i dischi e le directory montati nel suo namespace.
*   **PID (`pid`)**: Isola gli ID dei processi. All'interno del container, il processo principale può avere PID 1, senza vedere i processi dell'host o di altri container.
*   **Network (`net`)**: Isola lo stack di rete. Ogni namespace ha le proprie interfacce di rete, indirizzi IP, tabelle di routing e porte.
*   **User (`user`)**: Isola gli ID utente e gruppo. Un processo può essere "root" (UID 0) all'interno del suo namespace, ma essere un utente non privilegiato sull'host.
*   **UTS**: Isola l'hostname e il nome del dominio NIS, permettendo a ogni container di avere il proprio nome host.
*   **IPC**: Isola le risorse di comunicazione inter-processo (IPC), come le code di messaggi System V e POSIX.

###  Cgroups

I cgroups (abbreviazione di *control groups*) si occupano di **quante risorse i processi possono usare**. Sono una funzionalità del kernel che organizza i processi in gruppi gerarchici e monitora e limita il loro utilizzo di varie risorse.

In sostanza, i cgroups impediscono che un singolo container (o un gruppo di processi) possa monopolizzare le risorse dell'host, causando problemi agli altri. I controller principali includono:

*   **CPU**: Limita la quantità di tempo di CPU che un gruppo di processi può consumare.
*   **Memory**: Imposta un limite massimo alla memoria RAM che un gruppo può utilizzare.
*   **Blkio**: Limita la larghezza di banda I/O per l'accesso ai dischi (es. lettura/scrittura).
*   **Pids**: Limita il numero massimo di processi che possono essere creati in un cgroup.

###  In sintesi: il connubio perfetto per i container

Namespaces e cgroups sono **ortogonali** ma complementari. Per creare un container, è necessario utilizzare entrambi:

1.  I **namespaces** creano la "bolla" isolata, facendo sembrare al processo di essere su un sistema tutto suo.
2.  I **cgroups** mettono dei paletti su quella bolla, assicurandosi che non consumi più risorse di quelle assegnate.


