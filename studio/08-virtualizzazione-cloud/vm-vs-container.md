---
tags:
  - virtualizzazione
  - nota
aliases:
  - VM vs container
---
# VM vs container

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

## Dalla lezione 4

### 9.1 Virtualizzazione (tradizionale)

**Architettura:**
```
Infrastruttura
    ↓
OS
    ↓
Hypervisor
    ↓
VM1  VM2  VM3  (ognuna con OS completo)
```

**Caratteristiche:**
- Ogni VM ha OS completo, librerie, binari propri
- Richiede supporto hardware (VTX/AMD-V)
- Avvio: ordine di minuti
- Disco: GB per VM
- RAM: allocata staticamente
- Sicurezza: isolamento completo
- Esempio: VirtualBox, VMware

### 9.2 Containerizzazione

**Architettura:**
```
Infrastruttura
    ↓
OS
    ↓
Demone container
    ↓
Container1  Container2  Container3
(app + librerie essenziali)
```

**Caratteristiche:**
- Condivide kernel e OS con l'host
- Nessun supporto hardware richiesto
- Soft virtualization a livello OS
- Avvio: secondi/millisecondi
- Disco: centinaia di MB
- RAM: allocazione dinamica
- Sicurezza: isolamento a livello processo
- Risorse condivise read-only
- Esempio: Docker, Podman

---

**Area:** [[mappa-virtualizzazione-cloud|Virtualizzazione e cloud]]  
**Fonte:** [[lezione-4-installazione-pacchetti|Lezione 4 — Installazione e package management]]  
**Vedi anche:** [[namespaces-cgroups|Namespaces e cgroups]] · [[immagini-container|Immagini container]] · [[cloud-iaas-paas-saas|Cloud: IaaS, PaaS, SaaS]] · [[clonazione-vm-cloud-init|Clonazione VM e cloud-init]] · [[lvm|LVM]] · [[storia-virtualizzazione-kubernetes|Dal mainframe a Kubernetes]]
