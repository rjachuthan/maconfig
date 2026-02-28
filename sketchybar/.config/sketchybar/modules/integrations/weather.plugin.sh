#!/bin/bash

source "$CONFIG_DIR/config.sh"

# Fixed location: Ealing Broadway
get_location() {
  echo '{"city": "Ealing Broadway", "country_name": "United Kingdom", "latitude": 51.5157, "longitude": -0.3008, "timezone": "Europe/London"}'
}

# Fetch weather data from Open-Meteo API
fetch_weather() {
  local location=$(get_location)
  local lat=$(echo "$location" | jq -r '.latitude')
  local lon=$(echo "$location" | jq -r '.longitude')
  local tz=$(echo "$location" | jq -r '.timezone')

  local url="https://api.open-meteo.com/v1/forecast"
  url+="?latitude=${lat}&longitude=${lon}"
  url+="&current=temperature_2m,weather_code,apparent_temperature"
  url+="&hourly=temperature_2m,weather_code&forecast_hours=6"
  url+="&temperature_unit=celsius&timezone=${tz}"

  curl -s --max-time 10 "$url" 2>/dev/null
}

# Map WMO weather codes to emoji icons
map_weather_code() {
  local code=$1
  case $code in
    0) echo "☀️" ;;           # Clear sky
    1|2|3) echo "⛅" ;;       # Partly cloudy
    45|48) echo "🌫️" ;;      # Fog
    51|53|55|56|57) echo "🌦️" ;;  # Drizzle
    61|63|65|66|67) echo "🌧️" ;;  # Rain
    71|73|75|77) echo "❄️" ;;     # Snow
    80|81|82) echo "🌧️" ;;       # Rain showers
    85|86) echo "🌨️" ;;          # Snow showers
    95|96|99) echo "⛈️" ;;       # Thunderstorm
    *) echo "❓" ;;              # Unknown
  esac
}

# Main update function
update() {
  # Try to get cached data first
  local cached=$(cache_get "weather_data")

  if [[ -z "$cached" ]]; then
    # Cache miss or expired - fetch fresh data
    local json=$(fetch_weather)

    if [[ -z "$json" ]] || ! echo "$json" | jq -e .current >/dev/null 2>&1; then
      # API failure - use last known good data or show error
      local last_good=$(load_state "weather_last_good")
      if [[ -n "$last_good" ]]; then
        json="$last_good"
      else
        update_item "$NAME" icon="❌" label="No data" icon.color="$RED"
        return 1
      fi
    else
      # Success - cache for 15 min and persist as fallback
      cache_set "weather_data" "$json" 900
      save_state "weather_last_good" "$json"
    fi
  else
    json="$cached"
  fi

  # Parse current weather
  local temp=$(echo "$json" | jq -r '.current.temperature_2m')
  local feels_like=$(echo "$json" | jq -r '.current.apparent_temperature')
  local code=$(echo "$json" | jq -r '.current.weather_code')

  # Round to integer
  temp=${temp%.*}
  feels_like=${feels_like%.*}

  # Get weather icon
  local icon=$(map_weather_code "$code")

  # Temperature-based color
  local color=$(select_color_by_range "$temp" \
    "-999--10:$CYAN" "-9-5:$BLUE" "6-15:$WHITE" \
    "16-25:$YELLOW" "26-30:$ORANGE" "31-999:$RED")

  # Update display
  update_item "$NAME" \
    icon="$icon" \
    label="${temp}°" \
    icon.color="$color" \
    label.color="$color"
}

# Event dispatcher
case "$SENDER" in
  "routine"|"forced"|"weather_update"|"system_woke") update ;;
esac
