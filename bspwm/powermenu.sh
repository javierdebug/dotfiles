#!/bin/bash

chosen=$(printf "Shutdown\nReboot\nLock\nSuspend\nLogout" | rofi -dmenu -i -p "Power Menu")

case "$chosen" in
  Shutdown) systemctl poweroff ;;
  Reboot) systemctl reboot ;;
  Lock) i3lock ;; # or your preferred locker
  Suspend) systemctl suspend ;;
  Logout) bspc quit ;;
esac

