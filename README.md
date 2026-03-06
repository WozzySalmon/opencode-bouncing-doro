# 🩷 opencode-bouncing-doro

Bouncing Doro DVD screensaver while OpenCode thinks.

![Doro Bouncing GIF](https://via.placeholder.com/300x200.png?text=Bouncing+Doro+Demo)

## Features
- Small Doro anime character sprite rendered with `chafa` (`--symbols vhalf`, `--size 15x10`)
- Bouncing logic like the DVD logo screensaver
- Each time it hits a corner/edge, it shifts color through several pink/purple/cyan tones
- Appears only when OpenCode is in "thinking" or "generating" state
- Completely disappears when OpenCode is idle

## Requirements
- `bash`
- `chafa` (pre-renders the image)

## Installation
Copy this repository or its files to your OpenCode plugins directory:
- `~/.config/opencode/plugins/opencode-bouncing-doro/`
- or `~/.opencode/plugins/opencode-bouncing-doro/`

## Configuration
The default image is set to `/home/jess/dorofetch/logos/doro.png`.
You can pass a custom image using the `--image` flag within the script, or modify the `bouncing-doro.sh` directly.

## Credits
- Made for Mr.Bigg by Jess 👁️‍🗨️
