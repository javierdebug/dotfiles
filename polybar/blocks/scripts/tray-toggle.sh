#!/usr/bin/env bash
#
# polybar / blocks : collapse the system tray behind a chevron.
#
# Polybar has no drawer like waybar's group/tray-expander, but it hosts the
# tray in its own top-level X window, so that window is simply unmapped.
#
# The tray is detached (see tray-detached in config.ini), so polybar reserves
# no space for it and the window floats wherever tray-offset-x puts it. This
# module is the FIRST entry in modules-right, which is what keeps the rest of
# the bar still: the block is right-aligned, so its contents are laid out from
# the right edge inwards and only what sits to the LEFT of a module can be
# displaced by it. With the chevron at the block's left end there is nothing
# left of it but empty bar, so the tray unfolds into dead space and no icon,
# label or the clock moves by a pixel when the drawer opens. Nothing has to be
# reserved either, which is why this module prints only the chevron - earlier
# versions padded out a gap as wide as the tray window and that padding was
# itself what pushed the icons around.
#
# This is a tail script, not an interval one, so a click flips the chevron at
# once instead of on the next poll: --toggle records the new state and signals
# the loop, which maps the window and redraws in the same pass.
#
# Where the icons land, though, cannot be left to tray-offset-x: that is a
# fixed distance from the bar's RIGHT edge, and the chevron is not. Heading a
# right-aligned block, the chevron slides with the rendered width of every
# label to its right - "Wednesday 13:10" is 35px wider than "Friday 13:10" in
# Lato 11, "100%" 9px wider than "60%" - so a static offset has to reserve the
# ~44px the chevron wanders over a week or the icons end up on top of the one
# thing that closes the drawer, and on a short weekday that reserve is just a
# hole. So the loop looks the chevron up instead, with scripts/bar-chevron-x.py
# (a capture of the bar, the first ink after the moat around the block), and
# moves the tray window itself to sit AIR px short of it. That happens while
# the window is still unmapped, so the icons are already in place when they
# appear, and it is redone on every open, which is what lets the spacing be
# snug rather than budgeted for the worst weekday.
#
# The lookup needs python3 and xwd, and reads the bar rather than the config,
# so it can come up empty - a bar too crowded to show a moat, a missing tool.
# Then the tray is simply left wherever tray-offset-x put it, which is why that
# value is still set to a position clear of the chevron's whole range.
#
# The drawer starts collapsed. Polybar brings the tray up mapped, and remaps it
# whenever an app adds an icon, so the loop also re-checks once a second and
# pushes it back down. The loop truncates the state file when it starts, which
# is what makes every polybar launch come up collapsed - the tray window id
# cannot be used as the instance marker, X hands out the same one on restart.
#
#   tray-toggle.sh           run the module (tail = true; loops until killed)
#   tray-toggle.sh --toggle  hide or show the tray, waking the loop at once

# icomoon-feather (U+E900-U+EA09); see font-1 in config.ini.
COLLAPSED=$''  # feather-chevron-left  - click to reveal, apps open leftwards
EXPANDED=$''   # feather-chevron-right - click to hide

PROBE="$(dirname "$0")/bar-chevron-x.py"

# Gap left between the tray window's right edge and the chevron's leftmost ink.
# Polybar centres each client in a slot wider than tray-maxsize, so the window
# already carries ~11px of empty bar inside that edge; 7 here therefore reads
# as ~18px of clear space, which is about the spacing between the bar's own
# icons. Raise it if the drawer ever looks crowded against the chevron.
AIR=7

RUNTIME="${XDG_RUNTIME_DIR:-/tmp}"
CACHE="$RUNTIME/polybar-tray-win"      # last known tray window id
STATE="$RUNTIME/polybar-tray-state"    # "open" | "closed", reset by the loop
PIDFILE="$RUNTIME/polybar-tray-pid"    # the running loop, for --toggle to wake

# `xdotool search` walks the whole window tree, so cache the id and only fall
# back to searching when the cached one has gone away.
tray_window() {
	local id
	id=$(cat "$CACHE" 2>/dev/null)
	if [ -n "$id" ] && xwininfo -id "$id" >/dev/null 2>&1; then
		printf '%s' "$id"
		return
	fi
	id=$(xdotool search --name '^Polybar tray window$' 2>/dev/null | head -1)
	[ -n "$id" ] && printf '%s' "$id" >"$CACHE"
	printf '%s' "$id"
}

visible() {
	[ -n "$1" ] && xwininfo -id "$1" 2>/dev/null | grep -q 'Map State: IsViewable'
}

