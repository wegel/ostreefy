#!/bin/sh
set -eux

export OSTREE_SYS_BOOT_LABEL="${OSTREE_SYS_BOOT_LABEL:-SYS_BOOT}"
export OSTREE_SYS_ROOT_LABEL="${OSTREE_SYS_ROOT_LABEL:-SYS_ROOT}"
export OSTREE_SYS_VAR_LABEL="${OSTREE_SYS_VAR_LABEL:-SYS_VAR}"
export OSTREE_DEV_BOOT="${OSTREE_DEV_BOOT:-/dev/disk/by-label/$OSTREE_SYS_BOOT_LABEL}"
export OSTREE_DEV_ROOT="${OSTREE_DEV_ROOT:-/dev/disk/by-label/$OSTREE_SYS_ROOT_LABEL}"
export OSTREE_DEV_VAR="${OSTREE_DEV_VAR:-/dev/disk/by-label/$OSTREE_SYS_VAR_LABEL}"

check_programs() {
    for prog in "$@"; do
        if ! command -v "$prog" > /dev/null 2>&1; then
            echo "ERROR: Required program '$prog' is not installed."
            exit 1
        fi
    done
}

disk_create_layout() {
    parted -a optimal -s "$OSTREE_DEV_DISK" -- \
        mklabel gpt \
        mkpart "$OSTREE_SYS_BOOT_LABEL" fat32 0% 257MiB \
        set 1 esp on \
        mkpart "$OSTREE_SYS_ROOT_LABEL" xfs 257MiB 25GiB \
        mkpart "$OSTREE_SYS_VAR_LABEL" xfs 25GiB 100%
}

disk_create_format() {
    mkfs.vfat -n "$OSTREE_SYS_BOOT_LABEL" -F 32 "$OSTREE_DEV_BOOT"
    mkfs.xfs -L "$OSTREE_SYS_ROOT_LABEL" -f "$OSTREE_DEV_ROOT" -n ftype=1
    mkfs.xfs -L "$OSTREE_SYS_VAR_LABEL" -f "$OSTREE_DEV_VAR" -n ftype=1
}

# Check for required programs
check_programs mkfs.xfs mkfs.vfat parted

if [ -z "${OSTREE_DEV_DISK:-}" ]; then
    if [ -z "${OSTREE_DEV_BOOT:-}" ] || [ -z "${OSTREE_DEV_ROOT:-}" ] || [ -z "${OSTREE_DEV_VAR:-}" ]; then
        echo "ERROR: OSTREE_DEV_DISK or OSTREE_DEV_BOOT, OSTREE_DEV_ROOT, and OSTREE_DEV_VAR must be set"
        exit 1
    fi
else
    if [ -n "${OSTREE_DEV_BOOT:-}" ] || [ -n "${OSTREE_DEV_ROOT:-}" ] || [ -n "${OSTREE_DEV_VAR:-}" ]; then
        echo "ERROR: OSTREE_DEV_DISK and OSTREE_DEV_BOOT, OSTREE_DEV_ROOT, and OSTREE_DEV_VAR cannot be set at the same time"
        exit 1
    fi
fi

if [ -z "${OSTREE_DEV_DISK:-}" ]; then
    echo "Using $OSTREE_DEV_BOOT, $OSTREE_DEV_ROOT, and $OSTREE_DEV_VAR..."
else
    echo "Using $OSTREE_DEV_DISK..."
    read -r -p "WARNING: This will erase all data on $OSTREE_DEV_DISK. Are you sure? [y/N] " REPLY
    if [ ! "$REPLY" = "y" ] && [ ! "$REPLY" = "Y" ]; then
        exit 1
    fi
    disk_create_layout
fi

read -r -p "WARNING: This will erase all data on $OSTREE_DEV_BOOT, $OSTREE_DEV_ROOT, and $OSTREE_DEV_VAR. Are you sure? [y/N] " REPLY
if [ ! "$REPLY" = "y" ] && [ ! "$REPLY" = "Y" ]; then
    exit 1
fi
disk_create_format

echo "Done."
