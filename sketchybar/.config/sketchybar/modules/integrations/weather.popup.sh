#!/bin/bash

source "$CONFIG_DIR/config.sh"

# Map WMO weather codes to emoji icons (same as plugin)
map_weather_code() {
  local code=$1
  case $code in
    0) echo "☀️" ;;
    1|2|3) echo "⛅" ;;
    45|48) echo "🌫️" ;;
    51|53|55|56|57) echo "🌦️" ;;
    61|63|65|66|67) echo "🌧️" ;;
    71|73|75|77) echo "❄️" ;;
    80|81|82) echo "🌧️" ;;
    85|86) echo "🌨️" ;;
    95|96|99) echo "⛈️" ;;
    *) echo "❓" ;;
  esac
}

# Check if weather code indicates rain
is_rain() {
  local code=$1
  case $code in
    51|53|55|56|57|61|63|65|66|67|80|81|82|95|96|99) echo "yes" ;;
    *) echo "no" ;;
  esac
}

# Get weather description
get_weather_desc() {
  local code=$1
  case $code in
    0) echo "Clear" ;;
    1|2) echo "Partly Cloudy" ;;
    3) echo "Overcast" ;;
    45|48) echo "Foggy" ;;
    51|53|55) echo "Drizzle" ;;
    56|57) echo "Freezing Drizzle" ;;
    61|63|65) echo "Rain" ;;
    66|67) echo "Freezing Rain" ;;
    71|73|75) echo "Snow" ;;
    77) echo "Snow Grains" ;;
    80|81|82) echo "Rain Showers" ;;
    85|86) echo "Snow Showers" ;;
    95|96|99) echo "Thunderstorm" ;;
    *) echo "Unknown" ;;
  esac
}

