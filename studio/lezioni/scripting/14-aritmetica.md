---
tags:
  - lezione
  - scripting
aliases:
  - Scripting 14 — Aritmetica
---
# Scripting 14 — Aritmetica

La shell sa fare i conti, ma solo con gli interi, e legge i numeri con regole che vengono dal linguaggio C: uno zero davanti significa ottale, una divisione tronca, un risultato a 0 è un «falso». Qui si impara a contare senza sorprese e a lavorare sui bit, come serve per reti e permessi. Si fa dopo la lezione 02.

```sh
./prepara.sh 14 && cd palestra/l14
```

## La mappa

| # | Problema | Stato |
|---|---|---|
| 0 | Previsioni — carta e penna, poi la prova | — |
| 1 | `ip-calc.sh` — rete, broadcast e host di una sottorete | — |
| 2 | `umana.sh` — byte che si leggono | — |
| 3 | `durata.sh` — secondi e orologi | — |

---

## Problema 0 — Previsioni

**Situazione.** I conti sbagliati in uno script non danno errore: danno un numero, e il numero sembra giusto.

> [!info] Il contesto
> **Lo scenario.** Gli script da sistemista contano spesso: percentuali di disco, byte, secondi, indirizzi di rete. I risultati finiscono in un allarme o in una decisione automatica.
> - **Intero**: un numero senza virgola. È l'unico tipo di numero che la shell conosce.
>
> **Perché conta.** Un conto sbagliato non si annuncia: dà un numero plausibile, l'allarme non scatta e nessuno se ne accorge finché il disco non è pieno.

**Compito.** Per ogni riga scrivi **prima** cosa stampa e perché, poi lanciala.

```sh
echo $((7 / 2)) $((-7 / 2)) $((7 % 3)) $((-7 % 3))
echo $((2 ** 10)) $((2 ** 62)) $((2 ** 63)) $((2 ** 64))
echo $((010)) $((0x10)) $((2#1010)) $((16#ff))
echo $((08))
echo $((10#08))
echo $((1 << 4)) $((6 & 3)) $((6 | 3)) $((6 ^ 3)) $((~0))
x=5; ((x++)); echo $x; ((x += 10)); echo $x
x=3; y=x; echo $((y + 1))
a=1.5; echo $((a + 1))
(( 0 )); echo $?
(( 5 > 3 )) && echo si
i=0; ((i++)); echo $?
let 'z = 4 * 2'; echo $z
echo $((RANDOM % 6 + 1))
[ 010 -eq 10 ] && echo uguali
[[ 010 -eq 10 ]] && echo uguali
```

**Verifica.** Si controlla a mano, con Claude.

**Dopo.** Perché la riga con `i++` è un pericolo per uno script con `set -e`? Che differenza c'è fra `$(( ))`, `(( ))` e `let`? Perché `[ ]` e `[[ ]]` leggono `010` in modo diverso? Come fai un conto con i decimali, visto che la shell non sa? Prova `awk` e `bc`.

---

## Problema 1 — `ip-calc.sh`

**Situazione.** Ti assegnano la sottorete `192.168.10.37/22` per un nuovo laboratorio. Prima di configurare DHCP e firewall vuoi sapere dove inizia, dove finisce e quante macchine ci stanno, senza calcolatrici online.

> [!info] Il contesto
> **Lo scenario.** Il responsabile della rete ti assegna un blocco di indirizzi per un laboratorio nuovo. Tu devi configurare il servizio che distribuisce gli indirizzi alle macchine e le regole che decidono chi può parlare con chi.
> - **Sottorete**: un gruppo di indirizzi consecutivi che stanno sulla stessa rete. `/22` è il **prefisso**, in notazione CIDR (*Classless Inter-Domain Routing*, 1993): quanti bit, da sinistra, sono uguali per tutti gli indirizzi del gruppo.
> - **Rete** e **broadcast** (inglese, «trasmissione a tutti»): il primo e l'ultimo indirizzo del gruppo, riservati; il secondo raggiunge tutte le macchine insieme. **Host** (inglese, «chi ospita»): ciascuna macchina che riceve un indirizzo.
> - **DHCP** (*Dynamic Host Configuration Protocol*): il servizio che assegna gli indirizzi. **Firewall** (inglese, «muro tagliafuoco», come quello fra due edifici): il filtro sul traffico.
>
> **Perché conta.** Un confine sbagliato fa sovrapporre due reti, o lascia fuori metà delle macchine. I sintomi sono strani, e difficili da ricondurre a un conto.

