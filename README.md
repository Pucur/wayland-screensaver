# Wayland Swayidle Inhibit Watcher v1.5 🚦

This handy little Bash script listens for screen saver inhibit events on Wayland and automatically stops or restarts `swayidle` accordingly.  

When something "inhibits" the screen (like a video player or presentation), the script stops `swayidle` to prevent your screen from locking or going to sleep. When the inhibition ends, it restarts `swayidle` with your preferred timeout settings.

Tested on `Arch Linux 6.17.9-arch1-1 ~~ KDE Plasma 6.5.4 kwin`

# Notes on Swayidle behavior

At the beginning, about half a year ago, I didn’t know much about swayidle, but I feel that by now I’ve pretty much figured out all of its behavior.

Sometimes the screensaver starts in a slightly odd way or not exactly when you would expect it to, but this is not a bug in the script — it’s simply how swayidle works.

For example:

If Chrome is open and some kind of media player is running in the background (on another tab), swayidle will not start counting idle time, because it considers the process active. It only starts counting once the window is minimized to the taskbar.

GameMode inhibition is a different story: even though GameMode uses inhibit, it does not affect swayidle. swayidle will still count idle time even when a game is running in fullscreen — which I actually think is a really good thing.

Because of this, the earlier “kill swayidle for everything” approach didn’t really make sense. That’s why this script has gone through several hours (actually several days… but don’t tell my wife 😄) of testing. I hope this version finally eliminates the issues that existed in the previous script.

If you do find any bugs, feel free to report them in the Issues section!

---

## How it works

- Listens for `Inhibit` and `UnInhibit` signals on the DBus `org.freedesktop.ScreenSaver` interface.
- On `Inhibit` → stops `swayidle` completely 🔒
- On `Inhibit` from GameMode (`com.feralinteractive.GameMode`) → only screensaver runs, suspend disabled ⚠
- On `Inhibit` from any other application (e.g., YouTube in Chromium, VLC) → swayidle fully stopped (if its on the Top screen not in the tray)
- On `UnInhibit` → restarts `swayidle` with the correct mode 🔓
- Monitors Custom apps and GameMode activity continuously
- If custom apps or GameMode running → only screensaver mode
- If neither running and no other inhibit → full mode (screensaver + suspend)
- Logs activity state changes and relevant inhibit/uninhibit events to terminal
- Runs as a single process → it will appears 3 PID in process lists (one the main app, one for the DBUS monitor, and the last is for the custom app checker)

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
- Version 1.5 Brand new app as I can say, I learend a much about swayidle, now the code is simplier, faster, stronger, better. Added more easier variables to set up, more transparent than before.
- Version 1.3
  More optimalised, better serial echoes.
  Fixed the .xscreensaver file, that caused all the issue.
- Version 1.2b
  The previouses version doesnt stopped/opened swayidle properly, now it seems OK but needs more time to test it out how its working in different cases.<br>
  Please test it out is it working for you properly, if not, open a new isssue to discuss it.
- Version 1.1
  Wanted to fix issues but still doesnt worked well.
- Version 1.0
The first script, barely untested, not optimalised.
