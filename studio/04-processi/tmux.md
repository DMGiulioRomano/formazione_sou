---
tags:
  - processi
  - nota
aliases:
  - tmux
---
# tmux

`tmux` è uno strumento che permette di gestire più terminali virtuali all'interno di un'unica finestra. Il suo nome sta per **Terminal Multiplexer**. È particolarmente apprezzato da sistemisti e sviluppatori perché mantiene vive le sessioni di lavoro anche in caso di disconnessione dalla rete, e permette di organizzare il lavoro in modo molto più efficiente rispetto all'apertura di molteplici finestre del terminale.

---

## Perché usare `tmux`?

Immagina di dover lavorare su un server remoto via SSH. Se la connessione cade, il terminale si chiude e **tutti i processi in esecuzione vengono terminati**. `tmux` risolve questo problema e offre diversi altri vantaggi:

- **Persistenza della sessione**: I processi continuano a girare anche dopo che ti sei disconnesso (volontariamente o per un problema di rete). Puoi riconnetterti e ritrovare tutto esattamente come lo avevi lasciato.
- **Finestre multiple**: Puoi avere più shell (finestre) all'interno della stessa sessione, come le schede di un browser.
- **Pannelli (split)**: Puoi dividere una singola finestra in più riquadri per vedere e interagire con più terminali contemporaneamente (es. un editor, un comando in esecuzione e i log).
- **Condivisione della sessione**: Più utenti possono collegarsi alla stessa sessione per collaborare, fare pair programming o formare qualcuno.
- **Buffer di scorrimento (scrollback)**: Puoi rivedere la cronologia dell'output dei comandi.

---

## I tre concetti fondamentali: Sessioni, Finestre e Pannelli

Per usare `tmux` correttamente, devi comprendere la sua gerarchia, che si articola su tre livelli:

1.  **Sessione (Session)**: È il livello più alto. Una sessione è un ambiente di lavoro completo e indipendente. Può essere **agganciata (attached)** a un terminale o **staccata (detached)** e continuare a girare in background. Ogni sessione ha un nome (es. `lavoro`, `produzione`).
2.  **Finestra (Window)**: All'interno di una sessione, puoi avere una o più finestre. Sono l'equivalente delle **schede di un browser**. Ogni finestra occupa l'intero schermo e contiene una o più shell.
3.  **Pannello (Pane)**: All'interno di una finestra, puoi suddividere l'area in più **pannelli** (split). Ogni pannello è un terminale a sé stante. Questo ti permette, ad esempio, di avere un editor in un pannello e il comando `htop` in un altro, il tutto visibile contemporaneamente.

> **Analogia**: Una **Sessione** è un progetto. Le **Finestre** sono i vari aspetti del progetto (es. "codice", "test", "deploy"). I **Pannelli** sono gli strumenti specifici che usi contemporaneamente per un singolo aspetto (es. editor + terminale per i test).

---

## Il sistema di comandi: il tasto "Prefisso"

`tmux` non usa il mouse per impostazione predefinita (anche se può essere abilitato). I suoi comandi si impartiscono tramite **scorciatoie da tastiera** che seguono un sistema a due passaggi:

1.  Premi il **tasto prefisso**. Il valore predefinito è **`Ctrl + b`**.
2.  Rilascia `Ctrl + b` e premi il **tasto di comando**.

Ad esempio, per creare una nuova finestra, la sequenza è `Ctrl + b`, poi `c`. Questa modalità a due passaggi evita che i comandi di `tmux` entrino in conflitto con quelli dei programmi che stai usando all'interno dei pannelli.

---

## Comandi essenziali: una guida rapida

Ecco i comandi più importanti, organizzati per livello di gestione.

### 📂 Gestione delle Sessioni (dal terminale, fuori da `tmux`)

Questi comandi si eseguono dalla shell normale, prima di entrare in `tmux` o mentre si è staccati.

| Comando | Significato |
| :--- | :--- |
| `tmux new -s <nome>` | Crea una nuova sessione con un nome specifico. **Consigliatissimo** per riconoscerla facilmente. |
| `tmux ls` (o `tmux list-sessions`) | Elenca tutte le sessioni esistenti. |
| `tmux attach -t <nome>` (o `tmux a -t <nome>`) | Aggancia (riprende) una sessione specifica per nome. |
| `tmux attach` (o `tmux a`) | Aggancia l'ultima sessione creata. |
| `tmux kill-session -t <nome>` | Termina una sessione specifica. |

### ⌨️ Scorciatoie da tastiera (dentro `tmux`)

Queste sequenze richiedono sempre di premere prima `Ctrl + b` (prefisso).

#### Gestione Sessioni
| Scorciatoia (`Ctrl+b` + ...) | Significato |
| :--- | :--- |
| `d` | **Detach**: Stacca la sessione corrente. I processi continuano a girare in background. |
| `$` | Rinomina la sessione corrente. |
| `s` | Mostra un elenco interattivo delle sessioni per sceglierne una. |

#### Gestione Finestre
| Scorciatoia (`Ctrl+b` + ...) | Significato |
| :--- | :--- |
| `c` | **Crea** una nuova finestra. |
| `n` / `p` | Passa alla finestra **successiva** (next) o **precedente** (previous). |
| `0` ... `9` | Passa direttamente alla finestra con quel numero. |
| `,` | Rinomina la finestra corrente. |
| `w` | Mostra un elenco interattivo delle finestre. |
| `&` | Chiude la finestra corrente (con conferma). |

