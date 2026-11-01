#!/bin/bash -e
# Copy the overlay tree into the image and fix permissions.
cp -a files/. "${ROOTFS_DIR}/"

chmod 755 "${ROOTFS_DIR}"/usr/lib/aurora/*
chmod 755 "${ROOTFS_DIR}/usr/bin/aurora-control" "${ROOTFS_DIR}/usr/bin/aurora-firstboot-wizard"
chmod 755 "${ROOTFS_DIR}"/etc/skel/Desktop/*.desktop
chmod 644 "${ROOTFS_DIR}/etc/lightdm/lightdm.conf.d/60-aurora-firstboot.conf"

for d in Documents Downloads Music Pictures Videos; do
	install -d -m 755 "${ROOTFS_DIR}/etc/skel/${d}"
done
install -d -m 755 "${ROOTFS_DIR}/var/lib/aurora"
