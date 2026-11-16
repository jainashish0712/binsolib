#!/usr/bin/env bash
set -e

echo "Building VibeManager for arm64/arm64e iOS..."

SDK_PATH=$(xcrun --sdk iphoneos --show-sdk-path 2>/dev/null || echo "")

FRAMEWORKS="-framework Foundation -framework QuartzCore -framework UIKit"

if [ -n "$SDK_PATH" ]; then
    xcrun -sdk iphoneos clang++ -dynamiclib -arch arm64 -arch arm64e \
        -miphoneos-version-min=14.0 \
        -isysroot "$SDK_PATH" \
        $FRAMEWORKS \
        -O3 -fobjc-arc -std=c++17 \
        VibeManager.mm -lc++ \
        -o VibeManager.dylib
else
    echo "Using direct clang++..."
    clang++ -dynamiclib -target arm64-apple-ios14.0 \
        $FRAMEWORKS \
        -O3 -fobjc-arc -std=c++17 \
        VibeManager.mm -lc++ \
        -o VibeManager.dylib
fi

if command -v codesign >/dev/null 2>&1; then
    echo "Ad-hoc codesigning VibeManager.dylib..."
    codesign -s - --force VibeManager.dylib || true
fi

echo "Successfully built VibeManager.dylib!"
