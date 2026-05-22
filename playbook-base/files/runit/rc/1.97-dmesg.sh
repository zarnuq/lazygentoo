# vim: set ts=4 sw=4 et:

dmesg >/var/log/dmesg.log
# Use string compare so an empty/missing sysctl value doesn't trip `-eq`.
if [ "$(sysctl -n kernel.dmesg_restrict 2>/dev/null)" = "1" ]; then
	chmod 0600 /var/log/dmesg.log
else
	chmod 0644 /var/log/dmesg.log
fi
