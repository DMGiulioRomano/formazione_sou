# Revisione della PR #4: avanzamento

File di lavoro, da togliere nel lotto 9. Tiene il conto dei findings della review della PR #4, un lotto per sessione.

**Fonti.** Review 6072098847 (1/4: giudizio, G1-G15); commenti 7188988438 (2/4: M, m, s), 7189089072 (3/4: §2.6, problemi, §4.1 e §4.2), 7189225072 (4/4: esiti, appendici A, C, B10 e il diff delle correzioni). Le righe citate nella review (V:394, P:3400…) sono del commit b9d4b57.

**Stati.** `[ ]` da fare · `[x] <sha>` fatto · `[~]` proposta non collaudata · `[-] motivo` non si fa · `[?]` da decidere con lo studente, a fine lotto.

**Sigle di §4.** `F1`-`F28` sono le righe di §4.1 (affermazioni false) nell'ordine della tabella; `Q1`-`Q5` quelle di §4.2 (dubbie).

## Lotto 0: file di avanzamento

- [x] questo file

## Lotto 1: `azzera` tocca solo ciò che è del kit

- [x] 94a5da4 G9 — `azzera` cancellava configurazioni dell'utente fuori dalle lezioni che le usano. Fatti i punti 1 (parti riportate solo dopo un problema delle lezioni 07-11 che le usano; fotografie al primo prepara di quelle lezioni), 3 (copie in `/var/lib/lab-linux/copie/`) e 4 (L00). Collaudato sul banco
- [x] 6cd1717 ba210ae G7 — `azzera` poteva togliere dal file dei dispositivi di LVM la voce del PV di sistema (`DEVNAME` vecchio). Il collaudo ha trovato un errore nel diff della review (`losetup` con `set -e`), corretto in ba210ae. Collaudato anche il ramo `--deldev … --deviceidtype`
- [x] db8e600 ba210ae G1 — 01 4: il correttore faceva scrivere lo script dello studente su `/etc/hostname`, da root. Collaudato
- [x] 598d9b0 M23 — `pulisci_fstab` toglieva righe dell'utente su un punto del kit. Fatta la proposta: rifiuto con 3 se una riga altrui monta su un punto del kit; via le righe orfane. Collaudato
- [x] 598d9b0 M9 — `pulisci_fstab` toglieva righe `LABEL=` dell'utente uguali a meno delle maiuscole. Collaudato
- [?] G9, punto 2 — SELinux: togliere solo le differenze nei nomi che le lezioni usano, invece di `semanage import` di tutta la fotografia. Con i punti 1 e 3 il danno resta solo dentro le lezioni 10-11, e con una copia. Da decidere se farlo
- [x] 8372bdf b27e9ca M10 — `azzera` si fidava dei suoi file di stato. `kernel-finto` dal diff; `utenti-kit`, `file-kit`, `fstab-kit`, loop e `sysctl.d` dalla proposta. Collaudato

## Lotto 2: falsi positivi delle lezioni 01-04

- [x] 81a003d G2 — 01 1: un filesystem creato sulla partizione passava. Collaudato
- [x] 7ca5968 G3 — 01 4: tre casi del contratto non provati. Prove nuove: la sorgente con un secondo nome (secondo nodo nella gabbia), la destinazione al limite (401 MiB → 4) e appena sopra (402 MiB → 0), montata senza tabella e swap attiva (→ 3). Collaudato: le prime due bocciano le ingenue; le ultime due no, chi controlla le firme le prende già (restano come prove del contratto)
- [x] 943dd2b G4 — 02 2: la copia che perde date, proprietari e permessi passava. Messaggi 89:90, 0640/0600, date vecchie; manifest dei metadati al secondo. Collaudato
- [x] 2c6fe09 G5 — 04 P e 11 P: `swapoff -a` passava. Dal diff (`ricorda_per_la_pulizia`, `SWAP_SISTEMA`). Collaudato nella 04 P e, per la sola riga nuova, nella 11 P
- [x] 2c6fe09 G6 — pulizie: le firme dentro le vecchie partizioni non si vedevano. Dal diff (`INIZI_Dn`, `blkid -p -O`, `wipefs` per la GPT di riserva). Collaudato nelle pulizie 01, 07 e, per la sola riga nuova, 11. Resta un caso vicino, vedi le osservazioni del collaudo del lotto 2

