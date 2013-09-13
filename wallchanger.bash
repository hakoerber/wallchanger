#!/usr/bin/env bash

### Script to automatically cycle through wallpapers.
### Parameters:
### $1: Path to a directory that contains the wallpapers, will be searched
###     recursively.
### $2: Timeout in seconds between wallpaper changes. If omitted or 0, the
###     wallpaper will only be set once.

FOLDER="$1"
TIMEOUT="$2"

[[ -d "$FOLDER" ]] || { echo "[E] \"$FOLDER\" is not a directory." ; exit 1 ; }
[[ $TIMEOUT =~ ^[0-9]+$ ]] || \
    { echo "[E] Timeout \"$TIMEOUT\" is invalid." ; exit 1 ; }
pics="$(find $FOLDER -print -name "*.jpg" -o -name "*.jpeg" -o -name "*.png")"
while true ; do
    pic="$(echo "$pics" | shuf -n1)"
    echo "[I] Changing wallpaper to \"$pic\"."
    output=$(feh --bg-scale --no-fehbg "$pic" 2>&1) && \
        echo "[I] Wallpaper changed." || \
        { echo -e \
            "[E] Changing wallpaper failed:\n\n${output}\n\n[E]Skipping." ; \
            sleep 1 ; continue ; }
    [[ -z "$TIMEOUT" || "$TIMEOUT" == "0" ]] && { echo "[I] Done." ; break ; }
    echo "[I] Sleeping for $TIMEOUT seconds."
    sleep $TIMEOUT 2>/dev/null
    echo "[I] Waking up."
done