# "<x> <y> <width>" of a window, in root coordinates.
geom() {
	xwininfo -id "$1" 2>/dev/null | awk '
		/^  Absolute upper-left X:/ { x = $NF }
		/^  Absolute upper-left Y:/ { y = $NF }
		/^  Width:/                 { w = $NF }
		END { if (w != "") print x, y, w }'
}

# The bar itself, which the chevron lookup captures. Polybar gives the bar and
# its tray the same class, and only the tray carries a name.
bar_window() {
	local id
	for id in $(xdotool search --class polybar 2>/dev/null); do
		[ "$(xdotool getwindowname "$id" 2>/dev/null)" = 'Polybar tray window' ] && continue
		printf '%s' "$id"
		return
	done
}

# Where the tray window's right edge belongs: AIR short of the chevron. Prints
# nothing if the chevron cannot be found, or if it turns up somewhere the bar
# cannot have drawn it, in which case the caller leaves the window alone.
target_right() {
	local bar ink
	bar=$(bar_window)
	[ -n "$bar" ] || return
	ink=$(xwd -id "$bar" -silent 2>/dev/null | "$PROBE" 2>/dev/null)
	case "$ink" in
		'' | *[!0-9]*) return ;;
	esac
	printf '%s' "$((ink - AIR))"
}

# Whether the drawer should be showing. Missing or unreadable counts as closed.
wanted() {
	local state
	[ -r "$STATE" ] && read -r state <"$STATE"
	[ "$state" = open ] && printf 'open' || printf 'closed'
}

remember() {
	printf '%s\n' "$1" >"$STATE"
}

# Nudge the module loop so it redraws now instead of on its next tick. Guards
# against PID reuse: the recorded pid is only signalled if it is still us.
wake() {
	local pid
	pid=$(cat "$PIDFILE" 2>/dev/null) || return 1
	[ -n "$pid" ] || return 1
	grep -qas tray-toggle "/proc/$pid/cmdline" || return 1
	kill -USR1 "$pid" 2>/dev/null
}

if [ "$1" = --toggle ]; then
	id=$(tray_window)
	[ -n "$id" ] || exit 0
	if [ "$(wanted)" = open ]; then
		remember closed
		mapped=false
	else
		remember open
		mapped=true
	fi
	# Normally the loop applies this. Only touch the window directly if there
	# is no loop to wake - polybar restarting, or a toggle from the shell.
	if ! wake; then
		if $mapped; then
			xdotool windowmap "$id"
		else
			xdotool windowunmap "$id"
		fi
	fi
	exit 0
fi

## the module loop -----------------------------------------------------------

printf '%s\n' "$$" >"$PIDFILE"
remember closed        # a fresh polybar always comes up with the drawer shut
# A signal that lands while the loop is mid-pass cannot interrupt a `wait` that
# has not started yet, so the handler raises a flag and the tick is skipped
# instead of relying on the interrupt alone.
poked=0
trap 'poked=1' USR1
trap 'rm -f "$PIDFILE"; exit 0' TERM INT

right=                 # tray x target for the open drawer; see target_right
last=
emit() {
	[ "$1" = "$last" ] && return
	last=$1
	printf '%s\n' "$1"
}

while :; do
	id=$(tray_window)
	if [ -z "$id" ]; then
		# Polybar starts this before the tray window exists, so never wait for
		# it here; the next tick picks it up.
		emit "$(printf '%%{T2}%s%%{T-}' "$COLLAPSED")"
	elif [ "$(wanted)" = open ]; then
		read -r tx ty tw <<<"$(geom "$id")"
		if ! visible "$id"; then
			# Look the chevron up before the window is mapped, so the icons
			# never appear at the old position first.
			right=$(target_right)
			[ -n "$right" ] && [ -n "$tw" ] &&
				xdotool windowmove "$id" "$((right - tw))" "$ty"
			xdotool windowmap "$id"
		elif [ -n "$right" ] && [ -n "$tw" ] && [ "$tx" != "$((right - tw))" ]; then
			# Polybar re-lays the tray out when an app adds or drops an icon,
			# which both moves the window back and changes its width; keep the
			# right edge where the chevron is.
			xdotool windowmove "$id" "$((right - tw))" "$ty"
		fi
		emit "$(printf '%%{T2}%s%%{T-}' "$EXPANDED")"
	else
		! visible "$id" || xdotool windowunmap "$id"
		right=
		emit "$(printf '%%{T2}%s%%{T-}' "$COLLAPSED")"
	fi

	# Interruptible tick: a --toggle lands within milliseconds, an icon added
	# or removed behind the drawer within a second.
	if [ "$poked" = 0 ]; then
		sleep 1 &
		tick=$!
		wait "$tick" 2>/dev/null
		kill "$tick" 2>/dev/null
		wait "$tick" 2>/dev/null
	fi
	poked=0
done
