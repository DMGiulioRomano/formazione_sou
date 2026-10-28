---
tags:
  - virtualizzazione
  - nota
aliases:
  - Immagini container
---
# Immagini container

Un’**immagine di container** è, in sostanza, un **pacchetto immutabile** che contiene tutto il necessario per avviare un container: un filesystem di base, le applicazioni, le librerie, le variabili d’ambiente, il comando di avvio e altri metadati. Non è una macchina virtuale e non contiene un kernel: condivide il kernel dell’host.

## 1. Immagine = strati sovrapposti (layers)

Un’immagine è composta da più **layer** in sola lettura, impilati uno sopra l’altro. Ogni layer rappresenta una modifica rispetto al precedente:

- aggiunta di file;
- modifica di file;
- cancellazione di file (in realtà tramite “whiteout”);
- metadati come `ENV`, `CMD`, `ENTRYPOINT`, `EXPOSE`, `VOLUME`.

A runtime il filesystem dell’immagine viene presentato come un unico filesystem grazie a meccanismi come **OverlayFS** o altri union filesystem: i layer sono sovrapposti e il processo vede il risultato finale.

Esempio concettuale:

```text
Layer 5: copia dell'app
Layer 4: dipendenze Python
Layer 3: apt install ...
Layer 2: aggiornamenti base
Layer 1: immagine base (es. debian)
```

I layer sono **condivisi** tra immagini diverse: se due immagini usano la stessa base, quella base viene scaricata e memorizzata una sola volta.

## 2. Immagine = filesystem + configurazione

Oltre ai layer del filesystem, un’immagine contiene un **manifest** e una **configurazione**. La config include cose come:

- comando di default (`CMD`);
- punto di ingresso (`ENTRYPOINT`);
- variabili d’ambiente;
- directory di lavoro;
- utente con cui girare;
- porte esposte;
- volumi;
- etichette;
- architettura e sistema operativo.

Lo standard di riferimento è **OCI** (Open Container Initiative), quindi immagini e runtime sono interoperabili tra Docker, Podman, containerd, ecc.

## 3. Come nasce un’immagine: build

Normalmente si crea con un **Dockerfile** o un file OCI equivalente. Ogni istruzione che modifica il filesystem crea un nuovo layer:

```dockerfile
FROM debian:12
RUN apt-get update && apt-get install -y python3
COPY app.py /app/
CMD ["python3", "/app/app.py"]
```

- `FROM` sceglie l’immagine base;
- `RUN` crea un layer con i pacchetti installati;
- `COPY` crea un layer con i file copiati;
- `CMD` aggiunge metadati di configurazione.

Durante la build Docker usa una **cache**: se un’istruzione e i layer precedenti non cambiano, riusa il layer già costruito. Per questo conviene mettere prima le istruzioni che cambiano poco e poi quelle che cambiano spesso.

## 4. Immagine vs container

L’immagine è **sola lettura**. Quando avvii un container, il runtime:

1. scarica o recupera i layer dell’immagine;
2. li monta in modo sovrapposto;
3. aggiunge un **layer scrivibile** in cima;
4. avvia il processo indicato dalla configurazione.

Quindi:

```text
container = immagine (read-only) + layer scrivibile + processo in esecuzione
```

Le modifiche fatte dentro il container finiscono nel layer scrivibile. Se elimini il container, quel layer sparisce. Per conservare dati usi **volumi** o bind mount; per creare una nuova immagine da un container modificato puoi fare un commit, ma è una pratica meno pulita rispetto a ricostruire l’immagine da Dockerfile.

## 5. Registry, tag e digest

Le immagini vengono distribuite tramite **registry** (Docker Hub, GHCR, registry privati, ecc.). Un riferimento tipico è:

```text
docker.io/library/nginx:1.27
```

- `nginx` è il nome dell’immagine;
- `1.27` è un **tag**, che è mutabile: può essere riassegnato a un’immagine diversa;
- ogni immagine ha anche un **digest** crittografico, ad esempio `sha256:...`, che è immutabile e identifica esattamente quei contenuti.

Quando fai `docker pull`, il client scarica manifest, config e layer mancanti. I layer sono **content-addressable**: identificati da hash del contenuto, quindi verificabili e deduplicabili.

## 6. In sintesi

Un’immagine container funziona così:

1. è un **template immutabile** composto da layer di filesystem e metadati;
2. i layer sono sovrapposti e condivisi tramite union filesystem;
3. si costruisce a strati da un Dockerfile, con cache;
4. si distribuisce via registry tramite tag e digest;
5. quando diventa container, riceve un layer scrivibile sopra l’immagine;
6. non contiene un kernel: usa quello dell’host, isolata tramite namespaces e limitata tramite cgroups.

---

**Area:** [[mappa-virtualizzazione-cloud|Virtualizzazione e cloud]]  
**Vedi anche:** [[vm-vs-container|VM vs container]] · [[namespaces-cgroups|Namespaces e cgroups]] · [[filesystem|Filesystem]] · [[hashsum|Hash e checksum]]
