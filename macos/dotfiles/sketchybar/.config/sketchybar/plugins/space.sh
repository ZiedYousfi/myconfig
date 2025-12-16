#!/bin/sh
set -eu

LOG="/tmp/sketchybar_switch_space.log"
echo "---- $(date '+%F %T') ----" >>"$LOG"
echo "PWD=$(pwd)" >>"$LOG"
echo "ARGS: $*" >>"$LOG"
echo "NAME=${NAME:-} SID=${SID:-} SENDER=${SENDER:-} SELECTED=${SELECTED:-}" >>"$LOG"
echo "PATH=$PATH" >>"$LOG"

# $SELECTED: true/false
# $SID: space id associated to this item (available for space components)
# $NAME: item name

CURRENT_FILE="/tmp/sketchybar_current_space"

sketchybar --set "$NAME" background.drawing="$SELECTED"

if [ "${SELECTED:-false}" = "true" ] && [ -n "${SID:-}" ]; then
  echo "$SID" >"$CURRENT_FILE"
fi