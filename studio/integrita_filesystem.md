# filesystem

integrità del file system.
Ad ogni montaggio del file system c'è un valore che viene incrementato. quindi si può mettere una guardia ogni tot nel contatore per fare un check dell'integrità ogni tot montaggi.
Come lo faccio? uso

tune2fs -l <nome_disco>

e per vedere il nome del disco sul quale farlo? 
devo usare df che sta per disk free che analizzs spazio libero e occupato dei filesystem montati. 
Per renderlo piu leggibile uso -h che sta per human readable e -T aggiunge una colonna all'output che mostra espressamente il tipo di file system di ogni partizione (ad esempio: ext4, xfs, btrfs, vfat, tmpfs.

quindi df -hT
e poi scelgo il disco e lo passo a tune2fs. 
li cerco 'Maximum mount count' e quando il valore è -1, vuol dire che è spento.

se vediamo poi cat /etc/fstab vediamo che nella 6a colonna c'è un valore, che c'è un parametro che se ha valore 1 c'è check abilitato all'avvio.


come si controlla il file system per ext2-3-4 ? con e2fsck <nome_disco>
invece per dos o fat con le loro variani..? dosfsck <nome_disco>
per raisefs abbiamo reiserfsck <nome_disco>
per XSF abbiamo xfs_repair 


Regola fondamentale prima dell'uso

Non eseguire mai e2fsck o altri comandi su un file system attivo e montato. Farlo può causare la corruzione permanente dei dati. Prima di usarlo, la partizione deve essere sempre smontata (con il comando umount).

possiamo usare anche direttamente fsck che sta per File System Consistency Check che in realtò è unasorta di orchestratore: prima controlla il tipo di file system, poi delega il lavoro allo strumento specifico a differenza del file system.
cosa fa lo strumento specifico? come avvine il controllo? 5 fasi di controllo:
- inode e strutture dati
- struttura delle directory
- connettività direcrtory che siano aggangiate alla root /
- verifica uguaglianza collegamneti ai files
- controllo bitmap dei blocks/clusters.

#### bitmap
non è altro che una rappresentazione digitale di quali blocks/cluster sono liberi (valore 0) e occupati da file (1). letteralmente una mappa rappresentata con i bit, uno per ogni cluster/block.

ovviamente fsck ha delle opzioni ovviamente:
fsck -a  fa tutto in automatico ma su problemi minori.
invece L'opzione -A dove serve a controllare tutti i file system elencati nel file /etc/fstab in un colpo solo. 


se invece volessimo gestire le partizioni?
Permette di creare, distruggere, ridimensionare, spostare e copiare partizioni, oltre a gestire le tabelle delle partizioni (come GUID/GPT o MBR).
innanzitutto elenco i dischi e le partizioni con 
parted -l

