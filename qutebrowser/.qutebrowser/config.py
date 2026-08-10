from typing import TYPE_CHECKING, Any

if TYPE_CHECKING:
    # qutebrowser injects these as globals when it execs this file; declaring
    # them here (guarded so it's a no-op at runtime) gives editors/linters a
    # real binding instead of "undefined name" for `c` and `config`.
    c: Any
    config: Any

config.load_autoconfig(False)

c.content.autoplay = False

config.set("content.cookies.accept", "all", "chrome-devtools://*")
config.set("content.cookies.accept", "all", "devtools://*")

config.set(
    "content.headers.user_agent",
    "Mozilla/5.0 ({os_info}) AppleWebKit/{webkit_version} (KHTML, like Gecko) {upstream_browser_key}/{upstream_browser_version} Safari/{webkit_version}",
    "https://web.whatsapp.com/",
)
config.set(
    "content.headers.user_agent",
    "Mozilla/5.0 ({os_info}) AppleWebKit/{webkit_version} (KHTML, like Gecko) {upstream_browser_key}/{upstream_browser_version} Safari/{webkit_version} Edg/{upstream_browser_version}",
    "https://accounts.google.com/*",
)
config.set(
    "content.headers.user_agent",
    "Mozilla/5.0 ({os_info}) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/99 Safari/537.36",
    "https://*.slack.com/*",
)

config.set("content.images", True, "chrome-devtools://*")
config.set("content.images", True, "devtools://*")

config.set("content.javascript.enabled", True, "chrome-devtools://*")
config.set("content.javascript.enabled", True, "devtools://*")
config.set("content.javascript.enabled", True, "chrome://*/*")
config.set("content.javascript.enabled", True, "qute://*/*")

# Hints
c.hints.auto_follow = "always"
c.hints.chars = "arstdhneiowfpluy"

# Input
c.input.partial_timeout = 0
c.keyhint.delay = 250

# Scrolling
c.scrolling.bar = "never"
c.scrolling.smooth = True

# Tabs
c.tabs.background = True
c.tabs.new_position.unrelated = "next"
c.tabs.select_on_remove = "prev"
c.tabs.title.format = "{index:>02}"
c.tabs.position = "left"
c.tabs.favicons.scale = 1.1
c.tabs.indicator.padding = {"top": 0, "right": 0, "bottom": 0, "left": 0}
c.tabs.indicator.width = 0
c.tabs.padding = {"top": 2, "right": 2, "bottom": 2, "left": 2}
c.tabs.width = 45

# URL / Zoom
c.url.open_base_url = True
c.zoom.default = "75%"

c.url.searchengines = {
    "DEFAULT": "https://search.brave.com/search?q={}",
    "d": "http://duckduckgo.com/?q={}",
    "am": "https://amazon.in/s?k={}",
    "gh": "http://github.com/search?q={}",
    "r": "http://www.reddit.com/r/{}/",
    "rt": "http://www.rottentomatoes.com/search/?search={}",
    "y": "http://www.youtube.com/results?search_query={}",
    "g": "https://google.com/search?q={}",
    "gdr": "https://www.goodreads.com/search?q={}",
    "gen": "http://libgen.rs/search.php?req={}",
}

# Dark mode
config.set("colors.webpage.darkmode.enabled", True)

# Editor — ghostty on macOS
c.editor.command = ["ghostty", "-e", "nvim", "{}"]

# Fonts
c.fonts.default_size = "10pt"
c.fonts.contextmenu = "JetBrains Mono"
c.fonts.default_family = "JetBrains Mono"

# Window
c.window.hide_decoration = True

# Downloads
c.downloads.position = "bottom"
c.downloads.location.directory = "~/Downloads"
c.downloads.location.prompt = False

# Ad blocking
c.content.blocking.adblock.lists = [
    "https://raw.githubusercontent.com/uBlockOrigin/uAssets/master/filters/filters-2020.txt",
    "https://easylist.to/easylist/easylist.txt",
    "https://easylist.to/easylist/easyprivacy.txt",
]
c.content.blocking.method = "both"
c.content.notifications.enabled = False
c.content.cookies.accept = "all"
c.content.tls.certificate_errors = "load-insecurely"
c.content.fullscreen.window = True
c.content.geolocation = "ask"
c.content.webgl = True

# Key bindings
config.bind(",p", "open -p")
config.bind(
    ",y",
    "hint links spawn /opt/homebrew/bin/yt-dlp "
    "--ffmpeg-location /opt/homebrew/bin/ffmpeg "
    "-o ~/Downloads/%(title)s.%(ext)s "
    "{hint-url}",
)
config.bind(",s", "config-source")
config.bind(",d", "set downloads.location.directory ~/Downloads/;; hint links download")
config.bind(",i", "set downloads.location.directory ~/Pictures/;; hint images download")

