# 🛌 Bedtime Nag

A macOS app that aggressively reminds you to go to bed when it's past 2 AM.

<img width="4094" height="1938" alt="image" src="https://github.com/user-attachments/assets/828652ba-bc85-4b15-93f5-6196e213aa65" />

**⚠️⚠️⚠️⚠️ this readme is vibed by claude so don't judge me if it's written in a npc like way ⚠️⚠️⚠️⚠️**

## Features

- 🚨 **Undismissable Windows**: Alert windows with no close button
- 📚 **Piling Up**: New windows spawn every 30 seconds after 2 AM
- 🎯 **Always On Top**: Windows float above all other apps
- 💥 **Bouncing Windows**: Windows bounce around your screen chaotically like DVD screensavers
- 🌈 **Color Cycling**: Windows continuously cycle through rainbow colors as they bounce
- 🛌 **Dynamic Menu Bar Icon**: Icon changes based on time (☀️ day, 🌙 night, 🛌 bedtime)
- 🔒 **Lock to Dismiss**: Only way to clear windows is to lock your laptop
- 👻 **Auto-Background**: Automatically forks to background when launched

## How It Works

1. The app runs in the background checking the time every 5 minutes
2. Between 2 AM and 6 AM, it enters "nag mode"
3. Spawns a new window every 30 seconds with an alert beep
4. Windows appear at random positions on your screen
5. Only clears when you lock your laptop (Cmd+Ctrl+Q or closing the lid)

## Build & Run

```bash
# Build the app
make

# Run it (automatically forks to background)
make run
```

The app will automatically launch in the background and return control to your terminal. Look for an icon in your menu bar (top-right):
- ☀️ Daytime (6 AM - 8 PM)
- 🌙 Night (8 PM - 2 AM)
- 🛌 Bedtime (2 AM - 6 AM)

## Package as .app Bundle

To create a proper macOS application bundle:

```bash
make app
```

This creates `BedtimeNag.app` that you can:
- Drag to `/Applications`
- Double-click to run from Finder
- Add to Login Items more easily

## Run at Startup (Optional)

To have this run automatically when you log in:

1. Build the app bundle: `make app`
2. Open **System Settings** → **General** → **Login Items**
3. Click the **+** button under "Open at Login"
4. Navigate to `BedtimeNag.app` in this folder and add it

## Make Targets

- `make` or `make build` - Build the app
- `make app` - Build .app bundle for macOS
- `make run` - Build and run the app
- `make clean` - Remove build artifacts
- `make kill` - Stop all running instances
- `make help` - Show available targets

## Stop the App

Since it runs in the background with no dock icon:

```bash
make kill
```

Or manually:
```bash
pkill BedtimeNag
```

## Testing

To test without waiting until 2 AM, you can temporarily modify the time check in `Sources/main.swift`:

```swift
// Change this line:
if hour >= 2 && hour < 6 {

// To always nag (for immediate testing):
if true {
```

Then rebuild and run:
```bash
make run
```
