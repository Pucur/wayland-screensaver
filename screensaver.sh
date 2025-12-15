#!/usr/bin/env bash
# _       _                _                      _
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

app=tixati # Put your custom app name here or leave it empty
suspendtime=900 # Start suspend in minute
screensavertime=120 # Start screensaver in minute
apptime=60 # Suggest to set it to half than the screensaver time
initialized=0 # Run app search only once, set to 1 if you don't have any custom app
displaynumber=1 # Your display number (to get what display you using, type echo $DISPLAY in terminal)
activity_active=0 # Start app thread only once, don't modify it
inhibit=false # Inhibit check

echo "༄˖°.🍃.ೃ࿔*:･ Swayidle Inhibit Watcher v1.5 ~~ Created by Pucur - 2025.12.15 ~~ https://github.com/Pucur/wayland-screensaver ༄˖°.🍃.ೃ࿔*:･"

# Timestamp for echoes
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

    export DISPLAY=:$displaynumber
    export XAUTHORITY=$(find /run/user/$(id -u)/ -maxdepth 1 -name 'xauth_*' | head -n 1)

    DISPLAY=:$displaynumber xscreensaver -no-splash > /dev/null 2>&1 &
    sleep 1

    if pgrep -x xscreensaver > /dev/null; then
        stamp "✅ XScreenSaver started successfully."
        break
    fi

    stamp "❌ Failed to start xscreensaver. Retrying in 1 second ..."
    sleep 1
done

# Kill existing swayidle at start
pkill swayidle 2>/dev/null
# ==============================
# APP CHECK
# ==============================

if [[ $initialized -eq 0 ]]; then
    initialized=1
    (
    while true; do
        if pgrep -x "$app" > /dev/null; then
            if [[ $activity_active -eq 0 ]]; then
                activity_active=1
                stamp "💻 Application running, starting screensaver without suspend ..."
                pkill swayidle
                swayidle -w timeout $screensavertime 'xscreensaver-command -activate' 2>/dev/null &
            fi
        else
            if [[ $activity_active -eq 1 ]]; then
                activity_active=0
                stamp "🏞️ No inhibit, normal idle with suspend (if there is no video playing on top) ..."
                pkill swayidle
                swayidle -w timeout $screensavertime 'xscreensaver-command -activate' timeout $suspendtime 'systemctl suspend' 2>/dev/null &
            fi
        fi
        sleep $apptime
    done
    ) &
fi

# ==============================
# DBUS MONITOR LOOP
# ==============================

last_activity_state="INIT"
inhibit=false

dbus-monitor --session "interface='org.freedesktop.ScreenSaver'" |
while read -r line; do

    # ---- Inhibit figyelés (nem GameMode) ----
    if [[ "$line" =~ member=Inhibit ]]; then
        read -r nextline
        if ! [[ "$nextline" =~ "com.feralinteractive.GameMode" ]]; then
            inhibit=true
        fi
    elif [[ "$line" =~ member=UnInhibit ]]; then
        read -r nextline
        if ! [[ "$nextline" =~ "com.feralinteractive.GameMode" ]]; then
            inhibit=false
        fi
    fi
    if gamemoded -s 2>/dev/null | grep -vq "inactive"; then
        new_state="GAME"

    elif $inhibit || pgrep -x "$app" > /dev/null; then
        new_state="APP"
    else
        new_state="IDLE"
    fi
    if [ "$new_state" != "$last_activity_state" ]; then
        pkill swayidle 2>/dev/null
        case "$new_state" in
            GAME)
                stamp "🎮 Game running, starting screensaver without suspend ..."
                swayidle -w timeout "$screensavertime" 'xscreensaver-command -activate' 2>/dev/null &
                ;;

            APP)
                stamp "💻 Application or inhibit active, starting screensaver without suspend ..."
                swayidle -w timeout $screensavertime 'xscreensaver-command -activate' 2>/dev/null &
                ;;

            IDLE)
                stamp "🏞️ No inhibit, normal idle with suspend (if there is no video playing on top) ..."
                swayidle -w timeout "$screensavertime" 'xscreensaver-command -activate' timeout 900 'systemctl suspend' 2>/dev/null &
                ;;
        esac
        last_activity_state="$new_state"
    fi
done
