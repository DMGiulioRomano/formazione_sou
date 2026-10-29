---
tags:
  - storia
  - virtualizzazione
  - nota
aliases:
  - Dal mainframe a Kubernetes
  - Fly Me To The Moon
---
# Dal mainframe a Kubernetes

Appunti dal talk *Fly Me To The Moon* di Kat Cosgrove, lead developer advocate in Dell.

**Kubernetes** è una piattaforma open source per orchestrare container: automatizza deployment, gestione, scalabilità e montaggio di applicazioni containerizzate su cluster di macchine.

## Tesi centrale

Kubernetes è una nuova risposta a un problema vecchio di 60-70 anni: come far fare più cose, più in fretta, a una sola macchina. La sua complessità è normale per uno strumento giovane (rilascio pubblico nel 2014). Sembra difficile anche perché abbiamo dimenticato i problemi che ha risolto. Jenkins, Terraform e Kubernetes sembrano ostici finché non provi a fare a mano quello che fanno loro: deploy, infrastruttura, scaling.

**Virtualizzazione:** usare un computer per simulare aspetti di un altro computer. Una VM virtualizza l'hardware, un container il sistema operativo (vedi [[vm-vs-container|VM vs container]]). Anche VPN e file system distribuiti sono forme di virtualizzazione.

## Le tappe principali

- **ENIAC e mainframe:** macchine enormi, difficili da usare, molto costose e in genere noleggiate. Facevano girare un programma alla volta, poi arrivò il *batch processing* (programmi in coda uno dopo l'altro).
- **1959, time sharing:** primo brevetto sulla multiprogrammazione. Per realizzarlo davvero serviva la memoria virtuale.
- **1962, Atlas** (Manchester, Ferranti): primo supercomputer e prima implementazione funzionante della memoria virtuale. Per la relatrice è la macchina più importante della storia dell'informatica, ma non fu mai venduta.
- **IBM System/360:** una famiglia modulare di mainframe, retrocompatibile, cosa allora mai vista. Con i sistemi operativi CP-40 (su un 360/40 modificato, 1967) e poi CP-67 (sul 360/67, 1968) portò in commercio la virtualizzazione completa. IBM conquistò il mercato, e queste macchine contribuirono al programma Apollo e al Saturn V.
- **1969, Unix ai Bell Labs.** Nel 1979 Unix V7 introduce `chroot`, una specie di proto-container che isola il file system. Da qui la strada dei container si separa da quella delle VM.
- **2000, FreeBSD jails:** isolamento del file system e dei privilegi di root, quote di CPU e limiti di memoria. Poi Virtuozzo, Solaris Zones (2004), OpenVZ e altri.
- **2008, cgroups nel kernel Linux** (sviluppati da Google dal 2006): limitano le risorse di gruppi di processi (vedi [[namespaces-cgroups|Namespaces e cgroups]]). Sopra ci nascono LXC (2008) e systemd-nspawn (2010).
- **2013, Docker:** risolve portabilità e facilità d'uso e si diffonde rapidissimo. Come nel passaggio dal batch al time sharing, conta l'accessibilità oltre alla tecnica.
- **2014, Kubernetes:** primo rilascio pubblico, con Docker come primo runtime.

## Chiusura

L'ecosistema cloud native nasce da oltre 70 anni di lavoro sullo stesso problema. La relatrice chiede cosa farà sembrare primitivo Kubernetes fra 70 anni, e cosa vorrà dire allora "scale".

---

**Area:** [[mappa-storia|Storia]] · [[mappa-virtualizzazione-cloud|Virtualizzazione e cloud]]  
**Vedi anche:** [[vm-vs-container|VM vs container]] · [[namespaces-cgroups|Namespaces e cgroups]] · [[immagini-container|Immagini container]] · [[cloud-iaas-paas-saas|Cloud: IaaS, PaaS, SaaS]] · [[software-libero-gnu-linux|Software libero e GNU/Linux]]
