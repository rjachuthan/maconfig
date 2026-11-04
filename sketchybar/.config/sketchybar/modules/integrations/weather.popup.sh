#!/bin/bash

source "$CONFIG_DIR/config.sh"
source "$MODULE_DIR/integrations/weather.lib.sh"

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

  # Detected location (cached)
  local location=$(get_location)
  local location_text="$(echo "$location" | jq -r '[.city, .country_name] | map(select(. != null and . != "")) | join(", ")')"

  # Parse current weather
  local current_temp=$(echo "$weather_data" | jq -r '.current.temperature_2m')
  local feels_like=$(echo "$weather_data" | jq -r '.current.apparent_temperature')
  local current_code=$(echo "$weather_data" | jq -r '.current.weather_code')
  local current_is_day=$(echo "$weather_data" | jq -r '.current.is_day // 1')

  # Round temperatures
  current_temp=$(printf '%.0f' "$current_temp")
  feels_like=$(printf '%.0f' "$feels_like")

  # Extra details (absent in older cached data, so each is optional)
  local humidity=$(echo "$weather_data" | jq -r '.current.relative_humidity_2m // empty')
  local wind=$(echo "$weather_data" | jq -r '.current.wind_speed_10m // empty')
  local t_max=$(echo "$weather_data" | jq -r '.daily.temperature_2m_max[0] // empty')
  local t_min=$(echo "$weather_data" | jq -r '.daily.temperature_2m_min[0] // empty')
  local details=()
  [[ -n "$t_max" && -n "$t_min" ]] && details+=("H ${t_max%.*}°  L ${t_min%.*}°")
  [[ -n "$humidity" ]] && details+=("${humidity%.*}% humidity")
  [[ -n "$wind" ]] && details+=("${wind%.*} km/h")
  local details_text=""
  local sep="  ·  "
  for d in "${details[@]}"; do details_text+="${details_text:+$sep}$d"; done

  local current_desc=$(get_weather_desc "$current_code")
  local current_icon=$(map_weather_code "$current_code" "$current_is_day")

  # Build popup content (vertical card, fixed inner width so rows align)
  local W=240
  sketchybar --remove '/weather.popup.*/'

  # Shared row style: no icon/label padding surprises, consistent side margins
  local row=(
    icon.padding_left=0 icon.padding_right=0
    label.padding_left=0 label.padding_right=0
    padding_left=14 padding_right=14
    background.drawing=off
  )

  # Location header
  sketchybar --add item weather.popup.location popup.weather \
             --set weather.popup.location "${row[@]}" \
                   icon.drawing=off \
                   label="$location_text" \
                   label.font="$FONT:Bold:13.0" \
                   label.width=$W \
                   label.align=left \
                   y_offset=0

  # Current conditions: big icon + temperature on one row
  sketchybar --add item weather.popup.current popup.weather \
             --set weather.popup.current "${row[@]}" \
                   icon="$current_icon" \
                   icon.font="$FONT:Regular:24.0" \
                   icon.color="$(temp_color "$current_temp")" \
                   icon.width=46 \
                   icon.align=left \
                   label="${current_temp}°C" \
                   label.font="$FONT:Bold:24.0" \
                   label.width=$((W-46)) \
                   label.align=left

  # Description + feels like
  sketchybar --add item weather.popup.desc popup.weather \
             --set weather.popup.desc "${row[@]}" \
                   icon.drawing=off \
                   label="$current_desc  ·  Feels like ${feels_like}°" \
                   label.font="$FONT:Regular:11.5" \
                   label.color="$GREY" \
                   label.width=$W \
                   label.align=left

  # Details: high/low, humidity, wind
  if [[ -n "$details_text" ]]; then
    sketchybar --add item weather.popup.details popup.weather \
               --set weather.popup.details "${row[@]}" \
                     icon.drawing=off \
                     label="$details_text" \
                     label.font="$FONT:Regular:11.5" \
                     label.color="$GREY" \
                     label.width=$W \
                     label.align=left
  fi

  # Divider (1px line)
  add_divider() {
    sketchybar --add item "$1" popup.weather \
               --set "$1" icon.drawing=off label.drawing=off \
                     width=$((W+28)) padding_left=0 padding_right=0 \
                     background.drawing=on background.height=1 \
                     background.color="$BACKGROUND_2" \
                     background.corner_radius=0 \
                     y_offset=0
  }
  add_divider weather.popup.divider1

  # Forecast header
  sketchybar --add item weather.popup.forecast_header popup.weather \
             --set weather.popup.forecast_header "${row[@]}" \
                   icon.drawing=off \
                   label="NEXT 6 HOURS" \
                   label.font="$FONT:Heavy:9.0" \
                   label.color="$GREY" \
                   label.width=$W \
                   label.align=left

  # Hourly forecast: time on the left, "icon  temp" right-aligned
  local times=$(echo "$weather_data" | jq -r '.hourly.time[]')
  local temps=$(echo "$weather_data" | jq -r '.hourly.temperature_2m[]')
  local codes=$(echo "$weather_data" | jq -r '.hourly.weather_code[]')
  local days=$(echo "$weather_data" | jq -r 'if .hourly.is_day then .hourly.is_day[] else .hourly.time[] | 1 end')

  local hour_count=0
  local rain_warning=""

  while IFS= read -r time && IFS= read -r temp <&3 && IFS= read -r code <&4 && IFS= read -r day <&5; do
    if [[ $hour_count -ge 6 ]]; then
      break
    fi

    # "2026-02-15T15:00" -> "15:00"
    local hour=$(echo "$time" | sed 's/.*T\([0-9:]*\).*/\1/')
    temp=$(printf '%.0f' "$temp")

    local icon=$(map_weather_code "$code" "$day")

    if is_rain "$code" && [[ -z "$rain_warning" ]]; then
      rain_warning="Rain expected at $hour"
    fi

    sketchybar --add item "weather.popup.hour${hour_count}" popup.weather \
               --set "weather.popup.hour${hour_count}" "${row[@]}" \
                     icon="$hour" \
                     icon.font="$FONT:Medium:12.0" \
                     icon.color="$GREY" \
                     icon.width=64 \
                     icon.align=left \
                     label="$icon   ${temp}°" \
                     label.font="$FONT:Semibold:12.5" \
                     label.width=$((W-64)) \
                     label.align=left

    ((hour_count++))
  done < <(echo "$times") 3< <(echo "$temps") 4< <(echo "$codes") 5< <(echo "$days")

  # Rain warning
  if [[ -n "$rain_warning" ]]; then
    add_divider weather.popup.divider2

    sketchybar --add item weather.popup.rain_warning popup.weather \
               --set weather.popup.rain_warning "${row[@]}" \
                     icon="$WEATHER_RAIN" \
                     icon.font="$FONT:Regular:13.0" \
                     icon.color="$CYAN" \
                     icon.width=24 \
                     icon.align=left \
                     label="$rain_warning" \
                     label.font="$FONT:Bold:12.0" \
                     label.color="$CYAN" \
                     label.width=$((W-24)) \
                     label.align=left
  fi

  # Toggle popup visibility
  sketchybar --set weather popup.drawing=toggle
}

toggle_popup
