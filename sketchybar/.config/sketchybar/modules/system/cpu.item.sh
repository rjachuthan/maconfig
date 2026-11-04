#!/bin/bash

# CPU Module - Item Configuration
# Displays CPU usage with graphs


# Auto-detect CONFIG_DIR if not set (for IDE/shellcheck compatibility)
if [[ -z "$CONFIG_DIR" ]]; then
  CONFIG_DIR="$HOME/.config/sketchybar"
fi

source "$CONFIG_DIR/config.sh"

sketchybar --add item        cpu.top right                 \
           --set cpu.top     label.font="$FONT:Semibold:7" \
                             label=CPU                     \
                             label.max_chars=14            \
                             label.color=$GREY             \
                             icon.drawing=off              \
                             width=0                       \
                             padding_right=10              \
                             y_offset=6                    \
                                                           \
           --add item        cpu.percent right             \
           --set cpu.percent label.font="$FONT:Heavy:12"   \
                             label=CPU                     \
                             y_offset=-4                   \
                             padding_right=10              \
                             width=48                      \
                             icon.drawing=off              \
                             update_freq=2                 \
                             mach_helper="$HELPER_NAME"    \
                                                           \
           --add graph       cpu.sys right 50              \
           --set cpu.sys     width=0                       \
                             graph.color=$RED              \
                             graph.fill_color=$RED         \
                             label.drawing=off             \
                             icon.drawing=off              \
                             background.height=30          \
                             background.drawing=on         \
                             background.color=$TRANSPARENT \
                                                           \
           --add graph       cpu.user right 50             \
           --set cpu.user    graph.color=$BLUE             \
                             padding_left=8                \
                             label.drawing=off             \
                             icon.drawing=off              \
                             background.height=30          \
                             background.drawing=on         \
                             background.color=$TRANSPARENT
