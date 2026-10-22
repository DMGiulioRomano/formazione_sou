# Lezioncina: `md5sum`, `sha256sum`, `sha512sum`

Questi comandi calcolano un’**impronta digitale** (hash) di un file o di un flusso di dati. Servono a verificare l’integrità: se il file cambia anche di un solo bit, l’hash cambia completamente.

Sono strumenti quotidiani per sistemisti e sviluppatori: verificare download, confrontare copie, controllare backup, validare pacchetti.

---

## 1. Che cos’è un hash crittografico

Un hash è una funzione che prende un input di qualsiasi dimensione e produce una stringa di lunghezza fissa. Proprietà importanti:

- **Deterministico**: stesso input → stesso hash.
- **Effetto valanga**: un cambiamento minimo produce un hash completamente diverso.
- **Non reversibile**: dall’hash non si risale al contenuto.
- **Resistente alle collisioni**: due input diversi non dovrebbero produrre lo stesso hash (più o meno vero a seconda dell’algoritmo).

| Comando | Algoritmo | Dimensione hash | Sicurezza per firme/integrity malevola |
|---|---|---|---|
| `md5sum` | MD5 | 128 bit (32 caratteri hex) | **Rotto**: collisioni note, non usare per sicurezza |
| `sha256sum` | SHA-256 | 256 bit (64 caratteri hex) | Considerato sicuro |
| `sha512sum` | SHA-512 | 512 bit (128 caratteri hex) | Considerato sicuro |

> **Regola pratica**: MD5 va bene per verifiche non malevole (es. confrontare due copie, controllare un trasferimento). Per sicurezza, firme o integrità contro attacchi, usa SHA-256 o SHA-512.

---

## 2. Sintassi e output

La sintassi è identica per tutti e tre:

```bash
md5sum file
sha256sum file
sha512sum file
```

Output tipico:

```bash
$ sha256sum documento.txt
3a7bd3e2360a3d29eea436fcfb7e44c735d117c42d1c1835420b6b9942dd4f1b  documento.txt
```

L’output contiene **due campi**:
1. l’hash in esadecimale;
2. il nome del file (preceduto da due spazi, o da `*` se in modalità binaria).

### Opzioni utili

| Opzione | Significato |
|---|---|
| `-c file` | Verifica gli hash elencati nel file (check). |
| `-b` | Modalità binaria (l’output usa `*` prima del nome). |
| `-t` | Modalità testo (predefinita). |
| `--quiet` | In verifica, mostra solo gli errori. |
| `--tag` | Output in formato BSD-style (es. `SHA256 (file) = ...`). |

---

## 3. Esempi base

### Hash di un file

```bash
sha256sum documento.txt
```

### Hash da standard input

```bash
echo -n "ciao" | md5sum
```

Output:

```text
c1a5298f939e87e8f962a5edfc206918  -
```

Il `-` indica che l’input è arrivato da stdin.

> Attenzione: `echo` aggiunge un newline. Usa `echo -n` o `printf` per evitare sorprese.

### Hash di più file

```bash
sha256sum file1.txt file2.txt
```

Output:

```text
< hash1 >  file1.txt
< hash2 >  file2.txt
```

### Confronto rapido tra due file

```bash
md5sum copia1.bin copia2.bin
```

Se gli hash coincidono, i file sono identici (con altissima probabilità).

---

## 4. Verifica di integrità con `-c`

Questo è l’uso più importante. I siti di download pubblicano spesso un file di checksum, ad esempio `ubuntu.iso.sha256` che contiene:

```text
d6b3...  ubuntu-24.04.iso
```

Per verificare:

```bash
sha256sum -c ubuntu.iso.sha256
```

Output se tutto è corretto:

```text
ubuntu-24.04.iso: OK
```

Se il file è corrotto o manomesso:

```text
ubuntu-24.04.iso: FAILED
sha256sum: WARNING: 1 computed checksum did NOT match
```

### Generare un file di checksum

