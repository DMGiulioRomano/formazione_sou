#set terms(hanging-indent: 1.5em)

#set table(
  inset: 6pt,
  stroke: none
)

#let horizontalrule = line(start: (25%,0%), end: (75%,0%))
// Polyfill divider to allow compiling with typst < 0.15:
#let divider = if "divider" in std { divider } else { horizontalRule }

#show figure.where(
  kind: table
): set figure.caption(position: top)

#show figure.where(
  kind: image
): set figure.caption(position: bottom)

#let content-to-string(content) = {
  if content.has("text") {
    content.text
  } else if content.has("children") {
    content.children.map(content-to-string).join("")
  } else if content.has("body") {
    content-to-string(content.body)
  } else if content == [ ] {
    " "
  }
}
#let conf(
  title: none,
  subtitle: none,
  authors: (),
  keywords: (),
  date: none,
  abstract-title: none,
  abstract: none,
  thanks: none,
  cols: 1,
  margin: (x: 1.25in, y: 1.25in),
  paper: "us-letter",
  lang: "en",
  region: "US",
  font: none,
  fontsize: 11pt,
  mathfont: none,
  codefont: none,
  linestretch: 1,
  sectionnumbering: none,
  linkcolor: none,
  citecolor: none,
  filecolor: none,
  pagenumbering: "1",
  doc,
) = {
  set document(
    title: title,
    keywords: keywords,
  )
  set document(
      author: authors.map(author => content-to-string(author.name)).join(", ", last: " & "),
  ) if authors != none and authors != ()
  set page(
    paper: paper,
    margin: margin,
    numbering: pagenumbering,
    columns: cols
  )

  set par(
    justify: true,
    leading: linestretch * 0.65em
  )
  set text(lang: lang,
           region: region,
           size: fontsize)

  set text(font: font) if font != none
  show math.equation: set text(font: mathfont) if mathfont != none
  show raw: set text(font: codefont) if codefont != none

  set heading(numbering: sectionnumbering)

  show link: set text(fill: rgb(content-to-string(linkcolor))) if linkcolor != none
  show ref: set text(fill: rgb(content-to-string(citecolor))) if citecolor != none
  show link: this => {
    if filecolor != none and type(this.dest) == label {
      text(this, fill: rgb(content-to-string(filecolor)))
    } else {
      text(this)
    }
  }

  if title != none {
    place(top, float: true, scope: "parent", clearance: 4mm, block(below: 1em, width: 100%)[
      #if title != none {
        align(center, block[
            #text(weight: "bold", size: 1.5em, hyphenate: false)[#title #if thanks != none {
                footnote(thanks, numbering: "*")
                counter(footnote).update(n => n - 1)
              }]
            #(
              if subtitle != none {
                parbreak()
                text(weight: "bold", size: 1.25em, hyphenate: false)[#subtitle]
              }
             )])
      }

      #if authors != none and authors != [] {
        let count = authors.len()
        let ncols = calc.min(count, 3)
        grid(
          columns: (1fr,) * ncols,
          row-gutter: 1.5em,
          ..authors.map(author => align(center)[
            #author.name \
            #author.affiliation \
            #author.email
          ])
        )
      }

      #if date != none {
        align(center)[#block(inset: 1em)[
            #date
          ]]
      }

      #if abstract != none {
        block(inset: 2em)[
          #text(weight: "semibold")[#abstract-title] #h(1em) #abstract
        ]
      }
    ])
  }
  doc
}
#show table: set table(stroke: 0.5pt + black)


#show: doc => conf(
  abstract-title: [Abstract],
  margin: (: ,),
  paper: "a4",
  fontsize: 12pt,
  pagenumbering: "1",
  cols: 1,
  doc,
)


= SHELL - variabili
<shell---variabili>
Avere e utilizzare più shell sul computer serve a personalizzare
l'ambiente di lavoro, migliorare la produttività con funzionalità
avanzate e garantire la compatibilità con script e server diversi.

Per cambiare la tua shell predefinita in Zsh, ad esempio, useresti il
comando:

```bash
chsh -s /bin/zsh
```

\(Il sistema ti chiederà la password del computer per confermare il
cambio).

== 1. Shell di Login vs Non di Login
<shell-di-login-vs-non-di-login>
- #strong[Shell di Login]: viene avviata quando accedi al sistema per la
  prima volta. Ad esempio, quando ti colleghi a un server remoto tramite
  SSH o quando accedi in modalità testuale (TTY) premendo `Ctrl+Alt+F3`
  su Linux.
- Le altre sono #strong[shell non di login].

== 2. Shell Interattiva vs Non Interattiva
<shell-interattiva-vs-non-interattiva>
- #strong[Shell Interattiva]: è il terminale con cui interagisci
  direttamente. Mostra un prompt (es. `user@computer:~$`), attende che
  tu digiti un comando, lo esegue e ti mostra il risultato. Gestisce la
  cronologia dei comandi e ti permette di usare le frecce direzionali.
- #strong[Shell Non Interattiva]: viene avviata dal sistema per eseguire
  uno script automatizzato (un file `.sh`). Non mostra alcun prompt, non
  accetta input dalla tastiera in tempo reale e si chiude
  automaticamente non appena lo script ha finito di girare.

== Differenza tra shell di login iniziale e shell aperta con `su`
<differenza-tra-shell-di-login-iniziale-e-shell-aperta-con-su>
La differenza principale tra una shell di login iniziale (quella che si
avvia quando accedi al computer o al server) e una shell aperta tramite
il comando `su` sta tutta nel modo in cui l'ambiente viene ereditato e
configurato.

