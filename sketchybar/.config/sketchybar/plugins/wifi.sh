#!/bin/bash

# Check WiFi status
WIFI_STATUS=$(/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport -I 2>/dev/null)

if [[ "$WIFI_STATUS" == *"AirPort: Off"* ]] || [[ -z "$WIFI_STATUS" ]]; then
    ICON="󰖪"
else
    ICON="󰖩"
fi

sketchybar --set "$NAME" icon="$ICON"
