if [ -z "$IS_CONTAINER" ]; then
    msg "Unmounting filesystems, disabling swap..."
    swapoff -a
    umount -r -a -t nosysfs,noproc,nodevtmpfs,notmpfs
    msg "Remounting rootfs read-only..."
    LIBMOUNT_FORCE_MOUNT2=always mount -o remount,ro /
fi

sync

# Skip deactivate_vgs / deactivate_crypt at shutdown. The kernel's
# reboot(2) syscall tears down dm-crypt + LVM state in-kernel, so
# closing them cleanly here is unnecessary. cryptsetup close on an
# NVMe-backed mapper waits for in-flight I/O to drain and has been
# observed to stall stage 3 for tens of seconds after swapoff, with
# no benefit since reboot follows immediately.