**Compito.** `./ip-calc.sh INDIRIZZO/PREFISSO` stampa:

```text
indirizzo: 192.168.10.37
rete: 192.168.8.0
broadcast: 192.168.11.255
maschera: 255.255.252.0
host: 1022
```

- `host` è il numero di indirizzi assegnabili: di norma il totale meno rete e broadcast. Con `/31` sono 2 (è un collegamento punto a punto) e con `/32` è 1.
- Il prefisso va da 0 a 32. Ogni ottetto va da 0 a 255 ed è scritto senza zeri davanti (`010` è un errore).
- Qualsiasi errore di formato, o un numero di argomenti sbagliato: codice 2.
- Solo aritmetica e comandi interni della shell, senza `ipcalc` né altri programmi: il correttore lo lancia senza `PATH`.

**Verifica.** `../../verifica.sh 14 1`

> [!question]- Indizio 1
> Scrivi su carta `192.168.10.37` in binario, ottetto per ottetto, e sotto 22 uni seguiti da zeri. Cosa ottieni mettendo in AND le due righe?

> [!question]- Indizio 2
> Un indirizzo IPv4 è un solo numero di 32 bit. Come lo costruisci dai quattro ottetti con gli spostamenti `<<`? E come lo riporti a ottetti?

> [!question]- Indizio 3
> La maschera è fatta di 1 seguiti da 0. Come la ottieni da un numero di soli 1, spostando? Cosa succede ai bit che escono oltre i 32, in una shell a 64 bit?

> [!question]- Indizio 4
> Quanto vale `$((010))`? Il tuo controllo sugli ottetti lo vede?

**Dopo.** Il broadcast è rete OR il complemento della maschera: perché? Perché `/31` è un caso speciale (RFC 3021)? Confronta il tuo risultato con `ipcalc` (pacchetto `ipcalc` su Rocky) e con `ip route` sulla VM: qual è la rete della tua scheda NAT?

---

## Problema 2 — `umana.sh`

**Situazione.** `du -b` ti dà numeri come `5368709120`. In un avviso via mail vuoi scrivere `5.0 GiB`, e lo strumento che ti serve, `numfmt`, sul server vecchio non c'è.