config.bind("M", "hint links spawn /Users/rituraj/Codes/scripts/youtube {hint-url}")
config.bind(",f", "hint links run open -t https://freedium-mirror.cfd/{hint-url}")
config.bind(",z", "hint links run open -t https://defuddle.md/freedium-mirror.cfd/{hint-url}")
config.bind(",u", "hint links run open -t https://defuddle.md/{hint-url}")
config.bind("t", "set-cmd-text -s :open -t")
config.bind("PB", "hint links run open -p {hint-url}")
config.bind("xb", "config-cycle statusbar.show always never")
config.bind("xt", "config-cycle tabs.show always never")
config.bind(
    "xx",
    "config-cycle statusbar.show always never;; config-cycle tabs.show always never",
)

# Colors — hints
c.colors.hints.bg = "qlineargradient(x1:0, y1:0, x2:0, y2:1, stop:0 rgba(255, 247, 133, 1), stop:1 rgba(255, 197, 66, 1))"
c.colors.hints.fg = "black"
c.colors.hints.match.fg = "#c02020"
c.fonts.hints = "bold 11pt JetBrains Mono"

# Colors — completion
c.colors.completion.category.bg = (
    "qlineargradient(x1:0, y1:0, x2:0, y2:1, stop:0 #888888, stop:1 #505050)"
)
c.colors.completion.category.border.bottom = "black"
c.colors.completion.category.border.top = "black"
c.colors.completion.category.fg = "white"
c.colors.completion.even.bg = "#333333"
c.colors.completion.fg = "white"
c.colors.completion.item.selected.bg = "#e8c000"
c.colors.completion.item.selected.border.bottom = "#bbbb00"
c.colors.completion.item.selected.border.top = "#bbbb00"
c.colors.completion.item.selected.fg = "black"
c.colors.completion.match.fg = "#ff4444"
c.colors.completion.odd.bg = "#444444"
c.colors.completion.scrollbar.bg = "#333333"
c.colors.completion.scrollbar.fg = "white"

# Colors — downloads
c.colors.downloads.bar.bg = "black"
c.colors.downloads.error.bg = "red"
c.colors.downloads.error.fg = "white"
c.colors.downloads.start.bg = "#0000aa"
c.colors.downloads.start.fg = "white"
c.colors.downloads.stop.bg = "#00aa00"
c.colors.downloads.stop.fg = "white"
c.colors.downloads.system.bg = "rgb"
c.colors.downloads.system.fg = "rgb"

# Colors — keyhint
c.colors.keyhint.bg = "rgba(0, 0, 0, 80%)"
c.colors.keyhint.fg = "#FFFFFF"
c.colors.keyhint.suffix.fg = "#FFFF00"

# Colors — messages
c.colors.messages.error.bg = "red"
c.colors.messages.error.border = "#bb0000"
c.colors.messages.error.fg = "white"
c.colors.messages.info.bg = "black"
c.colors.messages.info.border = "#333333"
c.colors.messages.info.fg = "white"
c.colors.messages.warning.bg = "darkorange"
c.colors.messages.warning.border = "#d47300"
c.colors.messages.warning.fg = "white"

# Colors — prompts
c.colors.prompts.bg = "#444444"
c.colors.prompts.border = "1px solid gray"
c.colors.prompts.fg = "white"
c.colors.prompts.selected.bg = "grey"

# Colors — statusbar
c.colors.statusbar.caret.bg = "purple"
c.colors.statusbar.caret.fg = "white"
c.colors.statusbar.caret.selection.bg = "#a12dff"
c.colors.statusbar.caret.selection.fg = "white"
c.colors.statusbar.command.bg = "black"
c.colors.statusbar.command.fg = "white"
c.colors.statusbar.command.private.bg = "black"
c.colors.statusbar.command.private.fg = "white"
c.colors.statusbar.insert.bg = "darkgreen"
c.colors.statusbar.insert.fg = "white"
c.colors.statusbar.normal.bg = "black"
c.colors.statusbar.normal.fg = "white"
c.colors.statusbar.private.bg = "#666666"
c.colors.statusbar.private.fg = "white"
c.colors.statusbar.progress.bg = "white"
c.colors.statusbar.url.error.fg = "orange"
c.colors.statusbar.url.fg = "white"
c.colors.statusbar.url.hover.fg = "aqua"
c.colors.statusbar.url.success.http.fg = "white"
c.colors.statusbar.url.success.https.fg = "lime"
c.colors.statusbar.url.warn.fg = "yellow"

# Colors — tabs
c.colors.tabs.bar.bg = "black"
c.colors.tabs.even.bg = "darkgrey"
c.colors.tabs.even.fg = "white"
c.colors.tabs.indicator.error = "#ff0000"
c.colors.tabs.indicator.start = "#0000aa"
c.colors.tabs.indicator.stop = "#00aa00"
c.colors.tabs.indicator.system = "rgb"
c.colors.tabs.odd.bg = "grey"
c.colors.tabs.odd.fg = "white"
c.colors.tabs.selected.even.bg = "black"
c.colors.tabs.selected.even.fg = "white"
c.colors.tabs.selected.odd.bg = "black"
c.colors.tabs.selected.odd.fg = "grey"

# Colors — webpage
c.colors.webpage.bg = "white"
