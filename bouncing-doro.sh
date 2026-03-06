#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
IMAGE="${SCRIPT_DIR}/doro.png"

while [[ "$#" -gt 0 ]]; do
    case $1 in
        --image) IMAGE="$2"; shift ;;
        *) echo "Unknown parameter: $1"; exit 1 ;;
    esac
    shift
done

[[ ! -f "$IMAGE" ]] && { echo "Error: Image not found at $IMAGE"; exit 1; }

SPRITE_SIZE="${DORO_SIZE:-30x20}"
SPRITE_RAW=$(chafa --size "$SPRITE_SIZE" --symbols vhalf --colors 256 "$IMAGE")
IFS=$'\n' read -rd '' -a SPRITE_LINES <<< "$SPRITE_RAW"
SPRITE_WIDTH="${SPRITE_SIZE%%x*}"
SPRITE_HEIGHT=${#SPRITE_LINES[@]}

COLORS=('\033[38;5;213m' '\033[38;5;177m' '\033[38;5;201m' '\033[38;5;51m')
COLOR_IDX=0

X=2
Y=2
DX=1
DY=1

cleanup() {
    printf '\033[?25h'  # ANSI show cursor
    tput rmcup
    exit 0
}
trap cleanup SIGTERM SIGINT EXIT

tput smcup
printf '\033[?25l'  # ANSI hide cursor (more reliable than tput civis)
clear

while true; do
    COLS=$(tput cols)
    LINES=$(tput lines)
    MAX_X=$((COLS - SPRITE_WIDTH))
    MAX_Y=$((LINES - SPRITE_HEIGHT))
    [[ $MAX_X -lt 2 ]] && MAX_X=2
    [[ $MAX_Y -lt 2 ]] && MAX_Y=2

    ((X += DX))
    ((Y += DY))

    HIT_EDGE=false

    if ((X <= 1)); then X=1; DX=$((-DX)); HIT_EDGE=true; fi
    if ((X >= MAX_X)); then X=$MAX_X; DX=$((-DX)); HIT_EDGE=true; fi
    if ((Y <= 1)); then Y=1; DY=$((-DY)); HIT_EDGE=true; fi
    if ((Y >= MAX_Y)); then Y=$MAX_Y; DY=$((-DY)); HIT_EDGE=true; fi

    [[ "$HIT_EDGE" == true ]] && COLOR_IDX=$(( (COLOR_IDX + 1) % ${#COLORS[@]} ))

    # Draw using tput cup (faster, no buffer issues)
    CURRENT_COLOR="${COLORS[$COLOR_IDX]}"
    for ((i=0; i<SPRITE_HEIGHT; i++)); do
        tput cup $((Y + i)) $X
        printf "%b%s\033[0m" "$CURRENT_COLOR" "${SPRITE_LINES[$i]}"
    done

    # Move cursor to bottom-right corner so it's not visible over Doro
    tput cup $(tput lines) 0

    sleep 0.066
done
