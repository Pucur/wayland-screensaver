# Swayidle Inhibit Watcher v1.3 🚦

This handy little Bash script listens for screen saver inhibit events on Wayland and automatically stops or restarts `swayidle` accordingly.  

When something "inhibits" the screen (like a video player or presentation), the script stops `swayidle` to prevent your screen from locking or going to sleep. When the inhibition ends, it restarts `swayidle` with your preferred timeout settings.

## Changelog
v1.2b - The previouses version doesnt stopped/opened swayidle properly, now it seems OK but needs more time to test it out how its working in different cases.<br>
Please test it out is it working for you properly, if not, open a new isssue to discuss it.

---

## How it works

- Listens for `Inhibit` and `UnInhibit` signals on the DBus `org.freedesktop.ScreenSaver` interface.
- On `Inhibit` → stops `swayidle` completely 🔒
- On `Inhibit` from GameMode (`com.feralinteractive.GameMode`) → only screensaver runs, suspend disabled ⚠
- On `Inhibit` from any other application (e.g., YouTube in Chromium, VLC) → swayidle fully stopped
- On `UnInhibit` → restarts `swayidle` with the correct mode 🔓
- Monitors Tixati and GameMode activity continuously
- If Tixati or GameMode running → only screensaver mode
- If neither running and no other inhibit → full mode (screensaver + suspend)
- Logs activity state changes and relevant inhibit/uninhibit events to terminal
- Runs as a single process → only one PID appears in process lists

---

## Dependencies & Setup ⚙️

This script requires:

- `bash`  
- `dbus-monitor` (part of `dbus` package)  
- `swayidle` (Wayland idle management tool)  
- `xscreensaver-command` (for activating screensaver, optional)  

### 🧩 Dependencies

# Arch / Manjaro (pacman)
```bash
sudo pacman -S xscreensaver xscreensaver-extras xscreensaver-gl xscreensaver-data xscreensaver-data-extra swayidle
```
# Fedora (dnf)
```bash
sudo dnf install xscreensaver xscreensaver-extras xscreensaver-gl xscreensaver-gl-extra xscreensaver-data-extra swayidle
```
# CentOS / RHEL (yum)
```bash
sudo yum install xscreensaver xscreensaver-extras xscreensaver-gl xscreensaver-gl-extra xscreensaver-data-extra swayidle
```
# Debian / Ubuntu (apt)
```bash
sudo apt install xscreensaver xscreensaver-data xscreensaver-gl xscreensaver-gl-extra xscreensaver-data-extra swayidle
```
## Changelog 🔁
- Version 1.3
  More optimalised, better serial echoes.
  Fixed the .xscreensaver file, that caused all the issue.
- Version 1.2b
  Added new changes maybe that fix the issue that the screensaver always came up when fullscreen stuff is in the background.
- Version 1.1
  Wanted to fix issues but still doesnt worked well.
- Version 1.0
The first script, barely untested, not optimalised.
