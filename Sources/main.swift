import Cocoa
import Foundation

// Configuration
let INITIAL_PASSWORD_LENGTH = 6
let MAX_WINDOWS = 20

class PasswordDialog: NSWindow, NSWindowDelegate {
    var password: String = ""
    var enteredPassword: String = ""
    var passwordLabel: NSTextField?
    var entryLabel: NSTextField?
    var onSuccess: (() -> Void)?
    var bounceTimer: Timer?
    var velocityX: CGFloat = 0
    var velocityY: CGFloat = 0
    var buttonRow: NSStackView?

    init(passwordLength: Int, onSuccess: @escaping () -> Void) {
        self.onSuccess = onSuccess

        // Generate random password of specified length
        password = String((0..<passwordLength).map { _ in String(Int.random(in: 0...9)) }.joined())

        let rect = NSRect(x: 0, y: 0, width: 500, height: 250)
        super.init(
            contentRect: rect,
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )

        self.isReleasedWhenClosed = false

        self.title = "Enter Password to Clear Windows"
        self.level = .modalPanel

        setupUI()
        self.delegate = self
        self.center()

        // Random initial velocity for bouncing
        velocityX = CGFloat.random(in: -3...3)
        velocityY = CGFloat.random(in: -3...3)

        // Start bouncing
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
        if newFrame.origin.x <= screenFrame.minX {
            velocityX = abs(velocityX) + CGFloat.random(in: -1...1)
            newFrame.origin.x = screenFrame.minX + 1
        } else if newFrame.maxX >= screenFrame.maxX {
            velocityX = -(abs(velocityX) + CGFloat.random(in: -1...1))
            newFrame.origin.x = screenFrame.maxX - newFrame.width - 1
        }

        if newFrame.origin.y <= screenFrame.minY {
            velocityY = abs(velocityY) + CGFloat.random(in: -1...1)
            newFrame.origin.y = screenFrame.minY + 1
        } else if newFrame.maxY >= screenFrame.maxY {
            velocityY = -(abs(velocityY) + CGFloat.random(in: -1...1))
            newFrame.origin.y = screenFrame.maxY - newFrame.height - 1
        }

        // Keep velocity from getting too slow or too fast
        velocityX = max(-5, min(5, velocityX))
        velocityY = max(-5, min(5, velocityY))

        // Ensure minimum velocity to prevent stopping
        if abs(velocityX) < 2 { velocityX = velocityX < 0 ? -2 : 2 }
        if abs(velocityY) < 2 { velocityY = velocityY < 0 ? -2 : 2 }

        self.setFrame(newFrame, display: true)
    }

    deinit {
        bounceTimer?.invalidate()
    }

