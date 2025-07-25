#!/bin/bash

# Loop until xscreensaver is running
while true; do
    # Check if xscreensaver is already running
    if pgrep -x xscreensaver > /dev/null; then
        echo "✅ XScreenSaver is already running. Exiting wait loop."
        break
    fi

    # Set DISPLAY environment variable to :1
    export DISPLAY=:1
    # Find and export XAUTHORITY from current user's runtime directory
    export XAUTHORITY=$(find /run/user/$(id -u)/ -maxdepth 1 -name 'xauth_*' | head -n 1)

    # Start xscreensaver without splash screen, redirect output to /dev/null
    DISPLAY=:1 xscreensaver -no-splash > /dev/null 2>&1 &

    sleep 1

    # Check again if xscreensaver started successfully
    if pgrep -x xscreensaver > /dev/null; then
        echo "✅ XScreenSaver started successfully."
        break
    fi

    # If not started, wait 1 second and retry
    echo "❌ Failed to start xscreensaver. Retrying in 1 second..."
    sleep 1
done

inhibit_active=false

# Kill any existing swayidle processes quietly
pkill swayidle 2>/dev/null

echo "🚀 Starting swayidle and screensaver management"

# Start swayidle with two timeouts:
# - after 120s run 'xscreensaver-command -activate' (activate screensaver)
# - after 900s run 'systemctl suspend' (suspend the system)
swayidle -w timeout 120 'xscreensaver-command -activate' timeout 900 'systemctl suspend' &

# Function to monitor DBus for inhibit/uninhibit signals related to screen saver
monitor_inhibit() {
    while read -r line; do
        # Detect when an inhibit request is received (e.g., screen saver or suspend is blocked)
        if echo "$line" | grep -q "member=Inhibit"; then
            echo "🔒 Inhibit detected!"
            if [ "$inhibit_active" = false ]; then
                inhibit_active=true
                echo "⛔ Stopping swayidle..."
                pkill swayidle
            fi
        # Detect when inhibit is removed (allowing screen saver and suspend again)
        elif echo "$line" | grep -q "member=UnInhibit"; then
            echo "🔓 UnInhibit detected!"
            if [ "$inhibit_active" = true ]; then
                inhibit_active=false
                echo "▶ Restarting swayidle..."
                swayidle -w timeout 120 'xscreensaver-command -activate' timeout 900 'systemctl suspend' &
            fi
        fi
    done < <(dbus-monitor "interface='org.freedesktop.ScreenSaver'")
}

# Start monitoring inhibit events in the background
monitor_inhibit &

echo "✅ Script ready, background monitoring running."
