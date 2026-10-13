#!/usr/bin/env bash

query="$*"
[ -z "$query" ] && exit 0

url="https://duckduckgo.com/?q=$(printf '%s' "$query" | sed 's/ /+/g')"

# Close rofi explicitly
# pkill rofi

windows=$(bspc query -N -d focused -n .window)
# windows=$(bspc query -N -n .window)

found=""

for w in $windows; do
    if xprop -id "$w" WM_CLASS 2>/dev/null | grep -qi "brave"; then
        found="$w"
        break
    fi
done

if [ -n "$found" ]; then
    bspc node -f "$found"
    sleep 0.05
    brave-browser --new-tab "$url" >/dev/null 2>&1 &
else
    brave-browser --new-window "$url" >/dev/null 2>&1 &
fi
