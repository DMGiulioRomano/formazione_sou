# Revisione della PR #4: avanzamento

File di lavoro, da togliere nel lotto 9. Tiene il conto dei findings della review della PR #4, un lotto per sessione.

**Fonti.** Review 6072098847 (1/4: giudizio, G1-G15); commenti 7188988438 (2/4: M, m, s), 7189089072 (3/4: §2.6, problemi, §4.1 e §4.2), 7189225072 (4/4: esiti, appendici A, C, B10 e il diff delle correzioni). Le righe citate nella review (V:394, P:3400…) sono del commit b9d4b57.

**Stati.** `[ ]` da fare · `[x] <sha>` fatto · `[~]` proposta non collaudata · `[-] motivo` non si fa · `[?]` da decidere con lo studente, a fine lotto.

**Sigle di §4.** `F1`-`F28` sono le righe di §4.1 (affermazioni false) nell'ordine della tabella; `Q1`-`Q5` quelle di §4.2 (dubbie).

## Lotto 0: file di avanzamento

- [x] questo file

## Lotto 1: `azzera` tocca solo ciò che è del kit

- [~] 94a5da4 G9 — `azzera` cancella configurazioni dell'utente (moduli SELinux, booleani, porte, firewall, Apache, crond) dalla lezione 01. Fatti i punti 1 (parti riportate solo dopo un problema delle lezioni che le usano; fotografie al primo prepara di quelle lezioni), 3 (copie in `/var/lib/lab-linux/copie/`) e 4 (L00). Resta il punto 2, vedi sotto [?]
- [x] 6cd1717 G7 — `azzera` può togliere dal file dei dispositivi di LVM la voce del PV di sistema (`DEVNAME` vecchio). In più: la riga senza PVID si toglie per IDNAME (`--deldev … --deviceidtype`) se il DEVNAME non porta al bersaglio [~]
- [x] db8e600 G1 — 01 4: il correttore fa scrivere lo script dello studente su `/etc/hostname`, da root
- [~] 598d9b0 M23 — `pulisci_fstab` toglie righe dell'utente che usano un punto del kit. Fatta la proposta: rifiuto con 3 se una riga altrui monta su un punto del kit; via anche le righe orfane sui punti del kit
- [x] 598d9b0 M9 — `pulisci_fstab` toglie righe `LABEL=` dell'utente uguali a meno delle maiuscole
- [?] G9, punto 2 — SELinux: togliere solo le differenze nei nomi che le lezioni usano, invece di `semanage import` di tutta la fotografia. Con i punti 1 e 3 il danno resta solo dentro le lezioni 10-11, e con una copia. Da decidere se farlo
- [~] 8372bdf M10 — `azzera` si fida dei suoi file di stato. `kernel-finto` dal diff; `utenti-kit`, `file-kit`, `fstab-kit`, loop e `sysctl.d` dalla proposta

## Lotto 2: falsi positivi delle lezioni 01-04

- [ ] G2 — 01 1: un filesystem creato sulla partizione passa
- [ ] G3 — 01 4: tre casi del contratto non provati, uno script incompleto prende 22/22
- [ ] G4 — 02 2: la copia che perde date, proprietari e permessi passa
- [ ] G5 — 04 P e 11 P: `swapoff -a` passa e spegne la swap del sistema
- [ ] G6 — pulizie: le firme dentro le vecchie partizioni non si vedono

## Lotto 3: falsi positivi 07-11 e residui che falsano le prove

- [ ] G10 — 07 4: `noauto` aggira «niente nofail» (era M5)
- [ ] G11 — 08 1: chi riavvia invece di cambiare target a caldo passa (era m24)
- [ ] G12 — 10 3: firewalld acceso ma non abilitato passa
- [ ] G13 — 10 P e 11 P: «sempre enforcing» controllato solo con `getenforce`
- [ ] G14 — 09 3: nel quarto d'ora dopo il ricalcolo passa la soluzione senza ricalcolo (era m25)
- [ ] G15 — 08 2: il soccorso lasciato in `/etc/default/grub` passa (era M19)
- [ ] M27 — `azzera` non rimette la scheda nella sua zona se la zona sta nel profilo di NetworkManager
- [ ] M28 — 09 3: `azzera` non ferma il timer transitorio del ricalcolo con una descrizione propria

