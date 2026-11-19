#!/bin/sh
# Per-project to-do lists, shared by people and agents (Over9k's To-do panel,
# mods/over9k-todos, shows and edits the same files).
#   todo                      this project's list, numbered, grouped by topic
#   todo all                  every project's
#   todo add <text…>          add to this project's (first: --due "YYYY-MM-DD[ HH:MM]",
#                             -t <topic> to file it under a topic)
#   todo done|undo <n|text>   tick or untick item n (or the one with that exact text)
#   todo edit <n|text> <new…> reword item n (its due, tick and topic stay)
#   todo move <n|text> <topic> put item n under a topic ("-" for none)
#   todo topics               the topics and their open counts
#   todo topic <old> <new…>   rename a topic
#   todo rm <n>               delete item n
#   todo clear                delete the ticked ones
#   todo log [on|off]         this project: agents add what you ask for (default: Options › To-do)
#   todo sync [on|off]        this project: its TODO.md follows add/edit/move/rm (default: Options › To-do)
#   todo --rule on|off        add or remove the agents' to-do rule (CLAUDE.md, AGENTS.md)
# -p <folder> (first) picks the project; otherwise it's the git repo this runs in
# (its main checkout for a worktree), else this folder.
# Each list is ~/.local/share/over9k/todos/<slug>.md (DIR): a "<!-- folder: … -->"
# line, then "- [ ] text" / "- [x] text" lines, items with no topic first, then a
# "## Topic" heading over each topic's items (fine to edit by hand).
# Installed by Over9k's Options › To-do (or install.sh) as ~/.local/bin/todo, a
# small wrapper that runs this file (todo-cross.py is found next to it).
set -e
# The agents' rule (Options › To-do turns it on and off), between markers so it
# can be taken out again exactly: in CLAUDE.md, Codex's and Pi's AGENTS.md.
if [ "${1:-}" = --rule ]; then
  for f in "$HOME/.claude/CLAUDE.md" "$HOME/.codex/AGENTS.md" "$HOME/.pi/agent/AGENTS.md"; do
    [ -d "$(dirname "$f")" ] || continue
    if [ -f "$f" ]; then
      tmp="$f.over9k.$$"
      sed '/<!-- over9k:todo -->/,/<!-- \/over9k:todo -->/d' "$f" | awk 'NF { for (; n > 0; n--) print ""; print; next } { n++ }' > "$tmp" && mv "$tmp" "$f"
    fi
    [ "${2:-}" = on ] && { [ -s "$f" ] && printf '\n'; cat <<'EOF'
<!-- over9k:todo -->
## Project to-do lists (Herdr)

Each project has a to-do list the user sees in Herdr's To-do panel and edits there
too. Use the `todo` command (it picks the project from the git repo you run it in):
`todo` lists it, `todo add <text>` adds, `todo done <n>` ticks, `todo rm <n>` deletes,
`todo all` shows every project's. Items are grouped by topic (`## Topic` sections):
`todo add -t <topic> <text>` files one under a topic, `todo move <n> <topic>` regroups
(`-` for none), `todo topics` lists them, `todo topic <old> <new>` renames one. Put each
new item under the topic it fits, reusing an existing topic where one fits; start a new
one only for a distinct area of work. Regroup when the user asks. Numbers change after a move, so run `todo` again before using one. While request logging is on
for that project
(`todo log` says; in Claude Code a note on each message says so), add each thing
the user asks for in a project (a change, a fix, a feature), even mid-task, as soon
as you read it, and tick it once it's done and checked; leave it open if it's only
partly done, and say so. When they change, narrow or drop a request, correct its
item instead of adding another: `todo edit <n> <new text>` rewords it, `todo rm <n>`
removes it. When they say to stop or start logging, run `todo log off` / `todo log on` (that project only). Also add an item when the user asks you to note something for later, or
when you leave follow-up work undone. Keep items short, one line each.
<!-- /over9k:todo -->
EOF
    } >> "$f"
  done
  exit 0
