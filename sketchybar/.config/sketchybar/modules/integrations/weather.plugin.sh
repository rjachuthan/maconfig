#!/bin/bash

# Weather Module - Plugin
# Fetches current conditions from Open-Meteo (cached 15 min)

source "$CONFIG_DIR/config.sh"
source "$MODULE_DIR/integrations/weather.lib.sh"

fetch_weather() {
  local location=$(get_location)
  local lat=$(echo "$location" | jq -r '.latitude')
  local lon=$(echo "$location" | jq -r '.longitude')

  local url="https://api.open-meteo.com/v1/forecast"
  url+="?latitude=${lat}&longitude=${lon}"
  url+="&current=temperature_2m,weather_code,is_day,apparent_temperature,relative_humidity_2m,wind_speed_10m"
  url+="&hourly=temperature_2m,weather_code,is_day&forecast_hours=6"
  url+="&daily=temperature_2m_max,temperature_2m_min&forecast_days=1"
  url+="&temperature_unit=celsius&timezone=auto"

  curl -s --max-time 10 "$url" 2>/dev/null
}

update() {
  # Refresh location first so a move invalidates stale weather
  get_location >/dev/null

  local json=$(cache_get "weather_data")

  if [[ -z "$json" ]]; then
    json=$(fetch_weather)

    if [[ -z "$json" ]] || ! echo "$json" | jq -e .current >/dev/null 2>&1; then
      # API failure: fall back to the last good response
      json=$(load_state "weather_last_good")
      if [[ -z "$json" ]]; then
        update_item "$NAME" icon="$WEATHER_UNKNOWN" label="--" icon.color="$GREY" label.color="$GREY"
        return 1
      fi
    else
      cache_set "weather_data" "$json" 900
      save_state "weather_last_good" "$json"
    fi
  fi

  local temp=$(echo "$json" | jq -r '.current.temperature_2m')
  local code=$(echo "$json" | jq -r '.current.weather_code')
  local is_day=$(echo "$json" | jq -r '.current.is_day // 1')
  temp=$(printf '%.0f' "$temp")

  local color=$(temp_color "$temp")

  update_item "$NAME" \
    icon="$(map_weather_code "$code" "$is_day")" \
    label="${temp}°" \
    icon.color="$color" \
    label.color="$color"
}

case "$SENDER" in
  "routine"|"forced"|"weather_update"|"system_woke") update ;;
esac