## Lotto 4: falsi negativi

- [ ] G8 — 11 P: il file dei dispositivi di LVM è un requisito nascosto
- [ ] M1 — 01 4: chi usa `gdisk`/`sgdisk` non passa; l'ordine dei controlli diventa un requisito
- [ ] M2 — 02 3: `sgdisk -e` bocciato con un messaggio falso
- [ ] M3 — 03 1: due falsi negativi in fstab
- [ ] M4 — 07 1: «al massimo 200 MiB» vuol dire esattamente 200
- [ ] M22 — 09 4: l'attesa attiva della rete al posto di `sleep` è bocciata
- [ ] M26 — 10 1: la 80 aperta con una regola ricca è bocciata
- [ ] M29 — 11 1: la swap su LV scritta in fstab per UUID risulta «non scritta» (era m27)

## Lotto 5: altri medi

- [ ] M6 — `azzera` dalla shell di emergenza uccide sé stesso e la shell
- [ ] M7 — 06 3: un riavvio durante il problema porta in emergency mode, e la lezione non lo dice
- [ ] M8 — `riga_fstab` incolla la riga del kit all'ultima riga di fstab senza a capo
- [ ] M11 — la guardia non vede un VG con un PV mancante
- [ ] M12 — `azzera` lascia gli automount sui punti del kit
- [ ] M13 — `groupdel` che fallisce lascia `azzera` a metà con il codice 8
- [ ] M14 — `ticket` scrive da root nella palestra seguendo i link simbolici
- [ ] M15 — 05 2 e 02 2: lo stato non è quello che il ticket racconta
- [ ] M17 — 11 1: i messaggi sono l'elenco degli otto guasti, il riavvio finale non è verificato
- [ ] M18 — 10 4: «tutto vale anche dopo un riavvio» non si può ottenere
- [ ] M20 — `azzera` non riporta `/etc/sysctl.conf`
- [ ] M25 — `azzera` non riporta la configurazione di LVM (`use_devicesfile = 0`)
- [-] M5 — spostato fra i gravi: è G10 (lotto 3)
- [-] M19 — spostato fra i gravi: è G15 (lotto 3)

## Lotto 6: riquadri, indizi e messaggi che danno la soluzione

- [ ] M24 — riquadri «Il contesto» e indizi che danno la soluzione (Appendice B5)
- [ ] M16 — i messaggi del correttore danno la soluzione (T8)

## Lotto 7: affermazioni false e dubbie delle lezioni

§4.1, le false:

- [ ] F1 — L09:90, 103, 126; ticket 09 2: `MemoryMax` su crond limita «tutto ciò che lancia cron» (è M21)
- [ ] F28 — L08:20, 94, 111; L11:22: il menu di GRUB «compare» all'avvio (DP-1)
- [ ] F2 — L11:81 (Indizio 5): con la swap orfana `is-system-running` non dice `running`
- [ ] F3 — L07:172, L11:75 (Indizio 3): dopo un timeout di dispositivo «chi è fallito» si vede con `systemctl --failed`
- [ ] F4 — L02:175: il filesystem «fantasma» su un disco senza firme
- [ ] F5 — L05:199: un VG tolto con i volumi attivi «lascia il kernel a usare dischi che non esistono più»
- [ ] F6 — L04:148: la riga di swap orfana «lascia un'unità fallita a ogni riavvio»
- [ ] F7 — L07:64 (Indizio 3): basta riavviare journald (vedi m21)
- [ ] F8 — L10:239: «`semanage export` le elenca tutte»
- [ ] F9 — L06:131, L05:199: togliere l'origine o il VG con i volumi attivi lascia il device-mapper su dischi vuoti
- [ ] F10 — L11:132: il VG «ricompare sulla prossima macchina che lo monta»
- [ ] F11 — L07:112, ticket 07 3: il log di XFS ancora sporco dopo il riavvio
- [ ] F12 — L03:173 (Indizio 3): la risposta è in `man chmod`, SETUID AND SETGID BITS
- [ ] F13 — L09:141: l'ora convertita a mano «è giusta metà dell'anno»
- [ ] F14 — L02:90, 95: il numero di inode di un ext4 si decide una volta sola (vedi m30)
- [ ] F15 — L05:87: la dimensione degli extent «si decide una volta sola»
- [ ] F16 — L09:139: l'unità transitoria «sparisce quando ha finito»
- [ ] F17 — L09:49: ogni unità è «descritta da un file»
- [ ] F18 — L07:45: un journal su disco senza limite riempie `/var`
- [ ] F19 — L01:143: PARTUUID è il GUID di una partizione GPT
- [ ] F20 — L03:178: in fondo ai permessi si vede una `t` (è m32)
- [ ] F21 — L04:32, ticket 04 1: «La macchina non ha swap» (è m28)
- [ ] F22 — L05:17, 188: il VG di sistema si chiama `rl` (è m33)
- [ ] F23 — L03:113: «le due dipendenze di systemd»
- [ ] F24 — L02:127, 158: `man 5 xfs` cita `xfs_growfs`; `man xfs_growfs` parla di riduzione
- [ ] F25 — L08 (avvertenza), L00: la fotografia «di solito nella lezione 07» (è m37, legata a G9)
- [ ] F26 — appunto `journaling.md`:10: il journal memorizza dati e metadati. L'appunto è dello studente: la review lo segnala soltanto
- [ ] F27 — appunto `integrita-fsck.md`:24: il controllo all'avvio solo se il campo vale 1. L'appunto è dello studente: la review lo segnala soltanto

