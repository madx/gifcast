#!/bin/bash

# -s for screen region, -w for window
MODE=${1:--s}

# Output file name
FILE="$HOME/Images/Captures/`date +%FT%T.gif`"

# Temporary files
TMPDIR="/tmp"
TMP_AVI=$(mktemp -u $TMPDIR/gifcast.XXXXXXXXXX.avi)
TMP_PALETTE=$(mktemp $TMPDIR/gifcast.XXXXXXXXXX.png)
TMP_PIPE=$(mktemp -u $TMPDIR/gifcast.XXXXXXXXXX.fifo)
mkfifo $TMP_PIPE

exec 3<> $TMP_PIPE

# Cleanup temporary files at exit
function at_exit() {
  rm -f $TMP_AVI
  rm -f $TMP_PALETTE
  rm -f $TMP_PIPE
}
trap at_exit EXIT

# Stop recording and tray icon
function tray_cb {
echo $TMP_PIPE
  local pipe=$1
  local cast_pid=$2
  local capture_pid=`pgrep -P $cast_pid`

  kill $capture_pid
  echo "quit" > $pipe
}
export -f tray_cb

# Start capture
ffcast $MODE rec $TMP_AVI &
cast_pid=$!

yad --notification \
  --image media-playback-stop \
  --command "bash -c 'tray_cb $TMP_PIPE $cast_pid'" \
  --listen <&3


# Start convert using a GIF palette
ffmpeg -i $TMP_AVI -vf "fps=15,palettegen" -y $TMP_PALETTE
ffmpeg -i $TMP_AVI -i $TMP_PALETTE -lavfi "fps=15 [x]; [x][1:v] paletteuse" -y $FILE

echo "$FILE"
