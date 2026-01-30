.PHONY: all build run clean kill help app

# Default target
all: build

# Build the app
build:
	@echo "🔨 Building Bedtime Nag..."
	@swiftc Sources/main.swift -o BedtimeNag -framework Cocoa
	@echo "✅ Build successful!"

# Build .app bundle
app: build
	@echo "📦 Creating BedtimeNag.app bundle..."
	@rm -rf BedtimeNag.app
	@mkdir -p BedtimeNag.app/Contents/MacOS
	@mkdir -p BedtimeNag.app/Contents/Resources
	@cp BedtimeNag BedtimeNag.app/Contents/MacOS/
	@cp Info.plist BedtimeNag.app/Contents/
	@echo "✅ App bundle created: BedtimeNag.app"
	@echo "   You can now drag it to /Applications or run it from Finder"

# Build and run
run: build
	@./BedtimeNag

# Clean build artifacts
clean:
	@echo "🧹 Cleaning..."
	@rm -f BedtimeNag
	@rm -rf BedtimeNag.app
	@echo "✨ Clean complete"

# Kill running instances
kill:
	@echo "🛑 Stopping Bedtime Nag..."
	@pkill BedtimeNag || echo "No running instances found"

# Show help
help:
	@echo "Bedtime Nag - Makefile targets:"
	@echo ""
	@echo "  make          - Build the app (default)"
	@echo "  make build    - Build the app"
	@echo "  make app      - Build .app bundle for macOS"
	@echo "  make run      - Build and run the app"
	@echo "  make clean    - Remove build artifacts"
	@echo "  make kill     - Stop all running instances"
	@echo "  make help     - Show this help message"
