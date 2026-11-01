#!/bin/bash -e
# Quiet boot + Plymouth splash + one-shot recovery entry (tryboot).
for dir in boot/firmware boot; do
	CMD="${ROOTFS_DIR}/${dir}/cmdline.txt"
	CFG="${ROOTFS_DIR}/${dir}/config.txt"
	[ -f "$CMD" ] && [ -f "$CFG" ] && break
done
[ -f "$CMD" ] || { echo "cmdline.txt not found"; exit 1; }

sed -i -e 's/console=tty1/console=tty3/' -e 's/[[:space:]]*$//' "$CMD"
for opt in quiet splash plymouth.ignore-serial-consoles logo.nologo vt.global_cursor_default=0; do
	grep -qw -- "$opt" "$CMD" || sed -i "1 s/\$/ ${opt}/" "$CMD"
done

# Recovery cmdline: same root, no splash, boots the recovery target.
sed -E -e 's/ (quiet|splash|plymouth\.ignore-serial-consoles|logo\.nologo|vt\.global_cursor_default=0)//g' \
	-e 's/ init=[^ ]+//' -e 's/console=tty3/console=tty1/' "$CMD" > "$(dirname "$CMD")/cmdline-recovery.txt"
sed -i '1 s/$/ systemd.unit=aurora-recovery.target plymouth.enable=0/' "$(dirname "$CMD")/cmdline-recovery.txt"

grep -q '^auto_initramfs' "$CFG" || printf '\n[all]\nauto_initramfs=1\n' >> "$CFG"
cat >> "$CFG" <<'EOF'

# --- Aurora ---
[all]
disable_splash=1
boot_delay=0

[tryboot]
cmdline=cmdline-recovery.txt

[all]
EOF
