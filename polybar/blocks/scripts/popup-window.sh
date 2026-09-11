#!/usr/bin/env bash
#
# polybar / blocks : open a window as a small floating popup tucked under the
# bar, centred on the icon that launched it, and take it away again on the
# next click on that icon or on the first click anywhere outside it.
#
#   popup-window.sh <class> <width> <height> <command> [args...]
#
# <class> is the second field of the window's WM_CLASS - what `bspc rule -a`
# and `xdotool search --class` both match on. Find it with:
#
#   xprop WM_CLASS
#
#
# Placement
# ---------
# Done with a bspwm one-shot rule rather than by moving the window afterwards,
# so it is floating at the right size from the first frame and never flashes as
# a tiled pane. An app can still refuse the size, though - a minimum size hint
# beats the rule - so the placement is re-checked against the real geometry
# once the window maps. Give <width> the size the app actually wants and it is
# centred on the icon; give it less and it is merely kept on screen. Check with:
#
#   xprop WM_NORMAL_HINTS
#
# (blueman-manager, for one, will not go below 596 wide, and wants more than
# that once it has devices to list.)
#
#
# Dismissal
# ---------
# What makes a real menu vanish on an outside click is an X pointer grab: the
# menu's own client takes the pointer, so the stray click is delivered to it
# rather than to whatever was underneath. That is not available here. A grab
# belongs to one client, and these popups are third-party apps - grabbing the
# pointer while blueman-manager is up would swallow blueman's own clicks and
# leave it unusable.
#
# So dismissal is driven by the window manager's focus signal instead. bspwm
# emits node_focus whenever focus lands on another window, which covers a click
# on any other window; on a tiling desktop that is every click that is not on
# the popup, since there is a window under nearly every pixel. Clicks on the
# bar do not emit it - polybar is unmanaged, so bspwm never sees them - which
# is what keeps the icon a clean toggle rather than a close-then-reopen.
#
# The catch is that a dialog the popup opens for itself (blueman's pairing
# window, nm-connection-editor's connection editor) is a separate node, and
# focusing it would otherwise dismiss the parent out from under the dialog.
# belongs_to_popup() is what stops that.
#
#
# Pinning
# -------
# These are menus hanging off an icon, so they belong under that icon and
# nowhere else. bspwm has no flag for that - `bspc node -g locked` only refuses
# to close a window, and this version has no `bspc pointer` to call off a drag
# in progress - so the position is held by watching for it to change and
# putting the window back.
#
# super + drag is therefore not blocked at the button press; the window follows
# the pointer while the button is held and returns home on release, which is
# what the pointer_action events below are for. A move from anywhere else - the
# super + arrow keys bound in sxhkdrc, or a `bspc node -v` - has no such
# in-between state and is undone as soon as it is seen.
#
# Only the position is held. An app that resizes itself, as blueman-manager
# does when devices appear, keeps the new size and is merely kept on screen.

BAR_HEIGHT=35   # keep in sync with `height` in blocks/config.ini
GAP=4           # breathing room between the bar and the popup

class=$1
width=$2
height=$3
shift 3

