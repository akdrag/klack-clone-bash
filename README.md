# System-Wide Keystroke Sound Script

This script captures global keystrokes on a Linux system and plays a sound for each detected keypress. It works both in the foreground and as a background process and supports customizable sound files.

## Features
- **System-wide keypress detection**:
  - Uses `xinput` for X11 environments.
  - Falls back to `evtest` for Wayland or non-GUI environments.
- **Custom sound support**: Specify any `.wav` file to play on keypress.
- **Background mode**: Runs as a background service and writes its process ID (PID) to a file for easy management.
- **Clean termination**: Includes signal handling to stop the process and clean up PID files.

## Prerequisites

1. **Dependencies**:
   - Install `xinput` and `evtest`:
     ```bash
     sudo apt-get install xinput evtest
     ```
2. **Permissions**:
   - For `evtest`, root permissions are required:
     ```bash
     sudo ./script.sh
     ```

3. **Sound Playback Utilities**:
   - Ensure one of the following tools is installed:
     - `paplay` (from `pulseaudio-utils`)
     - `aplay` (from `alsa-utils`)
     - `afplay` (for macOS systems)

## Usage

### Running the Script

#### Foreground Mode
To run the script in the foreground:
```bash
./script.sh
