#!/bin/bash
set -e

FILE="$1"

if [[ -z "$FILE" ]]; then
  echo "No file provided" >&2
  exit 1
fi

case "${FILE##*.}" in
  jpg|jpeg|png|gif|heic|tiff|bmp|webp|JPG|JPEG|PNG|GIF|HEIC|TIFF|BMP|WEBP)
    ;;
  *)
    echo "Not a supported image: $(basename "$FILE")" >&2
    exit 1
    ;;
esac

osascript -e "tell application \"Finder\" to set desktop picture to POSIX file \"$FILE\""
echo "Wallpaper set: $(basename "$FILE")"
