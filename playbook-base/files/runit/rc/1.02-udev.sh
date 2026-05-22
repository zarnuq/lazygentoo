#!/bin/sh
# Either sys-apps/systemd-utils[udev] (systemd-udevd) or sys-fs/eudev (udevd).
[ -n "$IS_CONTAINER" ] && return 0

_udevd=
for _candidate in /usr/lib/systemd/systemd-udevd /lib/systemd/systemd-udevd /sbin/udevd; do
    [ -x "$_candidate" ] && { _udevd="$_candidate"; break; }
done

if [ -z "$_udevd" ]; then
    msg_warn "cannot find udevd binary"
    return 0
fi

msg "Starting udev ($_udevd) and waiting for devices to settle..."
${_udevd} --daemon
udevadm trigger --action=add --type=subsystems
udevadm trigger --action=add --type=devices
udevadm settle
