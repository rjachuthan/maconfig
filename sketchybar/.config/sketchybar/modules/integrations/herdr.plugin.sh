#!/bin/bash

# Herdr Module - Plugin
# Polls both herdr front-ends and shows counts of agents that are working,
# blocked or done-but-unseen. Redraws only when something changed.
#   - Herdr TUI:     `herdr agent list` (herdr server, shown in Ghostty)
#   - Herdr Desktop: herdr-core's `terminal.list` over `hc connect`
# Each takes ~10-20 ms; whichever isn't running just contributes no agents.
# The popup lists every agent (idle ones too) with its CLI's logo, grouped by
# where it runs.
#   herdr.plugin.sh          refresh (routine / herdr_update / forced)
#   herdr.plugin.sh click    toggle the agent popup

source "$CONFIG_DIR/config.sh"

# App that hosts the herdr TUI, brought to the front when jumping to an agent
HERDR_TERMINAL_APP="Ghostty"
# The Herdr desktop app, brought to the front when jumping to one of its agents
HERDR_DESKTOP_APP="Herdr"
# Max characters of an agent title in the popup
TITLE_MAX=36
# Per-agent logos: assets/agents/<agent>.png (herdr's agent id, e.g. claude,
# copilot, codex, opencode, pi). Unknown agents fall back to the herdr logo.
AGENT_LOGO_DIR="$CONFIG_DIR/assets/agents"

command -v herdr >/dev/null 2>&1 || export PATH="/opt/homebrew/bin:$PATH"
# hc (herdr-core) and herdr-app install to ~/.local/bin
command -v hc >/dev/null 2>&1 || export PATH="$HOME/.local/bin:$PATH"

# Shared jq: drop a title that just repeats the agent or folder name
JQ_TITLE='def tidy($t; $dir):
  ($t | sub("^π - "; "") | sub(" - GitHub Copilot$"; "")) as $t
  | if $t == "" or $t == "Claude Code" or $t == "OpenCode" or $t == $dir then $dir else $t end;'

# Agents in the herdr TUI
tui_agents() {
  command -v herdr >/dev/null 2>&1 || { echo "[]"; return; }
  herdr agent list 2>/dev/null | jq -c "$JQ_TITLE"'
    [.result.agents[]?
      | ((.cwd // "") | split("/") | last) as $dir
      | {src: "tui",
         id: .pane_id,
         agent: (.agent // ""),
         status: (.agent_status // "idle"),
         title: tidy(.terminal_title_stripped // ""; $dir)}]' 2>/dev/null || echo "[]"
}

# Agents in the Herdr desktop app (terminals in herdr-core with an agent
# status). "done" stays set after you look at it; the app records the turn
# you last saw in the herdr.seen label, so done counts only while unseen.
app_agents() {
  command -v hc >/dev/null 2>&1 || { echo "[]"; return; }
  echo '{"jsonrpc":"2.0","id":1,"method":"terminal.list","params":{}}' \
    | hc connect 2>/dev/null | jq -c "$JQ_TITLE"'
    [.result.terminals[]?
      | select(.state == "live" and .status.state != null)
      | ((.cwd // "") | split("/") | last) as $dir
      | ((.labels["herdr.seen"] // "0") | tonumber? // 0) as $seen
      | .status.state as $s
      | {src: "app",
         id: .address,
         agent: ((.status.app // "") | if . == "claude-code" then "claude" else . end),
         status: (if $s == "error" then "blocked"
                  elif $s == "done" and $seen >= (.turn // 0) then "idle"
                  else $s end),
         title: tidy(.title // ""; $dir)}]' 2>/dev/null || echo "[]"
}

# All agents as compact JSON, most urgent first:
# [{"src":"app","id":"t4","agent":"claude","status":"blocked","title":"RCT v2 UI revamp"}, ...]
all_agents() {
  jq -cs '
    def rank: {"blocked": 0, "done": 1, "working": 2}[.status] // 3;
    add // [] | sort_by(rank)' <(tui_agents) <(app_agents) 2>/dev/null
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

# Click action for a popup row: focus the agent in its front-end, bring that
# app forward, close the popup and refresh (focusing marks it seen)
focus_cmd() {
  local src="$1" id="$2"
  local close="sketchybar --set herdr popup.drawing=off --trigger herdr_update"
  if [[ "$src" == "app" ]]; then
    echo "'$(command -v herdr-app)' do agent.focus --terminal '$id' >/dev/null 2>&1; open -a '$HERDR_DESKTOP_APP'; $close"
  else
    echo "'$(command -v herdr)' agent focus '$id' >/dev/null 2>&1; open -a '$HERDR_TERMINAL_APP'; $close"
  fi
}

# Rebuild the popup rows from the agent list: one section per front-end that
# has agents (TUI, then Desktop), each with its own header.
build_popup() {
  local agents="$1"
  local W=290 LOGO_W=24
  local args=(--remove '/herdr\.popup\..*/')

  local i=0 src name n id agent status title
  for src in tui app; do
    n=$(echo "$agents" | jq --arg s "$src" '[.[] | select(.src == $s)] | length')
    (( n == 0 )) && continue
    [[ "$src" == "app" ]] && name="HERDR DESKTOP" || name="HERDR TUI"

    args+=(--add item "herdr.popup.header.$src" popup.herdr
           --set "herdr.popup.header.$src"
                 icon.drawing=off
                 label="$name · $n"
                 label.font="$FONT:Heavy:9.0"
                 label.color=$GREY
                 label.width=$W
                 label.padding_left=0 label.padding_right=0
                 padding_left=12 padding_right=12
                 background.drawing=off)

    while IFS=$'\t' read -r id agent status title; do
      [[ -z "$id" ]] && continue
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
                   click_script="$(focus_cmd "$src" "$id")")
      ((i++))
    done < <(echo "$agents" | jq -r --arg s "$src" '.[] | select(.src == $s) | [.id, .agent, .status, .title] | @tsv')
  done

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
