#!/bin/sh
# XDG_RUNTIME_DIR base dir (no logind/elogind).
# Per-user /run/user/$UID is created lazily by /etc/profile.d/xdg-runtime-dir.sh
# on first login.
install -d -m 1777 /run/user
