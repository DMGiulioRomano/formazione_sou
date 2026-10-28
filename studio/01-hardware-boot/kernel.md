---
tags:
  - hardware-boot
  - nota
aliases:
  - Kernel Linux
---
# Kernel Linux

Una volta lanciato systemd, il kernel Linux fa 3 cose:

1. **Scheduler** → gestisce il traffico dei vari processi dentro la CPU instradandolo nei core. La cosa figa è che alterna i programmi da un millisecondo all'altro, così velocemente da darti l'impressione che stiano girando tutti insieme.
2. **Memory manager** → regola la parte di RAM allocata per un certo processo o una certa applicazione in modo da liberare la memoria e pulirla se l'applicazione crasha. In questo modo sono tutte compartimentate e divise in due zone invalicabili: **kernel space** (dove risiede il codice compilato del kernel e dei suoi moduli, e qui ha potere assoluto) e **user space** (la zona dove vengono caricati systemd, server grafico e browser; in questo spazio sono protetti e non possono toccare direttamente l'hardware).
3. **Driver e system call** → i programmi nello userspace, quando hanno bisogno dell'hardware, fanno chiamate a sistema e il kernel se ne occupa.

Il kernel è scritto in C quasi interamente.

---

**Area:** [[mappa-hardware-boot|Hardware e boot]]  
**Vedi anche:** [[systemd|systemd]] · [[namespaces-cgroups|Namespaces e cgroups]] · [[nice-renice|nice e renice]] · [[dispositivi-moduli-kernel|Dispositivi e moduli del kernel]] · [[pseudo-filesystem-sys-proc|Pseudo-filesystem /sys e /proc]]
