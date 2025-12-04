#!/usr/bin/env bash

while true; do
    if pgrep -x xscreensaver > /dev/null; then
        echo "✅ XScreenSaver is already running. Exiting wait loop."
        break
    fi

    export DISPLAY=:1
    export XAUTHORITY=$(find /run/user/$(id -u)/ -maxdepth 1 -name 'xauth_*' | head -n 1)

    DISPLAY=:1 xscreensaver -no-splash > /dev/null 2>&1 &
    sleep 1

    if pgrep -x xscreensaver > /dev/null; then
        echo "✅ XScreenSaver started successfully."
        break
    fi

    echo "❌ Failed to start xscreensaver. Retrying in 1 second..."
    sleep 1
done

# Kill existing swayidle and start it a fresh one
pkill swayidle 2>/dev/null
swayidle -w timeout 120 'xscreensaver-command -activate' timeout 900 'systemctl suspend' &

# ==============================
# VARIABLES
# ==============================
youtube_or_other_inhibit=false
last_activity_state="unknown"
POLL_INTERVAL=5

# ==============================
# FUNCTIONS
# ==============================
is_activity_running() {
    if pgrep -x "tixati" > /dev/null; then
        return 0
    fi
    if ! gamemoded -s 2>/dev/null | grep -q "inactive"; then
        return 0
    fi
    return 1
}

start_swayidle() {
    pkill swayidle 2>/dev/null

    if [ "$youtube_or_other_inhibit" = true ]; then
        return
    fi

    if is_activity_running; then
        pkill swayidle 2>/dev/null
        swayidle -w timeout 120 'xscreensaver-command -activate' &
    else
        swayidle -w timeout 120 'xscreensaver-command -activate' timeout 900 'systemctl suspend' &
    fi
}

# ==============================
# DBUS MONITOR LOOP
# ==============================
dbus-monitor --session "interface='org.freedesktop.ScreenSaver'" |
while read -r line; do

    if [[ "$line" =~ member=Inhibit ]]; then
        read -r nextline

        if [[ "$nextline" =~ "com.feralinteractive.GameMode" ]]; then
            start_swayidle
        else
            youtube_or_other_inhibit=true
            pkill swayidle
        fi

    elif [[ "$line" =~ member=UnInhibit ]]; then
        read -r nextline

        if ! [[ "$nextline" =~ "com.feralinteractive.GameMode" ]]; then
            youtube_or_other_inhibit=false
            start_swayidle
        fi
    fi

    # Poll Tixati/GameMode activity
    if [ $((SECONDS % POLL_INTERVAL)) -eq 0 ]; then
        if is_activity_running; then
            current_state="running"
        else
            current_state="stopped"
        fi

        if [ "$current_state" != "$last_activity_state" ]; then
            echo "Activity state changed → $current_state"
            start_swayidle
            last_activity_state="$current_state"
        fi
    fi
done
