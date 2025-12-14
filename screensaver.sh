#!/usr/bin/env bash

 _       _                _                      _
# ( )  _  ( )              (_ )                   ( )
# | | ( ) | |   _ _  _   _  | |    _ _   ___     _| |     ___    ___  _ __   __     __    ___    ___    _ _  _   _    __   _ __
# | | | | | | /'_` )( ) ( ) | |  /'_` )/' _ `\ /'_` |   /',__) /'___)( '__)/'__`\ /'__`\/' _ `\/',__) /'_` )( ) ( ) /'__`\( '__)
# | (_/ \_) |( (_| || (_) | | | ( (_| || ( ) |( (_| |   \__, \( (___ | |  (  ___/(  ___/| ( ) |\__, \( (_| || \_/ |(  ___/| |
# `\___x___/'`\__,_)`\__, |(___)`\__,_)(_) (_)`\__,_)   (____/`\____)(_)  `\____)`\____)(_) (_)(____/`\__,_)`\___/'`\____)(_)
#                   ( )_| |
#                   `\___/'

# ==============================
# VARIABLES
# ==============================

inhibit=false
last_activity_state="unknown"
app=tixati # Put your custom app name here or leave it empty

echo "༄˖°.🍃.ೃ࿔*:･ Swayidle Inhibit Watcher v1.3 ~~ Created by Pucur - 2025.12.14 ~~ https://github.com/Pucur/wayland-screensaver ༄˖°.🍃.ೃ࿔*:･"

# Timestamp
stamp() {
    echo "[$(date '+%H:%M:%S')] $*"
}

# ==============================
# Start XscreenSaver
# ==============================

while true; do
    if pgrep -x xscreensaver > /dev/null; then
        stamp "✅ XScreenSaver is already running. Exiting wait loop."
        break
    fi

    export DISPLAY=:1
    export XAUTHORITY=$(find /run/user/$(id -u)/ -maxdepth 1 -name 'xauth_*' | head -n 1)

    DISPLAY=:1 xscreensaver -no-splash > /dev/null 2>&1 &
    sleep 1

    if pgrep -x xscreensaver > /dev/null; then
        stamp "✅ XScreenSaver started successfully."
        break
    fi

    stamp "❌ Failed to start xscreensaver. Retrying in 1 second ..."
    sleep 1
done

# Kill existing swayidle and start it a fresh one
pkill swayidle 2>/dev/null
swayidle -w timeout 120 'xscreensaver-command -activate' timeout 900 'systemctl suspend' 2>/dev/null &

# ==============================
# FUNCTIONS
# ==============================

# Detecting custom app or game mode is running or not
is_activity_running() {
    if pgrep -x "$app" > /dev/null; then
        return 0
    fi
    if ! gamemoded -s 2>/dev/null | grep -q "inactive"; then
        return 0
    fi
    return 1
}

# Determine which screensaver mod to start
start_swayidle() {
    pkill swayidle 2>/dev/null

    if [ "$youtube_or_other_inhibit" = true ]; then
        return
    fi

    if is_activity_running; then

        # When only game or app running
        pkill swayidle 2>/dev/null
        stamp "🎮 No video inhibit, starting Game mode screensaver ..."
        swayidle -w timeout 120 'xscreensaver-command -activate' 2>/dev/null &
        pkill -f "xscreensaver-gfx"
    else
        # When no process is running

        stamp "🏞️ No video inhibit, no game running, starting screensaver ..."
        swayidle -w timeout 120 'xscreensaver-command -activate' timeout 900 'systemctl suspend' 2>/dev/null &
        pkill -f "xscreensaver-gfx"
    fi
}

# ==============================
# DBUS MONITOR LOOP
# ==============================
dbus-monitor --session "interface='org.freedesktop.ScreenSaver'" |
while read -r line; do

    # When only game or app running
    if [[ "$line" =~ member=Inhibit ]]; then
        read -r nextline

        if [[ "$nextline" =~ "com.feralinteractive.GameMode" ]]; then
            start_swayidle
        else
        stamp "📺 Video playing, turning screensaver off ..."
            inhibit=true
            pkill swayidle
            pkill -f "xscreensaver-gfx"
        fi

    # When no process is running
    elif [[ "$line" =~ member=UnInhibit ]]; then
        read -r nextline
        if ! [[ "$nextline" =~ "com.feralinteractive.GameMode" ]]; then
            inhibit=false
                start_swayidle
        fi
    fi

    # Check state change
        if is_activity_running; then
            current_state="running"
        else
            current_state="stopped"
        fi

        if [ "$current_state" != "$last_activity_state" ]; then
            stamp "🚩 Activity state changed → $current_state"
            start_swayidle
            last_activity_state="$current_state"
        fi
done
