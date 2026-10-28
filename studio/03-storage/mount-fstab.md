---
tags:
  - storage
  - nota
aliases:
  - Mount e fstab
---
# Mount e fstab

## 1.4 Montaggio e filesystem

```bash
# Creare filesystem ext4
mkfs.ext4 /dev/sdb1

# Montare il filesystem
mount /dev/sdb1 /media

# Aggiornare tabella partizioni se non corrisponde
partprobe /dev/sdb
```

**Importante**: Se perdi una partizione o la tabella dei file, puoi ricrearla senza perdere i dati, perché il filesystem rimane sul disco.

## 3.1 Visualizzare filesystem montati

```bash
# Elenco filesystem
df

# Human readable + tipo filesystem
df -hT
```

## 3.5 Copia e sincronizzazione

```bash
# Copia ricorsiva preservando permessi
rsync -arv /home/ /mnt/
# -a: preserva permessi
# -r: ricorsivo
# -v: verbose

# Monta tutto da fstab
mount -a
```

> [!question] Da approfondire
> - Sintassi completa di fstab: `UUID="ID" swap swap sw,pri=5 0 0`

---

**Area:** [[mappa-storage|Storage]]  
**Fonte:** [[lezione-4-installazione-pacchetti|Lezione 4 — Installazione e package management]]  
**Vedi anche:** [[filesystem|Filesystem]] · [[swap|Swap]] · [[integrita-fsck|Integrità del filesystem e fsck]] · [[fhs|FHS]] · [[strumenti-partizionamento|Strumenti di partizionamento]]
