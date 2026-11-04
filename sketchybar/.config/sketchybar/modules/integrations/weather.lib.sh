#!/bin/bash

# Weather shared helpers: location detection.
# Location sources, in order: macOS Location Services (CoreLocationCLI, Wi-Fi
# based and accurate), then IP geolocation (city level). Cached for 30 min, with
# the last known location (then Ealing Broadway) as the final fallback.

DEFAULT_LOCATION='{"city": "Ealing Broadway", "country_name": "United Kingdom", "latitude": 51.5157, "longitude": -0.3008, "timezone": "Europe/London"}'

# macOS Location Services via CoreLocationCLI (brew install --cask corelocationcli)
fetch_corelocation() {
  command -v CoreLocationCLI >/dev/null 2>&1 || return 1
  local out
  # No coreutils `timeout` on macOS, so use perl's alarm to cap the wait
  out=$(perl -e 'alarm 10; exec @ARGV' CoreLocationCLI \
        --format '%latitude|%longitude|%locality|%country|%isoCountryCode' 2>/dev/null) || return 1
  local lat lon city country cc
  IFS='|' read -r lat lon city country cc <<<"$out"
  [[ "$lat" =~ ^-?[0-9.]+$ && "$lon" =~ ^-?[0-9.]+$ ]] || return 1
  jq -cn --arg c "$city" --arg k "$country" --arg cc "$cc" --argjson la "$lat" --argjson lo "$lon" \
    '{city: $c, country_name: $k, country_code: $cc, latitude: $la, longitude: $lo, timezone: "auto"}'
}

fetch_location() {
  local raw
  if raw=$(fetch_corelocation) && [[ -n "$raw" ]]; then
    echo "$raw"
    return 0
  fi
  raw=$(curl -s --max-time 6 "https://ipwho.is/" 2>/dev/null)
  if echo "$raw" | jq -e '.success == true and .latitude != null' >/dev/null 2>&1; then
    echo "$raw" | jq -c '{city, country_name: .country, country_code, latitude, longitude, timezone: .timezone.id}'
    return 0
  fi
  raw=$(curl -s --max-time 6 "https://ipinfo.io/json" 2>/dev/null)
  if echo "$raw" | jq -e '.loc != null' >/dev/null 2>&1; then
    echo "$raw" | jq -c '{city, country_name: .country, country_code: .country, latitude: (.loc | split(",")[0] | tonumber), longitude: (.loc | split(",")[1] | tonumber), timezone}'
    return 0
  fi
  return 1
}

get_location() {
  local cached=$(cache_get "weather_location")
  if [[ -n "$cached" ]]; then
    echo "$cached"
    return
  fi

  local fresh
  if fresh=$(fetch_location) && [[ -n "$fresh" ]]; then
    local previous=$(load_state "weather_last_location")
    # Moved somewhere new: drop cached weather so it refreshes immediately
    [[ "$(echo "$previous" | jq -r '.city' 2>/dev/null)" != "$(echo "$fresh" | jq -r '.city')" ]] && cache_invalidate "weather_data"
    cache_set "weather_location" "$fresh" 1800
    save_state "weather_last_location" "$fresh"
    echo "$fresh"
    return
  fi

  local last=$(load_state "weather_last_location")
  echo "${last:-$DEFAULT_LOCATION}"
}
