# vim: set ts=4 sw=4 et:

# Hard backstop. By this point all stage-3 scripts have run; the only
# thing left is for PID 1 (runit-init) to invoke reboot(2). On some
# hardware (NVMe + dm-crypt observed) PID 1's path back to that syscall
# has stalled, leaving the screen frozen on the last stage-3 message.
# This script forces the reboot/halt syscall directly from a child of
# /etc/runit/3, so we never depend on PID 1's trigger-file dance.
#
# The brief sleep gives kexec (3.90) a chance to complete if it ran;
# `find -perm -u+x` mirrors 3.90's own test for /run/runit/reboot so
# we pick the same action runit-init would have picked.

[ -n "$IS_CONTAINER" ] && return 0

sleep 2

if [ -n "$(find /run/runit/reboot -perm -u+x 2>/dev/null)" ]; then
    msg "Forcing reboot..."
    exec reboot -f
fi

if [ -n "$(find /run/runit/stopit -perm -u+x 2>/dev/null)" ]; then
    msg "Forcing halt..."
    exec halt -f
fi

# Neither trigger is set — let PID 1 decide.