Anche se in entrambi i casi puoi ritrovarti a usare l'utente root, il
punto di partenza e il passaggio dei dati cambiano radicalmente.

=== 1. La shell di login iniziale (es. accesso SSH o TTY)
<la-shell-di-login-iniziale-es.-accesso-ssh-o-tty>
Quando ti colleghi a un server via SSH o inserisci la password nella
modalità testuale di Linux, il sistema avvia una shell di login da zero.

- #strong[Ambiente pulito]: non c'è alcuna sessione precedente. Il
  sistema operativo crea un ambiente completamente nuovo, azzerando
  qualsiasi variabile precedente.
- #strong[Caricamento file]: legge i file globali (`/etc/profile`) e poi
  i file specifici dell'utente (`~/.bash_profile`, `~/.bash_login`, o
  `~/.profile`).
- #strong[Chi sei?] Sei l'utente che ha effettuato l'accesso fin dal
  primo istante.

=== 2. La shell in cui usi il comando `su`
<la-shell-in-cui-usi-il-comando-su>
Quando usi `su` (o `su -`), ti trovi già all'interno di una shell attiva
(es. come utente normale) e decidi di aprirne una nuova sopra di essa
per cambiare identità. Qui il comportamento si sdoppia a seconda di come
usi il comando:

==== Scenario A: comando semplice (`su root`)
<scenario-a-comando-semplice-su-root>
Questa viene definita una #strong[shell interattiva NON di login].

- #strong[Eredità totale]: la nuova shell di root eredita tutto
  l'ambiente dell'utente normale da cui sei partito. Rimarrai nella
  stessa cartella in cui ti trovavi e manterrai le variabili d'ambiente
  dell'utente precedente.
- #strong[File letti]: NON legge i file di profilo globali o di login di
  root. Legge solo il file `~/.bashrc` (o `~/.zshrc`) di root.
- #strong[Problema tipico]: poiché erediti il `PATH` (la lista delle
  cartelle in cui il sistema cerca i comandi) dell'utente normale, se
  provi a digitare comandi amministrativi come `reboot` o `fdisk`, il
  terminale ti risponderà "comando non trovato", perché non sta
  guardando nelle cartelle di sistema come `/usr/sbin`.

==== Scenario B: comando con il trattino (`su -` o `su - root`)
<scenario-b-comando-con-il-trattino-su---o-su---root>
Questo comando forza il sistema ad avviare una #strong[shell di login a
tutti gli effetti] dentro la sessione corrente.

- #strong[Simulazione di un login reale]: anche se sei già dentro il
  terminale, l'ambiente precedente dell'utente normale viene quasi
  interamente cancellato e sostituito con quello di root.
- #strong[File letti]: si comporta esattamente come la shell di login
  iniziale. Legge `/etc/profile` e il file `~/.bash_profile` (o
  `~/.zprofile`) di root.
- #strong[Risultato]: ti sposta automaticamente nella cartella Home di
  root (`/root`) e imposta il `PATH` corretto con tutti i comandi
  amministrativi pronti all'uso.

=== Confronto diretto
<confronto-diretto>
#figure(
  align(center)[#table(
    columns: (25%, 25%, 25%, 25%),
    align: (auto,auto,auto,auto,),
    table.header([Caratteristica], [Shell di Login Iniziale], [Shell con
      `su` (Semplice)], [Shell con `su -` (Consigliata)],),
    table.hline(),
    [Tipo di shell], [Di login], [Non di login], [Di login],
    [Cartella di partenza], [Home dell'utente], [Resta dove eri
    prima], [Home dell'utente d'arrivo (`/root`)],
    [Variabili d'ambiente (`PATH`, ecc.)], [Pulite e native
    dell'utente], [Ereditate dall'utente precedente], [Pulite e native
    dell'utente d'arrivo],
    [File di configurazione letti], [`~/.bash_profile` o
    `~/.profile`], [`~/.bashrc` o `~/.zshrc`], [`~/.bash_profile` o
    `~/.profile`],
  )]
  , kind: table
  )

Per vedere questa differenza con i tuoi occhi sul tuo sistema, ti va se
ti mostro due comandi per verificare come cambia il `PATH` quando passi
da `su` a `su -`? Oppure preferisci approfondire cosa succede quando usi
`sudo -i` rispetto a `su`?

== Variabili
<variabili>
```bash
pino=1
export pino
```

Quando le definisco normalmente sono locali. Ho bisogno di `export` per
renderle globali.

Oppure la creo direttamente come globale:

```bash
export varGlob=1
```

Come le eliminiamo le variabili? Uso `unset`.

Ovviamente anche se globali sono valide nella sessione corrente: quando
chiudo il terminale si eliminano.

== Opzioni della shell
<opzioni-della-shell>
Ma io posso attivare delle opzioni della shell con `set`.

La logica dei simboli meno (`-`) e più (`+`) può sembrare al contrario a
prima vista, ma funziona così:

- `set -o nome_opzione`: #strong[ATTIVA] (accende) l'opzione.
- `set +o nome_opzione`: #strong[DISATTIVA] (spegne) l'opzione.

=== Shell options
<shell-options>
Ho anche `shopt` (abbreviazione di #emph[shell options]): è un comando
integrato della shell Bash che serve ad attivare, disattivare e mostrare
le opzioni avanzate della shell.

A differenza del comando `set` (usato per le opzioni standard POSIX),
`shopt` gestisce funzionalità specifiche di Bash che modificano il
comportamento dei comandi, del completamento automatico e della gestione
dei file.

#quote(block: true)[
#strong[Nota:] non è uno standard POSIX, quindi non è presente in tutte
le shell Unix. Solo in Bash.
]

#divider()
