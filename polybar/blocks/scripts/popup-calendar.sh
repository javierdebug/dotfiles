#!/bin/bash

# === Config ===
YAD_WIDTH=200
YAD_HEIGHT=180
POS_X=2230      # 👈 Adjust this to match your Polybar's date X position
POS_Y=42        # 👈 Adjust this to be just below the Polybar bar
LOCKFILE="/tmp/yad-calendar.lock"
DATE="$(date +"%a %d %H:%M")"

case "$1" in
--popup)
    [ -f "$LOCKFILE" ] && exit 0
    touch "$LOCKFILE"
    trap 'rm -f "$LOCKFILE"' EXIT

    # Mouse + screen info
    eval "$(xdotool getmouselocation --shell)"
    eval "$(xdotool getdisplaygeometry --shell)"

    Positioning
    pos_x=$((X - YAD_WIDTH / 2))
    pos_y=$((Y + 25))  # Adjust this value to match polybar height

    [ "$pos_x" -lt 0 ] && pos_x=0
    [ "$((pos_x + YAD_WIDTH))" -gt "$WIDTH" ] && pos_x=$((WIDTH - YAD_WIDTH))

    # GTK theme tweaks for smaller font
    export GTK_THEME="Adwaita:dark"
    export GTK2_RC_FILES="$HOME/.gtkrc-2.0-polybar-calendar"

        yad --calendar \
        --undecorated \
        --fixed \
        --no-buttons \
        --close-on-unfocus \
        --skip-taskbar \
        --class="calendar-popup" \
        --window-icon=calendar \
        --width="$YAD_WIDTH" \
        --height="$YAD_HEIGHT" \
        --posx="$POS_X" \
        --posy="$POS_Y" \
        --borders=0 \
        --title="calendar" \
        --type=popup >/dev/null &
    wait $!
    ;;
*)
    echo "$DATE"
    ;;
esac
``


##!/bin/sh

#YAD_WIDTH=222  # 222 is minimum possible value
#YAD_HEIGHT=193 # 193 is minimum possible value
#DATE="$(date +"%a %d %H:%M")"
 
#case "$1" in
#--popup)
 
#    yad --calendar --undecorated --fixed --close-on-unfocus --no-buttons --posx=585\
#        --title="calendar" --borders=0 >/dev/null &
#    ;;
#*)
#    echo "$DATE"
#    ;;
#esac


# BAR_HEIGHT=22  # polybar height
# BORDER_SIZE=1  # border size from your wm settings
# YAD_WIDTH=222  # 222 is minimum possible value
# YAD_HEIGHT=193 # 193 is minimum possible value
# DATE="$(date +"%a %d %H:%M")"

# case "$1" in
# --popup)
#     if [ "$(xdotool getwindowfocus getwindowname)" = "yad-calendar" ]; then
#         exit 0
#     fi

#     eval "$(xdotool getmouselocation --shell)"
#     eval "$(xdotool getdisplaygeometry --shell)"

#     # X
#     if [ "$((X + YAD_WIDTH / 2 + BORDER_SIZE))" -gt "$WIDTH" ]; then #Right side
#         : $((pos_x = WIDTH - YAD_WIDTH - BORDER_SIZE))
#     elif [ "$((X - YAD_WIDTH / 2 - BORDER_SIZE))" -lt 0 ]; then #Left side
#         : $((pos_x = BORDER_SIZE))
#     else #Center
#         : $((pos_x = X - YAD_WIDTH / 2))
#     fi

#     # Y
#     if [ "$Y" -gt "$((HEIGHT / 2))" ]; then #Bottom
#         : $((pos_y = HEIGHT - YAD_HEIGHT - BAR_HEIGHT - BORDER_SIZE))
#     else #Top
#         : $((pos_y = BAR_HEIGHT + BORDER_SIZE))
#     fi

#     yad --calendar --undecorated --fixed --close-on-unfocus --no-buttons \
#         --width="$YAD_WIDTH" --height="$YAD_HEIGHT" --posx="$pos_x" --posy="$pos_y" \
#         --title="yad-calendar" --borders=0 >/dev/null &
#     ;;
# *)
#     echo "$DATE"
#     ;;
# esac