```bash
sha256sum documento.txt > documento.txt.sha256
```

Poi, per verificare in seguito:

```bash
sha256sum -c documento.txt.sha256
```

### Verifica silenziosa (solo errori)

```bash
sha256sum -c --quiet documento.txt.sha256
```

Utile negli script: se non stampa nulla, è andato tutto bene.

---

## 5. Esempio pratico da sistemista: verifica di un backup

Supponi di aver copiato un archivio su un disco esterno:

```bash
cp backup.tar.gz /mnt/usb/
```

Per essere sicuro che la copia sia integra:

```bash
sha256sum backup.tar.gz /mnt/usb/backup.tar.gz
```

Output:

```text
e3b0c442...  backup.tar.gz
e3b0c442...  /mnt/usb/backup.tar.gz
```

Se i due hash sono identici, la copia è integra.

Meglio ancora, genera il checksum prima e verificalo dopo:

```bash
sha256sum backup.tar.gz > backup.tar.gz.sha256
cp backup.tar.gz /mnt/usb/
cd /mnt/usb && sha256sum -c /percorso/backup.tar.gz.sha256
```

---

## 6. MD5: quando usarlo e quando no

**Usalo per**:
- confrontare due copie locali;
- verificare che un trasferimento non abbia corrotto i dati;
- controlli rapidi non critici.

**Non usarlo per**:
- firmare documenti o software;
- garantire integrità contro un attaccante attivo;
- sostituire SHA-256 in contesti di sicurezza.

MD5 è veloce e storicamente diffuso, ma le collisioni sono state dimostrate: due file diversi possono avere lo stesso MD5. Per questo è stato deprecato in ambito crittografico.

---

## 7. SHA-256 vs SHA-512

Entrambi sono sicuri. La differenza principale:

- **SHA-256**: hash più corto, più veloce su CPU a 32 bit, standard de facto per firme, certificati, blockchain.
- **SHA-512**: hash più lungo, spesso più veloce su CPU a 64 bit, usato in contesti ad alta sicurezza.

Per la maggior parte degli usi quotidiani, **SHA-256 è la scelta predefinita**. SHA-512 è utile se vuoi margine di sicurezza maggiore o se lavori su architetture a 64 bit dove è efficiente.

---

## 8. Errori comuni

### Confondere l’hash con una crittografia reversibile

L’hash non si “decifra”. Non puoi recuperare il contenuto originale dall’hash.

### Usare `echo` senza `-n`

```bash
echo "ciao" | md5sum   # include il newline
echo -n "ciao" | md5sum # non include il newline
```

I due hash sono diversi. Sii consapevole di cosa stai hashando.

### Verificare un file con il nome sbagliato

Il file `.sha256` contiene il nome del file originale. Se il file è stato rinominato, `sha256sum -c` fallirà perché non trova il nome indicato. Puoi comunque verificare manualmente confrontando gli hash.

### Pensare che MD5 sia “sicuro perché lungo”

32 caratteri esadecimali sembrano tanti, ma la sicurezza non si misura dalla lunghezza percepita: MD5 è crittograficamente rotto.

---

## 9. Riepilogo

| Comando | Uso tipico |
|---|---|
| `md5sum file` | Hash MD5 rapido, verifica non critica. |
| `sha256sum file` | Standard sicuro per integrità e sicurezza. |
| `sha512sum file` | Alternativa più robusta, utile su 64 bit. |
| `sha256sum -c file.sha256` | Verifica di integrità da file di checksum. |
| `sha256sum file > file.sha256` | Genera un file di checksum. |

**Best practice**:
- Usa **SHA-256** come default.
- Usa **MD5** solo per confronti rapidi e non malevoli.
- Verifica sempre i download con il checksum ufficiale.
- Conserva i file di checksum insieme ai backup.

Con questi tre comandi hai gli strumenti per garantire che i dati siano esattamente quelli che ti aspetti, dal singolo file al backup completo.