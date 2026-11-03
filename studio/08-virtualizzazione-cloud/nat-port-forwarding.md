---
tags:
  - virtualizzazione
  - nota
aliases:
  - NAT e inoltro di porta
---
# NAT e inoltro di porta

**NAT** sta per *Network Address Translation*, traduzione degli indirizzi di rete. Un intermediario sostituisce l'indirizzo privato con il proprio, così più macchine escono in rete usando un solo indirizzo. Con una scheda VM in modalità NAT, l'intermediario è VirtualBox.

## In uscita funziona

1. La VM (`10.0.2.15`) contatta `archlinux.org`.
2. VirtualBox fa uscire la richiesta a nome del Mac e annota chi l'ha fatta.
3. La risposta torna al Mac e VirtualBox, grazie all'annotazione, la consegna alla VM.

## In entrata no

Una connessione che arriva dall'esterno non ha nessuna annotazione, quindi VirtualBox non sa a chi consegnarla. Inoltre `10.0.2.15` esiste solo nella rete privata della VM.

## L'inoltro di porta

Una **porta** è il numero che indica a quale programma di una macchina è destinata una connessione: `sshd` usa la 22.

L'inoltro (*port forwarding*) è una regola scritta in anticipo: ciò che arriva a questa porta del Mac va consegnato a quella porta della VM.

```sh
VBoxManage modifyvm lab-arch --natpf1 "ssh,tcp,127.0.0.1,2222,,22"
```

I campi sono: nome, protocollo, indirizzo sul Mac, porta sul Mac, indirizzo nella VM, porta nella VM.

- **`127.0.0.1`**: la porta è raggiungibile solo dal Mac.
- **`2222`**: evita la 22 del Mac, che potrebbe essere usata dal suo SSH.

---

↑ [[mappa-virtualizzazione-cloud|Virtualizzazione e cloud]] · [[00-home|Home]]
