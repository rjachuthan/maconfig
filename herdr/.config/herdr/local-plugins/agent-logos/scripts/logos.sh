#!/bin/sh
# Report a `logo` token on each agent pane so the sidebar can render `$logo`.
# Glyphs are Nerd Font codepoints; colours live in config.toml (rows_by_agent).

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

"$HERDR" agent list 2>/dev/null |
  jq -r '.result.agents[]? | select(.agent != null) | "\(.pane_id) \(.agent)"' |
  while read -r pane agent; do
    "$HERDR" pane report-metadata "$pane" --source agent-logos \
      --token "logo=$(logo_for "$agent")" >/dev/null 2>&1
  done
