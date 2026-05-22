# `halt -w` writes a wtmp shutdown record without halting. The -w flag is
# specific to sysvinit/busybox halt; coreutils' halt rejects it. Guard the
# call so a future halt-provider swap doesn't blow up stage 3.
if halt --help 2>&1 | grep -qE '\B-w\b'; then
    halt -w
fi
