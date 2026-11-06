---
tags:
  - ai
  - nota
aliases:
  - Swap e SSD streaming
---
# Swap e SSD streaming nei modelli MoE

Sono due modi di far girare un LLM più grande della memoria. La swap sposta pagine senza sapere cosa contengono. Lo streaming sa che sono pesi di esperti e carica dall'SSD solo quelli scelti dal modello.

Funziona perché in un modello MoE (*Mixture of Experts*) a ogni token si attiva solo una parte degli esperti: DeepSeek-V3 ne usa 8 su 256 per strato.

| | Swap | Streaming da SSD |
|---|---|---|
| **Cosa sa del modello** | Nulla: stima da quanto le pagine sono state usate di recente | Quali esperti ha scelto il router |
| **Quando carica** | Dopo un *page fault* | Può leggere prima di calcolare lo strato |
| **Per liberare RAM** | Scrive sul disco le pagine anonime | Scarta i pesi, che sono già nel file |
| **Usura dell'SSD** | Alta se usata di continuo | Bassa: i pesi vengono solo letti |

## Il flusso di uno strato

1. Il router calcola quali esperti servono ai token correnti.
2. Il runtime controlla quali sono già in memoria.
3. Legge dall'SSD quelli mancanti, scartando se serve quelli usati meno di recente o meno probabili.
4. Calcola lo strato.

## Cosa resta fuori

La KV cache, cioè lo stato della conversazione, nasce durante l'esecuzione e non esiste in un file. Deve restare in memoria o finire in swap o in una cache scritta su disco. Lo stesso vale per i calcoli intermedi.

## Il caso di mezzo: `mmap`

Runtime come llama.cpp possono mappare il file dei pesi in memoria. Il kernel carica le pagine quando servono e può scartarle senza usare la swap, ma non sa nulla degli esperti, a meno di suggerimenti come `madvise`. Un *page fault* a metà calcolo può bloccare il thread.

## Il limite: la banda dell'SSD

Con 10 GB di esperti mancanti a ogni token e un SSD da 7 GB/s servono circa 1,4 secondi solo per leggerli (numeri di esempio). Lo streaming conviene se gli esperti si ripetono tra un token e l'altro. I batch grandi lo penalizzano, perché attivano insieme molti più esperti.

I dettagli variano da un algoritmo all'altro.

---

**Area:** [[mappa-ai|AI]]  
**Vedi anche:** [[swap|Swap]]
