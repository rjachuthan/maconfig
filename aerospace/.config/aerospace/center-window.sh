#!/bin/bash
# Centers a floating app window on the screen.
# Usage: center-window.sh <AppName>

APP="${1:-mpv}"
sleep 0.5

osascript << EOF
tell application "Finder"
    set {sx, sy, sw, sh} to bounds of window of desktop
end tell
tell application "System Events"
    tell process "$APP"
        if (count of windows) > 0 then
            set w to front window
            set {ww, wh} to size of w
            set position of w to {sx + (sw - ww) / 2, sy + (sh - wh) / 2}
        end if
    end tell
end tell
EOF