## Lotto 3: falsi positivi 07-11 e residui che falsano le prove

- [x] 941e7a3 G10 — 07 4: `noauto` aggirava «niente nofail». Dal diff: il montaggio dev'essere richiesto da `local-fs.target`. Collaudato, con tre riavvii
- [x] db3f00a G11 — 08 1: chi riavviava la macchina o sshd passava. Dal diff: `BOOT_ID` e PID di sshd salvati alla preparazione. Collaudato
- [x] d1d3608 G12 — 10 3: firewalld acceso ma non abilitato passava. Dal diff, più `sonda_non_parte`, che dice «firewalld è spento» invece di «non riesco a preparare la rete di prova». Collaudato
- [x] 28c11ee G13 — 10 P e 11 P: «sempre enforcing» solo con `getenforce`. Dal diff: `enforcing`, e «anche dopo un riavvio» nei due ticket. Collaudato nella 10 P; la 11 P usa la stessa funzione e non l'ho rifatta
- [x] 9402339 G14 — 09 3: il report lasciato dalla prova del servizio sembrava il ricalcolo. Dal diff: `prova_report` toglie il suo report. Collaudato con l'orologio spostato da prima della preparazione, così il timer settimanale non scatta nel salto. La correzione più robusta della review (cercare nel journal chi ha scritto il report) non l'ho fatta: resta promosso solo chi lancia il servizio a mano fra le 22:30 e le 22:45
- [x] b476cbb G15 — 08 2: il soccorso lasciato in `/etc/default/grub` passava. Proposta della review: le voci si guardano con `chiede_soccorso` (ogni grafia), più una riga su `GRUB_CMDLINE_LINUX` e `GRUB_CMDLINE_LINUX_DEFAULT`. Collaudato, con un avvio vero in soccorso
- [x] 40b8d18 M27 — `azzera` non rimetteva la scheda nella sua zona quando la zona sta nel profilo di NetworkManager. Proposta della review: la fotografia salva la zona di ogni connessione attiva (`zone-nm`, presa anche se la fotografia di firewalld c'è già), `riporta_zone_nm` la rimette con `nmcli`. Collaudato
- [x] cb0927b M28 — 09 3: `azzera` non fermava il timer transitorio con una descrizione propria. Dal diff: `TriggeredBy`. Collaudato
- [?] Residuo nuovo, non nella review: dopo una 07 4 con `x-systemd.automount`, `azzera` toglie la riga ma lascia attivo `srv-dati.automount`, e la `prepara` dopo monta il disco sopra l'autofs. Vedi il collaudo del lotto 3

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

### Collaudo lotto 1 — fatto sul banco, 26/11

**Il banco.** Una VM Rocky 9.9 (immagine GenericCloud LVM 20261112) in QEMU 8.2.2 senza KVM, dentro il container della sessione, fuori dal repo (`/root/banco`). Hardware come la `lab-rocky`: controller AHCI, disco di sistema da 20 GiB e tre dischi dedicati raw da 2048 MiB, tutti «VBOX HARDDISK» con seriali `VB…`; VG di sistema `rocky` con `lvroot` e `swap`, file dei dispositivi di LVM creato con `vgimportdevices -a`, SELinux enforcing, firewalld abilitato e attivo, i pacchetti della riga di L00. Il disco di sistema si chiama `sdd`, i bersagli `sda`-`sdc`. Il kit del ramo è copiato in `/home/remoto/formazione_sou`; quello di b9d4b57, per le controprove, in `/home/remoto/vecchio`. Le soluzioni giuste usate stanno solo in `/root/banco/soluzioni`, fuori dal repo.

| ID | Prova | Kit di prima (b9d4b57) | Kit del ramo |
|---|---|---|---|
| G1 | 01 4, lo script ingenuo con `dd` del «Riprodurre» | — | bocciato 4/23, **rc=1**; `/etc/hostname` identico (`cmp`) |
| G1 | 01 4, una soluzione giusta scritta dal ticket | — | 23/23, **rc=0** |
| G7 | 04 3, `DEVNAME` del PV di sistema riscritto `/dev/sda2` (una partizione di D1), `azzera` | «tolgo dal file dei dispositivi di LVM: /dev/sda2», `lvs` vuoto | rc=0, la voce del sistema resta, `lvs` vede `lvroot` e `swap` |
| G7 | un PV su D2 tolto con `pvremove` (riga con `PVID=.`), `azzera` | — | la riga di D2 va via (col primo diff no: `losetup` fermava la funzione, corretto in ba210ae) |
| G7 | come sopra, ma con il `DEVNAME` della riga di D2 riscritto `/dev/sdd4` (il disco di sistema) | — | la riga di D2 va via per IDNAME (`--deviceidtype`), la voce del sistema resta |
| M9 | `LABEL=backup` e `LABEL=ARCHIVIO2` dell'utente, `prepara 03 3` (D3 `BACKUP`), `azzera` | «tolgo da /etc/fstab: LABEL=backup …» | rc=0, restano tutte e due |
| M23 | `tmpfs /srv/www …` dell'utente, `azzera` e `prepara 03 1` | — | **rc=3** tutte e due, la riga elencata, `lsblk` identico |
| M23 | la stessa riga su `/srv/mio` | — | rc=0, la riga resta |
| M23 | una riga orfana `UUID=0000… /srv/dati`, e la riga del kit della 07 4 | — | tolte tutte e due, rc=0 |
| M10 | `utente 0` e `utente root` in `utenti-kit`, `..` in `file-kit`, l'UUID di `/boot` in `fstab-kit`; a secco, poi davvero | — | «non tocco l'utente 0/root», «non tolgo …/lab-x/../../conf/httpd.conf», nessun `pkill`; root, `httpd.conf` e le righe di `/boot` restano; i tre file di stato si svuotano |
| M10 | 03 4 e poi `azzera`, con `utente 0` aggiunto | — | anna, luca, marco e sviluppo tolti, `0` no |
| M10 | 08 1, `/root/vittima` in `kernel-finto`, `azzera` | — | «non tolgo /root/vittima», il file resta |
| M10 | `D4 loop /root/vittima.img` nell'inventario, `azzera` | — | **rc=3**, «non è un'immagine del kit», nessun loop |
| M10 | `/etc/sysctl.d/99-mio.conf` di soli commenti; `90-swap.conf` con `vm.swappiness = 10` dopo la 04 1 | — | il primo resta, il secondo va via |
| G9 | senza fotografie, la configurazione del «Riprodurre» (porta 8888, `httpd_can_sendmail on`, modulo `mio`, porta 9999 di firewalld, `conf.d/mio.conf`) più un drop-in di crond, poi `prepara 03 4` | (G9) tutto tolto | rc=0, niente toccato, nessuna fotografia |
| G9 | `prepara 10 1` (fotografa web e avvio), durante la lezione porta 7777, la 7778 con `semanage` e `httpd_can_network_connect on`, poi `azzera` | — | la configurazione di prima resta; 7777, 7778 e il booleano tornano indietro; copia in `copie/<data>/` con `etc/firewalld`, `selinux/semanage.export` (con la 7778) e `selinux/booleani` |
| G9 | `prepara 09 1`, un drop-in di crond nuovo, `azzera` | — | tolto il nuovo, con copia; resta quello di prima |
| G9 | `prepara 10 2`, un modulo `mio2` nuovo, `azzera` | — | tolto `mio2`, con `mio2.cil` in copia; resta `mio` |
| G9 | regressione: 10 1 giusta; 08 1 senza fare niente e poi giusta | — | 10 1 17/17 rc=0; 08 1 2/4, poi 4/4 rc=0 |

Note del collaudo: «Creating mailbox file: File exists» alla 03 4 è m10 (lotto 8a). Le prove M10 a secco stampano due volte i messaggi degli utenti: corretto in b27e9ca.

### Collaudo lotto 2 — fatto sul banco, 26/11

Stesso banco del lotto 1. Dopo il riavvio i dischi hanno cambiato nome: il sistema è `sda`, i bersagli `sdb`-`sdd`. Le soluzioni giuste e le varianti ingenue stanno in `/root/banco/soluzioni`, fuori dal repo:
- per la 01 4, una giusta e tre ingenue ricavate da lei: confronta i nomi invece dei dispositivi, non lascia posto alla GPT di riserva, non guarda le swap;
- per le pulizie, una pulizia giusta generica e quattro varianti: `swapoff -a`, `wipefs` sui soli dischi, `dd` sul primo MiB, partizioni e `dd` sul primo MiB;
- per la 02 2, la giusta con `cp -a` e l'ingenua con `cp -r`.

| ID | Prova | Correttore di prima (b9d4b57) | Correttore del ramo |
|---|---|---|---|
| G2 | 01 1 giusta (`sfdisk`) | — | 12/12, rc=0 |
| G2 | la stessa con `mkfs.xfs` sulla partizione | passava (G2) | 11/12, **rc=1**, «e sopra non c'è un filesystem» |
| G3 | 01 4 giusta | — | 29/29, rc=0 |
| G3 | confronta i nomi (`realpath`) invece dei dispositivi | — | 28/29: «la sorgente anche come destinazione, con un altro nome» (ottiene 3) |
| G3 | non lascia posto alla GPT di riserva | — | 28/29: la destinazione da 401 MiB dà 1 invece di 4 |
| G3 | non guarda `/proc/swaps` | — | 29/29: la swap ha una firma, e la giusta la prende già lì |
| G4 | 02 2 giusta, copia con `cp -a` | 6/6 | 7/7, rc=0 |
| G4 | ingenua, copia con `cp -r` | 6/6 | 6/7, **rc=1**, «con i proprietari, i permessi e le date di prima» |
| G5 | 04 P giusta | 19/19 | 24/24, rc=0 |
| G5 | 04 P con `swapoff -a` | 19/19 | 23/24, **rc=1**, «la swap del sistema è ancora accesa» (`/dev/dm-1`) |
| G5 | 11 P con `swapoff -a` (pulizia generica, solo la riga nuova) | — | NO «la swap del sistema è ancora accesa» |
| G6 | 01 P giusta | rc=0 | rc=0 |
| G6 | 01 P: `wipefs` sui soli dischi; `dd` sul primo MiB; partizioni e `dd` sul primo MiB | rc=0 tutte | **rc=1** tutte: «nessuna firma dove stavano le partizioni» e/o «non ha firme che wipefs vede (anche la GPT di riserva)» |
| G6 | 07 P giusta; `wipefs` sui soli dischi | 19/19; 19/19 | 24/24; 23/24, **rc=1** (firme a 1 MiB di D1-D3) |
| G6 | 11 P, `wipefs` sui soli dischi (solo la riga nuova) | — | NO «nessuna firma dove stavano le partizioni» per D2 e D3 |
| — | `prepara 11 pulizia` con `ricorda_per_la_pulizia` | — | rc=0; `SWAP_SISTEMA=/dev/dm-1`, la swap di D3 esclusa |

**Osservazioni.**
- Nella 11 P la variante «solo dischi» toglie il VG e le etichette dei PV prima di cancellare i dischi. All'inizio della partizione di D1 non resta nessuna firma, ma gli XFS dei volumi `vgdati-dati` e `vgdati-web` restano più avanti, dentro la vecchia area del PV, e il correttore non li guarda. È un caso vicino a G6, ma non quello della review: per ora non lo correggo.
- Le prove nuove della 01 4 sulla swap attiva e sul disco montato senza tabella non distinguono da sole una soluzione che controlla le firme: lo dice la riga di G3.

### Collaudo lotto 3 — fatto sul banco, 26/11

Stesso banco dei lotti 1 e 2: il sistema è `sda`, i bersagli `sdb`-`sdd`. Le soluzioni giuste e le varianti ingenue stanno in `/root/banco/soluzioni`, fuori dal repo: la 07 4 nelle tre forme della riga di fstab, la 09 3 con e senza ricalcolo, la 10 3, la «scheda in `trusted`» della 10 1 e la pulizia della 10.
- Per la 09 3 l'orologio della VM è stato messo alle 20:00 prima della preparazione. Così il ricalcolo è quello della sera stessa, e nel salto fino alle 22:3x il timer settimanale non scatta: era il limite del collaudo della review.
- Per la 08 2 il menu di GRUB del banco non esce sulla console seriale. La scelta a mano è fatta con una voce usa e getta e `grub2-reboot`; la voce è tolta dal soccorso, prima del controllo.

| ID | Prova | Correttore di prima (b9d4b57) | Correttore del ramo |
|---|---|---|---|
| G10 | 07 4, UUID corretto dalla console di emergenza, riavvio | 15/15 | 16/16, rc=0 |
| G10 | 07 4, UUID giusto con `noauto`, riavvio, `mount /srv/dati` | 15/15, rc=0 | 15/16, **rc=1**, «e lo monta l'avvio… (local-fs.target lo richiede)» |
| G10 | 07 4, UUID giusto con `x-systemd.automount`, riavvio | 14/15, rc=1, solo «è montato dalla partizione» | 14/16, rc=1, anche la riga nuova |
| G11 | 08 1, `set-default` e `isolate` | 4/4 | 6/6, rc=0 |
| G11 | 08 1, la giusta più `systemctl restart sshd` | 4/4, rc=0 | 5/6, **rc=1**, «e senza riavviare sshd» |
| G11 | 08 1, `set-default` e riavvio | 4/4, rc=0 | 4/6, **rc=1**, «senza riavviare la macchina» e «sshd» |
| G14 | 09 3 senza ricalcolo, prima delle 22:30 | 18/19, rc=1 | 18/19, rc=1 |
| G14 | la stessa alle 22:32 | 19/19, rc=0 (col report della sua prova) | 18/19, **rc=1**, «il ricalcolo… è stato fatto» |
| G14 | 09 3 giusta con `--description` propria: prima delle 22:30; alle 22:31, scattata | 20/20; 19/19 | 20/20; 19/19, rc=0 |
| M28 | `prepara 09 3` dopo la giusta con `--description` | il timer resta; poi il solo timer settimanale prende 20/20 | «fermo ricalcolo-direzione.timer…», nessun timer, niente del report in `/run/systemd/transient`; lo stesso `systemd-run` riparte senza «already loaded» |
| M27 | 10 1 con la scheda in `trusted` (adesso e permanente), `prepara 10 3`, 10 3 giusta | zona `trusted` anche nel profilo; 17/18, «da un'altra rete la console non si raggiunge» | «la connessione di eth0 torna nella zona «predefinita»», `public`, profilo vuoto; 19/19, rc=0 |
| G12 | 10 3 giusta | 18/18 | 19/19, rc=0 |
| G12 | la stessa con firewalld disabilitato | 18/18, rc=0 | 18/19, **rc=1**, «e parte all'avvio» |
| G12 | la stessa con firewalld fermo | — | «firewalld è spento: la prova da fuori non si può fare» |
| G13 | 10 P giusta | 28/28 | 35/35, rc=0 |
| G13 | la stessa con `SELINUX=permissive` nel file | 28/28, rc=0 | 34/35, **rc=1**, «e lo sarà dopo il riavvio» |
| G15 | 08 2 giusta: avvio in soccorso, `umount` ed `e2fsck -f -y`, riavvio | 15/15 | 16/16, rc=0 |
| G15 | la stessa con `systemd.unit=rescue.target` in `GRUB_CMDLINE_LINUX_DEFAULT` | 15/15, rc=0 | 15/16, **rc=1**, «né /etc/default/grub» |
| G15 | la stessa con `single` in tutte le voci (`grubby --update-kernel=ALL`) | 14/15, solo «nemmeno i kernel futuri» | 14/16, anche «nessuna voce del menu avvia in soccorso» |

**Osservazioni.**
- Il primo tentativo della 07 4 giusta è finito in emergenza per un errore del mio script: `findmnt /srv/dati` vedeva due righe, l'autofs rimasto dalla prova prima e la partizione. Da qui viene il residuo del `[?]`:
  - dopo una 07 4 con `x-systemd.automount`, `azzera` toglie la riga di fstab e fa `daemon-reload`;
  - ma `srv-dati.automount` resta attivo e l'autofs resta montato su `/srv/dati`, e la `prepara` dopo monta la partizione sopra;
  - l'ho riprodotto senza riavvio (`systemctl start srv-dati.automount`, poi `prepara 07 4`); sparisce al primo riavvio.
- La 11 P non l'ho rifatta per G13: la riga nuova è la stessa funzione `enforcing` della 10 P, e la mia pulizia generica non sistema servizi, firewall e SELinux della 11.
