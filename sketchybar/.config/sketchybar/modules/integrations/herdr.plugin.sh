#!/bin/bash

# Herdr Module - Plugin
# Polls `herdr agent list` (cheap, ~10 ms) and shows counts of agents that are
# working, blocked or done-but-unseen. Redraws only when something changed.
#   herdr.plugin.sh          refresh (routine / herdr_update / forced)
#   herdr.plugin.sh click    toggle the agent popup

source "$CONFIG_DIR/config.sh"

# App that hosts the herdr TUI, brought to the front when jumping to an agent
HERDR_TERMINAL_APP="Ghostty"
# Max characters of an agent title in the popup
TITLE_MAX=36

command -v herdr >/dev/null 2>&1 || export PATH="/opt/homebrew/bin:$PATH"

# Active agents as compact JSON, most urgent first:
# [{"pane":"w1:p2","status":"blocked","title":"RCT v2 UI revamp"}, ...]
active_agents() {
  herdr agent list 2>/dev/null | jq -c '
    def rank: {"blocked": 0, "done": 1, "working": 2}[.status];
    [.result.agents[]?
      | select(.agent_status == "working" or .agent_status == "blocked" or .agent_status == "done")
      | ((.cwd // "") | split("/") | last) as $dir
      | ((.terminal_title_stripped // "") | sub("^π - "; "")) as $t
      | {pane: .pane_id,
         status: .agent_status,
         title: (if $t == "" or $t == "Claude Code" or $t == $dir then $dir else $t end)}]
    | sort_by(rank)' 2>/dev/null
}

status_icon() {
  case "$1" in
    working) echo "$AGENT_WORKING" ;;
    blocked) echo "$AGENT_BLOCKED" ;;
    done)    echo "$AGENT_DONE" ;;
  esac
}

status_color() {
  case "$1" in
    working) echo "$WHITE" ;;
    blocked) echo "$ORANGE" ;;
    done)    echo "$GREEN" ;;
  esac
}

# Rebuild the popup rows from the agent list
build_popup() {
  local agents="$1"
  local W=250
  local args=(--remove '/herdr\.popup\..*/')

  args+=(--add item herdr.popup.header popup.herdr
         --set herdr.popup.header
               icon.drawing=off
               label="HERDR AGENTS"
               label.font="$FONT:Heavy:9.0"
               label.color=$GREY
               label.width=$W
               label.padding_left=0 label.padding_right=0
               padding_left=12 padding_right=12
               background.drawing=off)

  local i=0 pane status title
  while IFS=$'\t' read -r pane status title; do
    [[ -z "$pane" ]] && continue
    (( ${#title} > TITLE_MAX )) && title="${title:0:TITLE_MAX-1}…"
    args+=(--add item "herdr.popup.$i" popup.herdr
           --set "herdr.popup.$i"
                 icon="$(status_icon "$status")"
                 icon.font="$FONT:Bold:12.0"
                 icon.color="$(status_color "$status")"
                 icon.width=22
                 icon.padding_left=0 icon.padding_right=0
                 label="$title"
                 label.font="$FONT:Semibold:12.5"
                 label.color=$WHITE
                 label.width=$((W - 22))
                 label.padding_left=0 label.padding_right=0
                 padding_left=12 padding_right=12
                 background.drawing=off
                 click_script="herdr agent focus '$pane' >/dev/null 2>&1; open -a '$HERDR_TERMINAL_APP'; sketchybar --set herdr popup.drawing=off --trigger herdr_update")
    ((i++))
  done < <(echo "$agents" | jq -r '.[] | [.pane, .status, .title] | @tsv')

  if (( i == 0 )); then
    args+=(--add item herdr.popup.empty popup.herdr
           --set herdr.popup.empty
                 icon.drawing=off
                 label="All agents idle"
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
  local agents=$(active_agents)
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
  local agents=$(active_agents)
  build_popup "${agents:-[]}"
  sketchybar --set herdr popup.drawing=on
}

if [[ "$1" == "click" ]]; then
  toggle_popup
else
  update
fi
