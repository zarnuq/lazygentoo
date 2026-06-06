
● That's a TPM policy mismatch, not a tooling bug. The key line:

  ERROR: Esys_Unseal(0x99D) - tpm:session(1):a policy check failed
  Unsealing jwk from TPM failed!

  0x99D is TPM_RC_POLICY_FAIL. clevis sealed your LUKS key to PCR 7 (Secure Boot state), and PCR 7 now reads a different value than it did when the key was sealed, so the
  TPM refuses to release it.

  Why this was inevitable with the current playbook order

  secureboot.yml runs: 02 enroll keys → 03 clevis TPM bind → 04 sign UKI. The bind in 03 happens while you're still booted in the pre-Secure-Boot state (SB not yet
  enforced, unsigned/old boot chain). PCR 7 measures the Secure Boot policy and what validated the boot. So:

  - At seal time: PCR 7 = value of the install-time boot (SB off / setup mode / unsigned).
  - At this boot: PCR 7 = value with your keys enrolled, SB enforcing, signed UKI. Different → policy fails.

  PCR 7 is the right PCR (it's stable across kernel updates, which is why it was chosen) — the bug is purely that the initial seal happened before the machine was in its 
  final Secure Boot state.

  Recover right now

  Your passphrase keyslot was deliberately kept as fallback. After clevis exhausts its TPM attempts it should drop to a passphrase prompt — enter your LUKS passphrase to
  boot. If it instead drops to a dracut emergency shell, unlock manually:

  cryptsetup open /dev/nvme0n1p3 root   # enter passphrase, then `exit` to continue boot

  Fix permanently (once booted into the real SB-enabled system)

  Now that PCR 7 is at its final, stable value, re-seal against it:

  # see the current binding + its slot
  doas clevis luks list -d /dev/nvme0n1p3
  # drop the stale binding (use the slot number from the list, e.g. 1)
  doas clevis luks unbind -d /dev/nvme0n1p3 -s 1
  # re-bind against the CURRENT pcr7
  doas clevis luks bind -d /dev/nvme0n1p3 tpm2 '{"pcr_bank":"sha256","pcr_ids":"7"}'

  Reboot — it should now auto-unlock, and stay working across kernel updates.

  The real fix for the playbook

  The TPM bind must run after the first successful Secure-Boot boot, not during the install run. Also, 03-tpm.yml's idempotency check (skip if a tpm2 binding already
  exists) would prevent a re-seal — so even re-running it wouldn't repair a stale binding.

  Two reasonable options:

  1. Split it out — move 03-tpm.yml into its own small playbook you run once, after rebooting into the enrolled/SB-enforcing system. Cleanest; the seal always matches
  reality.
  2. Detect-and-reseal — make 03 verify the existing binding actually unseals now (clevis luks unlock test or compare current PCR7), and unbind+rebind if it doesn't.

  Want me to implement option 1 (pull TPM binding out of secureboot.yml into a tpm-enroll.yml you run post-reboot)? That matches how this is normally done and avoids the
  chicken-and-egg entirely.

✻ Crunched for 1m 15s

❯ it spams that message i cant type a password                                                                                                                              

