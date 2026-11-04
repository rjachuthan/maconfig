#!/bin/bash

# Herdr Module - Plugin
# Polls `herdr agent list` (cheap, ~10 ms) and shows counts of agents that are
# working, blocked or done-but-unseen. Redraws only when something changed.
# The popup lists every agent (idle ones too) with its CLI's logo.
#   herdr.plugin.sh          refresh (routine / herdr_update / forced)
#   herdr.plugin.sh click    toggle the agent popup

source "$CONFIG_DIR/config.sh"

# App that hosts the herdr TUI, brought to the front when jumping to an agent
HERDR_TERMINAL_APP="Ghostty"
# Max characters of an agent title in the popup
TITLE_MAX=36
# Per-agent logos: assets/agents/<agent>.png (herdr's agent id, e.g. claude,
# copilot, codex, opencode, pi). Unknown agents fall back to the herdr logo.
AGENT_LOGO_DIR="$CONFIG_DIR/assets/agents"

command -v herdr >/dev/null 2>&1 || export PATH="/opt/homebrew/bin:$PATH"

# All agents as compact JSON, most urgent first:
# [{"pane":"w1:p2","agent":"claude","status":"blocked","title":"RCT v2 UI revamp"}, ...]
all_agents() {
  herdr agent list 2>/dev/null | jq -c '
    def rank: {"blocked": 0, "done": 1, "working": 2}[.status] // 3;
    [.result.agents[]?
      | ((.cwd // "") | split("/") | last) as $dir
      | ((.terminal_title_stripped // "") | sub("^π - "; "")) as $t
      | {pane: .pane_id,
         agent: (.agent // ""),
         status: (.agent_status // "idle"),
         title: (if $t == "" or $t == "Claude Code" or $t == $dir then $dir else $t end)}]
    | sort_by(rank)' 2>/dev/null
}

agent_logo() {
  local logo="$AGENT_LOGO_DIR/$1.png"
  [[ -f "$logo" ]] || logo="$CONFIG_DIR/assets/herdr.png"
  echo "$logo"
}

status_icon() {
  case "$1" in
    working) echo "$AGENT_WORKING" ;;
    blocked) echo "$AGENT_BLOCKED" ;;
    done)    echo "$AGENT_DONE" ;;
    *)       echo "$AGENT_IDLE" ;;
  esac
}

status_color() {
  case "$1" in
    working) echo "$WHITE" ;;
    blocked) echo "$ORANGE" ;;
    done)    echo "$GREEN" ;;
    *)       echo "$GREY" ;;
  esac
}

# Rebuild the popup rows from the agent list
build_popup() {
  local agents="$1"
  local W=290 LOGO_W=24
  local total=$(echo "$agents" | jq 'length')
  local args=(--remove '/herdr\.popup\..*/')

  args+=(--add item herdr.popup.header popup.herdr
         --set herdr.popup.header
               icon.drawing=off
               label="HERDR AGENTS · $total"
               label.font="$FONT:Heavy:9.0"
               label.color=$GREY
               label.width=$W
               label.padding_left=0 label.padding_right=0
               padding_left=12 padding_right=12
               background.drawing=off)

  local i=0 pane agent status title
  while IFS=$'\t' read -r pane agent status title; do
    [[ -z "$pane" ]] && continue
    (( ${#title} > TITLE_MAX )) && title="${title:0:TITLE_MAX-1}…"

    # Row: [agent logo] [status glyph + title, coloured by status]. The logo
    # is the icon's background image, so the label carries the status glyph.
    args+=(--add item "herdr.popup.$i" popup.herdr
           --set "herdr.popup.$i"
                 icon=" "
                 icon.width=$LOGO_W
                 icon.padding_left=0 icon.padding_right=0
                 icon.background.drawing=on
                 icon.background.color=$TRANSPARENT
                 icon.background.image="$(agent_logo "$agent")"
                 icon.background.image.scale=0.125
                 icon.background.image.drawing=on
                 label="$(status_icon "$status")  $title"
                 label.font="$FONT:Semibold:12.5"
                 label.color="$(status_color "$status")"
                 label.width=$((W - LOGO_W))
                 label.padding_left=4 label.padding_right=0
                 padding_left=12 padding_right=12
                 background.drawing=off
                 click_script="herdr agent focus '$pane' >/dev/null 2>&1; open -a '$HERDR_TERMINAL_APP'; sketchybar --set herdr popup.drawing=off --trigger herdr_update")
    ((i++))
  done < <(echo "$agents" | jq -r '.[] | [.pane, .agent, .status, .title] | @tsv')

  if (( i == 0 )); then
    args+=(--add item herdr.popup.empty popup.herdr
           --set herdr.popup.empty
                 icon.drawing=off
                 label="No agents running"
                 label.font="$FONT:Semibold:12.5"
                 label.color=$GREY
                 label.width=$W
                 label.padding_left=0 label.padding_right=0
                 padding_left=12 padding_right=12
                 background.drawing=off)
  fi

  sketchybar "${args[@]}" >/dev/null 2>&1
}

update() {
  local agents=$(all_agents)
  [[ -z "$agents" ]] && agents="[]"

  # Skip redraws when nothing changed since the last poll
  [[ "$agents" == "$(load_state herdr_agents)" && "$SENDER" == "routine" ]] && return
  save_state herdr_agents "$agents"

  local working=$(echo "$agents" | jq '[.[] | select(.status == "working")] | length')
  local blocked=$(echo "$agents" | jq '[.[] | select(.status == "blocked")] | length')
  local n_done=$(echo "$agents" | jq '[.[] | select(.status == "done")] | length')
  local total=$((working + blocked + n_done))

  # The logo is always shown; counts appear only when non-zero. With no
  # counts the logo gets its own end padding so the pill stays balanced.
  local on_off=(off on)
  local logo_pad=0
  (( total == 0 )) && logo_pad=2
  sketchybar --set herdr          padding_right=$logo_pad \
             --set herdr.working  drawing=${on_off[$((working > 0))]} label="$working" \
             --set herdr.blocked  drawing=${on_off[$((blocked > 0))]} label="$blocked" \
             --set herdr.done     drawing=${on_off[$((n_done > 0))]} label="$n_done"

  # Keep the end padding on whichever count is last
  local last=""
  (( working > 0 )) && last=herdr.working
  (( blocked > 0 )) && last=herdr.blocked
  (( n_done > 0 )) && last=herdr.done
  sketchybar --set herdr.working label.padding_right=4 \
             --set herdr.blocked label.padding_right=4 \
             --set herdr.done label.padding_right=4
  [[ -n "$last" ]] && sketchybar --set "$last" label.padding_right=10

  if [[ "$(query_item herdr popup.drawing)" == "on" ]]; then
    build_popup "$agents"
  fi
}

toggle_popup() {
  if [[ "$(query_item herdr popup.drawing)" == "on" ]]; then
    sketchybar --set herdr popup.drawing=off
    return
  fi
  local agents=$(all_agents)
  build_popup "${agents:-[]}"
  sketchybar --set herdr popup.drawing=on
}

if [[ "$1" == "click" ]]; then
  toggle_popup
else
  update
fi
