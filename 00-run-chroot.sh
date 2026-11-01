#!/bin/bash -e
export DEBIAN_FRONTEND=noninteractive

echo "== locales"
python3 - <<'PY'
import json
with open("/etc/locale.gen", "a") as fh:
    for l in json.load(open("/usr/share/aurora/languages.json")):
        fh.write(l["locale"] + " UTF-8\n")
PY
locale-gen

echo "== LightDM + Plasma session"
SESSION=plasmax11
[ -f /usr/share/xsessions/plasmax11.desktop ] || SESSION=plasma
cat > /etc/lightdm/lightdm.conf.d/50-aurora.conf <<EOF
[Seat:*]
greeter-session=lightdm-gtk-greeter
user-session=${SESSION}
allow-guest=false
greeter-hide-users=false
EOF
echo /usr/sbin/lightdm > /etc/X11/default-display-manager
systemctl enable lightdm.service
systemctl set-default graphical.target

echo "== no default account: lock the pi-gen setup user, drop passwordless sudo"
if id aurora-setup >/dev/null 2>&1; then
	passwd -l aurora-setup
	gpasswd -d aurora-setup sudo || true
fi
rm -f /etc/sudoers.d/*nopasswd* /etc/sudoers.d/010_*
systemctl mask userconfig.service ModemManager.service || true
systemctl disable NetworkManager-wait-online.service || true

echo "== Plymouth"
plymouth-set-default-theme aurora
update-initramfs -u -k all || echo "WARN: initramfs update failed (splash will start later in boot)"

echo "== memory: zram"
if dpkg -s rpi-swap >/dev/null 2>&1; then
	echo "rpi-swap present: it already provides zram swap"
else
	apt-get install -y --no-install-recommends systemd-zram-generator
	apt-get purge -y dphys-swapfile 2>/dev/null || true
	cat > /etc/systemd/zram-generator.conf <<EOF
[zram0]
zram-size = ram / 2
swap-priority = 100
fs-type = swap
EOF
fi

echo "== enable our services"
for u in aurora-cpufreq.service aurora-flathub.service aurora-rename-user.service \
	earlyoom.service cron.service unattended-upgrades.service; do
	systemctl enable "$u" || echo "WARN: could not enable $u"
done

echo "== Flathub (best effort now, the service retries on the device)"
if flatpak remote-add --system --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo; then
	touch /var/lib/aurora/flathub-added
fi
appstreamcli refresh-cache --force || true

echo "== defaults"
update-alternatives --set x-www-browser /usr/bin/firefox-esr || true
update-alternatives --set gnome-www-browser /usr/bin/firefox-esr || true
gtk-update-icon-cache -f /usr/share/icons/hicolor || true
update-desktop-database || true
fc-cache -f || true