● It's stuck in clevis's retry loop and never falling through to the passphrase prompt. Since your kernel command line is baked into a signed UKI, you can't edit it at boot
  to break the loop — so you need to recover from a live USB and remove the bad TPM binding. The passphrase keyslot is still intact underneath it.

  Recovery (live USB)

  1. Force power off (hold the power button), boot any Linux live USB that has cryptsetup (Gentoo admin CD, Arch ISO, Ubuntu live, etc.).
  2. Remove the stale clevis/TPM binding so only your passphrase slot remains.

  2. If the live environment has clevis:
  clevis luks list -d /dev/nvme0n1p3            # note the slot number, e.g. 1
  clevis luks unbind -d /dev/nvme0n1p3 -s 1     # asks for your passphrase

  2. If clevis isn't available, do it with cryptsetup directly:
  cryptsetup luksDump /dev/nvme0n1p3
  2. Under Tokens: find the clevis token — note its id and the Keyslot it points to. Then:
  cryptsetup token remove --token-id <id> /dev/nvme0n1p3
  cryptsetup luksKillSlot /dev/nvme0n1p3 <keyslot>   # the clevis slot, NOT your passphrase slot
  2. luksKillSlot will ask for a passphrase from a surviving slot to authorize — that's your normal LUKS passphrase.
  
  2. ⚠️ Double-check you're killing the clevis keyslot, not the passphrase slot. In luksDump, your passphrase slot is the one you can still unlock with; the clevis one is
  the slot referenced by the clevis token (usually slot 1, passphrase usually slot 0).
  3. Reboot into the installed system (remove the USB). With no clevis binding present, the boot will fall through to the normal passphrase prompt — type your passphrase
  and you're in.
  
  Then re-bind correctly

  Once you're booted into the final, Secure-Boot-enforcing system, seal against the current PCR 7 (now stable):

  doas clevis luks bind -d /dev/nvme0n1p3 tpm2 '{"pcr_bank":"sha256","pcr_ids":"7"}'

  Reboot to confirm it auto-unlocks. From here it'll survive kernel updates.
  
  ---
  Want me to also fix the playbook so this can't recur — i.e. pull the TPM bind out of secureboot.yml into a tpm-enroll.yml meant to run after the first Secure-Boot boot?
  That's the structural fix; the loop you're hitting now is the direct result of sealing before the system was in its final state.

✻ Worked for 48s

❯ am i cooked or can i fix from bios?                                                                                                                                       

● Not cooked. Your data is fine and your passphrase keyslot is intact — the TPM slot is just an additional way in, and it's the broken one. Worst case is a 5-minute
  live-USB fix. But there's a decent chance you can avoid the USB entirely from BIOS:

  BIOS trick to try first (no USB)

  BIOS can't edit the LUKS header, so it can't remove the bad binding directly. But it can make the TPM disappear, which usually breaks the loop:

  1. Enter BIOS → find Security → TPM / "Security Device" / PTT / fTPM → disable it (or "Clear TPM").
  2. Save & reboot.

  With no TPM present, clevis's unseal fails immediately instead of looping on a policy check, and the dracut clevis module should then fall through to the normal
  passphrase prompt. Type your LUKS passphrase → you're booted.

  Then fix it from inside the OS:
  doas clevis luks list -d /dev/nvme0n1p3        # find the stale tpm2 slot
  doas clevis luks unbind -d /dev/nvme0n1p3 -s 1 # remove it
  Re-enable the TPM in BIOS, boot once more with your passphrase, then re-bind against the now-correct PCR 7:
  doas clevis luks bind -d /dev/nvme0n1p3 tpm2 '{"pcr_bank":"sha256","pcr_ids":"7"}'
  
  Clearing/disabling the TPM is safe here — the only thing sealed to it is this already-broken clevis slot, and you're re-binding anyway. (Don't do this if you had
  Windows/BitLocker on the same TPM, but this is a Linux-only box.)

  If the loop still doesn't yield a prompt

  Then the dracut clevis module isn't falling back on your setup, and you'll need the live USB from my last message to clevis luks unbind (or cryptsetup token remove +
  luksKillSlot) the stale slot. Either way you end up at the same place — booted on your passphrase, then re-bind cleanly.

  Bottom line: try disabling the TPM in BIOS first; if you don't get a passphrase prompt within a few seconds, fall back to the USB. No risk to your data in either path.

✻ Cogitated for 35s

❯ how much would it take to get zfs to work would it matter?                                                                                                                

● Let me look at your current disk/boot setup so I can answer in terms of what you'd actually have to change.

● Bash(cd /home/miles/lazygentoo; echo "=== base config (fs/disk bits) ==="; grep -niE "fs|ext4|btrfs|xfs|zfs|luks|crypt|filesystem|subvol|dracut|mkfs" playbook-base/c…)
  ⎿  === base config (fs/disk bits) ===
     25:root_part_override: "/dev/nvme0n1p6"    # Linux root (ext4)
     28:# ENCRYPTION OPTIONS #
     … +165 lines (ctrl+o to expand)

