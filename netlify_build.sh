#!/bin/bash

# Exit on any error
set -e

FLUTTER_PATH="$HOME/flutter"

if [ ! -d "$FLUTTER_PATH" ]; then
    echo "Cloning Flutter SDK..."
    git clone https://github.com/flutter/flutter.git --depth 1 -b stable "$FLUTTER_PATH"
fi

# Add flutter to path for this session
export PATH="$PATH:$FLUTTER_PATH/bin"

echo "Running Flutter build web..."
flutter build web --release --web-renderer canvaskit

echo "Build successful."