fi
# Where the lists live (the panel, main.js, uses the same folder).
DIR="${XDG_DATA_HOME:-$HOME/.local/share}/over9k/todos"
# This script's own folder, through a symlink (todo-cross.py lives there).
SELF=$(readlink -f "$0" 2>/dev/null || printf %s "$0")
HERE=$(dirname "$SELF")
# Python 3 for todo-cross.py: python3, else python (as on Windows); none: no TODO.md sync.
PY=$(command -v python3 2>/dev/null || command -v python 2>/dev/null || true)
dir=$DIR
mkdir -p "$dir"
folder=""
if [ "$1" = "-p" ]; then folder=$(cd "$2" && pwd); shift 2; fi
if [ -z "$folder" ]; then
  common=$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null || true)
  case "$common" in */.git) folder=${common%/.git} ;; *) folder=$(git rev-parse --show-toplevel 2>/dev/null || pwd) ;; esac
fi
folder=${folder%/}
# A project's Log or Sync: its own "<!-- log|sync: on|off -->" line, else the
# default Over9k's Options › To-do writes to todo-defaults ("log on", "sync off").
DEFAULTS="${XDG_DATA_HOME:-$HOME/.local/share}/over9k/todo-defaults"
opt() {
  v=$(sed -n -E "s/^<!-- $1: (on|off) -->\$/\1/p" "$file" 2>/dev/null | head -n 1)
  [ -n "$v" ] || v=$(sed -n -E "s/^$1 (on|off)\$/\1/p" "$DEFAULTS" 2>/dev/null | head -n 1)
  [ -n "$v" ] || { [ "$1" = log ] && v=on || v=off; }
  [ "$v" = on ]
}
# Sync on (`todo sync on`): the project's TODO.md follows add, edit and rm.
md() { [ -n "$PY" ] && opt sync && "$PY" -I "$HERE/todo-cross.py" "$folder" "$@" 2>/dev/null || true; }
slug=$(printf %s "$folder" | sed 's/[^A-Za-z0-9][^A-Za-z0-9]*/-/g; s/^-//; s/-$//')
file="$dir/$slug.md"

