---
tags:
  - pacchetti
  - nota
aliases:
  - Librerie condivise
---
# Librerie condivise

## 6.1 Tipi di eseguibili

**Dinamically Linked**
- Fanno riferimento a librerie esterne
- Più comuni in Linux

**Staticly Linked**
- Contengono tutte le librerie necessarie
- Esempio: `ln` esiste in entrambe le versioni

## 6.2 Librerie condivise (.so)

```bash
# Vedere librerie necessarie a un eseguibile
ldd /bin/ln /sbin/sln

# Vedere tutte le librerie con percorsi
ldconfig -p
```

## 6.3 Dove vengono cercate le librerie

**Percorsi di default:**
- `/lib`
- `/lib64`

**Configurazione aggiuntiva:**
- `/etc/ld.so.conf.d/` - file di configurazione percorsi

**Aggiornare cache:**
```bash
# Come root
ldconfig
```

## 6.4 Variabili d'ambiente

```bash
# Impostare temporaneamente
export LD_LIBRARY_PATH=/lib2

# Verificare
ldd /bin/ls
```

## 6.5 Architettura sistema
```bash
uname -a
```

---

**Area:** [[mappa-pacchetti-librerie|Pacchetti e librerie]]  
**Fonte:** [[lezione-4-installazione-pacchetti|Lezione 4 — Installazione e package management]]  
**Vedi anche:** [[dpkg-apt|dpkg e APT]] · [[rpm-yum-dnf-zypper|rpm, YUM, DNF e Zypper]] · [[fhs|FHS]] · [[variabili-opzioni|Variabili e opzioni della shell]]
