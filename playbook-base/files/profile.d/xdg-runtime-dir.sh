# Provide XDG_RUNTIME_DIR on a system without elogind.
# /run/user is created sticky-1777 at boot by
# /etc/runit/rc/1.99-xdg-rundir.sh.
if [ -z "${XDG_RUNTIME_DIR}" ] && [ -n "${UID}" ]; then
    export XDG_RUNTIME_DIR=/run/user/${UID}
    if [ ! -d "${XDG_RUNTIME_DIR}" ]; then
        mkdir -p "${XDG_RUNTIME_DIR}"
        chmod 0700 "${XDG_RUNTIME_DIR}"
    fi
fi