● Grounded in what you actually have: single NVMe, GPT → ESP + swap + LUKS2(cryptroot) + ext4, booting a UKI via dracut, with clevis/TPM unlocking the LUKS slot. So "add
  ZFS" means reworking the root filesystem layer underneath all of that.

  What it'd take

  It's not a flag flip — it touches five areas:

  1. Out-of-tree module. ZFS is CDDL, so it can't be =y in your kernel. You'd add sys-fs/zfs + sys-fs/zfs-kmod, rebuilt against the kernel on every kernel update
  (@module-rebuild). And ZFS lags the newest kernels — your 06-kernel.yml kernel choice would now be constrained by what zfs-kmod supports. Expect version-pinning friction.
  2. Encryption decision — this is the big one for you:
    - ZFS native encryption (drop LUKS): breaks your clevis/TPM unlock entirely — clevis is LUKS-only, and there's no clean TPM auto-unlock for ZFS native keys. You'd be
  hand-rolling a TPM keystore. Also leaks pool metadata (weaker than LUKS).
    - ZFS inside LUKS (single-disk pool on /dev/mapper/cryptroot): keeps your LUKS + clevis + TPM work untouched. Lower friction, but you give up ZFS's own encryption/key
  features.
  3. Boot + init. root=ZFS=rpool/ROOT/..., dracut zfs module baked into the UKI, hostid, zpool cache, import-at-boot. You're on runit, so you'd write runit services for
  pool import / mount / zed (no systemd presets to lean on).
  4. fstab/mounts. Root leaves fstab (ZFS mounts by dataset property); fstab.j2 changes.
  5. Secure Boot. zfs.ko loads from the signed UKI's initramfs — fine unless you turn on module-signature enforcement / lockdown, in which case it needs handling.

  Realistic effort: a half-day to a couple of days of iteration, mostly on zfs↔kernel version compat, runit service wiring, and dracut/UKI integration.

  Would it matter?

  Honestly, on a single-disk encrypted laptop — mostly not for the headline reasons:

  - ZFS's flagship value is multi-disk redundancy + scrub/self-heal. With one disk you get none of that (detection only, no healing unless copies=2).
  - What you'd actually use: snapshots/rollbacks, compression, send/recv backups. Those are real and nice — especially snapshots before a big Gentoo emerge — but they don't
  need ZFS.

  The pragmatic middle path: btrfs

  If the real goal is snapshots + rollbacks + compression, btrfs gets ~80% of the benefit for ~10% of the work in your stack:

  - In-tree → no module rebuilds, no kernel-version pinning, no UKI/Secure-Boot module-signing concern.
  - Sits on your existing LUKS + clevis + TPM unchanged.
  - Playbook change is small: root_fs: btrfs, a subvolume layout (@, @home, @snapshots), and matching fstab.j2 mount opts — no boot/init surgery.

  So: ZFS matters if you want send/recv replication, plan to add disks, or specifically want ZFS's integrity model and are willing to own the out-of-tree + runit +
  kernel-pinning maintenance. Otherwise, for this laptop, it's a lot of added complexity on top of a stack you're already fighting (you just spent today on the TPM/UKI
  chain), and btrfs is the better cost/benefit.

  Want me to sketch the btrfs conversion (subvolumes + fstab + the one-line root_fs change), or spec out the ZFS-inside-LUKS path properly if you'd rather commit to ZFS?

✻ Baked for 1m 15s

※ recap: You're hardening a Gentoo laptop install (LUKS + UKI + Secure Boot + TPM unlock) and just hit a boot loop from a stale clevis TPM binding. Next: disable the TPM in
  BIOS to get a passphrase prompt, boot in, then re-bind clevis against the current PCR 7.

──────────────────────────────────────────────────────────────────────────────────────────────
