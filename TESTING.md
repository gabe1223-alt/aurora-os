# Test checklist

Tick each item on a real Pi 4 (4 GB) with a freshly flashed card.

## 1. Startup & login
- [ ] Aurora splash (pulsing logo) appears, no kernel text visible
- [ ] Filesystem expanded: `df -h /` shows the whole card
- [ ] Wizard starts unattended; every page works; Back/Next work
- [ ] Short or mismatched password blocks "Next"; invalid username blocks "Next"
- [ ] Wi-Fi scan lists networks (after country code) and the Pi connects
- [ ] After Finish: login screen shows the new user, **not** `aurora-setup`
- [ ] `sudo passwd -S aurora-setup` → unknown user; `ls /etc/sudoers.d` has no NOPASSWD file
- [ ] Wrong password is rejected, correct one logs in
- [ ] Start menu → Leave: Lock, Log out, Restart, Shut down all work
- [ ] Meta+L locks; unlock needs the password; auto-lock triggers after 10 min idle

## 2. Desktop
- [ ] Bottom panel with start button, grid button, window list, tray, clock with date
- [ ] Grid button opens fullscreen app grid; start button opens the menu
- [ ] Clock click shows the calendar
- [ ] Desktop icons: Home, Trash, Files, Browser, Settings all open
- [ ] `notify-send hello` shows a popup and appears in the tray history

## 3. Files
- [ ] Dolphin: new folder, rename, copy/paste, move, delete → Trash, restore from Trash
- [ ] Search (Ctrl+F in Dolphin, and Alt+Space KRunner) finds a freshly created file within ~1 min
- [ ] Mousepad: create, edit, save, reopen
- [ ] USB stick auto-mounts and appears in Dolphin; eject works; exFAT/NTFS sticks work

## 4. Internet
- [ ] Firefox ESR starts, DuckDuckGo is default, bookmarks toolbar visible
- [ ] Download a file to ~/Downloads; upload a file in a web form (file dialog works)
- [ ] Tray applet connects/disconnects Wi-Fi; Ethernet connects on plug-in

## 5. Applications
- [ ] Discover lists apps from Debian and Flathub
- [ ] Install and uninstall one Flatpak app (for example Calculator) and one apt app
- [ ] Alt+Tab switches windows; taskbar entries focus/minimise/close windows

## 6. Settings
- [ ] System Settings: wallpaper changes (3 Aurora wallpapers present)
- [ ] Global Theme: Aurora Light / Aurora Dark switch; "Switch Light/Dark Theme" menu entry works
- [ ] Users: change password, then log out and in with it
- [ ] Aurora Control → Account: schedule username change, reboot, log in with the new name, files intact
- [ ] Language & region, Sound (HDMI/headphone output), Display (resolution, scale), Network, Date & time all open and apply

## 7. System management
- [ ] Ctrl+Esc opens System Monitor; process list, CPU and RAM graphs, kill a test process (`sleep 999`)
- [ ] Aurora Control → Storage: usage bar, Clean up, Empty Trash, Filelight, GParted open
- [ ] `swapon --show` lists `/dev/zram0`; `sysctl vm.swappiness` = 100; Aurora Control → Memory matches
- [ ] Discover → Updates works; toggle automatic updates, `cat /etc/apt/apt.conf.d/20auto-upgrades` changes
- [ ] `systemctl show -p RuntimeWatchdogUSec` = 10s
- [ ] `sudo systemctl kill -s KILL cron` → "A system service stopped unexpectedly" notification
- [ ] Run `kill -SEGV $(pgrep -n konsole)` → DrKonqi crash notification
- [ ] Aurora Control → Logs: all four filters show output
- [ ] Recovery: "Reboot into Recovery Mode" shows the whiptail menu; "Reboot normally" returns to the desktop and the *next* boot is normal
- [ ] Timeshift opens already configured; create a snapshot; list it in recovery menu option 3
- [ ] Aurora Control → Backup: back up to a USB stick, delete a file, restore it
- [ ] Aurora Control → Power: switch to Performance, reboot, `cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor`
- [ ] Energy Saving page: screen dims and turns off after the configured time

## 8. Constraints
- [ ] `systemd-analyze` ≤ 30 s (expected to miss with Plasma; record the real number)
- [ ] `free -m` used ≤ 700 MB after 2 min idle (expected to miss; record the real number)
- [ ] Image fits on a 16 GB card

## Limitations / closest alternatives
1. **Not built or booted by the author.** Package names, a few KDE config keys and the
   panel script are written from knowledge of Debian trixie / Plasma 6.3 and need a real test.
2. **RAM and boot-time goals** are unlikely with Plasma; use XFCE if they are hard requirements.
3. **One Settings app**: System Settings plus Aurora Control. A single window would need C++ KCM plugins.
4. **File manager**: Dolphin instead of Thunar/PCManFM-Qt (native to Plasma). Mousepad is kept as requested (GTK).
5. **Username change** needs a reboot; absolute `/home/old` paths are rewritten in `~/.config` and
   `~/.local/share` only.
6. **Battery/sleep**: the Pi 4 has no battery or reliable suspend; the power menu offers
   lock, log out, restart, shut down. A battery appears only with a UPS HAT supported by UPower.
7. **Recovery** is a one-shot `tryboot` entry, not a boot menu (the Pi bootloader has none). Needs a recent EEPROM.
8. **Timeshift** snapshots go to the SD card itself by default; point it at a USB drive for real protection.
9. **Wizard UI is English only**; the chosen language applies to the installed system (12 locales).
   Firefox language packs and KDE translations beyond what the packages ship are not added.
10. **Wayland** is not used (X11 session) for stability on VideoCore VI.
11. **Panel layout** is applied by script at first login, so you may see the default panel for a moment.
12. Do not use Raspberry Pi Imager's OS customisation; it bypasses the wizard.
