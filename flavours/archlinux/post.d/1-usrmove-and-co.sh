#!/bin/bash
set -eux

# Doing it here allows the container to be runnable/debuggable and Containerfile reusable
mv ${OSTREE_SYS_TREE}/etc ${OSTREE_SYS_TREE}/usr/

rm -r ${OSTREE_SYS_TREE}/home
ln -s /var/home ${OSTREE_SYS_TREE}/home

rm -r ${OSTREE_SYS_TREE}/mnt
ln -s /var/mnt ${OSTREE_SYS_TREE}/mnt

# We need /opt in the image because we might install software there, eg using yay
#rm -r ${OSTREE_SYS_TREE}/opt
#ln -s /var/opt ${OSTREE_SYS_TREE}/opt

rm -r ${OSTREE_SYS_TREE}/root
ln -s /var/roothome ${OSTREE_SYS_TREE}/root

rm -r ${OSTREE_SYS_TREE}/srv
ln -s /var/srv ${OSTREE_SYS_TREE}/srv

mkdir ${OSTREE_SYS_TREE}/sysroot
ln -s /sysroot/ostree ${OSTREE_SYS_TREE}/ostree

rm -r ${OSTREE_SYS_TREE}/usr/local
ln -s /var/usrlocal ${OSTREE_SYS_TREE}/usr/local

printf '%s\n' "Creating tmpfiles"
cat << EOF >> ${OSTREE_SYS_TREE}/usr/lib/tmpfiles.d/ostree-0-integration.conf
d /var/home 0755 root root -
d /var/lib 0755 root root -
d /var/log/journal 0755 root root -
d /var/mnt 0755 root root -
d /var/opt 0755 root root -
d /var/roothome 0700 root root -
d /var/srv 0755 root root -
d /var/usrlocal 0755 root root -
d /var/usrlocal/bin 0755 root root -
d /var/usrlocal/etc 0755 root root -
d /var/usrlocal/games 0755 root root -
d /var/usrlocal/include 0755 root root -
d /var/usrlocal/lib 0755 root root -
d /var/usrlocal/man 0755 root root -
d /var/usrlocal/sbin 0755 root root -
d /var/usrlocal/share 0755 root root -
d /var/usrlocal/src 0755 root root -
d /run/media 0755 root root -
EOF

# Only retain information about Pacman packages in new rootfs
mv ${OSTREE_SYS_TREE}/var/lib/pacman ${OSTREE_SYS_TREE}/usr/lib/
#mkdir /usr/lib/pacmanlocal
sed -i \
    -e "s|^#\(DBPath\s*=\s*\).*|\1/usr/lib/pacman|g" \
    -e "s|^#\(IgnoreGroup\s*=\s*\).*|\1modified|g" \
    ${OSTREE_SYS_TREE}/usr/etc/pacman.conf

# OSTree mounts /ostree/deploy/archlinux/var to /var
rm -r ${OSTREE_SYS_TREE}/var/*

# /usr/bin/newuidmap currently loses the setuid bit, not sure why
chmod u-s ${OSTREE_SYS_TREE}/usr/bin/new[gu]idmap
setcap cap_setuid+eip ${OSTREE_SYS_TREE}/usr/bin/newuidmap
setcap cap_setgid+eip ${OSTREE_SYS_TREE}/usr/bin/newgidmap