§4.2, le dubbie:

- [ ] Q1 — L05:199: un PV rimasto nel file dei dispositivi «lascia avvisi a ogni comando LVM» (DP-4)
- [ ] Q2 — L07:98: «leggi la prima riga della risposta» di e2fsck (DP-9)
- [ ] Q3 — L08:157, ticket 08 4 e 11 1: «Macchina → Ripristina» (è m47)
- [ ] Q4 — L00:151: l'EX200 «oggi è basato su RHEL 10» (non verificabile)
- [ ] Q5 — altre 9 di formulazione (D6-D15, D19, Appendice B6)

## Lotto 8a: minori m1-m27

- [ ] m1 — `--a-secco` cambia lo stato
- [ ] m2 — `prepara.sh` senza argomenti esce con 1, L00 dice 2
- [ ] m3 — `LAB_MODELLO` non documentato, aggira il controllo del modello
- [ ] m4 — `dischi --rifai` con uno scenario in piedi
- [ ] m5 — VG omonimo di quello di sistema su un bersaglio: messaggio sbagliato
- [ ] m6 — i prerequisiti si controllano dopo `azzera`
- [ ] m7 — senza `base/avvio/target` `azzera` esce 1
- [ ] m8 — un loop su un file dentro un punto del kit blocca `azzera`
- [ ] m9 — il journal resta persistente dopo la lezione 07
- [ ] m10 — `userdel` senza `-r`
- [ ] m11 — `riporta_crond` copia sopra un file del pacchetto
- [ ] m12 — inventario `--loop`: immagini e loop restano
- [ ] m13 — `ammesso` accetta `/dev/sr0`
- [ ] m14 — `SERVIZI` e `PORTE` ordinati con due lingue diverse
- [ ] m15 — le pulizie confrontano fstab con l'inventario
- [ ] m16 — 03 3 con `x-systemd.automount`: messaggio illeggibile
- [ ] m17 — 02 3 e 02 4: XFS controllati con il 20% di tolleranza
- [ ] m18 — 02 2: lo spazio per 50.000 messaggi non è controllato
- [ ] m19 — 05 3: il disco tolto resta nel file dei dispositivi
- [ ] m20 — 06 2: il merge in sospeso
- [ ] m21 — 07 1: nessun indizio porta a `journalctl --flush`
- [ ] m22 — 07 2: dopo `errors=remount-ro` `findmnt` dice ancora `rw`
- [ ] m23 — 07 4: l'indizio 2 mostra solo il dispositivo
- [-] m24 — spostato fra i gravi: è G11 (lotto 3)
- [-] m25 — spostato fra i gravi: è G14 (lotto 3)
- [ ] m26 — swap su file in un filesystem dei bersagli
- [-] m27 — spostato fra i medi: è M29 (lotto 4)

