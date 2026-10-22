# Resoconto seconda settimana.

## Lun 19

Ho iniziato lo studio del terzo capitolo 3. 102 - Installazione di Linux e Package Management. Ho dedicato la mattinata nel risolvere il problema della virtual machine. Successivamente ho studiato partizioni, volumi, file system e il collegamento tra logico e fisico. Ho inoltre deciso di strutturare gli appunti personali sotto forma di vault obsidian e hostare all'interno del repository formazione_sou i suddetti materiali.
Ho inoltre deciso di iniziare un piano di esercizi e test sulla virtual machine, per cui ho scaricato debian minimal da https://www.debian.org/download nella versione debian-13.7.0-amd64-netinst.iso.
L'idea è di imparare a creare partizioni, riparare file system etc.
Sono riuscito a installare macport al posto di homebrew, in questo modo posso lavorare piu agilmente da terminale.

## Mar 20

Ho ho iniziato lo studio del cpaitolo 4 riguardo bash. A tal proposito ho deciso di dedicarmi nello sviluppo di un repo github in cui ho predisposto un ambiente con Makefile per orchestrare i vari scripts bash che ho creato per testare il funzionamento e lo stato delle macchine virtuali create con virtualBox. Ho inoltre studiato come creare e distruggere una macchina virtuale da terminale con i comandi di virtualBox. Mi ha richiesto diverso tempo, il lavoro non è ancora stato completato ma è fondamentale per automatizzare i processi di creazione e distruzione e montaggio dei dischi virtuali. Ho approfittato per imparare man mano nvim e git. 

## Mer 21

Sto preferendo affrontare uno studio interattivo tramite micro-progetti. In questo caso ho voluto risolvere un problema ipotetico che potrebbe accadere da un momento all'altro poiché la batteria del computer continua a dire di richiedere assistenza. La mia domanda è: poiché voglio lavorare in un ambiente ergonomico e customizzato secondo le mie necessità e i miei workflow, se il computer aziendale appena preso si rompesse perderei tutte le customizzazioni. come posso fare? risposta: ho creato un [repository github](https://github.com/DMGiulioRomano/dotfiles) dove ho mantengo tutti i files di configurazione (per ora ~/.zshrc ~/.zprofile ~/.wezterm.lua ~/.local/bin/* ~/.config) e attraverso un semplice script bash studiando GNU stow creo e posso manutenere symlink che puntano direttamente nei giusti path della $HOME. In questo modo ho potuto studiare questi files e la disposizione del Filesystem Hierarchy Standard (FHS) anche se macos è leggermente differente.
Un altro punto importante di oggi è continuare il lavoro sullo sviluppo di esercizi da svolgere con le virtual machine circa le partizioni.

## Gio 22

Ho iniziato il corso fornito su e-learning circa la sicurezza sul lavoro. Ho inoltre installato docker con tutte le sue dipendenze e approcciato alle differenze tra virtual machine e container. 
Inoltre ho concluso la cartella 3 e la cartella 4 dei video.

## Ven 20


