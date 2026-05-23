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
- playbook-kernel
  - Run cmd: `ansible-playbook kernel.yml`
  - Run with computer in setup mode and with boot keys deleted


## playbook-base
**Does nothing but the very base install for gentoo**

Runs a gentoo install, without systemd and openrc and instead uses runit a more minimal init system.
Also provides seatd as a session manager instead of elogind or logind.
Provides options for single or dual boot, LUKS encryption or plain text, and for a choice of networking daemon.
Autodetects cpu,gpu and sets up the needed gpu,cpu flags.
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
## playbook-kernel
**Assembles a UKI and Signs it and boots without a bootloader**

Makes a UKI from the binary kernel (not gunna compile a kernel for 1-3% better performance).
signs the UKI so its secureboot ready.
Changes boot order via efibootmgr.
Deletes grub since bios boots right off the UKI.


# Requirements
edit playbook `config.yml`, edit `inventory.ini` before running
