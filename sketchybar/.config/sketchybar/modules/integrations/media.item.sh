#!/bin/bash

# Media Module - Item Configuration
# Left-side pill for whatever is playing system-wide (via `media-control`):
#   [source logo] [title] [prev] [play/pause] [next]
# The logo reflects where the media is playing: Spotify, YouTube, YouTube
# Music, Apple Music, or the host app's icon otherwise. Click the logo/title
# to bring that app to the front. Hidden when nothing is playing.

MEDIA_PLUGIN="$MODULE_DIR/integrations/media.plugin.sh"

media_button=(
  drawing=off
  icon.font="$FONT:Regular:12.0"
  icon.color=$WHITE
  icon.padding_left=5
  icon.padding_right=5
  label.drawing=off
  padding_left=0
  padding_right=0
)

sketchybar --add event media_update \
                                                       \
           --add item media left \
           --set media drawing=off \
                 updates=on \
                 update_freq=2 \
                 script="$MEDIA_PLUGIN" \
                 click_script="$MEDIA_PLUGIN focus" \
                 icon.font="sketchybar-app-font:Regular:15.0" \
                 icon.padding_left=10 \
                 icon.padding_right=4 \
                 label.font="$FONT:Semibold:12.5" \
                 label.padding_left=2 \
                 label.padding_right=4 \
                 padding_left=0 \
                 padding_right=0 \
           --subscribe media media_update system_woke \
                                                       \
           --add item media.prev left \
           --set media.prev "${media_button[@]}" icon="$MEDIA_PREV" \
                 click_script="$MEDIA_PLUGIN prev" \
                                                       \
           --add item media.play left \
           --set media.play "${media_button[@]}" icon="$MEDIA_PLAY" \
                 click_script="$MEDIA_PLUGIN toggle" \
                                                       \
           --add item media.next left \
           --set media.next "${media_button[@]}" icon="$MEDIA_NEXT" \
                 icon.padding_right=10 \
                 click_script="$MEDIA_PLUGIN next" \
                                                       \
           --add bracket media.pill media media.prev media.play media.next \
           --set media.pill "${pill[@]}" drawing=off
