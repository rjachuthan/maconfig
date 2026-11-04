#!/bin/sh
# Report a `logo` token on agent panes so the sidebar can render `$logo`.
# Glyphs are Nerd Font codepoints; colours live in config.toml (rules on $logo).
# Startup tags every agent pane; agent_detected events tag only the event's pane.

HERDR="${HERDR_BIN_PATH:-herdr}"

logo_for() {
  case "$1" in
    claude)              printf '\363\260\233\204' ;; # 󰛄 nf-md-asterisk
    codex)               printf '\357\222\211' ;;     #  nf-oct-terminal
    gemini)              printf '\363\260\253\242' ;; # 󰫢 nf-md-star_four_points
    copilot|github_copilot) printf '\357\222\270' ;;  #  nf-oct-copilot
    pi)                  printf '\363\260\217\277' ;; # 󰏿 nf-md-pi
    cursor)              printf '\363\260\206\276' ;; # 󰆾 nf-md-cursor_default
    opencode|open_code)  printf '\363\260\205\251' ;; # 󰅩 nf-md-code_braces
    droid)               printf '\363\260\200\262' ;; # 󰀲 nf-md-android
    amp)                 printf '\363\261\220\213' ;; # 󱐋 nf-md-lightning_bolt
    *)                   printf '\363\260\232\251' ;; # 󰚩 nf-md-robot
  esac
}

# Pane the event is about; empty on startup (or unknown payload) => tag all panes.
target=""
if [ "$HERDR_PLUGIN_EVENT" != "startup" ]; then
  target=$(printf '%s' "$HERDR_PLUGIN_EVENT_JSON" |
    jq -r 'first(.. | objects | .pane_id? // empty)' 2>/dev/null)
  [ -n "$target" ] || target="$HERDR_PANE_ID"
fi

"$HERDR" agent list 2>/dev/null |
  jq -r --arg t "$target" '.result.agents[]?
    | select(.agent != null and ($t == "" or .pane_id == $t))
    | "\(.pane_id) \(.agent)"' |
  while read -r pane agent; do
    "$HERDR" pane report-metadata "$pane" --source agent-logos \
      --token "logo=$(logo_for "$agent")" >/dev/null 2>&1
  done
