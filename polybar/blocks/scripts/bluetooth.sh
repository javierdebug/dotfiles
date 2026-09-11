#!/usr/bin/env bash
#
# polybar / blocks : bluetooth controller state.
#
# Omarchy-style: a single glyph, no label. Three states, distinguished by the
# glyph itself and dimmed when nothing is connected.
#
#   bluetooth.sh           print the glyph (called by polybar)
#   bluetooth.sh --toggle  power the controller on or off

# from colors.ini. icomoon-feather has a single bluetooth glyph and no
# struck-through variant, so the three states are told apart by colour alone
# and "off" is dimmed well below "idle" rather than given its own icon.
FG='#FFFFFF'    # a device is connected
DIM='#6D8895'   # powered on but idle
OFF='#232936'   # controller powered off - barely above the bar background

# icomoon-feather (U+E900-U+EA09); see font-1 in config.ini.
ICON_BT=$'\ue920'  # feather-bluetooth

glyph() {
	printf '%%{F%s}%%{T2}%s%%{T-}%%{F-}\n' "$2" "$1"
}

# bluetoothctl colourises its output even when it is not on a tty.
btctl() {
	bluetoothctl "$@" 2>/dev/null | sed 's/\x1b\[[0-9;]*m//g'
}

powered() {
	btctl show | grep -q 'Powered: yes'
}

if ! command -v bluetoothctl >/dev/null 2>&1; then
	exit 0
fi

case "$1" in
--toggle)
	if powered; then
		bluetoothctl power off >/dev/null 2>&1
	else
		bluetoothctl power on >/dev/null 2>&1
	fi
	exit 0
	;;
esac

if ! powered; then
	glyph "$ICON_BT" "$OFF"
	exit 0
fi

# `bluetoothctl devices Connected` needs bluez 5.65+; this works on 5.64 too.
while read -r _ mac _; do
	[ -n "$mac" ] || continue
	if btctl info "$mac" | grep -q 'Connected: yes'; then
		glyph "$ICON_BT" "$FG"
		exit 0
	fi
done < <(btctl devices)

glyph "$ICON_BT" "$DIM"
exit 0
