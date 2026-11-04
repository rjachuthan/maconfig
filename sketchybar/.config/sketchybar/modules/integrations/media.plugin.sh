#!/bin/bash

# Media Module - Plugin
# Polls `media-control get` (~50 ms) for the system now-playing session and
# shows its source logo, title and transport controls. Redraws only when the
# track, source or play state changed.
#   media.plugin.sh          refresh (routine / media_update / forced)
#   media.plugin.sh toggle   play / pause
#   media.plugin.sh next     next track
#   media.plugin.sh prev     previous track
#   media.plugin.sh focus    bring the app that is playing to the front

source "$CONFIG_DIR/config.sh"

# Max characters of "title · artist" in the bar
TITLE_MAX=34
# Seconds a paused session stays visible before the pill hides
PAUSE_GRACE=10

# Brand colours for the source logo
SPOTIFY_GREEN=0xff1ed760
YOUTUBE_RED=0xffff0033
APPLE_MUSIC_RED=0xfffa2d48

command -v media-control >/dev/null 2>&1 || export PATH="/opt/homebrew/bin:$PATH"

MEDIA_ITEMS=(media media.prev media.play media.next media.pill gap.media)

set_drawing() {
  local args=() item
  for item in "${MEDIA_ITEMS[@]}"; do args+=(--set "$item" drawing="$1"); done
  sketchybar "${args[@]}"
}

# Classify a "bundle|app name|window title" line into a source
classify() {
  shopt -s nocasematch
  case "$1" in
    *"YouTube Music"*) echo youtube_music ;;
    *YouTube*)         echo youtube ;;
    *Spotify*)         echo spotify ;;
    *)                 return 1 ;;
  esac
}

# Where the media is playing: spotify, youtube, youtube_music, music,
# or "app:<App Name>" for anything else
detect_source() {
  local bundle="$1" title="$2"
  case "$bundle" in
    com.spotify.client) echo spotify; return ;;
    com.apple.Music)    echo music; return ;;
  esac

  # Browsers and web apps: the tab playing the media names the site in its
  # window title (e.g. "Song - YouTube Music", "Video - YouTube")
  local windows match
  windows=$(aerospace list-windows --all \
              --format '%{app-bundle-id}|%{app-name}|%{window-title}' 2>/dev/null \
            | awk -F'|' -v b="$bundle" '$1 == b')
  match=$(grep -F -- "$title" <<<"$windows" | head -1)

  if [[ -n "$match" ]]; then
    classify "$match" && return
    # Spotify's web player titles its tab "Song • Artist"
    [[ "${match##*|}" == *" • "* ]] && { echo spotify; return; }
  fi
  [[ -n "$windows" ]] && classify "$windows" && return

  # Anything else: the host app's own icon
  local name="${windows%%$'\n'*}"
  name=$(cut -d'|' -f2 <<<"$name")
  if [[ -z "$name" ]]; then
    name=$(mdfind "kMDItemCFBundleIdentifier == '$bundle'" 2>/dev/null | head -1)
    name=$(basename "${name:-Unknown}" .app)
  fi
  echo "app:$name"
}

source_icon() {
  case "$1" in
    spotify)       echo ":spotify:" ;;
    youtube)       echo ":youtube:" ;;
    youtube_music) echo ":youtube_music:" ;;
    music)         echo ":music:" ;;
    app:*)         get_app_icon "${1#app:}" ;;
  esac
}

source_color() {
  case "$1" in
    spotify)               echo "$SPOTIFY_GREEN" ;;
    youtube|youtube_music) echo "$YOUTUBE_RED" ;;
    music)                 echo "$APPLE_MUSIC_RED" ;;
    *)                     echo "$WHITE" ;;
  esac
}

update() {
  # Zen mode hides the pill; forget the last state so it redraws on exit
  if is_zen_mode; then
    save_state media_key zen
    set_drawing off
    return
  fi

  # Unit-separator delimited: tabs are IFS whitespace, so an empty artist
  # would collapse and shift the fields
  local bundle title artist playing
  IFS=$'\x1f' read -r bundle title artist playing < <(
    media-control get 2>/dev/null | jq -r '
      select(. != null and (.title // "") != "")
      | [.bundleIdentifier // "", .title, .artist // "", (.playing // false | tostring)]
      | join("\u001f")' 2>/dev/null)

  # Paused sessions linger forever, so treat paused as "nothing playing"
  # once it has been paused for PAUSE_GRACE seconds (the grace period
  # leaves time to resume from the bar's own button)
  if [[ -n "$title" && "$playing" != "true" ]]; then
    local now=$(date +%s) paused_at=$(load_state media_paused_at)
    [[ -z "$paused_at" ]] && { paused_at=$now; save_state media_paused_at "$now"; }
    (( now - paused_at >= PAUSE_GRACE )) && title=""
  else
    rm -f "$STATE_DIR/media_paused_at"
  fi

  local key="$bundle|$title|$artist|$playing"
  [[ "$key" == "$(load_state media_key)" && "$SENDER" == "routine" ]] && return
  save_state media_key "$key"

  if [[ -z "$title" ]]; then
    set_drawing off
    return
  fi

  # Source detection only depends on the track, not the play state
  local track_key="$bundle|$title" src
  if [[ "$track_key" == "$(load_state media_track)" ]]; then
    src=$(load_state media_source)
  else
    src=$(detect_source "$bundle" "$title")
    save_state media_track "$track_key"
    save_state media_source "$src"
  fi
  save_state media_bundle "$bundle"

  local label="$title"
  [[ -n "$artist" ]] && label="$title · $artist"
  (( ${#label} > TITLE_MAX )) && label="${label:0:TITLE_MAX-1}…"

  local play_icon=$MEDIA_PLAY label_color=$GREY
  [[ "$playing" == "true" ]] && { play_icon=$MEDIA_PAUSE; label_color=$WHITE; }

  sketchybar --set media      icon="$(source_icon "$src")" \
                              icon.color="$(source_color "$src")" \
                              label="$label" \
                              label.color="$label_color" \
             --set media.play icon="$play_icon"
  set_drawing on
}

# Send a transport command, then refresh once the player has reacted
control() {
  media-control "$1" >/dev/null 2>&1
  sleep 0.3
  trigger_event media_update
}

case "$1" in
  toggle) control toggle-play-pause ;;
  next)   control next-track ;;
  prev)   control previous-track ;;
  focus)
    bundle=$(load_state media_bundle)
    [[ -n "$bundle" ]] && open -b "$bundle"
    ;;
  *) update ;;
esac