toggle_popup() {
  # Get cached weather data
  local weather_data=$(cache_get "weather_data")

  if [[ -z "$weather_data" ]]; then
    weather_data=$(load_state "weather_last_good")
  fi

  if [[ -z "$weather_data" ]]; then
    sketchybar --set weather popup.drawing=toggle
    return
  fi

  # Fixed location: Ealing Broadway
  local location_text="Ealing Broadway, United Kingdom"

  # Parse current weather
  local current_temp=$(echo "$weather_data" | jq -r '.current.temperature_2m')
  local feels_like=$(echo "$weather_data" | jq -r '.current.apparent_temperature')
  local current_code=$(echo "$weather_data" | jq -r '.current.weather_code')

  # Round temperatures
  current_temp=${current_temp%.*}
  feels_like=${feels_like%.*}

  local current_desc=$(get_weather_desc "$current_code")
  local current_icon=$(map_weather_code "$current_code")

  # Build popup content
  sketchybar --remove '/weather.popup.*/'

  # Location header
  sketchybar --add item weather.popup.location popup.weather \
             --set weather.popup.location \
                   icon="📍" \
                   label="$location_text" \
                   label.font="$FONT:Bold:13.0" \
                   background.padding_left=12 \
                   background.padding_right=12 \
                   background.padding_top=8 \
                   background.padding_bottom=4 \
                   icon.padding_right=6

  # Current conditions - icon on separate line
  sketchybar --add item weather.popup.current_icon popup.weather \
             --set weather.popup.current_icon \
                   icon="$current_icon" \
                   label="" \
                   icon.font="$FONT:Regular:24.0" \
                   background.padding_left=12 \
                   background.padding_right=12 \
                   background.padding_top=4 \
                   background.padding_bottom=2

  # Current temperature
  sketchybar --add item weather.popup.current_temp popup.weather \
             --set weather.popup.current_temp \
                   icon="" \
                   label="${current_temp}°C" \
                   label.font="$FONT:Bold:16.0" \
                   background.padding_left=12 \
                   background.padding_right=12 \
                   background.padding_top=2 \
                   background.padding_bottom=2

  # Current description and feels like
  sketchybar --add item weather.popup.current_desc popup.weather \
             --set weather.popup.current_desc \
                   icon="" \
                   label="$current_desc • Feels like ${feels_like}°" \
                   label.font="$FONT:Regular:11.0" \
                   label.color="$GREY" \
                   background.padding_left=12 \
                   background.padding_right=12 \
                   background.padding_top=2 \
                   background.padding_bottom=6

  # Separator
  sketchybar --add item weather.popup.separator popup.weather \
             --set weather.popup.separator \
                   icon="" \
                   label="━━━━━━━━━━━━━━━━━━" \
                   label.color="$GREY" \
                   label.font="$FONT:Regular:8.0" \
                   background.padding_left=12 \
                   background.padding_right=12 \
                   background.padding_top=4 \
                   background.padding_bottom=4

  # Forecast header
  sketchybar --add item weather.popup.forecast_header popup.weather \
             --set weather.popup.forecast_header \
                   icon="🕐" \
                   label="Next 6 Hours" \
                   label.font="$FONT:Semibold:12.0" \
                   background.padding_left=12 \
                   background.padding_right=12 \
                   background.padding_top=4 \
                   background.padding_bottom=6 \
                   icon.padding_right=6

  # Hourly forecast (next 6 hours) - each hour on separate line
  local times=$(echo "$weather_data" | jq -r '.hourly.time[]')
  local temps=$(echo "$weather_data" | jq -r '.hourly.temperature_2m[]')
  local codes=$(echo "$weather_data" | jq -r '.hourly.weather_code[]')

  local hour_count=0
  local rain_warning=""

  while IFS= read -r time && IFS= read -r temp <&3 && IFS= read -r code <&4; do
    if [[ $hour_count -ge 6 ]]; then
      break
    fi

    # Extract hour from ISO timestamp (e.g., "2026-02-15T15:00" -> "15:00")
    local hour=$(echo "$time" | sed 's/.*T\([0-9:]*\).*/\1/')

    # Round temperature
    temp=${temp%.*}

    local icon=$(map_weather_code "$code")
    local will_rain=$(is_rain "$code")

    # Track if rain is coming
    if [[ "$will_rain" == "yes" && -z "$rain_warning" ]]; then
      rain_warning="💧 Rain expected at $hour"
    fi

    # Add each hour as a separate item for vertical layout
    sketchybar --add item "weather.popup.hour${hour_count}" popup.weather \
               --set "weather.popup.hour${hour_count}" \
                     icon="$hour" \
                     label="$icon  ${temp}°" \
                     icon.font="$FONT:Regular:11.0" \
                     label.font="$FONT:Regular:12.0" \
                     icon.width=50 \
                     icon.align=left \
                     background.padding_left=16 \
                     background.padding_right=16 \
                     background.padding_top=4 \
                     background.padding_bottom=4

    ((hour_count++))
  done < <(echo "$times") 3< <(echo "$temps") 4< <(echo "$codes")

  # Add rain warning if applicable
  if [[ -n "$rain_warning" ]]; then
    sketchybar --add item weather.popup.separator2 popup.weather \
               --set weather.popup.separator2 \
                     icon="" \
                     label="━━━━━━━━━━━━━━━━━━" \
                     label.color="$GREY" \
                     label.font="$FONT:Regular:8.0" \
                     background.padding_left=12 \
                     background.padding_right=12 \
                     background.padding_top=4 \
                     background.padding_bottom=4

    sketchybar --add item weather.popup.rain_warning popup.weather \
               --set weather.popup.rain_warning \
                     icon="" \
                     label="$rain_warning" \
                     label.font="$FONT:Bold:12.0" \
                     label.color="$CYAN" \
                     background.padding_left=12 \
                     background.padding_right=12 \
                     background.padding_top=4 \
                     background.padding_bottom=8
  fi

  # Toggle popup visibility
  sketchybar --set weather popup.drawing=toggle
}

toggle_popup
