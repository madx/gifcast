#!/bin/bash

# -s for screen region, -w for window
MODE=${1:--s}

# Output file name
FILE="$HOME/Images/Captures/`date +%FT%T.gif`"

# Temporary files
TMPDIR="/tmp"
TMP_AVI=$(mktemp $TMPDIR/gifcast.XXXXXXXXXX.avi)
TMP_PALETTE=$(mktemp $TMPDIR/gifcast.XXXXXXXXXX.png)

# Cleanup temporary files at exit
function at_exit() {
  rm -f $TMP_AVI
  rm -f $TMP_PALETTE
  rm -f $TMP_PIPE
}
trap at_exit EXIT

# Stop recording and tray icon
function tray_cb {
  tray_pid=`pidof yad`
  capture_pid=`pidof ffmpeg`
  kill $capture_pid
  kill $tray_pid
}
export -f tray_cb

# Start capture
ffcast $MODE % ffmpeg -y -f x11grab -show_region 1 -framerate 15 \
    -video_size %s -i %D+%c -codec:v huffyuv                  \
    -vf crop="iw-mod(iw\\,2):ih-mod(ih\\,2)" $TMP_AVI &


yad --notification \
  --image media-playback-stop \
  --command "bash -c 'tray_cb'"

# Start convert using a GIF palette
ffmpeg -i $TMP_AVI -vf "fps=15,palettegen" -y $TMP_PALETTE
ffmpeg -i $TMP_AVI -i $TMP_PALETTE -lavfi "fps=15 [x]; [x][1:v] paletteuse" -y $FILE

echo "$FILE"
