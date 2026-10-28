---
tags:
  - virtualizzazione
  - nota
aliases:
  - Clonazione VM e cloud-init
---
# Clonazione VM e cloud-init

## 11.1 Cosa cambiare dopo clonazione

**MAC Address**
- Virtuale, legato al sistema di virtualizzazione

**UUID dei dischi**
- Non viene cambiato automaticamente
- Cambiare con `tune2fs` per evitare confusione

**Hostname**
```bash
cat /etc/hostname
hostnamectl
```

**Chiavi SSH Host**
```bash
cat /etc/ssh/ssh_host_*
```
Importante per sicurezza: ogni host deve avere chiavi univoche

**UUID del D-Bus**
```bash
dbus-uuidgen --ensure
cat /var/lib/dbus/machine-id
```
Più importante per containerizzazione

**Software di integrazione**
- Cartelle condivise host/guest
- Accelerazione video
- Copia/incolla clipboard

## 11.2 Clonazione in VirtualBox

**Opzioni:**
1. **Clone completo**: copia fisica, indipendente dall'originale
2. **Clone collegato**: dipende dalla macchina originale

**Esportazione come template:**
```
File → Esporta applicazione virtuale → seleziona VM → formato .ova
```

## 11.3 Cloud-init

Strumento per personalizzare istanze cloud tramite file di configurazione (YAML).

**Cosa può fare:**
- Impostare hostname
- Cambiare chiavi SSH
- Configurare servizi
- Eseguire script custom (runcmd)

**Altri tool simili:**
- Puppet
- Ansible

> [!question] Da approfondire
> - Cloud-init: sintassi YAML ed esempi pratici

---

**Area:** [[mappa-virtualizzazione-cloud|Virtualizzazione e cloud]]  
**Fonte:** [[lezione-4-installazione-pacchetti|Lezione 4 — Installazione e package management]]  
**Vedi anche:** [[vm-vs-container|VM vs container]] · [[cloud-iaas-paas-saas|Cloud: IaaS, PaaS, SaaS]] · [[dispositivi-moduli-kernel|Dispositivi e moduli del kernel]] · [[integrita-fsck|Integrità del filesystem e fsck]]
