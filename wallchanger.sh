#!/usr/bin/env bash

### Script to automatically cycle through wallpapers.
### Parameters:
### $1: Path to a directory that contains the wallpapers, will be searched
###     recursively.
### $2: Timeout in seconds between wallpaper changes. If omitted or 0, the
###     wallpaper will only be set once.
### $3: A fallback directory that is used if the directory specified in $1
###     does not exist. In fallback mode, wallpapers will not be cycled, but
###     only the first one found will be used.

LOGFILE="$HOME/.var/log/wallchanger.log"

set -e

log() {
    if [[ "$LOGFILE" ]]; then
        echo -e "[$(date +%FT%T)] $*" >> "$LOGFILE"
    fi
}

output() {
    echo -e $*
    log $*
}

error() {
    msg="[ERROR] $*"
    echo -e $msg >&2
    log $msg
}

usage() {
    cat << EOF
usage: $(basename $0) PATH_TO_WALLPAPER_DIRECTORY INTERVAL_IN_SECONDS [FALLBACK_DIRECTORY]
EOF
}

FOLDER="$1"
TIMEOUT="$2"
FALLBACK="$3"

FALLBACK_MODE=0

if [[ -z "$FOLDER" ]]; then
    usage
    exit 1
elif [[ ! -d "$FOLDER" ]]; then
    error "\"$FOLDER\" is not a directory. Using fallback directory instead."
    if [[ -z "$FALLBACK" ]]; then
        error "Fallback directory not specified. Aborting."
        exit 1
    elif [[ ! -d "$FALLBACK" ]]; then
        error "\"$FALLBACK\" is not a directory. Aborting."
        exit 1
    fi
    FOLDER="$FALLBACK"
    FALLBACK_MODE=1
fi

if [[ -z "$TIMEOUT" ]]; then
    TIMEOUT=0
else
    if [[ ! $TIMEOUT =~ ^[0-9]+$ ]]; then
        error "Timeout \"$TIMEOUT\" is invalid."
        exit 1
    fi
fi

screencount=$(xrandr | awk '{if ($2 == "connected") {c+=1}} END{print c}')
output "[I] $screencount screens detected."

output "[I] Looking for pictures in \"$FOLDER\""
# -H resolves symbolic links for command line arguments only.
pics="$(find -H $FOLDER \( -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" \))"

pics_count=$(echo "$pics" | wc -l)
output "[I] $pics_count pictures found."

if [[ "$pics_count" -eq 0 ]]; then
    error  "No suitable wallpapers found. Aborting"
    exit 1
elif [[ "$pics_count" -lt "$screencount" ]]; then
    output "[W] Not enough wallpapers for every screen found."
    # setting TIMEOUT to 0 so the while loop aborts
    TIMEOUT=0
elif [[ "$pics_count" -eq "$screencount" ]]; then
    output "[W] Only found one wallpaper for every screen. Will just set the wallpaper once."
    TIMEOUT=0
fi

next_wallpaper() {
    for i in $(seq 0 $(( $screencount - 1 ))); do
        pic_array[$i]="$(echo "$pics" | shuf -n 1)"
    done
    output "[I] Changing wallpaper to \"${pic_array[@]}\"."
    if fehoutput=$(feh --bg-fill --no-fehbg "${pic_array[@]}" 2>&1); then
        output "[I] Wallpaper changed."
    else
        error "Changing wallpaper failed:\n\n${fehoutput}\n\n[E] Skipping." 
        sleep 1 
        return 1
    fi
}

trap ":" SIGUSR1
trap "error \"Unknown error. Terminating.\"" ERR

while : ; do
    next_wallpaper || continue
    if [[ -z "$TIMEOUT" || "$TIMEOUT" == "0" ]]; then
        output "[I] No timeout given. Done."
        break
    fi
    if [[ "$FALLBACK_MODE" == "1" ]]; then
        output "[I] No cycling in fallback mode. Done."
        break
    fi
    output "[I] Sleeping for $TIMEOUT seconds."
    sleep $TIMEOUT 2>/dev/null &
    wait || true
    output "[I] Waking up."
done

