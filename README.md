# Swayidle Inhibit Watcher 🚦

This handy little Bash script listens for screen saver inhibit events on Wayland and automatically stops or restarts `swayidle` accordingly.  

When something "inhibits" the screen (like a video player or presentation), the script stops `swayidle` to prevent your screen from locking or going to sleep. When the inhibition ends, it restarts `swayidle` with your preferred timeout settings.

---

## How it works

- Listens for `Inhibit` and `UnInhibit` signals on the DBus `org.freedesktop.ScreenSaver` interface  
- On `Inhibit` → stops `swayidle` to keep your session active 🔒  
- On `UnInhibit` → restarts `swayidle` with your custom timeout settings 🔓  

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
sudo pacman -S xscreensaver xscreensaver-extras xscreensaver-gl xscreensaver-data xscreensaver-data-extra
```
# Fedora (dnf)
```bash
sudo dnf install xscreensaver xscreensaver-extras xscreensaver-gl xscreensaver-gl-extra xscreensaver-data-extra
```
# CentOS / RHEL (yum)
```bash
sudo yum install xscreensaver xscreensaver-extras xscreensaver-gl xscreensaver-gl-extra xscreensaver-data-extra
```
# Debian / Ubuntu (apt)
```bash
sudo apt install xscreensaver xscreensaver-data xscreensaver-gl xscreensaver-gl-extra xscreensaver-data-extra
```
