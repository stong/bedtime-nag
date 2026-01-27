.PHONY: all build run clean kill help

# Default target
all: build

# Build the app
build:
	@echo "🔨 Building Bedtime Nag..."
	@swiftc Sources/main.swift -o BedtimeNag -framework Cocoa
	@echo "✅ Build successful!"

# Build and run
run: build
	@./BedtimeNag

# Clean build artifacts
clean:
	@echo "🧹 Cleaning..."
	@rm -f BedtimeNag
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
	@echo "  make run      - Build and run the app"
	@echo "  make clean    - Remove build artifacts"
	@echo "  make kill     - Stop all running instances"
	@echo "  make help     - Show this help message"
