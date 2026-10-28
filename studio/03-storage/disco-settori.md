---
tags:
  - storage
  - nota
aliases:
  - Disco e settori
---
# Disco e settori

Il disco fisso è un dispositivo di archiviazione.

Per essere utilizzato c'è bisogno di qualcosa che definisca come suddividerlo e organizzi lo spazio a disposizione.

## Perché un settore è di 512 byte

1 settore = 512 byte. perché?
compromesso matematico ed economico tra:
- limiti fisici (hardware): dati sull'harddisk vengono scritti orientando la polarità di zone minuscole e queste zone devono essere intervallate da zone vuote così che la testina capisce dove finisce un settore e inizia un altro (inter-sector gap). 
- necessità logiche (software): **l'allineamento con le architetture dei processori e le convenzioni dei sistemi operativi**. La dimensione di 512 byte, che corrisponde a 2929 (due elevato alla nona potenza), è una potenza di due. Questo non è un caso: semplifica notevolmente i calcoli di indirizzamento e la gestione della memoria da parte della CPU e del sistema operativo, che lavorano naturalmente con numeri binari. Un settore di 512 byte si traduce in un'indirizzamento che utilizza 9 bit per identificare un byte all'interno del settore, un'operazione computazionalmente efficiente.

---

**Area:** [[mappa-storage|Storage]]  
**Vedi anche:** [[partizioni|Partizioni]] · [[mbr-gpt|MBR e GPT]] · [[block-group|Block e block group]] · [[bootloader-grub|Bootloader e GRUB]]
