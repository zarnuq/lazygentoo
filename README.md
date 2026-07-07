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


## The stage4 tarball

Base no longer bootstraps from an upstream stage3. It extracts a **personalized
stage4 tarball** built ahead of time with **catalyst** (config in `catalyst-stage4/`).
The tarball bakes, at `-march=x86-64-v3`, everything that's the same on every machine:
the whole `@world` (toolchain, runit, seatd, river + reach WM, greetd, kitty, the
Wayland/GTK foundation, fonts, nftables, zsh, a source-compiled kernel), plus all
the portage config and overlays. The playbooks then only do the **host-specific**
work on top. Rebuild the tarball with `catalyst -f catalyst-stage4/specs/stage1..4`.


## playbook-base
**Extracts the stage4 tarball, then does the per-host install**

Lays down the baked runit (no systemd/openrc) + seatd system, then configures what
can't be baked: disk partitioning, LUKS encryption (single or dual boot), fstab,
hostname, the network daemon, the user, and the kernel. Autodetects cpu/gpu for
the make.conf host overrides and microcode. Assembles + registers a UKI (from the
baked source kernel) directly via efibootmgr — no bootloader, no grub. Prompts for
the LUKS password.
## playbook-desktop
**Adds the non-baked desktop layer on top**

The WM (river + reach), greetd, kitty, the firewall, and zsh are all baked into
the stage4. This layer adds only what's left:
- dotfiles (stowed from git)
- pipewire audio (with an EQ)
- themes, fonts, icons
- nix + home-manager
- the rest of the apps
- greetd NVIDIA env + host tweaks
## playbook-secureboot
**Enrolls Secure Boot keys and signs the UKI**

Generates and enrolls sbctl keys (keeps Microsoft's keys via -m for dual boot).
Wires ukify signing into kernel-install so future kernels sign on rebuild.
Re-signs the current UKI so it boots with Secure Boot enabled.


# Requirements
edit playbook `config.yml`, edit `inventory.ini` before running
