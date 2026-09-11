#!/usr/bin/env bash
#
# polybar / blocks : the network connection that is actually carrying traffic.
#
# Omarchy-style: a single glyph, no label. The icon says what kind of link it
# is, the colour says whether that link actually reaches the internet. The
# detail is one click away in the connection editor.
#
#   network.sh    print the glyph (called by polybar)

# from colors.ini
FG='#FFFFFF'      # link up, internet reachable
ALERT='#EC7875'   # offline, or up but no internet behind it

# icomoon-feather (U+E900-U+EA09); see font-1 in config.ini.
ICON_WIRED=$'\ue9c3'  # feather-server
ICON_WIFI=$'\ue9ff'   # feather-wifi
ICON_OFF=$'\uea00'    # feather-wifi-off

# <glyph> <colour>
glyph() {
	printf '%%{F%s}%%{T2}%s%%{T-}%%{F-}\n' "$2" "$1"
}

if ! command -v nmcli >/dev/null 2>&1; then
	glyph "$ICON_OFF" "$ALERT"
	exit 0
fi

# The interface holding the default route is the one we are browsing on.
dev=$(ip route show default 2>/dev/null | awk '$1 == "default" { print $5; exit }')

if [ -z "$dev" ]; then
	glyph "$ICON_OFF" "$ALERT"
	exit 0
fi

if [ "$(nmcli -t -f GENERAL.TYPE device show "$dev" 2>/dev/null | cut -d: -f2)" = 'wifi' ]; then
	icon="$ICON_WIFI"
else
	icon="$ICON_WIRED"
fi

# Connected to something is not the same as being online.
case "$(nmcli -t networking connectivity 2>/dev/null)" in
full) glyph "$icon" "$FG" ;;
*) glyph "$icon" "$ALERT" ;;
esac

exit 0