## Lotto 8b: minori m28-m53 e stile

- [ ] m28 — 04 1: «La macchina non ha swap» (vedi F21)
- [ ] m29 — 01 P: «i due dischi dedicati», ma sono tre
- [ ] m30 — 02 2 «Dopo»: la partizione si potrebbe ingrandire (vedi F14)
- [ ] m31 — 02 4: messaggi in MiB fuorvianti
- [ ] m32 — 03 4 «Dopo»: `t` minuscola contro `T` (vedi F20)
- [ ] m33 — 05: il VG di sistema è `rlm`, non `rl` (vedi F22)
- [ ] m34 — pulizia 05 «Dopo»: `/etc/lvm/archive` mostra i comandi del kit
- [ ] m35 — 06 1-2: montare lo snapshot `ro,nouuid` scrive comunque nel COW
- [ ] m36 — 08 2: la voce «0-rescue» non è la modalità di soccorso
- [ ] m37 — 08, avvertenza: la fotografia si fa al primo `prepara` (vedi F25)
- [ ] m38 — L00: `git` non è fra i pacchetti
- [ ] m39 — link ambigui fra `linux/11-progetto-finale.md` e `scripting/11-progetto-…`
- [ ] m40 — `CLAUDE.md`: Apache, firewall e SELinux sono dalla 10, non dalla 09
- [ ] m41 — T5, T6, T7, T9: `findmnt --verify` controlla solo la riga del problema
- [ ] m42 — L00:101: l'elenco degli utenti e gruppi di prova
- [ ] m43 — grubenv fotografato tutto, riportato solo `saved_entry`
- [ ] m44 — utente orfano dopo uno spegnimento brusco
- [ ] m45 — `riporta_sysctl` forza `vm.swappiness` in memoria
- [ ] m46 — messaggio dopo `azzera`: «Il problema preparato ora è «- -»»
- [ ] m47 — «Macchina → Ripristina»: la voce è «Reset» (vedi Q3)
- [ ] m48 — lanciato da un link simbolico, il kit non trova `lib/`
- [ ] m49 — 02 3: il correttore vuole anche il nome della partizione
- [ ] m50 — 09 P: l'unità fallita annunciata non c'è
- [ ] m51 — 11 1: appena riavviata, «l'avvio è arrivato in fondo» può dare NO
- [ ] m52 — 11 1, il resoconto: mancano una lunghezza e una fonte per le ore della notte
- [ ] m53 — 11 1, indizio 7: su una macchina permissive il sito si vede anche dopo il riavvio
- [ ] s1 — i riquadri «Il contesto» delle pulizie hanno 2-3 righe e 0-1 termini
- [ ] s2 — piè di pagina: «↑ ← →» contro «← ↑ →» dello scripting
- [ ] s3 — tabella degli appunti, riga 8: parafrasi, non citazione
- [ ] s4 — 11 «Il resoconto dell'incidente» senza criteri né «Dopo»

## Lotto 9: rilettura finale

- [ ] `bash -n` e `shellcheck` su tutto il kit
- [ ] togliere questo file
- [ ] aggiornare la descrizione della PR: fatto e da collaudare

## Collaudo

Un blocco per lotto, aggiunto alla fine di ogni lotto. Il lotto 0 non tocca il kit: niente da collaudare.

### Collaudo lotto 1

Da `~/formazione_sou/lab/linux`, con il kit del ramo aggiornato (`git pull`). Prima di cominciare, una copia di ciò che le prove toccano a mano:

```
sudo cp /etc/fstab /root/fstab.bak
sudo cp /etc/lvm/devices/system.devices /root/system.devices.bak
sudo cp /var/lib/lab-linux/bersagli /root/bersagli.bak
cp palestra/l01/clona-schema.sh ~/clona-schema.mio 2>/dev/null
```

