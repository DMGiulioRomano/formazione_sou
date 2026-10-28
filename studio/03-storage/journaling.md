---
tags:
  - storage
  - nota
aliases:
  - Journaling
---
# Journaling

memorizza dati e metadati. serve ad evitare la corruzione del file system se ci sono black out e si spegne il computer. come? c'è una zona del disco che si chiama JOURNAL (un'area di memoria riservata e circolare).
 
 ### Le fasi tecniche della scrittura con Journaling (Modalità standard: _Data Ordered_)
1. **Scrittura dei Dati sul disco**: il file system scrive i blocchi di dati grezzi del file all'interno dei cluster liberi della partizione. In questa fase, i metadati generali del sistema non sono ancora stati modificati: il computer ha scritto i bit sul disco, ma il sistema operativo non sa ancora che esistono.
2. **Scrittura nel Journal (Fase di _Log_)**: Il file system prepara una transazione atomica contenente tutte le modifiche che dovranno essere applicate ai metadati (es. _Aggiornare l'inode X per puntare ai nuovi blocchi Y, sottrarre i blocchi Y dalla mappa dello spazio libero_). Questa transazione viene scritta interamente all'interno dell'area del Journal. Alla fine della transazione viene scritto un blocco speciale chiamato **Commit Block**.
3. **Modifica dei Metadati reali (_Checkpointing_)**: Solo dopo che il _Commit Block_ è stato scritto fisicamente nel Journal, il file system copia le modifiche dal Journal ai metadati effettivi del disco (la tabella degli inodi principale, l'indice della directory, ecc.). Una volta terminata la copia, la transazione nel Journal viene marcata come "rimossa" o rilasciata.

come viene gestito il recovery dopo un crash?
Se l'alimentazione si interrompe, al riavvio il kernel del sistema operativo non esegue una scansione completa di tutti i nodi del disco (`fsck` o `chkdsk`). Esegue invece una scansione sequenziale del solo **Journal**, che richiede pochi millisecondi.

---

**Area:** [[mappa-storage|Storage]]  
**Vedi anche:** [[filesystem|Filesystem]] · [[inode|Inode e scrittura dei file]] · [[integrita-fsck|Integrità del filesystem e fsck]]
