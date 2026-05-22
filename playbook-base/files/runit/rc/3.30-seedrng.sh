if [ -z "$IS_CONTAINER" ]; then
    # seedrng ships in sys-apps/util-linux >= 2.39 but isn't always on PATH
    # on Gentoo. Skip cleanly when missing rather than logging a fatal-looking
    # "command not found" on every shutdown.
    if command -v seedrng >/dev/null 2>&1; then
        msg "Saving random number generator seed..."
        seedrng
    fi
fi
