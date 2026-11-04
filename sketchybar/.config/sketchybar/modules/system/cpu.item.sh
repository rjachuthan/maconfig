#!/bin/bash

# CPU Module - Item Configuration
# Displays CPU usage with graphs

sketchybar --add item        cpu.top right                 \
           --set cpu.top     label.font="$FONT:Semibold:7" \
                             label=CPU                     \
                             label.max_chars=14            \
                             label.width=60                \
                             label.align=right             \
                             label.color=$GREY             \
                             icon.drawing=off              \
                             width=0                       \
                             padding_right=12              \
                             y_offset=6                    \
                                                           \
           --add item        cpu.percent right             \
           --set cpu.percent label.font="$FONT:Heavy:12"   \
                             label=CPU                     \
                             y_offset=-4                   \
                             padding_right=12              \
                             width=60                      \
                             label.align=right             \
                             icon.drawing=off              \
                             update_freq=2                 \
                             mach_helper="$HELPER_NAME"    \
                                                           \
           --add graph       cpu.sys right 44              \
           --set cpu.sys     width=0                       \
                             graph.color=$RED              \
                             graph.fill_color=0x66ff5f87 \
                             label.drawing=off             \
                             icon.drawing=off              \
                             background.height=30          \
                             background.drawing=on         \
                             background.color=$TRANSPARENT \
                                                           \
           --add graph       cpu.user right 44             \
           --set cpu.user    graph.color=$BLUE             \
                             graph.fill_color=0x665fafff   \
                             padding_left=12               \
                             graph.line_width=1.5          \
                             label.drawing=off             \
                             icon.drawing=off              \
                             background.height=30          \
                             background.drawing=on         \
                             background.color=$TRANSPARENT
