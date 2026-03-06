#!/bin/bash

# Default image path — look next to this script first
SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
IMAGE="${SCRIPT_DIR}/doro.png"

# Parse arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --image) IMAGE="$2"; shift ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

if [[ ! -f "$IMAGE" ]]; then
    echo "Error: Image not found at $IMAGE"
    exit 1
fi

# Pre-render the sprite with chafa
# We use --symbols vhalf as requested. Size 15x10.
# Render sprite — bigger size + full block for more detail
SPRITE_SIZE="${DORO_SIZE:-30x20}"
SPRITE_RAW=$(chafa --size "$SPRITE_SIZE" --symbols block+border+space --colors 256 --color-space din99d "$IMAGE")
IFS=$'\n' read -rd '' -a SPRITE_LINES <<< "$SPRITE_RAW"
# Calculate actual width from rendered output
SPRITE_WIDTH="${SPRITE_SIZE%%x*}"
SPRITE_HEIGHT=${#SPRITE_LINES[@]}

# Colors
COLORS=('\033[38;5;213m' '\033[38;5;177m' '\033[38;5;201m' '\033[38;5;51m')
COLOR_IDX=0

# Cleanup function
cleanup() {
    tput cnorm  # Show cursor
    tput rmcup  # Restore original screen buffer
    exit 0
}

trap cleanup SIGTERM SIGINT

# Initial position and velocity
X=1
Y=1
DX=1
DY=1

# Switch to alternate screen buffer (preserves original terminal content)
tput smcup
# Hide cursor
tput civis

while true; do
    # Get terminal dimensions
    COLS=$(tput cols)
    LINES=$(tput lines)

    # Calculate boundaries
    MAX_X=$((COLS - SPRITE_WIDTH + 1))
    MAX_Y=$((LINES - SPRITE_HEIGHT + 1))

    # Clear old sprite (only the characters we occupied)
    for ((i=0; i<SPRITE_HEIGHT; i++)); do
        printf "\033[%d;%dH" $((Y + i)) $X
        printf "%${SPRITE_WIDTH}s" ""
    done

    # Move
    ((X += DX))
    ((Y += DY))

    HIT_CORNER=false

    # Bounce X
    if ((X <= 1)); then
        X=1
        DX=$(( -DX ))
        HIT_CORNER=true
    elif ((X >= MAX_X)); then
        X=$MAX_X
        DX=$(( -DX ))
        HIT_CORNER=true
    fi

    # Bounce Y
    if ((Y <= 1)); then
        Y=1
        DY=$(( -DY ))
        HIT_CORNER=true
    elif ((Y >= MAX_Y)); then
        Y=$MAX_Y
        DY=$(( -DY ))
        HIT_CORNER=true
    fi

    # Color shift on corner hit
    if [ "$HIT_CORNER" = true ]; then
        COLOR_IDX=$(( (COLOR_IDX + 1) % ${#COLORS[@]} ))
    fi

    # Draw new sprite
    CURRENT_COLOR="${COLORS[$COLOR_IDX]}"
    for ((i=0; i<SPRITE_HEIGHT; i++)); do
        printf "\033[%d;%dH%b%s\033[0m" $((Y + i)) $X "$CURRENT_COLOR" "${SPRITE_LINES[$i]}"
    done

    sleep 0.066
done
