#!/usr/bin/env bash

# Screen Recording Script (using wl-screenrec)
# Toggles recording on/off

RECORD_DIR="$HOME/records"
mkdir -p "$RECORD_DIR"

PID_FILE="/tmp/wl-screenrec.pid"
LOG_FILE="/tmp/wl-screenrec.log"

if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
    # Stop recording
    PID=$(cat "$PID_FILE")
    kill -SIGINT "$PID"
    rm -f "$PID_FILE"
    notify-send -a "Screen Recorder" "Recording Stopped" "Saved to $RECORD_DIR"
else
    # Start recording
    FILENAME="recording_$(date +%Y-%m-%d_%H-%M-%S).mp4"
    FILEPATH="$RECORD_DIR/$FILENAME"
    
    # Detect focused monitor for multi-head setups
    MONITOR=""
    if command -v hyprctl >/dev/null; then
        MONITOR=$(hyprctl monitors -j | jq -r '.[] | select(.focused == true) | .name')
    fi
    
    # Fallback to default if detection fails
    if [ -z "$MONITOR" ]; then
        OPT_MONITOR=""
    else
        OPT_MONITOR="-o $MONITOR"
    fi

    notify-send -a "Screen Recorder" "Recording Started" "Saving to $FILEPATH (Monitor: ${MONITOR:-default})"
    
    # Using hevc (H.265) per user request for GFX90c
    # Including monitor selection to fix multi-display error
    wl-screenrec --codec hevc --low-power off $OPT_MONITOR -f "$FILEPATH" > "$LOG_FILE" 2>&1 &
    REC_PID=$!
    echo $REC_PID > "$PID_FILE"
    
    # Wait a moment and check if it's still running
    sleep 1
    if ! kill -0 "$REC_PID" 2>/dev/null; then
        notify-send -a "Screen Recorder" -u critical "Recording Failed" "Check $LOG_FILE for details"
        rm -f "$PID_FILE"
    fi
fi
