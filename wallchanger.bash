#!/usr/bin/env bash

### Script to automatically cycle through wallpapers.
### Parameters:
### $1: Path to a directory that contains the wallpapers, will be searched
###     recursively.
### $2: Timeout in seconds between wallpaper changes. If omitted or 0, the
###     wallpaper will only be set once.

output() {
    echo -e  "[$(date +%FT%T)] $*"
}

FOLDER="$1"
TIMEOUT="$2"

[[ -d "$FOLDER" ]] || { output "[E] \"$FOLDER\" is not a directory." ; exit 1 ; }

[[ $TIMEOUT =~ ^[0-9]+$ ]] || \
    { output "[E] Timeout \"$TIMEOUT\" is invalid." ; exit 1 ; }

screencount=$(xrandr | awk '{if ($2 == "connected") {c+=1}} END{print c}')
output "[I] $screencount screens detected."

pics="$(find $FOLDER \( -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" \))"

pics_count=$(echo "$pics" | wc -l)
output "[I] $pics_count pictures found."

if [[ "$pics_count" -eq 0 ]]; then
    output "[E] No suitable wallpapers found. Aborting"
    exit 1
elif [[ "$pics_count" -lt "$screencount" ]]; then
    output "[W] Not enough wallpapers for every screen found."
    # setting TIMEOUT to 0 so the while loop aborts
    TIMEOUT=0
elif [[ "$pics_count" -eq "$screencount" ]]; then
    output "[W] Only found one wallpaper for every screen. Will just set the wallpaper once."
    TIMEOUT=0
fi

while true ; do
    pic_array=($(echo "$pics" | shuf -n $screencount))
    echo "[I] Changing wallpaper to \"${pic_array[@]}\"."
    output=$(feh --bg-fill --no-fehbg "${pic_array[@]}" 2>&1) && \
        output "[I] Wallpaper changed." || \
        { output \
            "[E] Changing wallpaper failed:\n\n${output}\n\n[E] Skipping." ; \
            sleep 1 ; continue ; }
    [[ -z "$TIMEOUT" || "$TIMEOUT" == "0" ]] && { output "[I] Done." ; break ; }
    output "[I] Sleeping for $TIMEOUT seconds."
    sleep $TIMEOUT 2>/dev/null
    output "[I] Waking up."
done

