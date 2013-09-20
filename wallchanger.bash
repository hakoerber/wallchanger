#!/usr/bin/env bash

### Script to automatically cycle through wallpapers.
### Parameters:
### $1: Path to a directory that contains the wallpapers, will be searched
###     recursively.
### $2: Timeout in seconds between wallpaper changes. If omitted or 0, the
###     wallpaper will only be set once.

FOLDER="$1"
TIMEOUT="$2"

screencount=$(xrandr | awk '{if ($2 == "connected") {c+=1}} END{print c}')

[[ -d "$FOLDER" ]] || { echo "[E] \"$FOLDER\" is not a directory." ; exit 1 ; }

[[ $TIMEOUT =~ ^[0-9]+$ ]] || \
    { echo "[E] Timeout \"$TIMEOUT\" is invalid." ; exit 1 ; }

pics="$(find $FOLDER \( -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" \))"

pics_count=$(echo "$pics" | wc -l)

if [[ "$pics_count" -eq 0 ]]; then
    echo "[E] No suitable wallpapers found. Aborting"
    exit 1
elif [[ "$pics_count" -lt "$screencount" ]]; then
    echo "[W] Not enough wallpapers for every screen found."
    # setting TIMEOUT to 0 so the while loop aborts
    TIMEOUT=0
elif [[ "$pics_count" -eq "$screencount" ]]; then
    echo "[W] Only found one wallpaper for every screen. Will just set the wallpaper once."
    TIMEOUT=0
fi

while true ; do
    pic_array=($(echo "$pics" | shuf -n $screencount))
    echo "[I] Changing wallpaper to \"${pic_array[@]}\"."
    output=$(feh --bg-fill --no-fehbg "${pic_array[@]}" 2>&1) && \
        echo "[I] Wallpaper changed." || \
        { echo -e \
            "[E] Changing wallpaper failed:\n\n${output}\n\n[E]Skipping." ; \
            sleep 1 ; continue ; }
    [[ -z "$TIMEOUT" || "$TIMEOUT" == "0" ]] && { echo "[I] Done." ; break ; }
    echo "[I] Sleeping for $TIMEOUT seconds."
    sleep $TIMEOUT 2>/dev/null
    echo "[I] Waking up."
done

