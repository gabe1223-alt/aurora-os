# Aurora OS for Raspberry Pi 4 (4 GB)

A custom, flashable desktop image built with the official **pi-gen** system:
Raspberry Pi OS 64-bit (Debian trixie) + **KDE Plasma (X11)**, LightDM, Firefox ESR,
Discover (apt + Flatpak), Timeshift and a first-boot wizard.

> **Status: untested.** The project was written and syntax-checked without access to a Pi or
> a network, so the image has never been booted. Expect to fix a package name or two on the
> first build; the pi-gen log tells you exactly which. Section "Troubleshooting" lists the
> most likely spots.

## Layout

```
aurora-os/
├── build.sh                 one-command build (clones pi-gen, injects the stage, runs Docker)
├── config                   pi-gen config (release, hostname, stages, xz compression)
├── tools/make_assets.py     regenerates wallpapers + logo
├── TESTING.md               test checklist
└── stage-aurora/            custom pi-gen stage, runs after stage2 (Lite)
    ├── EXPORT_IMAGE  prerun.sh
    ├── 00-preseed/          debconf: LightDM as display manager
    ├── 01-packages/         every apt package (no-recommends)
    ├── 02-overlay/          00-run.sh copies files/ into the image
    │   └── files/           etc/, usr/lib/aurora/, usr/bin/, skel defaults, themes, wallpapers
    ├── 03-configure/        chroot step: locales, services, Plymouth, zram, Flathub
    └── 04-boot/             cmdline.txt / config.txt: quiet splash + recovery entry
```

## Build

Requirements: Linux host (x86-64 or arm64), Docker, git, openssl, ~30 GB free disk, internet.
On x86 hosts also install `qemu-user-static binfmt-support`.

```bash
cd aurora-os
./build.sh            # first build: 1-3 hours
./build.sh --clean    # discard the previous build container and start over
CONTINUE=1 ./build.sh # resume a failed build
```

Result: `out/<date>-Aurora.img.xz` (+ `.info`). The pi-gen branch is `arm64`; override with
`PIGEN_BRANCH=<branch> ./build.sh` if Raspberry Pi renames it. It must match `RELEASE` in `config`.

## Flash

Raspberry Pi Imager → *Choose OS → Use custom* → pick the `.img.xz` → choose the SD card
(16 GB or larger). **Leave "OS customisation" off**: Aurora has its own wizard, and Imager's
cloud-init settings would bypass it. balenaEtcher also works.

## First boot

1. The splash shows, then the root filesystem expands to fill the card (one extra reboot may happen).
2. The wizard starts by itself: language → account (name, username, password) → Wi-Fi (optional) →
   time zone → Finish.
3. The wizard creates your account, sets locale, keyboard, time zone and Wi-Fi, pre-configures
   Timeshift, deletes the temporary `aurora-setup` account and shows the login screen.
4. Log in. The panel layout is applied once, a few seconds after the desktop appears.

There is no default password: the setup account is locked, passwordless sudo is removed, and SSH is off.

## What provides what

| Requirement | Implementation |
|---|---|
| Boot splash | Plymouth theme `aurora` (script module), `quiet splash` on the kernel line |
| Login screen | LightDM + gtk-greeter (Breeze-Dark, Aurora wallpaper, power menu) |
| First-boot wizard | `aurora-firstboot-wizard` (PyQt6) + root helper `apply-setup` via polkit |
| Lock / logout / shutdown / restart | Plasma start menu "Leave", lock after 10 min (`kscreenlockerrc`) |
| Taskbar, start menu, app grid | Panel script: Kickoff + Application Dashboard + task manager + tray + clock/calendar |
| Desktop icons | `/etc/skel/Desktop`: Home, Trash, Files, Browser, Settings |
| Notifications | Plasma notification daemon + tray |
| Files, search, USB | Dolphin, Baloo (names only, low RAM), udisks2 + Plasma auto-mount |
| Text editor | Mousepad |
| Browser | Firefox ESR, DuckDuckGo, bookmarks toolbar, policies in `/etc/firefox/policies` |
| Network | NetworkManager + Plasma tray applet (Wi-Fi power-save off) |
| App store | KDE Discover with apt (PackageKit) and Flatpak/Flathub |
| Settings | KDE System Settings (wallpaper, theme, language, sound, display, network, date/time, users) + **Aurora Control** (username, updates, CPU profile, memory, storage, backup, logs, recovery) |
| Themes | Global themes *Aurora Dark* / *Aurora Light*, 3 wallpapers, "Switch Light/Dark" menu entry |
| Task manager | Plasma System Monitor (Ctrl+Esc) |
| Storage | Aurora Control, Filelight, GParted, clean-up button |
| Memory | zram (RAM/2), swappiness 100, page-cluster 0, earlyoom |
| Updates | Discover updates, unattended security updates (toggle in Aurora Control) |
| Error handling | systemd watchdog (10 s), persistent journald, `OnFailure` desktop notifications, DrKonqi + coredump |
| Recovery | `reboot "0 tryboot"` → `cmdline-recovery.txt` → `aurora-recovery.target` (whiptail menu on tty1) |
| Backup | Timeshift (pre-configured, rsync) + rsync-based home backup/restore in Aurora Control |
| Power | CPU governor profiles (persistent), DPMS/blanking via Plasma Energy Saving |

## Measure the targets

```bash
systemd-analyze                     # boot time (goal < 30 s)
free -m                             # idle RAM after 2 min on the desktop (goal < 700 MB used)
ps -eo rss,comm --sort=-rss | head  # biggest consumers
```
**Expect Plasma to miss both goals** (roughly 0.9-1.3 GB idle, 35-50 s boot on a good card).
Cheap wins if you want to push further: disable Bluetooth (`systemctl disable bluetooth`),
turn off Baloo (`balooctl6 disable`), set the compositor to XRender in Display settings,
use a fast A2 SD card or USB SSD.

## Troubleshooting

* **Build stops with `E: Unable to locate package X`**: the name differs in your pi-gen release; fix it in
  `stage-aurora/01-packages/00-packages-nr` and run `CONTINUE=1 ./build.sh`.
* **`build-docker.sh` complains about the container name**: `./build.sh --clean`.
* **Wrong pi-gen branch / release mismatch**: set `PIGEN_BRANCH` and `RELEASE` together.
* **No splash**: check `lsinitramfs /boot/firmware/initramfs* | grep plymouth` and that `auto_initramfs=1` is in `config.txt`.
* **Black screen after boot**: switch to tty2 (Ctrl+Alt+F2), read `journalctl -b -u lightdm` and `~/.xsession-errors`.
* **Wizard does not appear**: `/etc/lightdm/lightdm.conf.d/60-aurora-firstboot.conf` must exist and the user `aurora-setup` must exist.
* **Panel looks like stock Plasma**: delete `~/.config/aurora/layout-applied` and log in again.
* **Wi-Fi invisible**: set the country code in the wizard (Raspberry Pi keeps Wi-Fi blocked until it is set).
* **Recovery mode does nothing**: update the bootloader (`sudo rpi-eeprom-update -a`); tryboot needs a recent EEPROM.
  Fallback: copy `/boot/firmware/cmdline-recovery.txt` over `cmdline.txt` from another computer.
* **Re-run the wizard**: boot into recovery, option 6.

## Limitations

See the end of `TESTING.md`.