**G1 — 01 4 non scrive più su `/etc/hostname`.**
1. `sudo ./prepara.sh 01 4`
2. Ingenua (quella del «Riprodurre» della review): `printf '#!/bin/bash\ndd if="$1" of="$2" bs=1M count=1 status=none\n' > palestra/l01/clona-schema.sh; chmod +x palestra/l01/clona-schema.sh`
3. `sudo ./verifica.sh 01 4; echo rc=$?` → **rc=1**, con «NO destinazione che non è un dispositivo: 2» e «NO e il file è rimasto com'era».
4. `head -c 16 /etc/hostname | od -c` → il nome della macchina, non byte di una tabella.
5. Giusta: `cp ~/clona-schema.mio palestra/l01/clona-schema.sh` (il tuo script della 01 4), `sudo ./verifica.sh 01 4; echo rc=$?` → **rc=0**.

**G7 — la voce del PV di sistema resta nel file dei dispositivi.**
1. `sudo ./prepara.sh 04 3`, poi `lsblk -o NAME,SERIAL` e `sudo lvmdevices`: annota il nome del PV di sistema (es. `/dev/sda2`) e quello della seconda partizione di D1 (es. `/dev/sdb2`).
2. `sudo sed -i 's|DEVNAME=/dev/sda2 |DEVNAME=/dev/sdb2 |' /etc/lvm/devices/system.devices` (con i nomi annotati).
3. `sudo ./prepara.sh azzera; echo rc=$?` → **rc=0**; nessuna riga «tolgo dal file dei dispositivi di LVM» col seriale del disco di sistema.
4. `sudo lvs` → `rlm` con `root` e `swap`; `sudo lvmdevices` → la riga del sistema c'è ancora.
5. `sudo cp /root/system.devices.bak /etc/lvm/devices/system.devices`.
6. Che le righe dei bersagli vadano ancora via: `sudo ./prepara.sh 05 4`, `sudo ./prepara.sh azzera`, `sudo lvmdevices` → solo la riga del sistema. Se trovi una riga di un bersaglio con `PVID=none`, incolla l'output: è il ramo `--deldev … --deviceidtype` non collaudato.

**M9 — le etichette contano le maiuscole.**
1. `printf 'LABEL=backup /mnt/mio xfs noauto,nofail 0 0\nLABEL=ARCHIVIO2 /mnt/mio2 xfs noauto,nofail 0 0\n' | sudo tee -a /etc/fstab`
2. `sudo ./prepara.sh 03 3`, poi `sudo ./prepara.sh azzera` → **rc=0** tutte e due le volte.
3. `grep -E 'mio2?' /etc/fstab` → le due righe ci sono ancora.

**M23 — le righe altrui sui punti del kit.**
1. `echo 'tmpfs /srv/www tmpfs defaults,nofail,size=8m 0 0' | sudo tee -a /etc/fstab`
2. `sudo ./prepara.sh azzera; echo rc=$?` → **rc=3**, il rifiuto con la riga elencata, e niente toccato (`lsblk` come prima).
3. Nella riga sostituisci `/srv/www` con `/srv/mio`: `sudo sed -i 's| /srv/www tmpfs | /srv/mio tmpfs |' /etc/fstab`; `sudo ./prepara.sh azzera` → **rc=0**, e la riga di `/srv/mio` resta.
4. Una riga orfana su un punto del kit: `echo 'UUID=00000000-0000-4000-8000-000000000000 /srv/dati xfs defaults,nofail 0 0' | sudo tee -a /etc/fstab`; `sudo ./prepara.sh azzera` → **rc=0**, «tolgo da /etc/fstab: UUID=0000…».
5. Le righe del kit vanno ancora via: `sudo ./prepara.sh 07 4`, `sudo ./prepara.sh azzera`, `grep /srv/dati /etc/fstab` → niente.
6. Alla fine `diff /root/fstab.bak /etc/fstab` → solo le righe di `/mnt/mio`, `/mnt/mio2` e `/srv/mio`, da togliere a mano.

