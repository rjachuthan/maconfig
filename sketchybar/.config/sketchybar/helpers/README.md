# Helpers Directory

This directory contains auto-generated helper files from the [sketchybar-app-font](https://github.com/kvndrsslr/sketchybar-app-font) project.

## Files

- `icon_map.sh` - Auto-generated icon mapping function (444 app mappings)

## Updating Icons

To update the icon mappings with the latest icons from sketchybar-app-font:

```bash
# Clone or update the repository
cd /tmp
git clone https://github.com/kvndrsslr/sketchybar-app-font.git
# or: cd /tmp/sketchybar-app-font && git pull

# Install dependencies and build
cd sketchybar-app-font
npm install
npm run build:install

# The icon_map.sh will be automatically updated at ~/.config/sketchybar/helpers/icon_map.sh
```

## Usage

The `icon_map.sh` file is sourced by `lib/common.sh`, which exposes
`get_app_icon` (used by the front app module).

To use the icon map in your scripts:

```bash
source "$CONFIG_DIR/helpers/icon_map.sh"

__icon_map "App Name"
echo "$icon_result"  # Outputs: :app_name:
```

## Note

Do not manually edit `icon_map.sh` as it will be overwritten when you rebuild from sketchybar-app-font.
If you need custom mappings, contribute them to the upstream repository.
