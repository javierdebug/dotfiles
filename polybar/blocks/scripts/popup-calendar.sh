#!/usr/bin/env bash
#
# polybar / blocks : clock label plus a yad calendar popped up underneath it.
#
# Date format: weekday, day, month, time (e.g. "Fri 4 Sep 13:45").
#
#   popup-calendar.sh          print the clock (called by polybar)
#   popup-calendar.sh --popup  toggle the calendar window
#
# Placement, floating state and dismissal all come from popup-window.sh, the
# same path the bluetooth, network and system-monitor icons take, so the
# calendar behaves identically to the rest of the bar. That leaves this script
# responsible for the date string and for yad's own appearance only.

DATE_FORMAT='%a %-d %b %H:%M'
WM_CLASS='polybar-calendar'
# The calendar's natural size, and also the minimum yad reports in
# WM_NORMAL_HINTS. Ask for less and the window does shrink - bspwm's floating
# rectangle wins - but GTK keeps laying the grid out at its natural width and
# simply clips it, losing the Saturday column and the year's forward arrow.
CAL_WIDTH=240
CAL_HEIGHT=196

DIR="$(cd "$(dirname "$0")" && pwd)"

case "$1" in
--popup)
	# Private GTK config so the popup follows the bar's colours instead of
	# the desktop theme. See scripts/calendar-gtk/gtk-3.0/gtk.css
	export XDG_CONFIG_HOME="$DIR/calendar-gtk"
	export GTK_THEME='Adwaita:dark'

	# --class sets the WM_CLASS class field popup-window.sh matches on.
	# No --posx/--posy and no --close-on-unfocus: bspwm places the window
	# and the shared watcher takes it away, so yad doing either itself
	# would only fight them.
	exec "$DIR/popup-window.sh" "$WM_CLASS" "$CAL_WIDTH" "$CAL_HEIGHT" \
		yad --calendar --class="$WM_CLASS" \
			--undecorated --fixed --no-buttons --skip-taskbar \
			--width="$CAL_WIDTH" --height="$CAL_HEIGHT" \
			--borders=0 --title='calendar'
	;;
*)
	date +"$DATE_FORMAT"
	;;
esac
