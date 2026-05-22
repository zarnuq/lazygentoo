# vim: set ts=4 sw=4 et:

[ -n "$IS_CONTAINER" ] && return 0

# Swap isn't required to reach a usable system; never drop to an emergency
# shell on swapon failure (e.g. crypttab swap mapper not yet created on a
# fresh install, no swap configured at all, fstab UUID mismatch). Log and
# continue — the rest of the boot can complete and the user can fix it.
msg "Initializing swap..."
swapon -a || msg_warn "swapon -a failed; continuing without swap"
