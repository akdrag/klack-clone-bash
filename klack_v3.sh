#!/bin/bash

# Default sound file (adjust the path as needed)
SOUND_FILE="keypress.wav"
PID_FILE="keypress.pid"

# Function to play sound
play_sound() {
    if [ ! -f "$SOUND_FILE" ]; then
        echo "Sound file not found: $SOUND_FILE"
        exit 1
    fi

    if command -v paplay &> /dev/null; then
        paplay "$SOUND_FILE" &
    elif command -v aplay &> /dev/null; then
        aplay -q "$SOUND_FILE" &
    elif command -v afplay &> /dev/null; then
        afplay "$SOUND_FILE" &
    else
        echo "No supported sound playback utility found. Please install pulseaudio-utils, alsa-utils, or equivalent."
        exit 1
    fi
}

# Function to display usage information
usage() {
    echo "Usage: $0 [options]"
    echo "Options:"
    echo "  -b, --background   Run the script in the background"
    echo "  -s, --sound FILE   Specify a custom sound file"
    echo "  -h, --help         Show this help message"
    exit 0
}

# Function to handle cleanup (e.g., removing PID file)
cleanup() {
    echo "Stopping..."
    [ -f "$PID_FILE" ] && rm -f "$PID_FILE"
    exit 0
}

# Detect global keystrokes using xinput
capture_keystrokes_xinput() {
    trap cleanup SIGINT SIGTERM
    echo "Listening for system-wide keystrokes (X11). Press Ctrl+C to stop."

    # Identify the keyboard device
    DEVICE_ID=$(xinput list | grep -i "keyboard" | grep -o 'id=[0-9]*' | grep -o '[0-9]*' | head -n 1)
    if [ -z "$DEVICE_ID" ]; then
        echo "No keyboard device found. Ensure xinput is installed and a keyboard is connected."
        exit 1
    fi
    DEVICE_ID=9;
    # Monitor keyboard events
    xinput test "$DEVICE_ID" | while read -r line; do
        if [[ "$line" == *"key press"* ]]; then
            play_sound
        fi
    done
}

# Detect global keystrokes using evtest (requires root)
capture_keystrokes_evtest() {
    trap cleanup SIGINT SIGTERM
    echo "Listening for system-wide keystrokes (evtest). Press Ctrl+C to stop."

    # List available devices
    DEVICES=$(ls /dev/input/event* 2>/dev/null)
    if [ -z "$DEVICES" ]; then
        echo "No input devices found. Ensure evtest is installed."
        exit 1
    fi

    # Automatically select a keyboard device (customize as needed)
    for DEVICE in $DEVICES; do
        if evtest --info "$DEVICE" 2>/dev/null | grep -qi "keyboard"; then
            echo "Using device: $DEVICE"
            evtest "$DEVICE" | while read -r line; do
                if echo "$line" | grep -q "KEY"; then
                    play_sound
                fi
            done
            break
        fi
    done
}

# Parse command-line arguments
BACKGROUND=false
while [[ $# -gt 0 ]]; do
    case $1 in
        -b|--background)
            BACKGROUND=true
            shift
            ;;
        -s|--sound)
            SOUND_FILE="$2"
            shift 2
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo "Unknown option: $1"
            usage
            ;;
    esac
done

# Main function to handle system-wide key capture
if [ "$BACKGROUND" = true ]; then
    echo "Running in background. Use 'kill $(cat $PID_FILE)' to stop."
    if [ -f "$PID_FILE" ]; then
        echo "Script is already running (PID: $(cat $PID_FILE))."
        exit 1
    fi

    # Run listener in the background
    (capture_keystrokes_xinput || capture_keystrokes_evtest) &> /dev/null &
    echo $! > "$PID_FILE"
else
    # Foreground mode
    capture_keystrokes_xinput || capture_keystrokes_evtest
fi
