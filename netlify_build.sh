#!/bin/bash

# Exit on any error
set -e

FLUTTER_PATH="$HOME/flutter"

if [ ! -d "$FLUTTER_PATH" ]; then
    echo "Cloning Flutter SDK..."
    git clone https://github.com/flutter/flutter.git --depth 1 -b stable "$FLUTTER_PATH"
fi

# Enable web support and use the absolute path to the flutter binary
"$FLUTTER_PATH/bin/flutter" config --enable-web
"$FLUTTER_PATH/bin/flutter" doctor -v

echo "Running Flutter build web..."
"$FLUTTER_PATH/bin/flutter" build web --release --web-renderer canvaskit -v

echo "Build successful."
