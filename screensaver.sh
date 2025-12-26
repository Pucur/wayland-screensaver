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
# CONFIG
# ==============================

app=tixati # Put your custom app name here or leave it empty
suspendtime=900 # Start suspend in seconds
screensavertime=120 # Start screensaver in seconds
apptime=60 # Suggest to set it to half than the screensaver time
displaynumber=1 # Your display number (to get what display you using, type echo $DISPLAY in terminal)

# ==============================
# STATE FLAGS
# ==============================

current_state="NONE"
video_inhibit=false
last_uninhibit_time=0

pending_uninhibit=false
pending_uninhibit_time=0
uninhibit_confirm=10

initialized=0 # Run app search only once, set to 1 if you don't have any custom app

echo "༄˖°.🍃.ೃ࿔*:･ Swayidle Inhibit Watcher v1.7 ~~ Created by Pucur - 2025.12.26 ~~ https://github.com/Pucur/wayland-screensaver ༄˖°.🍃.ೃ࿔*:･"

stamp() {
    echo "[$(date '+%H:%M:%S')] $*"
}

# ==============================
# XScreenSaver
# ==============================

start_screensaver() {
while true; do
    if pgrep -x xscreensaver >/dev/null 2>&1; then
        stamp "🖼️ XScreenSaver is already running."
        break
    fi

    export DISPLAY=:$displaynumber
    export XAUTHORITY
    XAUTHORITY=$(find /run/user/$(id -u)/ -maxdepth 1 -name 'xauth_*' 2>/dev/null | head -n 1)

    xscreensaver -no-splash >/dev/null 2>&1 &
    sleep 1
done

}

pkill -f swayidle 2>/dev/null

# ==============================
# HELPERS
# ==============================

STATE_DIR="/tmp/swayidle_inhibit_watcher_state"
mkdir -p "$STATE_DIR"
FLAG_APP_ACTIVE="$STATE_DIR/app_active"

flag_set() { printf '%s' "$2" > "$1" 2>/dev/null; }
flag_get() { [ -f "$1" ] && cat "$1" 2>/dev/null || printf '%s' "$2"; }

flag_set "$FLAG_APP_ACTIVE" "0"

kill_swayidle() {
    pkill -f xscreensaver
    pkill -f swayidle 2>/dev/null
}

is_game_or_app_active() {
    [ "$(flag_get "$FLAG_APP_ACTIVE" "0")" = "1" ] && return 0
    if command -v gamemoded >/dev/null 2>&1; then
        gamemoded -s 2>/dev/null | grep -vq inactive && return 0
    fi
    return 1
}

force_app_refresh() {
    if pgrep -x "$app" >/dev/null 2>&1; then
        flag_set "$FLAG_APP_ACTIVE" "1"
    else
        flag_set "$FLAG_APP_ACTIVE" "0"
    fi
}

# ==============================
# MODES
# ==============================

start_screensaver_mode() {
    kill_swayidle
    start_screensaver
    stamp "🎮 Game / App running, starting screensaver without suspend"
    swayidle -w timeout "$screensavertime" 'xscreensaver-command -activate' >/dev/null 2>&1 &
    current_state="SCREENSAVER"
}

start_full_idle_mode() {
    kill_swayidle
    start_screensaver
    stamp "🏞️ No inhibit, normal idle with suspend"
    swayidle -w \
        timeout "$screensavertime" 'xscreensaver-command -activate' \
        timeout "$suspendtime" 'systemctl suspend' >/dev/null 2>&1 & # >/dev/null 2>&1 &
    current_state="FULL_IDLE"
}

# ==============================
# APP CHECK THREAD
# ==============================

if [[ $initialized -eq 0 ]]; then
    initialized=1
    (
        last="0"
        while true; do
            now="0"
            pgrep -x "$app" >/dev/null 2>&1 && now="1"

            flag_set "$FLAG_APP_ACTIVE" "$now"

            if [ "$now" = "1" ] && [ "$last" != "1" ]; then
                stamp "💻 App detected → inhibit suspend"
            elif [ "$now" = "0" ] && [ "$last" != "0" ]; then
                stamp "🏞️ App stopped → normal idle allowed"
            fi

            last="$now"
            sleep "$apptime"
        done
    ) &
fi

# ==============================
# MAIN LOOP
# ==============================

start_full_idle_mode

dbus-monitor --session "interface='org.freedesktop.ScreenSaver'" |
while true; do

    # --- POLLING ---
    if ! read -r -t 1 line; then

        if [ "$pending_uninhibit" = true ]; then
            if [ $(( $(date +%s) - pending_uninhibit_time )) -ge $uninhibit_confirm ]; then
                pending_uninhibit=false
                video_inhibit=false
            fi
        fi

        if [ "$video_inhibit" = true ]; then
            if [ "$current_state" != "VIDEO" ]; then
                kill_swayidle
                current_state="VIDEO"
            fi
            continue
        fi

        if is_game_or_app_active; then
            if [ "$current_state" != "SCREENSAVER" ]; then
                start_screensaver_mode
            fi
        else
            if [ "$current_state" != "FULL_IDLE" ]; then
                start_full_idle_mode
            fi
        fi

        continue
    fi

    # --- DBUS EVENTS ---
    if [[ "$line" =~ member=Inhibit ]]; then
        read -r nextline
        if ! [[ "$nextline" =~ GameMode ]]; then
            pending_uninhibit=false
            video_inhibit=true
            stamp "📺 VIDEO detected"
            kill_swayidle
            current_state="VIDEO"
        fi
    elif [[ "$line" =~ member=UnInhibit ]]; then
        read -r nextline
        if ! [[ "$nextline" =~ GameMode ]]; then
            pending_uninhibit=true
            pending_uninhibit_time=$(date +%s)
            last_uninhibit_time=$(date +%s)
            stamp "⏹️ VIDEO or APP stopped"
            force_app_refresh
        fi
    fi
done
