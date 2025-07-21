#!/bin/bash
inhibit_active=false
pkill swayidle
xscreensaver --nosplash > /dev/null 2>&1 &
echo "🚀Starting Screensaver"
swayidle -w timeout 120 'xscreensaver-command -activate' timeout 900 'systemctl suspend' &
while read -r line; do
    if echo "$line" | grep -q "member=Inhibit"; then
        echo "🔒 Inhibit detected!"
        if [ "$inhibit_active" = false ]; then
            inhibit_active=true
            echo "⛔ Stopping swayidle..."
            pkill swayidle
        fi
    elif echo "$line" | grep -q "member=UnInhibit"; then
        echo "🔓 UnInhibit detected!"
        if [ "$inhibit_active" = true ]; then
            inhibit_active=false
            echo "▶ Restarting swayidle..."
            swayidle -w timeout 120 'xscreensaver-command -activate' timeout 900 'systemctl suspend' &
        fi
    fi
done < <(dbus-monitor "interface='org.freedesktop.ScreenSaver'")
