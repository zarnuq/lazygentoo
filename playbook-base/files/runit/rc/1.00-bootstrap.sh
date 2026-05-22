# Bootstrap: provides msg/emergency_shell/detect_container + rc.conf vars.
# Reads /etc/runit/rc.conf (kept separate from OpenRC's /etc/rc.conf so the
# two init systems can coexist on disk).
. /etc/runit/functions
[ -r /etc/runit/rc.conf ] && . /etc/runit/rc.conf
detect_container
msg "Bootstrap complete"
