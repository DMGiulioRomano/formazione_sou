# Profilo Arch Linux: make lab-crea PROFILO=arch
# Con ?= una variabile passata a mano ha comunque la precedenza:
#   make lab-crea PROFILO=arch VM=lab-arch-2
VM ?= lab-arch
ISO ?= archlinux-2026.10.01-x86_64.iso
export VM_OSTYPE ?= ArchLinux_64