if [ -z "$class" ] || [ -z "$width" ] || [ -z "$height" ] || [ $# -eq 0 ]; then
	echo "usage: popup-window.sh <class> <width> <height> <command> [args...]" >&2
	exit 2
fi

# bspwm and xprop disagree on how to spell a window id (0x05C00007 against
# 0x5c00007); compare them only after putting both through this.
norm() { printf '0x%x' "$(($1))"; }

find_window() { xdotool search --onlyvisible --class "^${class}\$" 2>/dev/null | head -1; }

close_window() { bspc node "$1" -c 2>/dev/null || xdotool windowclose "$((${1}))"; }

# Second click on the icon: the popup is already up, so put it away.
wid=$(find_window)
if [ -n "$wid" ]; then
	close_window "$(norm "$wid")"
	exit 0
fi

# Monitor under the pointer, so the popup lands on the screen holding the bar
# that was clicked. bspc reports the monitor rectangle first in its tree.
geom=$(bspc query -T -m pointed 2>/dev/null |
	grep -o '"rectangle":{[^}]*}' | head -1 |
	grep -o '[-0-9]\+')
if [ -n "$geom" ]; then
	read -r mon_x mon_y mon_w mon_h <<<"$(echo $geom)"
else
	eval "$(xdotool getdisplaygeometry --shell)"
	mon_x=0 mon_y=0 mon_w=$WIDTH mon_h=$HEIGHT
fi

eval "$(xdotool getmouselocation --shell)"

# bspwm draws its border outside the rectangle both the rule and xdotool talk
# in, so the frame is 2*border wider than the client area and clamping on the
# client size alone leaves the border hanging off the edge of the monitor.
border=$(bspc config border_width 2>/dev/null)
[ -n "$border" ] || border=0

# Where a <w>x<h> window asking to sit at <x>,<y> can actually go: fully on the
# monitor and clear of the bar. Echoes the corrected "<x> <y>".
clamp_pos() {
	local x=$1 y=$2 w=$3 h=$4
	[ $((x + w + 2 * border)) -gt $((mon_x + mon_w)) ] &&
		x=$((mon_x + mon_w - w - 2 * border))
	[ "$x" -lt $((mon_x + border)) ] && x=$((mon_x + border))
	[ $((y + h + 2 * border)) -gt $((mon_y + mon_h)) ] &&
		y=$((mon_y + mon_h - h - 2 * border))
	[ "$y" -lt $((mon_y + BAR_HEIGHT)) ] && y=$((mon_y + BAR_HEIGHT + GAP))
	echo "$x $y"
}

# Centred under the cursor, below the bar when it is on top and above it when
# it is on the bottom.
pos_x=$((X - width / 2))
if [ "$Y" -gt $((mon_y + mon_h / 2)) ]; then
	pos_y=$((mon_y + mon_h - height - 2 * border - BAR_HEIGHT - GAP))
else
	pos_y=$((mon_y + BAR_HEIGHT + GAP))
fi
read -r pos_x pos_y <<<"$(clamp_pos "$pos_x" "$pos_y" "$width" "$height")"

# Consumed by the first window of this class to appear.
bspc rule -a "$class" -o \
	state=floating \
	focus=on \
	rectangle="${width}x${height}+${pos_x}+${pos_y}"

"$@" &

for _ in $(seq 1 100); do
	wid=$(find_window)
	[ -n "$wid" ] && break
	sleep 0.1
done

if [ -z "$wid" ]; then
	# Nothing ever mapped. Drop the rule again so it cannot ambush some
	# unrelated window of this class minutes from now.
	bspc rule -r "$class" 2>/dev/null
	exit 0
fi

wid_hex=$(norm "$wid")
pid=$(xprop -id "$wid" _NET_WM_PID 2>/dev/null | grep -o '[0-9]\+$')

# The app may have refused the size we asked for - a minimum size hint wins
# over the rule's rectangle, and for something like blueman-manager the minimum
# grows with the content, so no fixed <width> stays right forever. That makes
# the clamp above a guess against the wrong number, and the popup can end up
# hanging over the edge of the monitor. Measure what actually mapped and nudge
# it back inside.
eval "$(xdotool getwindowgeometry --shell "$wid")"
read -r fix_x fix_y <<<"$(clamp_pos "$X" "$Y" "$WIDTH" "$HEIGHT")"
if [ "$fix_x" != "$X" ] || [ "$fix_y" != "$Y" ]; then
	xdotool windowmove "$wid" "$fix_x" "$fix_y"
fi

# Where the popup lives from here on. Held against anything that moves it, and
# re-clamped every time in case the window has since changed size.
pin_x=$fix_x
pin_y=$fix_y
dragging=0

pin_window() {
	local X Y WIDTH HEIGHT want_x want_y
	eval "$(xdotool getwindowgeometry --shell "$wid" 2>/dev/null)"
	[ -n "$X" ] || return
	read -r want_x want_y <<<"$(clamp_pos "$pin_x" "$pin_y" "$WIDTH" "$HEIGHT")"
	[ "$X" = "$want_x" ] && [ "$Y" = "$want_y" ] && return
	xdotool windowmove "$wid" "$want_x" "$want_y"
}

# Is the newly focused window part of this popup rather than a click away from
# it? Three ways it can be: it is the popup; it is another window of the same
# process, which is what a GTK app's dialogs are; or it is transient for the
# popup, for the apps that spawn their dialogs from a separate process.
belongs_to_popup() {
	local other=$1 other_pid transient_for

	[ "$other" = "$wid_hex" ] && return 0

	other_pid=$(xprop -id "$other" _NET_WM_PID 2>/dev/null | grep -o '[0-9]\+$')
	[ -n "$pid" ] && [ "$other_pid" = "$pid" ] && return 0

	transient_for=$(xprop -id "$other" WM_TRANSIENT_FOR 2>/dev/null |
		grep -o '0x[0-9a-fA-F]\+' | head -1)
	[ -n "$transient_for" ] && [ "$(norm "$transient_for")" = "$wid_hex" ] && return 0

	return 1
}

# `exec bspc` inside the substitution so $! is bspwm's own pid and the trap
# really does reap it, rather than a shell wrapped around it.
exec 3< <(exec bspc subscribe node_focus node_remove node_geometry pointer_action)
watch_pid=$!
trap 'kill "$watch_pid" 2>/dev/null' EXIT

while read -r event _ _ node rest <&3; do
	node=$(norm "$node")
	case $event in
	node_remove)
		# Closed by the icon or by the app itself; nothing left to watch.
		[ "$node" = "$wid_hex" ] && break
		;;
	node_geometry)
		# Something moved or resized the popup. Not while a drag is in
		# flight, though: bspwm reports every step of it, and putting
		# the window back on each one would only make it flicker
		# between here and the pointer until the button comes up.
		[ "$node" = "$wid_hex" ] || continue
		[ "$dragging" = 1 ] && continue
		pin_window
		;;
	pointer_action)
		# "<action> begin" then "<action> end", in $rest.
		[ "$node" = "$wid_hex" ] || continue
		case $rest in
		*begin) dragging=1 ;;
		*end)
			dragging=0
			pin_window
			;;
		esac
		;;
	node_focus)
		belongs_to_popup "$node" && continue
		close_window "$wid_hex"
		break
		;;
	esac
done
