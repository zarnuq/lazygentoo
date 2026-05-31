# lazygentoo

Ansible-driven Gentoo installer

This project has three independent playbooks, run in order, each against a remote target

- playbook-base
  - Run cmd: `ansible-playbook install.yml`
  - Run from a freshly loaded gentoo minimal livecd
  - Make sure to `rc-service sshd start` set `passwd` to connect to the livecd
- playbook-desktop
  - Run cmd: `ansible-playbook desktop.yml`
  - Run after having installed the base playbook
- playbook-secureboot
  - Run cmd: `ansible-playbook secureboot.yml`
  - Run with computer in setup mode and with boot keys deleted


## playbook-base
**Does nothing but the very base install for gentoo**

Runs a gentoo install, without systemd and openrc and instead uses runit a more minimal init system.
Also provides seatd as a session manager instead of elogind or logind.
Provides options for single or dual boot, LUKS encryption or plain text, and for a choice of networking daemon.
Autodetects cpu,gpu and sets up the needed gpu,cpu flags.
Boots a UKI from the binary kernel registered with efibootmgr (no bootloader, no grub).
Will prompt for the LUKS password
## playbook-desktop
**sets up a full GUI with apps and services**

installs a full desktop environment including:
- DWL for a window manager
- greetd for login mangager
- pipewire for audio (with an EQ)
- themes,fonts, icons, etc
- set zsh as shell
- installs nix + home-manger
- base needed apps
- firewall
## playbook-secureboot
**Enrolls Secure Boot keys and signs the UKI**

Generates and enrolls sbctl keys (keeps Microsoft's keys via -m for dual boot).
Wires ukify signing into kernel-install so future kernels sign on rebuild.
Re-signs the current UKI so it boots with Secure Boot enabled.


# Requirements
edit playbook `config.yml`, edit `inventory.ini` before running
