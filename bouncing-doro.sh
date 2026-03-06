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

# Render sprite — vhalf for smooth look, transparent bg
SPRITE_SIZE="${DORO_SIZE:-30x20}"
SPRITE_RAW=$(chafa --size "$SPRITE_SIZE" --symbols vhalf --colors 256 --color-space din99d --bg 000000 --fill space "$IMAGE" 2>/dev/null || \
             chafa --size "$SPRITE_SIZE" --symbols vhalf --colors 256 "$IMAGE")
IFS=$'\n' read -rd '' -a SPRITE_LINES <<< "$SPRITE_RAW"
SPRITE_WIDTH="${SPRITE_SIZE%%x*}"
SPRITE_HEIGHT=${#SPRITE_LINES[@]}

# Colors for corner hits
COLORS=('\033[38;5;213m' '\033[38;5;177m' '\033[38;5;201m' '\033[38;5;51m')
COLOR_IDX=0

# Cleanup
cleanup() {
    tput cnorm
    tput rmcup
    exit 0
}
trap cleanup SIGTERM SIGINT EXIT

# Initial position and velocity
X=2
Y=2
DX=1
DY=1

# Switch to alternate screen + hide cursor + black background
tput smcup
tput civis
printf "\033[2J"  # Clear alternate screen

while true; do
    COLS=$(tput cols)
    LINES_T=$(tput lines)
    MAX_X=$((COLS - SPRITE_WIDTH))
    MAX_Y=$((LINES_T - SPRITE_HEIGHT))
    [[ $MAX_X -lt 2 ]] && MAX_X=2
    [[ $MAX_Y -lt 2 ]] && MAX_Y=2

    # Build entire frame in buffer to avoid flicker
    FRAME=""

    # Clear old position
    for ((i=0; i<SPRITE_HEIGHT; i++)); do
        FRAME+="\033[$((Y + i));${X}H$(printf '%*s' "$SPRITE_WIDTH" '')"
    done

    # Move
    ((X += DX))
    ((Y += DY))

    HIT_EDGE_X=false
    HIT_EDGE_Y=false

    if ((X <= 1)); then X=1; DX=$((-DX)); HIT_EDGE_X=true; fi
    if ((X >= MAX_X)); then X=$MAX_X; DX=$((-DX)); HIT_EDGE_X=true; fi
    if ((Y <= 1)); then Y=1; DY=$((-DY)); HIT_EDGE_Y=true; fi
    if ((Y >= MAX_Y)); then Y=$MAX_Y; DY=$((-DY)); HIT_EDGE_Y=true; fi

    # Color shift on any edge hit
    if [[ "$HIT_EDGE_X" == true ]] || [[ "$HIT_EDGE_Y" == true ]]; then
        COLOR_IDX=$(( (COLOR_IDX + 1) % ${#COLORS[@]} ))
    fi

    # Draw sprite at new position
    CURRENT_COLOR="${COLORS[$COLOR_IDX]}"
    for ((i=0; i<SPRITE_HEIGHT; i++)); do
        FRAME+="\033[$((Y + i));${X}H${CURRENT_COLOR}${SPRITE_LINES[$i]}\033[0m"
    done

    # Flush entire frame at once — no flicker
    printf '%b' "$FRAME"

    sleep 0.066
done
