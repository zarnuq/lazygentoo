# vim: set ts=4 sw=4 et:

# utmp group ships in Gentoo stage3 (acct/sys-libs/glibc baseline), but be
# defensive: fall back to root group if it's missing so cleanup never aborts.
_utmp_grp=utmp
getent group utmp >/dev/null 2>&1 || _utmp_grp=root
if [ ! -e /var/log/wtmp ]; then
	install -m0664 -o root -g "$_utmp_grp" /dev/null /var/log/wtmp
fi
if [ ! -e /var/log/btmp ]; then
	install -m0600 -o root -g "$_utmp_grp" /dev/null /var/log/btmp
fi
if [ ! -e /var/log/lastlog ]; then
	install -m0600 -o root -g "$_utmp_grp" /dev/null /var/log/lastlog
fi
unset _utmp_grp
install -dm1777 /tmp/.X11-unix /tmp/.ICE-unix
rm -f /etc/nologin /forcefsck /forcequotacheck /fastboot
