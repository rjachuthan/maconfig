#!/bin/bash

# Volume Module - Item Configuration
# Volume icon; click it to reveal a slider that sets the volume

volume_slider=(
  script="$MODULE_DIR/system/volume.plugin.sh"
  updates=on
  label.drawing=off
  icon.drawing=off
  slider.highlight_color=$WHITE
  slider.background.height=5
  slider.background.corner_radius=3
  slider.background.color=$BACKGROUND_2
  slider.knob=􀀁
  slider.knob.drawing=off
)

volume_icon=(
  click_script="$MODULE_DIR/system/volume.plugin.sh"
  padding_left=0
  padding_right=4
  icon=$VOLUME_100
  icon.width=0
  icon.align=left
  icon.color=$GREY
  icon.font="$FONT:Regular:14.0"
  label.width=22
  label.align=left
  label.font="$FONT:Regular:14.0"
)

sketchybar --add slider volume right            \
           --set volume "${volume_slider[@]}"   \
           --subscribe volume volume_change     \
                              mouse.clicked     \
                              mouse.entered     \
                              mouse.exited      \
                                                \
           --add item volume_icon right         \
           --set volume_icon "${volume_icon[@]}"