> [!info] Il contesto
> **Lo scenario.** Uno script controlla lo spazio delle cartelle e, quando qualcosa cresce troppo, manda un avviso. Chi lo legge vuole capire a colpo d'occhio, ma lo strumento che misura lo spazio parla in byte. E sui server vecchi, che restano in servizio per anni, mancano i programmi più recenti.
> - **Byte** (dall'inglese *bite*, «morso», scritto con la *y* per non confonderlo con *bit*): otto bit, l'unità della memoria.
> - **KiB, MiB, GiB** (*kibi*, *mebi*, *gibi*, cioè kilo, mega e giga «binari»): multipli da 1024, fissati dalla IEC, l'ente internazionale per l'elettrotecnica, nel 1998.
>
> **Perché conta.** `5368709120` si legge male e si sbaglia di uno zero. Un avviso letto male porta a trascurare un problema vero.

**Compito.** `./umana.sh BYTE` stampa il valore in unità binarie (1 KiB = 1024 B) con un decimale, arrotondato con il mezzo per eccesso.

| Ingresso | Uscita |
|---|---|
| `0` | `0 B` |
| `1023` | `1023 B` |
| `1024` | `1.0 KiB` |
| `1100` | `1.1 KiB` |
| `1075` | `1.0 KiB` |
| `1536` | `1.5 KiB` |
| `1048575` | `1.0 MiB` |
| `5368709120` | `5.0 GiB` |

- Sotto 1024 si stampano i byte, senza decimali.
- Si sceglie l'unità più piccola in cui il valore **arrotondato** è minore di 1024. Le unità sono `KiB`, `MiB`, `GiB`, `TiB`; oltre si resta in `TiB`.
- Ingresso non intero o negativo, o numero di argomenti sbagliato: codice 2.
- Solo comandi interni della shell: il correttore lo lancia senza `PATH`.

**Verifica.** `../../verifica.sh 14 2`

> [!question]- Indizio 1
> Se la shell non ha decimali, come rappresenti 1.07 con un intero? Pensa a come si lavora con i centesimi invece che con gli euro.

> [!question]- Indizio 2
> Dividere tronca. Come ottieni un arrotondamento con una divisione intera, aggiungendo qualcosa prima di dividere?

> [!question]- Indizio 3
> Prova `1048575`. Il valore in KiB è 1023.999: cosa stampi? La regola sull'unità guarda il valore prima o dopo l'arrotondamento?

**Dopo.** Che differenza c'è fra `KiB` e `KB`, e quale usa `df -h`? E `df -H`? Fino a quanti byte regge la tua aritmetica prima di traboccare?

---

## Problema 3 — `durata.sh`

**Situazione.** I log dei lavori notturni riportano la durata in secondi. Nei rapporti la vuoi leggibile, e a volte devi fare il conto inverso per impostare un tempo massimo.

> [!info] Il contesto
> **Lo scenario.** Di notte girano i lavori pesanti: backup, rapporti, copie fra sistemi. Il mattino dopo si leggono i log per capire quanto sono durati, e se uno ci mette ogni giorno di più.
> - **Lavoro notturno**, in inglese **batch** («infornata», come il pane cotto tutto insieme): un'elaborazione lanciata in automatico, senza nessuno davanti.
> - **Tempo massimo**, in inglese **timeout**: la durata oltre la quale un lavoro si considera bloccato e si ferma.
>
> **Perché conta.** `93784` secondi non dicono nulla a chi legge un rapporto. E un tempo massimo calcolato male uccide un lavoro sano, o ne lascia girare uno bloccato fino al mattino.

**Compito.** `./durata.sh` converte nei due sensi:

| Chiamata | Uscita |
|---|---|
| `./durata.sh 59` | `00:00:59` |
| `./durata.sh 93784` | `1g 02:03:04` |
| `./durata.sh 02:03:04` | `7384` |
| `./durata.sh 1g 02:03:04` | `93784` |
| `./durata.sh 08:09:00` | `29340` |

- Sotto un giorno non si scrive `0g`.
- Nell'ingresso con i due punti ore da 00 a 23, minuti e secondi da 00 a 59, sempre due cifre.
- Qualsiasi altro ingresso, o un numero di argomenti sbagliato: codice 2.

**Verifica.** `../../verifica.sh 14 3`

> [!question]- Indizio 1
> Quali due operazioni intere ti danno, da un totale di secondi, i minuti interi e i secondi che avanzano?

> [!question]- Indizio 2
> Come spezzi `02:03:04` in tre pezzi senza comandi esterni? Hai già visto `IFS` e `read`, e anche la *Parameter Expansion*.

> [!question]- Indizio 3
> `08:09:00` ti dà un errore? Rileggi la riga 5 del problema 0.

**Dopo.** Cosa fa `date -u -d @93784 +%T`, e perché non basta per durate oltre le 24 ore? Come misureresti la durata di un comando in uno script? Cerca la variabile `SECONDS` in `man bash`, e confrontala con `EPOCHREALTIME`.

---

## Diario

Domande numerate, risposte e correzioni di questa lezione.

## Sintesi

Da scrivere a lezione finita, con le tue parole.

---

← [[02-decisioni|Lezione 02]] · ↑ [[00-percorso|Il percorso]] · → [[03-cicli-e-nomi|Lezione 03]]
