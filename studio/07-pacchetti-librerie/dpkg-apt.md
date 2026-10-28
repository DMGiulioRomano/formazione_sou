---
tags:
  - pacchetti
  - nota
aliases:
  - dpkg e APT
---
# dpkg e APT

## 7.1 dpkg (basso livello)

```bash
# Installare pacchetto .deb
dpkg -i nome_pacchetto

# Info sul pacchetto
dpkg --info nome_pacchetto

# Lista file nel pacchetto
dpkg --listfile nome_pacchetto

# Da quale pacchetto viene un file
dpkg -S /percorso/file

# Percorso completo eseguibile
which nome_comando

# Alternanze (es. versioni Java)
update-alternatives --display nome

# Lista pacchetti installati
dpkg -L

# Filtrare per nome
dpkg -l tz*

# Riconfigurare pacchetto
dpkg-reconfigure tzdata

# Rimuovere (mantiene config)
dpkg -r nome_pacchetto

# Rimuovere tutto (config inclusa)
dpkg --purge nome_pacchetto
```

## 7.2 APT (alto livello, gestisce dipendenze)

```bash
# Cercare pacchetti
apt-cache search pdf

# Dettagli pacchetto
apt-cache showpkg nome_pacchetto

# Statistiche cache
apt-cache stats

# Dipendenze non soddisfatte
apt-cache unmet

# Dipendenze di un pacchetto
apt-cache depends nome_pacchetto

# Dipendenze inverse (chi dipende da questo)
apt-cache rdepends nome_pacchetto

# Ricerca per nome
apt-cache pkgnames nome

# Repository
vi /etc/apt/sources.list

# Aggiornare cache
apt-get update

# Aggiornare pacchetti installati
apt-get upgrade

# Installare
apt-get install virtualbox

# Simulazione
apt-get -s install virtualbox

# Solo download (in /var/cache/apt/archives)
apt-get install -d virtualbox

# Pulire cache
apt-get clean

# Rimuovere
apt-get remove virtualbox

# Rimuovere con dipendenze
apt-get autoremove virtualbox

# Rimuovere tutto
apt-get autoremove --purge virtualbox
```

## 7.3 Aptitude

```bash
# Cercare
aptitude search nome_pacchetto

# Interfaccia testuale
# (premere U per aggiornare)
```

**Nota**: Aptitude è stato rimosso in favore di apt in molte distribuzioni.

> [!question] Da approfondire
> - `rdepends`: cosa sono le dipendenze inverse e quando usarle

---

**Area:** [[mappa-pacchetti-librerie|Pacchetti e librerie]]  
**Fonte:** [[lezione-4-installazione-pacchetti|Lezione 4 — Installazione e package management]]  
**Vedi anche:** [[rpm-yum-dnf-zypper|rpm, YUM, DNF e Zypper]] · [[librerie-condivise|Librerie condivise]] · [[comandi-ricerca|Comandi di ricerca]]
