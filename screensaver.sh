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
grace_time=5 # Minimum 5 seconds recommended
apptime=60 # Suggest to set it to half than the screensaver time
displaynumber=1 # Your display number (to get what display you using, type echo $DISPLAY in terminal)

# ==============================
# STATE FLAGS
# ==============================

current_state="NONE"
video_inhibit=false
grace_start_time=0

initialized=0 # Run app search only once, set to 1 if you don't have any custom app

echo "༄˖°.🍃.ೃ࿔*:･ Swayidle Inhibit Watcher v1.6 ~~ Created by Pucur - 2025.12.19 ~~ https://github.com/Pucur/wayland-screensaver ༄˖°.🍃.ೃ࿔*:･"

stamp() {
    echo "[$(date '+%H:%M:%S')] $*"
}

# ==============================
# XScreenSaver
# ==============================

while true; do
    if pgrep -x xscreensaver >/dev/null 2>&1; then
        stamp "✅ XScreenSaver is already running."
        break
    fi

    export DISPLAY=:$displaynumber
    export XAUTHORITY
    XAUTHORITY=$(find /run/user/$(id -u)/ -maxdepth 1 -name 'xauth_*' 2>/dev/null | head -n 1)

    xscreensaver -no-splash >/dev/null 2>&1 &
    sleep 1
done

pkill -f swayidle 2>/dev/null

# ==============================
# HELPERS
# ==============================

STATE_DIR="/tmp/swayidle_inhibit_watcher_state"
mkdir -p "$STATE_DIR"
FLAG_APP_ACTIVE="$STATE_DIR/app_active"
FLAG_APP_BLOCK_GRACE="$STATE_DIR/app_block_grace"

flag_set() { printf '%s' "$2" > "$1" 2>/dev/null; }
flag_get() { [ -f "$1" ] && cat "$1" 2>/dev/null || printf '%s' "$2"; }

flag_set "$FLAG_APP_ACTIVE" "0"
flag_set "$FLAG_APP_BLOCK_GRACE" "0"

kill_swayidle() {
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
        flag_set "$FLAG_APP_BLOCK_GRACE" "1"
    else
        flag_set "$FLAG_APP_ACTIVE" "0"
        flag_set "$FLAG_APP_BLOCK_GRACE" "0"
    fi
}

# ==============================
# MODES
# ==============================

start_screensaver_mode() {
    kill_swayidle
    stamp "🎮 Game / App running, starting screensaver without suspend"
    swayidle -w timeout "$screensavertime" 'xscreensaver-command -activate' >/dev/null 2>&1 &
    current_state="SCREENSAVER"
}

start_full_idle_mode() {
    kill_swayidle
    stamp "🏞️ No inhibit, normal idle with suspend"
    swayidle -w \
        timeout "$screensavertime" 'xscreensaver-command -activate' \
        timeout "$suspendtime" 'systemctl suspend' >/dev/null 2>&1 &
    current_state="FULL_IDLE"
}

start_grace() {
    [ "$(flag_get "$FLAG_APP_BLOCK_GRACE" "0")" = "1" ] && return
    kill_swayidle
    grace_start_time=$(date +%s)
    stamp "⏳ Grace START (${grace_time}s)"
    current_state="GRACE"
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
            flag_set "$FLAG_APP_BLOCK_GRACE" "$now"

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

dbus-monitor --session "interface='org.freedesktop.ScreenSaver'" |
while true; do

    # --- POLLING ---
    if ! read -r -t 1 line; then

        if [ "$video_inhibit" = true ]; then
            kill_swayidle
            current_state="VIDEO"
            continue
        fi

        case "$current_state" in
            NONE)
                if is_game_or_app_active; then
                    start_screensaver_mode
                else
                    start_grace
                fi
                ;;
            GRACE)
                if is_game_or_app_active; then
                    start_screensaver_mode
                elif [ $(( $(date +%s) - grace_start_time )) -ge $grace_time ]; then
                    stamp "✅ Grace DONE"
                    start_full_idle_mode
                fi
                ;;
            SCREENSAVER)
                :
                ;;
            FULL_IDLE)
                if is_game_or_app_active; then
                    start_screensaver_mode
                fi
                ;;
        esac
        continue
    fi

    # --- DBUS EVENTS ---
    if [[ "$line" =~ member=Inhibit ]]; then
        read -r nextline
        if ! [[ "$nextline" =~ GameMode ]]; then
            video_inhibit=true
            stamp "📺 VIDEO detected"
            kill_swayidle
            current_state="VIDEO"
        fi
    elif [[ "$line" =~ member=UnInhibit ]]; then
        read -r nextline
        if ! [[ "$nextline" =~ GameMode ]]; then
            video_inhibit=false
            stamp "✅ VIDEO stopped"
            force_app_refresh
            kill_swayidle
            current_state="NONE"
        fi
    fi
done
