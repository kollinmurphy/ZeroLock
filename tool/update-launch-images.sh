#!/bin/bash
cd "$(cd "$(dirname "$0")" && pwd)" || exit 1
python3 ./update-launch-images.py ../Broke/Assets.xcassets/LaunchImage.launchimage --bg "#292928" --svg ../logo-transparent.svg --scale 0.4
