# vim: set ts=4 sw=4 et:

[ -n "$IS_CONTAINER" ] && return 0

# Compressed-RAM swap. disksize is set to half of RAM -- that's the *uncompressed*
# capacity it advertises; with zstd (~2-3x) the real RAM cost when completely full
# is well under that, and an empty zram costs ~nothing. Enabled at a high priority
# (100) so the kernel fills zram BEFORE spilling to the slower encrypted disk swap
# (which sits at its default negative priority); disk swap becomes overflow only.
# zram is RAM-backed, so it vanishes on poweroff -- no shutdown teardown needed.
modprobe zram 2>/dev/null || { msg_warn "zram module unavailable; skipping zram swap"; return 0; }

msg "Setting up zram swap..."
zram_kib=$(( $(awk '/^MemTotal:/{print $2}' /proc/meminfo) / 2 ))
zram_dev=$(zramctl --find --algorithm zstd --size "${zram_kib}KiB" 2>/dev/null) \
    || { msg_warn "zramctl failed; continuing without zram swap"; return 0; }
mkswap "$zram_dev" >/dev/null 2>&1
swapon --priority 100 "$zram_dev" || msg_warn "swapon $zram_dev failed"
