---
tags:
  - pacchetti
  - nota
aliases:
  - rpm, YUM, DNF e Zypper
---
# rpm, YUM, DNF e Zypper

## 8.1 rpm (basso livello)

```bash
# Info pacchetto (senza installarlo)
rpm -qpi nome_pacchetto

# Lista file nel pacchetto
rpm -qpl nome_pacchetto

# Installare
rpm -ih nome_pacchetto
# (mostra dipendenze fallite se presenti)

# Lista tutti i pacchetti installati
rpm -qa

# Info su pacchetto installato
rpm -qi nome_pacchetto

# Da quale pacchetto viene un file
rpm -qf nome_file

# Estrarre archivio cpio da rpm
rpm2cpio nome_pacchetto.rpm > output.cpio
cpio -i --make-directories < output.cpio

# Rimuovere
rpm -e nome_pacchetto
```

## 8.2 YUM (obsoleto, sostituito da DNF)

```bash
# Aiuto
yum -help

# Cercare
yum search nome_pacchetto

# Quali pacchetti contengono un file
yum provides nome_file

# Info pacchetto
yum info nome_pacchetto

# Controllare aggiornamenti (non cachato)
yum check-update

# Aggiornare (come upgrade di apt)
yum update

# Lista pacchetti
yum list
yum list nome

# Installare
yum install pacchetto

# Rimuovere
yum remove pacchetto

# Gruppi
yum grouplist
yum groupinstall nome_gruppo
```

## 8.3 DNF (sostituto di YUM)

**Sintassi identica a yum**, quindi tutti i comandi sopra funzionano sostituendo `yum` con `dnf`.

## 8.4 ZYPPER (openSUSE)

```bash
# Cercare (lento ma completo, con tabella stato)
zypper search ssh

# Solo download
zypper download autossh
```

**Nota**: Zypper sostituisce yum downloader e può fare molte più operazioni.

---

**Area:** [[mappa-pacchetti-librerie|Pacchetti e librerie]]  
**Fonte:** [[lezione-4-installazione-pacchetti|Lezione 4 — Installazione e package management]]  
**Vedi anche:** [[dpkg-apt|dpkg e APT]] · [[librerie-condivise|Librerie condivise]]
