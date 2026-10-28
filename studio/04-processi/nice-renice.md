---
tags:
  - processi
  - nota
aliases:
  - nice e renice
---
# nice e renice

I comandi `nice` e `renice` servono a gestire la **priorità di scheduling** dei processi, cioè quanto tempo di CPU il sistema operativo concede loro rispetto agli altri. Sono strumenti fondamentali per amministrare un sistema in modo che i processi interattivi rimangano reattivi anche quando sono in esecuzione attività pesanti in background.

## Il concetto di base: il valore "nice"

Tutto ruota attorno al **valore nice** (o "niceness"), un numero che indica quanto un processo è "gentile" (nice) nel cedere la CPU agli altri.

La scala va da **-20 a +19** ed è controintuitiva:

*   **Valore più basso (-20)** → Priorità **più alta**. Il processo è "meno gentile" e riceve più CPU.
*   **Valore più alto (+19)** → Priorità **più bassa**. Il processo è "molto gentile" e riceve CPU solo quando nessun altro lo richiede.
*   **Valore 0** → Priorità di base predefinita per la maggior parte dei processi.

## 1. `nice`: avviare un processo con una priorità diversa

Il comando `nice` si usa per **avviare** un nuovo comando con un valore nice specifico. La sintassi moderna è:

```bash
nice -n <valore> <comando>
```

*   **Valori positivi (+1 a +19)**: Rendono il processo più "gentile", abbassandone la priorità. Questo è utile per attività lunghe e non urgenti (es. backup, compressioni) che non devono rallentare il resto del sistema.
*   **Valori negativi (-1 a -20)**: Rendono il processo meno "gentile", alzandone la priorità. **Questa operazione richiede i privilegi di root (`sudo`)**.

**Esempi pratici**

*   **Avviare un backup a bassa priorità**: immagina di voler comprimere una cartella senza rallentare il lavoro sul desktop.
    ```bash
    nice -n 15 tar -czf backup.tar.gz /home/utente/documenti
    ```
    Il processo `tar` girerà solo quando la CPU non è impegnata in altro.

*   **Avviare un'attività critica con priorità alta**: se hai bisogno che un'operazione di calcolo importante termini il prima possibile (richiede `sudo`).
    ```bash
    sudo nice -n -10 ./calcolo_critico.sh
    ```
    Questo comando avvia lo script con una priorità maggiore rispetto ai processi standard.

> **Nota**: Se usi `nice` senza l'opzione `-n`, il comando viene avviato con un incremento predefinito di +10 (quindi con valore nice 10).

## 2. `renice`: modificare la priorità di un processo in esecuzione

Se ti accorgi che un processo già in esecuzione ha bisogno di una priorità diversa, non serve fermarlo: puoi usare `renice`.

La sintassi principale è:
```bash
renice -n <nuovo_valore> -p <PID>
```

**Esempi pratici**

*   **Abbassare la priorità di un processo che sta saturando la CPU**: supponi di aver avviato un processo con PID `552` che sta rendendo il sistema lento. Puoi ridurne la priorità al minimo.
    ```bash
    renice -n 19 -p 552
    ```
    L'output confermerà il cambio: `552 (process ID) old priority 0, new priority 19`.

*   **Alzare la priorità di un processo per farlo finire prima**: se un processo con PID `6258` è bloccato a priorità bassa e ti serve che finisca, puoi alzarla (richiede `sudo`).
    ```bash
    sudo renice -n -5 -p 6258
    ```
    Questo comando imposta il valore nice a -5, dando al processo più CPU.

*   **Riportare un processo alla priorità normale**: per annullare le modifiche e riportare un processo alla priorità di base.
    ```bash
    renice -n 0 -p 552
    ```
    Questo è utile per "resettare" la situazione.

`renice` è molto flessibile e permette di agire non solo su singoli PID, ma anche su **gruppi di processi** o su **tutti i processi di un utente**:

*   **Per utente** (`-u`): cambia la priorità di tutti i processi di un utente.
    ```bash
    sudo renice -n 10 -u www-data
    ```
    Utile per limitare l'impatto di un utente o di un servizio specifico.

*   **Per gruppo di processi** (`-g`): agisce su tutti i processi di un determinato gruppo.

## Riepilogo e regole d'oro

| Comando | Quando usarlo | Effetto |
| :--- | :--- | :--- |
| **`nice`** | **Prima** di avviare un processo | Avvia il comando con una priorità (nice value) specificata. |
| **`renice`** | Su un processo **già in esecuzione** | Cambia la priorità di un processo esistente, identificato da PID, utente o gruppo. |

**Regole fondamentali da ricordare:**

1.  **Permessi**: Un utente normale può solo **aumentare** il valore nice (cioè, abbassare la priorità) dei propri processi. Per **diminuire** il valore nice (alzare la priorità) o modificare processi di altri utenti, sono necessari i privilegi di **root** (`sudo`).
2.  **Effetto**: Valori nice alti (+19) sono ideali per processi in background che non devono disturbare l'uso interattivo del sistema. Valori nice bassi (-20) sono per processi critici che devono avere la precedenza assoluta.
3.  **Verifica**: Puoi controllare il valore nice di un processo con il comando `ps -o pid,ni,comm -p <PID>` (la colonna `NI` mostra il nice value).

---

**Area:** [[mappa-processi|Processi]]  
**Vedi anche:** [[gestione-processi|Gestione dei processi]] · [[kernel|Kernel Linux]] · [[namespaces-cgroups|Namespaces e cgroups]]