items() { [ -f "$1" ] && grep -E '^- \[( |x)\] ' "$1" || true; }
# A list, numbered as `items` counts, with a "## Topic" line over each topic.
show() {
  [ -f "$1" ] || return 0
  awk '
    /^## / { h = $0; sub(/^##[ \t]+/, "", h); sub(/[ \t]+$/, "", h); pend = h; next }
    /^- \[[ x]\] / {
      n++
      if (pend != "") { printf "%s## %s\n", (n > 1 ? "\n" : ""), pend; pend = "" }
      text = substr($0, 7); box = substr($0, 4, 1); due = ""; dn = ""
      if (match(text, /<!-- due: [^>]*-->/)) due = substr(text, RSTART + 10, RLENGTH - 14)
      if (match(text, /<!-- done: [^>]*-->/)) dn = substr(text, RSTART + 11, RLENGTH - 15)
      gsub(/ *<!--[^>]*-->/, "", text)
      printf "%3d. [%s] %s%s%s\n", n, box, text, (due != "" ? "  (due " due ")" : ""), (dn != "" ? "  (done " dn ")" : "")
    }' "$1"
}
# Item $1's number: as given, or the one whose text is exactly $1.
num() {
  case "$1" in
    *[!0-9]*) m=$(items "$file" | sed 's/^- \[.\] //; s/ *<!--[^>]*-->//g' | grep -n -x -F -- "$1" | head -n 1 | cut -d: -f1)
      [ -n "$m" ] || { echo "No item \"$1\"" >&2; return 1; }; echo "$m" ;;
    *) echo "$1" ;;
  esac
}
# Item $1's text (without its due and done marks).
text_of() { items "$file" | sed -n "${1}p" | sed 's/^- \[.\] //; s/ *<!--[^>]*-->//g'; }
# Puts line $2 at the end of topic $1's section ($1 empty: with the items that have
# no topic, before the first heading); a topic with no heading yet gets one at the end.
ins() {
  [ -f "$file" ] || printf '<!-- folder: %s -->\n' "$folder" > "$file"
  awk -v t="$1" -v new="$2" '
    { L[NR] = $0 }
    END {
      want = tolower(t); cur = ""; at = 0; head = 0; first = 0
      for (i = 1; i <= NR; i++) {
        if (L[i] ~ /^## /) {
          h = L[i]; sub(/^##[ \t]+/, "", h); sub(/[ \t]+$/, "", h); cur = tolower(h)
          if (!first) first = i
          if (want != "" && cur == want) { head = i; at = i }
          continue
        }
        if (L[i] ~ /^- \[[ x]\] / && cur == want) at = i
      }
      if (want == "" && !at) { if (first) { at = first - 1; while (at > 0 && L[at] == "") at-- } else at = NR }
      if (want != "" && !head) {
        n = NR; while (n > 0 && L[n] == "") n--
        for (i = 1; i <= n; i++) print L[i]
        print ""; print "## " t; print new
        exit
      }
      for (i = 1; i <= NR; i++) { print L[i]; if (i == at) print new }
    }' "$file" > "$file.tmp" && mv "$file.tmp" "$file"
}
# Drops headings with no items under them, and runs of blank lines.
tidy() {
  [ -f "$file" ] || return 0
  awk '
    { L[NR] = $0 }
    END {
      for (i = 1; i <= NR; i++) if (L[i] ~ /^## /) {
        keep = 0
        for (j = i + 1; j <= NR && L[j] !~ /^## /; j++) if (L[j] ~ /^- \[[ x]\] /) { keep = 1; break }
        if (!keep) drop[i] = 1
      }
      out = 0; blank = 0
      for (i = 1; i <= NR; i++) {
        if (drop[i]) continue
        if (L[i] == "") { blank = 1; continue }
        if (blank && out) print ""
        blank = 0; print L[i]; out = 1
      }
    }' "$file" > "$file.tmp" && mv "$file.tmp" "$file"
}
# Rewrites item $1 of this list with sed expression $2 (on that line only).
edit() {
  [ -f "$file" ] || { echo "No to-dos for $folder" >&2; exit 1; }
  line=$(grep -n -E '^- \[( |x)\] ' "$file" | sed -n "${1}p" | cut -d: -f1)
  [ -n "$line" ] || { echo "No item $1" >&2; exit 1; }
  sed "${line}$2" "$file" > "$file.tmp" && mv "$file.tmp" "$file"
}

cmd=${1:-list}; [ $# -gt 0 ] && shift
case "$cmd" in
  list|ls) [ -n "$(items "$file")" ] && show "$file" || echo "No to-dos for $folder" ;;
  all)
    for f in "$dir"/*.md; do
      [ -f "$f" ] && [ -n "$(items "$f")" ] || continue
      printf '%s\n' "$(sed -n 's/^<!-- folder: \(.*\) -->$/\1/p' "$f" | head -n 1 | sed "s#^$HOME#~#")"; show "$f"
    done ;;
  add)
    due="" topic=""
    while :; do case "${1:-}" in --due) due=$2; shift 2 ;; -t|--topic) topic=$2; shift 2 ;; *) break ;; esac; done
    text=$(printf '%s' "$*" | tr '\n' ' ' | sed 's/  *$//')
    topic=$(printf '%s' "$topic" | tr '\n' ' ' | sed 's/^  *//; s/  *$//'); [ "$topic" = "-" ] && topic=""
    [ -n "$text" ] || { echo "usage: todo add [-t topic] <text>" >&2; exit 2; }
    ins "$topic" "- [ ] $text${due:+ <!-- due: $due -->}"
    md add "$text" "$topic"
    echo "Added to $(printf %s "$folder" | sed "s#^$HOME#~#")${topic:+ › $topic}: $text" ;;
  # Also crossed out (or back in) in the project's own TODO.md, if it lists it.
  done|check|undo|uncheck)
    n=$(num "${1:?item number or text}")
    text=$(text_of "$n")
    case "$cmd" in done|check) way=done ;; *) way=undo ;; esac
    "$0" -p "$folder" "_$way" "$n"
    [ -n "$text" ] && { [ -n "$PY" ] && "$PY" -I "$HERE/todo-cross.py" "$folder" "$way" "$text" 2>/dev/null; } || true ;;
  _done) edit "${1:?item number}" "s/^- \\[ \\] \\(.*\\)\$/- [x] \\1 <!-- done: $(date '+%F %H:%M') -->/" ;;
  _undo) edit "${1:?item number}" 's/^- \[x\] /- [ ] /; s/ *<!-- done: [^>]* -->//' ;;
  edit|reword)
    n=$(num "${1:?item number or text}"); shift
    new=$(printf '%s' "$*" | tr '\n' ' ' | sed 's/  *$//')
    [ -n "$new" ] || { echo "usage: todo edit <n|text> <new text>" >&2; exit 2; }
    old=$(text_of "$n")
    [ -n "$old" ] || { echo "No item $n" >&2; exit 1; }
    # The new text, safe for sed's replacement (\, & and the | delimiter).
    esc=$(printf '%s' "$new" | sed 's/[\\&|]/\\&/g')
    edit "$n" "s|^\(- \[.\] \)[^<]*\(<!--.*\)\{0,1\}\$|\1$esc \2|; s| *\$||"
    md rename "$old" "$new"
    echo "Now: $new" ;;
  move|mv)
    n=$(num "${1:?item number or text}"); shift
    topic=$(printf '%s' "$*" | tr '\n' ' ' | sed 's/^  *//; s/  *$//'); [ "$topic" = "-" ] && topic=""
    raw=$(items "$file" | sed -n "${n}p")
    [ -n "$raw" ] || { echo "No item $n" >&2; exit 1; }
    text=$(text_of "$n")
    edit "$n" d; ins "$topic" "$raw"; tidy
    md move "$text" "$topic"
    echo "Moved to ${topic:-no topic}: $text" ;;
  topics)
    [ -f "$file" ] && awk '
      /^## / { h = $0; sub(/^##[ \t]+/, "", h); sub(/[ \t]+$/, "", h); if (!(h in c)) o[++k] = h; c[h] += 0; next }
      /^- \[ \] / { if (h != "") c[h]++ }
      END { for (i = 1; i <= k; i++) printf "%s (%d open)\n", o[i], c[o[i]] }' "$file" ;;
  topic)
    old=${1:?usage: todo topic <old> <new>}; shift
    new=$(printf '%s' "$*" | tr '\n' ' ' | sed 's/^  *//; s/  *$//')
    [ -n "$new" ] || { echo "usage: todo topic <old> <new>" >&2; exit 2; }
    [ -f "$file" ] || { echo "No to-dos for $folder" >&2; exit 1; }
    awk -v o="$old" -v n="$new" '
      /^## / { h = $0; sub(/^##[ \t]+/, "", h); sub(/[ \t]+$/, "", h); if (tolower(h) == tolower(o)) { print "## " n; f = 1; next } }
      { print }
      END { if (!f) exit 3 }' "$file" > "$file.tmp" || { rm -f "$file.tmp"; echo "No topic \"$old\"" >&2; exit 1; }
    mv "$file.tmp" "$file"
    md retopic "$old" "$new"
    echo "Topic now: $new" ;;
  # A project switch: "<!-- log|sync: on|off -->" under the folder line.
  log|sync)
    case "${1:-}" in on|off) want="<!-- $cmd: $1 -->" ;; "") want=keep ;; *) echo "usage: todo $cmd [on|off]" >&2; exit 2 ;; esac
    if [ "$want" != keep ]; then
      [ -f "$file" ] || printf '<!-- folder: %s -->\n' "$folder" > "$file"
      grep -v "^<!-- $cmd: [a-z]* -->\$" "$file" | awk -v w="$want" '{ print } NR == 1 && w != "" { print w }' > "$file.tmp" && mv "$file.tmp" "$file"
    fi
    if [ "$cmd" = log ]; then opt log && echo "Request logging: on" || echo "Request logging: off"
    else opt sync && echo "TODO.md sync: on" || echo "TODO.md sync: off"; fi ;;
  rm|delete)
    text=$(grep -E '^- \[( |x)\] ' "$file" 2>/dev/null | sed -n "${1:?item number}p" | sed 's/^- \[.\] //; s/ *<!--[^>]*-->//g')
    edit "$1" 'd'; tidy
    [ -n "$text" ] && md rm "$text" ;;
  clear) [ -f "$file" ] && { grep -v -E '^- \[x\] ' "$file" > "$file.tmp"; mv "$file.tmp" "$file"; tidy; } ;;
  *) sed -n '2,18s/^# \{0,1\}//p' "$SELF"; exit 2 ;;
esac