**M10 — file di stato rovinati.** Le prove distruttive girano a secco.
1. Utenti: `echo 'utente 0' | sudo tee -a /var/lib/lab-linux/utenti-kit; echo 'utente root' | sudo tee -a /var/lib/lab-linux/utenti-kit`; `sudo ./prepara.sh --a-secco azzera` → nessun `pkill -KILL -u 0`, «non tocco l'utente 0» e «non tocco l'utente root».
2. File: `echo /etc/httpd/conf.d/lab-x/../../conf/httpd.conf | sudo tee -a /var/lib/lab-linux/file-kit`; `sudo ./prepara.sh --a-secco azzera` → «non tolgo …: non è un percorso del kit», nessun `rm -rf`.
3. fstab: `echo "UUID=$(findmnt -no UUID /boot)" | sudo tee -a /var/lib/lab-linux/fstab-kit`; `sudo ./prepara.sh --a-secco azzera` → nessun «tolgo da /etc/fstab» per `/boot`.
4. Dopo le tre prove: `sudo ./prepara.sh azzera` (vero, adesso innocuo) → **rc=0**, e i tre file di stato si svuotano; `getent passwd root` e `/etc/httpd/conf/httpd.conf` ci sono.
5. Kernel finto: `sudo ./prepara.sh 08 1`; `sudo touch /root/vittima; echo /root/vittima | sudo tee -a /var/lib/lab-linux/kernel-finto`; `sudo ./prepara.sh azzera` → «non tolgo /root/vittima: non ha la forma…», e `ls /root/vittima` c'è ancora.
6. Inventario: `sudo truncate -s 100M /root/vittima.img; echo 'D4 loop /root/vittima.img' | sudo tee -a /var/lib/lab-linux/bersagli`; `sudo ./prepara.sh azzera; echo rc=$?` → **rc=3**, «non è un'immagine del kit»; `losetup -j /root/vittima.img` vuoto. Poi `sudo cp /root/bersagli.bak /var/lib/lab-linux/bersagli`.
7. sysctl: `echo '# solo un commento' | sudo tee /etc/sysctl.d/99-mio.conf`; `sudo ./prepara.sh azzera` → il file resta.

**G9 — `azzera` non tocca la configurazione dell'utente fuori dalle lezioni 07-11.**
1. Dopo un `prepara` qualsiasi, i comandi del «Riprodurre» della review: porta 8888 con `semanage`, `httpd_can_sendmail on`, il modulo `mio`, la porta 9999 di firewalld, `/etc/httpd/conf.d/mio.conf`; in più il drop-in di crond: `sudo mkdir -p /etc/systemd/system/crond.service.d; printf '[Service]\nNice=2\n' | sudo tee /etc/systemd/system/crond.service.d/mio.conf; sudo systemctl daemon-reload`.
2. `sudo ./prepara.sh 03 4; echo rc=$?` → **rc=0**, e nessuno dei messaggi «tolgo il modulo SELinux mio», «semanage … tornano com'erano», «/etc/firewalld torna com'era», «tolgo /etc/httpd/conf.d/mio.conf», «ritocco di crond».
3. Controlla che ci sia tutto: `sudo semanage port -l | grep 8888`, `getsebool httpd_can_sendmail`, `sudo semodule -l | grep -w mio`, `sudo firewall-cmd --list-ports`, `ls /etc/httpd/conf.d/mio.conf /etc/systemd/system/crond.service.d/mio.conf`.
4. Dentro una lezione che li usa il kit li riporta ancora, ma con una copia: `sudo ./prepara.sh 10 1`, poi `sudo ./prepara.sh azzera` → «copia di ciò che tolgo o cambio: /var/lib/lab-linux/copie/<data>», e lì dentro `selinux/semanage.export` (con la porta 8888), `selinux/booleani`, il modulo `mio` estratto, `etc/firewalld` (con la 9999) ed `etc/httpd/conf.d/mio.conf`. Incolla `sudo find /var/lib/lab-linux/copie -maxdepth 3`.
5. Lo stesso per crond: `sudo ./prepara.sh 09 1`, `sudo ./prepara.sh azzera` → il drop-in `mio.conf` tolto, e una copia in `copie/<data>/etc/systemd/system/crond.service.d/`.
6. Che le lezioni 07-11 restino giuste: `sudo ./prepara.sh 10 1`, la tua soluzione della 10 1, `sudo ./verifica.sh 10 1` → **rc=0** come prima; poi `sudo ./prepara.sh 08 1` e `sudo ./verifica.sh 08 1` senza fare niente → **rc=1** (lo stato di partenza non è già risolto).

Nota: sulla `lab-rocky` le fotografie di avvio, servizi e web sono quelle del primo `prepara` del kit di prima (lezione 01). Restano valide; il kit nuovo le rifà solo se mancano.
