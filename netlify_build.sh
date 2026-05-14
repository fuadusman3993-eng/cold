#!/bin/bash
set -e

FLUTTER_PATH="$HOME/flutter"

if [ ! -d "$FLUTTER_PATH" ]; then
    git clone https://github.com/flutter/flutter.git --depth 1 -b stable "$FLUTTER_PATH"
fi

export PATH="$PATH:$FLUTTER_PATH/bin"

flutter config --enable-web
flutter clean
flutter pub get
flutter build web --release --base-href "/"

echo "Build successful."
