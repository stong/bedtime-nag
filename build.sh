#!/bin/bash

echo "🔨 Building Bedtime Nag..."
swiftc Sources/main.swift -o BedtimeNag -framework Cocoa

if [ $? -eq 0 ]; then
    echo "✅ Build successful!"
    echo ""
    echo "To run the app:"
    echo "  ./BedtimeNag"
    echo ""
    echo "To stop the app:"
    echo "  pkill BedtimeNag"
else
    echo "❌ Build failed"
    exit 1
fi
