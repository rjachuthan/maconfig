#!/bin/sh
# Builds HerdrAlerts.app, Better Alerts' notifier, into the mod's bin/ (or the folder given),
# with Herdr's icon, signed for this Mac. Needs swiftc and codesign: xcode-select --install.
set -eu
here=$(cd "$(dirname "$0")" && pwd)
out=${1:-$here/../bin}
app="$out/HerdrAlerts.app"

[ "$(uname -s)" = Darwin ] || { echo "HerdrAlerts is for macOS." >&2; exit 1; }
command -v swiftc >/dev/null || { echo "swiftc is missing: run xcode-select --install" >&2; exit 1; }

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/HerdrAlerts.app/Contents/MacOS" "$tmp/HerdrAlerts.app/Contents/Resources"
swiftc -O -o "$tmp/HerdrAlerts.app/Contents/MacOS/HerdrAlerts" "$here/main.swift"
cp "$here/Info.plist" "$tmp/HerdrAlerts.app/Contents/Info.plist"
# Herdr's own icon, from the bundle herdr-app links to (Spotlight or /Applications otherwise);
# without it the banner shows a blank one.
link=$(readlink "$(command -v herdr-app 2>/dev/null)" 2>/dev/null || true)
herdr=${link%/Contents/MacOS/*}
[ -n "$link" ] && [ -d "$herdr" ] || herdr=$(mdfind "kMDItemCFBundleIdentifier == 'dev.herdr.app'" 2>/dev/null | head -n 1)
icon="${herdr:-/Applications/Herdr.app}/Contents/Resources/Herdr.icns"
if [ -f "$icon" ]; then cp "$icon" "$tmp/HerdrAlerts.app/Contents/Resources/Herdr.icns"; else echo "Herdr's icon wasn't found; the banner shows a blank one." >&2; fi
codesign --force --sign - "$tmp/HerdrAlerts.app"

mkdir -p "$out"
rm -rf "$app"
mv "$tmp/HerdrAlerts.app" "$app"
echo "Built $app"