#### Gestione Pannelli (Split)
| Scorciatoia (`Ctrl+b` + ...) | Significato |
| :--- | :--- |
| `%` | Divide il pannello **verticalmente** (affiancati). |
| `"` | Divide il pannello **orizzontalmente** (sopra/sotto). |
| `Freccia (Su/Giù/Sinistra/Destra)` | Sposta il focus sul pannello nella direzione indicata. |
| `o` | Passa al pannello successivo in ordine ciclico. |
| `z` | **Zoom**: Ingrandisce il pannello corrente a tutto schermo (e viceversa). |
| `x` | Chiude il pannello corrente (con conferma). |
| `Spazio` | Cambia la disposizione dei pannelli (layout). |
| `Ctrl + Freccia` | Ridimensiona il pannello nella direzione indicata. |

---

## Personalizzazione: `~/.tmux.conf`

Le potenzialità di `tmux` si esprimono al meglio personalizzando il file di configurazione `~/.tmux.conf`. Ecco alcune impostazioni utili.

### 1. Abilitare il mouse
Di default `tmux` è pensato per il solo uso da tastiera. Abilitare il mouse permette di selezionare i pannelli, ridimensionarli e usare la rotella per lo scroll in modo molto più naturale.

```tmux
# Abilita il supporto del mouse
set -g mouse on
```

### 2. Cambiare il tasto prefisso
Se `Ctrl+b` ti risulta scomodo, puoi cambiarlo. Molti utenti preferiscono `Ctrl+a` (storico prefisso di `screen`).

```tmux
# Imposta Ctrl+a come tasto prefisso
unbind C-b
set -g prefix C-a
bind C-a send-prefix
```

### 3. Ricaricare la configurazione
Dopo aver modificato `~/.tmux.conf`, puoi applicare le modifiche senza riavviare `tmux`:

- Da dentro `tmux`: `Ctrl+b`, poi `:`, e digita `source-file ~/.tmux.conf`.
- Da fuori: `tmux source-file ~/.tmux.conf`.

### 4. Plugin: Tmux Plugin Manager (TPM)
L'ecosistema di plugin è vivace. Lo strumento standard per gestirli è **TPM**. Una volta installato, puoi aggiungere plugin al tuo `.tmux.conf` e installarli con una scorciatoia.

---

## Casi d'uso pratici per un sistemista

La teoria prende senso solo nella pratica. Ecco scenari in cui `tmux` è indispensabile.

### Scenario 1: Aggiornamento critico su server remoto via SSH
Devi aggiornare un pacchetto su un server di produzione. L'operazione richiede 20 minuti e la tua connessione domestica non è stabile.

- **Senza `tmux`**: Se la connessione cade a metà, il processo di aggiornamento potrebbe interrompersi, lasciando il sistema in uno stato inconsistente.
- **Con `tmux`**:
    1.  Ti connetti via SSH e lanci `tmux new -s aggiornamento`.
    2.  Avvii l'aggiornamento.
    3.  Se la connessione cade, il processo continua a girare nella sessione `aggiornamento` sul server.
    4.  Ti riconnetti, lanci `tmux attach -t aggiornamento` e controlli lo stato del lavoro come se non fosse successo nulla.

### Scenario 2: Monitoraggio e debug su un server web
Devi indagare su un problema di prestazioni. Vuoi vedere contemporaneamente i log di `nginx` e l'utilizzo delle risorse.

- **Senza `tmux`**: Apri due terminali separati, oppure esegui i comandi uno dopo l'altro.
- **Con `tmux`**:
    1.  Crea una sessione: `tmux new -s debug`.
    2.  Dividi il pannello orizzontalmente (`Ctrl+b "`).
    3.  In un pannello esegui `tail -f /var/log/nginx/error.log`.
    4.  Nell'altro pannello esegui `htop` o `top`.
    5.  Ora hai una vista completa e in tempo reale del problema in un'unica schermata.

### Scenario 3: Sessione di pair programming
Un collega deve aiutarti a risolvere un problema sul server.

- **Senza `tmux`**: Condividi lo schermo con uno strumento esterno, con possibili problemi di latenza o permessi.
- **Con `tmux`**:
    1.  Crea una sessione condivisibile: `tmux new -s aiuto`.
    2.  Il collega si connette via SSH allo stesso server.
    3.  Esegue `tmux attach -t aiuto`.
    4.  Entrambi vedete e controllate la stessa sessione in tempo reale, potendo lavorare insieme sullo stesso terminale.

---

## Mappa riassuntiva

```
CONCETTI
├─ Sessione: ambiente di lavoro persistente (può essere detached)
│  └─ Finestra: come una scheda del browser, contiene pannelli
│     └─ Pannello: terminale individuale (split)
│
COMANDI CHIAVE
├─ Fuori da tmux: new -s, ls, attach -t, kill-session
├─ Prefisso (Ctrl+b) + d: Detach (lascia tutto in esecuzione)
├─ Prefisso + c / n / p / 0-9: Gestione finestre
├─ Prefisso + % / " / frecce: Creazione e navigazione pannelli
└─ Prefisso + z: Zoom pannello
│
PERSONALIZZAZIONE (~/.tmux.conf)
├─ set -g mouse on (abilita mouse)
├─ Cambio prefisso (es. Ctrl+a)
└─ TPM per i plugin
│
CASI D'USO
├─ Lavoro remoto persistente (SSH instabile)
├─ Monitoraggio multi-pannello (log + risorse)
└─ Collaborazione e session sharing
```

In sintesi, `tmux` è uno strumento che cambia il modo di lavorare al terminale: da una singola finestra effimera a un **ambiente di lavoro persistente, organizzato e condivisibile**. La curva di apprendimento iniziale è ripagata ampiamente dalla produttività e dalla tranquillità che offre, soprattutto in ambito sistemistico.

---

**Area:** [[mappa-processi|Processi]]  
**Vedi anche:** [[gestione-processi|Gestione dei processi]] · [[tipi-di-shell|Tipi di shell e su]]
