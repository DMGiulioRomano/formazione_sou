---
tags:
  - virtualizzazione
  - nota
aliases:
  - Cloud: IaaS, PaaS, SaaS
---
# Cloud: IaaS, PaaS, SaaS

con lcoud usufruiamo le infrastrutture senza dover possedere l'hardware. 





## infrastructure as a service

tutta la parte relativa all'hardware è gestita dal provider. 

Non gestiamo:
- virtualization
- servers
- storage
- network

Cosa gestisce il provider: data center, hardware fisico, hypervisor, rete fisica.
Cosa gestisce l'utente: sistema operativo, middleware, runtime, applicazioni, dati.

## platform as a service

Definizione: il provider offre una piattaforma completa per sviluppare, testare, distribuire e gestire applicazioni. L'utente si concentra sul codice e sui dati, non sull'infrastruttura sottostante.

Cosa gestisce il provider: tutto lo stack fino al runtime (SO, middleware, database, ambienti di esecuzione, scaling).
Cosa gestisce l'utente: applicazione e dati.

Non gestiamo nemmeno:
- os
- middleware
- runtime

## software as a service

Definizione: il provider eroga un'applicazione completa pronta all'uso, accessibile via browser o API. L'utente non gestisce nulla dello stack: usa solo il software.

Cosa gestisce il provider: tutto (infrastruttura, piattaforma, applicazione, aggiornamenti, sicurezza).
Cosa gestisce l'utente: solo i propri dati e la configurazione del proprio account.

Per i consumatori. 

## Dalla lezione 4

### 10.1 Modelli di servizio

**IaaS (Infrastructure as a Service)**
- **Per**: Amministratori di sistema
- **Gestito dal provider**: Virtualizzazione, hardware, networking, storage
- **Gestito da te**: OS, middleware, runtime, applicazioni, dati
- **Esempio**: VPS, Aruba, Rackspace

**PaaS (Platform as a Service)**
- **Per**: Sviluppatori
- **Gestito dal provider**: OS, middleware, runtime
- **Gestito da te**: Solo applicazioni e dati
- **Esempio**: Heroku

**SaaS (Software as a Service)**
- **Per**: Utenti finali
- **Gestito dal provider**: Tutto
- **Gestito da te**: Nulla (usi il servizio)
- **Esempio**: Social network, web app, Gmail

### 10.2 Componenti cloud

**Cloud Computing Instance**
- Virtualizzazione e server
- Ridondanza, failover, load balancing, calcolo distribuito

**Block Storage**
- Storage flessibile con snapshot
- Aumenti/riduci dinamicamente

**Cloud Networking**
- Software Defined Networking (SDN)
- Infrastruttura di rete virtuale e scalabile

---

**Area:** [[mappa-virtualizzazione-cloud|Virtualizzazione e cloud]]  
**Fonte:** [[lezione-4-installazione-pacchetti|Lezione 4 — Installazione e package management]]  
**Vedi anche:** [[vm-vs-container|VM vs container]] · [[clonazione-vm-cloud-init|Clonazione VM e cloud-init]] · [[lvm|LVM]]