    func setupUI() {
        guard let contentView = self.contentView else { return }

        let stack = NSStackView()
        stack.orientation = .vertical
        stack.alignment = .centerX
        stack.spacing = 20
        stack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
        ])

        // Title
        let titleLabel = NSTextField(labelWithString: "Type this password using the buttons:")
        titleLabel.alignment = .center
        stack.addArrangedSubview(titleLabel)

        // Password display
        passwordLabel = NSTextField(labelWithString: password)
        passwordLabel?.isBordered = true
        passwordLabel?.isEditable = false
        passwordLabel?.backgroundColor = .textBackgroundColor
        passwordLabel?.textColor = .labelColor
        passwordLabel?.alignment = .center
        stack.addArrangedSubview(passwordLabel!)

        // Entry title
        let entryTitle = NSTextField(labelWithString: "Your entry:")
        entryTitle.alignment = .center
        stack.addArrangedSubview(entryTitle)

        // Entry display
        entryLabel = NSTextField(labelWithString: "")
        entryLabel?.isBordered = true
        entryLabel?.isEditable = false
        entryLabel?.backgroundColor = .textBackgroundColor
        entryLabel?.textColor = .labelColor
        entryLabel?.alignment = .center
        stack.addArrangedSubview(entryLabel!)

        // Keyboard row: 1,2,3,4,5,6,7,8,9,0
        buttonRow = NSStackView()
        buttonRow!.orientation = .horizontal
        buttonRow!.spacing = 4
        stack.addArrangedSubview(buttonRow!)

        for num in 1...9 {
            let button = NSButton(title: "\(num)", target: self, action: #selector(numberPressed(_:)))
            button.bezelStyle = .rounded
            button.tag = num
            buttonRow!.addArrangedSubview(button)
        }

        let zeroButton = NSButton(title: "0", target: self, action: #selector(numberPressed(_:)))
        zeroButton.bezelStyle = .rounded
        zeroButton.tag = 0
        buttonRow!.addArrangedSubview(zeroButton)

        // Action buttons
        let actionRow = NSStackView()
        actionRow.orientation = .horizontal
        actionRow.spacing = 20
        stack.addArrangedSubview(actionRow)

        let clearButton = NSButton(title: "Clear", target: self, action: #selector(clearPressed))
        clearButton.bezelStyle = .rounded
        actionRow.addArrangedSubview(clearButton)

        let submitButton = NSButton(title: "Submit", target: self, action: #selector(submitPressed))
        submitButton.bezelStyle = .rounded
        actionRow.addArrangedSubview(submitButton)
    }

    @objc func numberPressed(_ sender: NSButton) {
        if enteredPassword.count < password.count {
            enteredPassword += "\(sender.tag)"
            entryLabel?.stringValue = enteredPassword
            NSSound.beep()

            // Shuffle the button order
            shuffleButtons()
        }
    }

    func shuffleButtons() {
        guard let buttonRow = buttonRow else { return }

        // Get all buttons
        var buttons = buttonRow.arrangedSubviews.compactMap { $0 as? NSButton }

        // Remove all buttons from the stack
        for button in buttons {
            buttonRow.removeArrangedSubview(button)
            button.removeFromSuperview()
        }

        // Shuffle the buttons
        buttons.shuffle()

        // Add them back in shuffled order
        for button in buttons {
            buttonRow.addArrangedSubview(button)
        }
    }

    @objc func clearPressed() {
        enteredPassword = ""
        entryLabel?.stringValue = ""
    }

    @objc func submitPressed() {
        if enteredPassword == password {
            let callback = onSuccess
            callback?()
            self.close()
        } else {
            NSSound(named: "Basso")?.play()

            // Shake the window
            let originalFrame = self.frame
            let shakeDistance: CGFloat = 10

            NSAnimationContext.runAnimationGroup({ context in
                context.duration = 0.05
                self.animator().setFrameOrigin(NSPoint(x: originalFrame.origin.x - shakeDistance, y: originalFrame.origin.y))
            }, completionHandler: {
                NSAnimationContext.runAnimationGroup({ context in
                    context.duration = 0.05
                    self.animator().setFrameOrigin(NSPoint(x: originalFrame.origin.x + shakeDistance, y: originalFrame.origin.y))
                }, completionHandler: {
                    NSAnimationContext.runAnimationGroup({ context in
                        context.duration = 0.05
                        self.animator().setFrameOrigin(originalFrame.origin)
                    }, completionHandler: nil)
                })
            })

            enteredPassword = ""
            entryLabel?.stringValue = ""
        }
    }

    func windowWillClose(_ notification: Notification) {
        // If window is closed without success, do nothing
    }
}

class BedtimeNagWindow: NSWindow {
    var bounceTimer: Timer?
    var velocityX: CGFloat = 0
    var velocityY: CGFloat = 0
    var colorHue: CGFloat = 0.0

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

        // Start with random color
        colorHue = CGFloat.random(in: 0...1)
        self.backgroundColor = NSColor(hue: colorHue, saturation: 0.8, brightness: 0.9, alpha: 0.95)
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

        var didBounce = false

        // Bounce off edges
        if newFrame.origin.x <= screenFrame.minX {
            velocityX = abs(velocityX) + CGFloat.random(in: -1...1)
            newFrame.origin.x = screenFrame.minX + 1
            didBounce = true
        } else if newFrame.maxX >= screenFrame.maxX {
            velocityX = -(abs(velocityX) + CGFloat.random(in: -1...1))
            newFrame.origin.x = screenFrame.maxX - newFrame.width - 1
            didBounce = true
        }

        if newFrame.origin.y <= screenFrame.minY {
            velocityY = abs(velocityY) + CGFloat.random(in: -1...1)
            newFrame.origin.y = screenFrame.minY + 1
            didBounce = true
        } else if newFrame.maxY >= screenFrame.maxY {
            velocityY = -(abs(velocityY) + CGFloat.random(in: -1...1))
            newFrame.origin.y = screenFrame.maxY - newFrame.height - 1
            didBounce = true
        }

        // Keep velocity from getting too slow or too fast
        velocityX = max(-8, min(8, velocityX))
        velocityY = max(-8, min(8, velocityY))

        // Ensure minimum velocity to prevent stopping
        if abs(velocityX) < 2 { velocityX = velocityX < 0 ? -3 : 3 }
        if abs(velocityY) < 2 { velocityY = velocityY < 0 ? -3 : 3 }

        self.setFrame(newFrame, display: true)

        // Change color only when bouncing off an edge
        if didBounce {
            colorHue += 0.15
            if colorHue > 1.0 {
                colorHue -= 1.0
            }
            self.backgroundColor = NSColor(hue: colorHue, saturation: 0.8, brightness: 0.9, alpha: 0.95)
        }
    }

    deinit {
        bounceTimer?.invalidate()
    }
}

class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    var windows: [BedtimeNagWindow] = []
    var timer: Timer?
    var nagTimer: Timer?
    var statusItem: NSStatusItem?
    var passwordLength: Int = INITIAL_PASSWORD_LENGTH
    var passwordDialog: PasswordDialog?
    var clearMenuItem: NSMenuItem?

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
        menu.autoenablesItems = false
        menu.delegate = self

        let statusMenuItem = NSMenuItem(title: "Bedtime Nag", action: nil, keyEquivalent: "")
        statusMenuItem.isEnabled = false
        menu.addItem(statusMenuItem)

        menu.addItem(NSMenuItem.separator())

        clearMenuItem = NSMenuItem(title: "Clear Windows", action: #selector(clearWindowsButton), keyEquivalent: "c")
        clearMenuItem?.target = self
        menu.addItem(clearMenuItem!)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem?.menu = menu
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        // Update Clear Windows menu item based on dialog visibility
        clearMenuItem?.isEnabled = !isPasswordDialogOpen()
    }

    func isPasswordDialogOpen() -> Bool {
        return passwordDialog?.isVisible == true
    }

    @objc func clearWindowsButton() {
        // Failsafe: don't open multiple dialogs
        if isPasswordDialogOpen() {
            print("⚠️ Password dialog already open")
            return
        }

        // Disable menu item while dialog is open
        clearMenuItem?.isEnabled = false

        // Show password dialog
        passwordDialog = PasswordDialog(passwordLength: passwordLength) { [weak self] in
            // Only clear if password was correct
            self?.clearWindows()

            // Increase password length by 3 for next time
            self?.passwordLength += 3
            print("🔒 Password length increased to \(self?.passwordLength ?? 0)")

            self?.passwordDialog = nil
            // Re-enable menu item
            self?.clearMenuItem?.isEnabled = true
        }
        passwordDialog?.makeKeyAndOrderFront(nil)
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
        passwordLength = INITIAL_PASSWORD_LENGTH
        print("☀️ Password length reset to \(INITIAL_PASSWORD_LENGTH)")
    }

    @objc func spawnWindow() {
        if windows.count >= MAX_WINDOWS {
            print("⚠️ Max windows (\(MAX_WINDOWS)) reached, not spawning more")
            return
        }
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
        for window in self.windows {
            window.close()
        }
        self.windows.removeAll()
        print("✨ All windows cleared")
    }
}

// Check for existing instance using PID file
let lockFilePath = NSTemporaryDirectory() + "bedtime-nag.lock"
let fileManager = FileManager.default

if fileManager.fileExists(atPath: lockFilePath) {
    // Read existing PID
    if let pidString = try? String(contentsOfFile: lockFilePath, encoding: .utf8),
       let existingPID = Int32(pidString.trimmingCharacters(in: .whitespacesAndNewlines)) {
        // Check if process is still running (kill with signal 0 doesn't kill, just checks)
        if kill(existingPID, 0) == 0 {
            print("❌ Another instance of Bedtime Nag is already running (PID: \(existingPID))")
            exit(1)
        } else {
            print("⚠️ Found stale lock file from PID \(existingPID), removing")
        }
    }
}

// Write our PID to the lock file
let ourPID = getpid()
try? String(ourPID).write(toFile: lockFilePath, atomically: true, encoding: .utf8)
print("🔒 Created lock file with PID \(ourPID)")

// Auto-background if not already backgrounded (unless --no-fork is specified)
if !CommandLine.arguments.contains("--backgrounded") && !CommandLine.arguments.contains("--no-fork") {
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
