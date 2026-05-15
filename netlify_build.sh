#!/bin/bash
set -e

# Define Flutter path
FLUTTER_PATH="$HOME/flutter"

# Clone Flutter if it doesn't exist
if [ ! -d "$FLUTTER_PATH" ]; then
    echo "Cloning Flutter stable branch..."
    git clone https://github.com/flutter/flutter.git --depth 1 -b stable "$FLUTTER_PATH"
fi

# Add Flutter to PATH
export PATH="$PATH:$FLUTTER_PATH/bin"

# Pre-cache web artifacts
echo "Pre-caching web artifacts..."
flutter precache --web

# Enable web support
flutter config --enable-web

# Get dependencies
echo "Fetching dependencies..."
flutter pub get

# Build for web with specified renderer
# Using --web-renderer canvaskit as requested for premium rendering
echo "Building Flutter Web with CanvasKit..."
flutter build web --release --base-href "/" --web-renderer canvaskit

echo "Build successful."
