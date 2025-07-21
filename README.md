🛑 Screensaver support for Wayland window manager 🎉
This little Bash helper watches your system’s DBus for screen saver events — specifically, when something inhibits or un-inhibits the screen idle (like when you’re watching a video or doing a presentation).

What does it do? 🤔
When it spots an Inhibit event 🔒, it pauses swayidle so your screen won’t dim or go to sleep.

When it spots an UnInhibit event 🔓, it restarts swayidle with your usual timers ⏰, letting your screen go idle and eventually suspend again.

Why is this handy? ✨
Sometimes apps want to keep your screen awake (think Netflix binge or important slides). This script makes sure your screen behaves nicely — no annoying blackouts while you’re focused, but it still respects your power-saving preferences once the action’s over.

Dependencies 📦
Make sure these are installed on your system to run the script smoothly:

Distribution	Packages to install
Arch Linux	swayidle, dbus, xscreensaver
Fedora (Wayland)	swayidle, dbus, xscreensaver
Ubuntu (Wayland)	swayidle, dbus-user-session, xscreensaver
Debian (Wayland)	swayidle, dbus-user-session, xscreensaver

You’ll also want to make sure bash is available (almost always installed by default).

How to use? 🚀
Just run it in the background:

bash
Copy
Edit
./inhibit-monitor.sh
Make sure the script is executable:

bash
Copy
Edit
chmod +x inhibit-monitor.sh
