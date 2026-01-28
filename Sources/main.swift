import Cocoa
import Foundation

class BedtimeNagWindow: NSWindow {
    var bounceTimer: Timer?
    var velocityX: CGFloat = 0
    var velocityY: CGFloat = 0

    init() {
        let screenSize = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 400, height: 200)

        // Random position on screen
        let x = CGFloat.random(in: 100...(screenSize.width - 500))
        let y = CGFloat.random(in: 100...(screenSize.height - 300))
        let rect = NSRect(x: x, y: y, width: 400, height: 200)

        super.init(
            contentRect: rect,
            styleMask: [.titled, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        self.level = .floating
        self.isOpaque = false
        self.backgroundColor = NSColor(calibratedRed: 1.0, green: 0.3, blue: 0.3, alpha: 0.95)
        self.title = "⏰ BEDTIME!"

        // Remove close button
        self.standardWindowButton(.closeButton)?.isHidden = true
        self.standardWindowButton(.miniaturizeButton)?.isHidden = true
        self.standardWindowButton(.zoomButton)?.isHidden = true

        // Create the message view
        let textField = NSTextField(frame: NSRect(x: 20, y: 20, width: 360, height: 160))
        textField.stringValue = "🛌 GO TO BED! 🛌\n\nIt's past 2 AM!\n\nLock your laptop to dismiss."
        textField.isEditable = false
        textField.isBordered = false
        textField.backgroundColor = .clear
        textField.textColor = .white
        textField.font = NSFont.boldSystemFont(ofSize: 24)
        textField.alignment = .center
        textField.maximumNumberOfLines = 0

        self.contentView?.addSubview(textField)
        self.isReleasedWhenClosed = false

        // Random initial velocity for bouncing
        velocityX = CGFloat.random(in: -5...5)
        velocityY = CGFloat.random(in: -5...5)

        // Start bouncing!
        startBouncing()
    }

    func startBouncing() {
        bounceTimer = Timer.scheduledTimer(withTimeInterval: 0.03, repeats: true) { [weak self] _ in
            self?.bounce()
        }
    }

    func bounce() {
        guard let screen = NSScreen.main else { return }
        let screenFrame = screen.visibleFrame

        var newFrame = self.frame
        newFrame.origin.x += velocityX
        newFrame.origin.y += velocityY

        // Bounce off edges
        if newFrame.origin.x <= screenFrame.minX || newFrame.maxX >= screenFrame.maxX {
            velocityX *= -1
            // Add some randomness to make it more chaotic
            velocityX += CGFloat.random(in: -2...2)
        }

        if newFrame.origin.y <= screenFrame.minY || newFrame.maxY >= screenFrame.maxY {
            velocityY *= -1
            // Add some randomness to make it more chaotic
            velocityY += CGFloat.random(in: -2...2)
        }

        // Keep velocity from getting too slow or too fast
        velocityX = max(-10, min(10, velocityX))
        velocityY = max(-10, min(10, velocityY))

        // Keep window on screen
        newFrame.origin.x = max(screenFrame.minX, min(newFrame.origin.x, screenFrame.maxX - newFrame.width))
        newFrame.origin.y = max(screenFrame.minY, min(newFrame.origin.y, screenFrame.maxY - newFrame.height))

        self.setFrame(newFrame, display: true)
    }

    deinit {
        bounceTimer?.invalidate()
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var windows: [BedtimeNagWindow] = []
    var timer: Timer?
    var nagTimer: Timer?
    var statusItem: NSStatusItem?

    func applicationDidFinishLaunching(_ notification: Notification) {
        print("🌙 Bedtime Nag started...")

        // Create menu bar item
        setupMenuBar()

        // Register for screen lock notifications
        let dnc = DistributedNotificationCenter.default()
        dnc.addObserver(
            self,
            selector: #selector(screenLocked),
            name: NSNotification.Name("com.apple.screenIsLocked"),
            object: nil
        )

        // Check time every 30 seconds
        timer = Timer.scheduledTimer(
            timeInterval: 30.0,
            target: self,
            selector: #selector(checkTime),
            userInfo: nil,
            repeats: true
        )

        // Initial check
        checkTime()
    }

    func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        // Icon will be set by checkTime() on first run

        let menu = NSMenu()

        let statusMenuItem = NSMenuItem(title: "Bedtime Nag", action: nil, keyEquivalent: "")
        statusMenuItem.isEnabled = false
        menu.addItem(statusMenuItem)

        menu.addItem(NSMenuItem.separator())

        let clearItem = NSMenuItem(title: "Clear Windows", action: #selector(clearWindows), keyEquivalent: "c")
        clearItem.target = self
        menu.addItem(clearItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem?.menu = menu
    }

    @objc func quitApp() {
        NSApplication.shared.terminate(nil)
    }

    func getIconForHour(_ hour: Int) -> String {
        if hour >= 2 && hour < 6 {
            // Bedtime: 2 AM - 6 AM
            return "🛌"
        } else if hour >= 6 && hour < 20 {
            // Daytime: 6 AM - 8 PM
            return "☀️"
        } else {
            // Night: 8 PM - 2 AM
            return "🌙"
        }
    }

    func updateMenuBarIcon(_ hour: Int) {
        if let button = statusItem?.button {
            button.title = getIconForHour(hour)
        }
    }

    @objc func checkTime() {
        let calendar = Calendar.current
        let now = Date()
        let hour = calendar.component(.hour, from: now)

        // Update menu bar icon based on time
        updateMenuBarIcon(hour)

        // Between 2 AM (02:00) and 6 AM (06:00) - nag time!
        if hour >= 2 && hour < 6 {
            if nagTimer == nil {
                print("⏰ It's past 2 AM! Starting nag mode...")
                startNagging()
            }
        } else {
            if nagTimer != nil {
                print("✅ Before 2 AM, stopping nag mode...")
                stopNagging()
            }
        }
    }

    func startNagging() {
        // Spawn a window immediately
        spawnWindow()

        // Then spawn a new window every 30 seconds
        nagTimer = Timer.scheduledTimer(
            timeInterval: 30.0,
            target: self,
            selector: #selector(spawnWindow),
            userInfo: nil,
            repeats: true
        )
    }

    func stopNagging() {
        nagTimer?.invalidate()
        nagTimer = nil
        clearWindows()
    }

    @objc func spawnWindow() {
        let window = BedtimeNagWindow()
        window.makeKeyAndOrderFront(nil)
        windows.append(window)
        NSSound.beep()
        print("💥 Spawned nag window #\(windows.count)")
    }

    @objc func screenLocked() {
        print("🔒 Screen locked! Clearing all nag windows...")
        clearWindows()
    }

    @objc func clearWindows() {
        for window in windows {
            window.close()
        }
        windows.removeAll()
        print("✨ All windows cleared")
    }
}

// Auto-background if not already backgrounded
if !CommandLine.arguments.contains("--backgrounded") {
    let executablePath = CommandLine.arguments[0]

    // Launch in background and exit
    let task = Process()
    task.executableURL = URL(fileURLWithPath: executablePath)
    task.arguments = ["--backgrounded"]
    task.standardOutput = nil
    task.standardError = nil

    do {
        try task.run()
        print("🌙 Bedtime Nag launched in background (PID: \(task.processIdentifier))")
        print("   Check menu bar for icon (☀️ day, 🌙 night, 🛌 bedtime)")
        print("   To stop: pkill BedtimeNag")
        exit(0)
    } catch {
        print("❌ Failed to background: \(error)")
        exit(1)
    }
}

// Create and run the application
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory) // Runs in background, no dock icon
app.run()
