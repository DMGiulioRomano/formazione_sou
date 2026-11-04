
# TO-DO giornaliwera

- Sviluppare competenze autonome in partizioni. 
- VM esercizi:
    - fare su ogni distro.
    - se possibile provare sia con mbr che con gpt.
    - imparare a usare VLM.
    - passare tramite l'init del processore alle varie tipologie.
    - Devo provare a creare volumi

## Per il 5 novembre: riprendere il laboratorio Rocky

Appunti in `studio/lezioni/laboratorio-installazione-rocky.md`, passo 7.

- Controllare le porte impostate per ogni VM (comando del ciclo su `VBoxManage list vms`, non ancora lanciato).
- Se `lab-rocky` non ha la regola `ssh,tcp,127.0.0.1,2222,,22`, crearla.
- Spegnere Rocky con `poweroff`, riavviarla con `VBoxManage startvm lab-rocky --type headless` e verificare con `VBoxManage list runningvms`.
- Collegarsi dal Mac con `ssh -p 2222 remoto@127.0.0.1` e controllare con `hostname` e `whoami`.
- Rispondere alla D5 ancora aperta: a cosa servono la shell e le schede di log durante l'installazione?

## Lab

- `doctor.sh` non controlla la versione di GNU Make, ma il Makefile usa `.SHELLFLAGS`.
- `aggiungi-dischi.sh` va lanciato due volte di fila per confermare l'idempotenza.
