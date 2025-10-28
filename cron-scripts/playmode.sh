#!/bin/bash

# Disable screen locker
xautolock -disable

# Disable DPMS (monitor sleep) and screensaver
xset s off
xset -dpms

echo "🎮 Play mode ON (press Ctrl+C to quit)"

# Keep faking activity until Ctrl+C
trap "echo '⏹ Play mode OFF'; xautolock -enable; xset s 600; xset +dpms; exit" INT

while true; do
  xset s reset   # reset idle timer
  sleep 50
done
