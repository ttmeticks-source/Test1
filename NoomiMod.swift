import Cocoa
import UniformTypeIdentifiers

private enum Backdrop: String, CaseIterable {
    case sky = "Clear Sky"
    case sunset = "Sunset"
    case aurora = "Aurora"
    case midnight = "Midnight"
}

private enum CapeStyle: String, CaseIterable {
    case ember = "Ember"
    case ocean = "Ocean"
    case violet = "Violet"
    case mint = "Mint"
    case rose = "Rose"

    var colors: (NSColor, NSColor) {
        switch self {
        case .ember:
            return (NSColor(calibratedRed: 0.98, green: 0.25, blue: 0.18, alpha: 1), NSColor(calibratedRed: 0.52, green: 0.07, blue: 0.12, alpha: 1))
        case .ocean:
            return (NSColor(calibratedRed: 0.12, green: 0.72, blue: 0.91, alpha: 1), NSColor(calibratedRed: 0.05, green: 0.22, blue: 0.58, alpha: 1))
        case .violet:
            return (NSColor(calibratedRed: 0.70, green: 0.42, blue: 0.98, alpha: 1), NSColor(calibratedRed: 0.28, green: 0.12, blue: 0.54, alpha: 1))
        case .mint:
            return (NSColor(calibratedRed: 0.30, green: 0.90, blue: 0.66, alpha: 1), NSColor(calibratedRed: 0.06, green: 0.40, blue: 0.34, alpha: 1))
        case .rose:
            return (NSColor(calibratedRed: 1.00, green: 0.48, blue: 0.67, alpha: 1), NSColor(calibratedRed: 0.55, green: 0.13, blue: 0.34, alpha: 1))
        }
    }
}

private final class PreviewCanvas: NSView {
    var backdrop: Backdrop = .sky { didSet { needsDisplay = true } }
    var cape: CapeStyle = .ember { didSet { needsDisplay = true } }
    var customBackground: NSImage? { didSet { needsDisplay = true } }

    override var isFlipped: Bool { true }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        let rect = bounds
        guard rect.width > 0, rect.height > 0 else { return }

        if let image = customBackground {
            image.draw(in: rect, from: .zero, operation: .sourceOver, fraction: 1, respectFlipped: true, hints: nil)
            NSColor.black.withAlphaComponent(0.16).setFill()
            NSBezierPath(rect: rect).fill()
        } else {
            let colors: [NSColor]
            switch backdrop {
            case .sky:
                colors = [NSColor(calibratedRed: 0.18, green: 0.58, blue: 0.86, alpha: 1), NSColor(calibratedRed: 0.58, green: 0.82, blue: 0.95, alpha: 1)]
            case .sunset:
                colors = [NSColor(calibratedRed: 0.30, green: 0.14, blue: 0.40, alpha: 1), NSColor(calibratedRed: 0.98, green: 0.43, blue: 0.28, alpha: 1)]
            case .aurora:
                colors = [NSColor(calibratedRed: 0.02, green: 0.15, blue: 0.30, alpha: 1), NSColor(calibratedRed: 0.08, green: 0.55, blue: 0.51, alpha: 1)]
            case .midnight:
                colors = [NSColor(calibratedRed: 0.025, green: 0.035, blue: 0.12, alpha: 1), NSColor(calibratedRed: 0.15, green: 0.16, blue: 0.36, alpha: 1)]
            }
            NSGradient(colors: colors)?.draw(in: rect, angle: 90)
            drawBackgroundDetails(in: rect)
        }

        drawGround(in: rect)
        drawMascot(in: rect)
        drawCaption(in: rect)
    }

    private func drawBackgroundDetails(in rect: NSRect) {
        if backdrop == .sky {
            NSColor.white.withAlphaComponent(0.22).setFill()
            NSBezierPath(ovalIn: NSRect(x: rect.width * 0.72, y: rect.height * 0.12, width: 72, height: 72)).fill()
            drawCloud(x: rect.width * 0.18, y: rect.height * 0.22, scale: 1)
            drawCloud(x: rect.width * 0.73, y: rect.height * 0.36, scale: 0.7)
        } else if backdrop == .sunset {
            NSColor(calibratedRed: 1, green: 0.78, blue: 0.47, alpha: 0.28).setFill()
            NSBezierPath(ovalIn: NSRect(x: rect.width * 0.67, y: rect.height * 0.16, width: 112, height: 112)).fill()
        } else {
            let points: [(CGFloat, CGFloat, CGFloat)] = [
                (0.12, 0.18, 2.0), (0.27, 0.12, 1.6), (0.43, 0.24, 2.2),
                (0.64, 0.13, 1.7), (0.84, 0.22, 2.0), (0.91, 0.43, 1.5),
                (0.18, 0.43, 1.4), (0.54, 0.38, 1.8), (0.76, 0.50, 1.4)
            ]
            for (x, y, size) in points {
                NSColor.white.withAlphaComponent(0.72).setFill()
                NSBezierPath(ovalIn: NSRect(x: rect.width * x, y: rect.height * y, width: size, height: size)).fill()
            }
        }
    }

    private func drawCloud(x: CGFloat, y: CGFloat, scale: CGFloat) {
        NSColor.white.withAlphaComponent(0.27).setFill()
        let path = NSBezierPath()
        path.appendOval(in: NSRect(x: x, y: y + 12 * scale, width: 44 * scale, height: 25 * scale))
        path.appendOval(in: NSRect(x: x + 18 * scale, y: y, width: 35 * scale, height: 34 * scale))
        path.appendOval(in: NSRect(x: x + 39 * scale, y: y + 10 * scale, width: 42 * scale, height: 25 * scale))
        path.fill()
    }

    private func drawGround(in rect: NSRect) {
        let floorHeight = rect.height * 0.16
        let floor = NSRect(x: 0, y: rect.height - floorHeight, width: rect.width, height: floorHeight)
        let color: NSColor = customBackground == nil ? NSColor(calibratedWhite: 0.06, alpha: 0.22) : NSColor.black.withAlphaComponent(0.25)
        color.setFill()
        NSBezierPath(rect: floor).fill()
        NSColor.white.withAlphaComponent(0.16).setStroke()
        let line = NSBezierPath()
        line.lineWidth = 1
        line.move(to: NSPoint(x: 0, y: floor.minY))
        line.line(to: NSPoint(x: rect.width, y: floor.minY))
        line.stroke()
    }

    private func drawMascot(in rect: NSRect) {
        let scale = min(rect.width / 700, rect.height / 430)
        let cx = rect.midX
        let headY = rect.height * 0.30
        let shoulderY = rect.height * 0.43
        let waistY = rect.height * 0.61
        let hipY = rect.height * 0.65
        let floorY = rect.height * 0.81
        let lineWidth = max(7, 10 * scale)
        let capeColors = cape.colors

        let capePath = NSBezierPath()
        capePath.move(to: NSPoint(x: cx - 12 * scale, y: shoulderY))
        capePath.curve(to: NSPoint(x: cx - 82 * scale, y: waistY + 72 * scale), controlPoint1: NSPoint(x: cx - 42 * scale, y: shoulderY + 20 * scale), controlPoint2: NSPoint(x: cx - 72 * scale, y: waistY + 26 * scale))
        capePath.curve(to: NSPoint(x: cx + 80 * scale, y: waistY + 72 * scale), controlPoint1: NSPoint(x: cx - 16 * scale, y: waistY + 92 * scale), controlPoint2: NSPoint(x: cx + 48 * scale, y: waistY + 92 * scale))
        capePath.curve(to: NSPoint(x: cx + 12 * scale, y: shoulderY), controlPoint1: NSPoint(x: cx + 72 * scale, y: waistY + 20 * scale), controlPoint2: NSPoint(x: cx + 40 * scale, y: shoulderY + 18 * scale))
        capePath.close()
        capeColors.0.withAlphaComponent(0.96).setFill()
        capePath.fill()
        capeColors.1.withAlphaComponent(0.75).setStroke()
        capePath.lineWidth = 3 * scale
        capePath.stroke()

        let bodyColor = NSColor(calibratedRed: 0.95, green: 0.94, blue: 0.90, alpha: 1)
        bodyColor.setStroke()
        bodyColor.setFill()
        let headSize = 48 * scale
        NSBezierPath(ovalIn: NSRect(x: cx - headSize / 2, y: headY - headSize / 2, width: headSize, height: headSize)).fill()

        let torso = NSBezierPath(roundedRect: NSRect(x: cx - 17 * scale, y: shoulderY, width: 34 * scale, height: 92 * scale), xRadius: 15 * scale, yRadius: 15 * scale)
        torso.fill()

        stroke(from: NSPoint(x: cx - 8 * scale, y: shoulderY + 14 * scale), to: NSPoint(x: cx - 66 * scale, y: shoulderY + 58 * scale), width: lineWidth, color: bodyColor)
        stroke(from: NSPoint(x: cx + 8 * scale, y: shoulderY + 14 * scale), to: NSPoint(x: cx + 64 * scale, y: shoulderY + 48 * scale), width: lineWidth, color: bodyColor)
        stroke(from: NSPoint(x: cx - 8 * scale, y: hipY), to: NSPoint(x: cx - 46 * scale, y: floorY), width: lineWidth, color: bodyColor)
        stroke(from: NSPoint(x: cx + 8 * scale, y: hipY), to: NSPoint(x: cx + 48 * scale, y: floorY - 8 * scale), width: lineWidth, color: bodyColor)

        NSColor(calibratedWhite: 0.19, alpha: 0.8).setFill()
        NSBezierPath(ovalIn: NSRect(x: cx - 9 * scale, y: headY - 3 * scale, width: 3 * scale, height: 3 * scale)).fill()
        NSBezierPath(ovalIn: NSRect(x: cx + 6 * scale, y: headY - 3 * scale, width: 3 * scale, height: 3 * scale)).fill()
    }

    private func stroke(from start: NSPoint, to end: NSPoint, width: CGFloat, color: NSColor) {
        let path = NSBezierPath()
        path.lineCapStyle = .round
        path.lineWidth = width
        path.move(to: start)
        path.line(to: end)
        color.setStroke()
        path.stroke()
    }

    private func drawCaption(in rect: NSRect) {
        let text = "NOOMIMOD  /  COSMETIC PREVIEW"
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 11, weight: .semibold),
            .foregroundColor: NSColor.white.withAlphaComponent(0.78),
            .kern: 1.2
        ]
        (text as NSString).draw(at: NSPoint(x: 22, y: 20), withAttributes: attributes)
    }
}

private final class NoomiModApp: NSObject, NSApplicationDelegate {
    private var window: NSWindow!
    private var preview = PreviewCanvas(frame: .zero)
    private var backgroundPicker = NSPopUpButton(frame: .zero, pullsDown: false)
    private var capePicker = NSPopUpButton(frame: .zero, pullsDown: false)
    private var statusLabel = NSTextField(labelWithString: "Ready — all built-in styles are free.")

    func applicationDidFinishLaunching(_ notification: Notification) {
        buildWindow()
        restorePreferences()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }

    private func buildWindow() {
        let content = NSView()
        content.wantsLayer = true
        content.layer?.backgroundColor = NSColor(calibratedRed: 0.075, green: 0.082, blue: 0.11, alpha: 1).cgColor

        let headerTitle = NSTextField(labelWithString: "NoomiMod")
        headerTitle.font = NSFont.systemFont(ofSize: 30, weight: .bold)
        headerTitle.textColor = .white
        let headerSubtitle = NSTextField(labelWithString: "A little style. Your own playground.")
        headerSubtitle.font = NSFont.systemFont(ofSize: 13, weight: .regular)
        headerSubtitle.textColor = NSColor(calibratedWhite: 0.72, alpha: 1)
        let headerTexts = NSStackView(views: [headerTitle, headerSubtitle])
        headerTexts.orientation = .vertical
        headerTexts.alignment = .leading
        headerTexts.spacing = 4
        let header = NSStackView(views: [headerTexts])
        header.orientation = .horizontal
        header.alignment = .centerY

        let sidebar = makeSidebar()
        sidebar.translatesAutoresizingMaskIntoConstraints = false
        sidebar.widthAnchor.constraint(equalToConstant: 270).isActive = true

        preview.translatesAutoresizingMaskIntoConstraints = false
        preview.wantsLayer = true
        preview.layer?.cornerRadius = 20
        preview.layer?.masksToBounds = true
        preview.layer?.borderWidth = 1
        preview.layer?.borderColor = NSColor.white.withAlphaComponent(0.12).cgColor
        preview.heightAnchor.constraint(equalToConstant: 450).isActive = true
        preview.widthAnchor.constraint(greaterThanOrEqualToConstant: 570).isActive = true

        let workArea = NSStackView(views: [sidebar, preview])
        workArea.orientation = .horizontal
        workArea.alignment = .top
        workArea.spacing = 22

        statusLabel.font = NSFont.systemFont(ofSize: 11, weight: .medium)
        statusLabel.textColor = NSColor(calibratedWhite: 0.68, alpha: 1)
        let footer = NSStackView(views: [statusLabel])
        footer.orientation = .horizontal
        footer.alignment = .centerY

        let root = NSStackView(views: [header, workArea, footer])
        root.orientation = .vertical
        root.alignment = .leading
        root.spacing = 22
        root.edgeInsets = NSEdgeInsets(top: 28, left: 28, bottom: 24, right: 28)
        root.translatesAutoresizingMaskIntoConstraints = false
        content.addSubview(root)
        NSLayoutConstraint.activate([
            root.leadingAnchor.constraint(equalTo: content.leadingAnchor),
            root.trailingAnchor.constraint(equalTo: content.trailingAnchor),
            root.topAnchor.constraint(equalTo: content.topAnchor),
            root.bottomAnchor.constraint(equalTo: content.bottomAnchor),
            preview.widthAnchor.constraint(greaterThanOrEqualToConstant: 570)
        ])

        window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 930, height: 650), styleMask: [.titled, .closable, .miniaturizable, .resizable], backing: .buffered, defer: false)
        window.title = "NoomiMod"
        window.minSize = NSSize(width: 900, height: 620)
        window.center()
        window.contentView = content
    }

    private func makeSidebar() -> NSView {
        let panel = NSView()
        panel.wantsLayer = true
        panel.layer?.backgroundColor = NSColor(calibratedRed: 0.12, green: 0.13, blue: 0.17, alpha: 1).cgColor
        panel.layer?.cornerRadius = 16
        panel.heightAnchor.constraint(equalToConstant: 450).isActive = true

        let heading = sectionLabel("CUSTOMIZE")
        let backgroundLabel = sectionLabel("BACKGROUND")
        backgroundPicker.addItems(withTitles: Backdrop.allCases.map(\.rawValue))
        backgroundPicker.target = self
        backgroundPicker.action = #selector(backgroundChanged(_:))
        backgroundPicker.controlSize = .large

        let uploadButton = makeButton("Upload your background…", action: #selector(uploadBackground))
        let capeLabel = sectionLabel("CAPE STYLE")
        capePicker.addItems(withTitles: CapeStyle.allCases.map(\.rawValue))
        capePicker.target = self
        capePicker.action = #selector(capeChanged(_:))
        capePicker.controlSize = .large

        let exportButton = makeButton("Export preview as PNG", action: #selector(exportPreview))
        exportButton.keyEquivalent = "e"

        let finePrint = NSTextField(wrappingLabelWithString: "Original preview styles, made for NoomiMod. Your uploaded image stays on this Mac. This companion does not change the NoomiClone game or its in-game store.")
        finePrint.font = NSFont.systemFont(ofSize: 11)
        finePrint.textColor = NSColor(calibratedWhite: 0.65, alpha: 1)
        finePrint.maximumNumberOfLines = 0

        let stack = NSStackView(views: [heading, backgroundLabel, backgroundPicker, uploadButton, capeLabel, capePicker, exportButton, finePrint])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 12
        stack.edgeInsets = NSEdgeInsets(top: 20, left: 18, bottom: 18, right: 18)
        stack.translatesAutoresizingMaskIntoConstraints = false
        panel.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: panel.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: panel.trailingAnchor),
            stack.topAnchor.constraint(equalTo: panel.topAnchor),
            stack.bottomAnchor.constraint(lessThanOrEqualTo: panel.bottomAnchor)
        ])
        backgroundPicker.widthAnchor.constraint(equalToConstant: 230).isActive = true
        capePicker.widthAnchor.constraint(equalToConstant: 230).isActive = true
        uploadButton.widthAnchor.constraint(equalToConstant: 230).isActive = true
        exportButton.widthAnchor.constraint(equalToConstant: 230).isActive = true
        return panel
    }

    private func sectionLabel(_ value: String) -> NSTextField {
        let label = NSTextField(labelWithString: value)
        label.font = NSFont.systemFont(ofSize: 10, weight: .bold)
        label.textColor = NSColor(calibratedRed: 0.55, green: 0.78, blue: 0.96, alpha: 1)
        return label
    }

    private func makeButton(_ title: String, action: Selector) -> NSButton {
        let button = NSButton(title: title, target: self, action: action)
        button.bezelStyle = .rounded
        button.controlSize = .large
        return button
    }

    private func restorePreferences() {
        let defaults = UserDefaults.standard
        if let saved = defaults.string(forKey: "NoomiMod.backdrop"), let value = Backdrop(rawValue: saved) {
            backgroundPicker.selectItem(withTitle: value.rawValue)
            preview.backdrop = value
        }
        if let saved = defaults.string(forKey: "NoomiMod.cape"), let value = CapeStyle(rawValue: saved) {
            capePicker.selectItem(withTitle: value.rawValue)
            preview.cape = value
        }
        if let path = defaults.string(forKey: "NoomiMod.customBackground"), let image = NSImage(contentsOfFile: path) {
            preview.customBackground = image
            statusLabel.stringValue = "Custom background restored."
        }
    }

    @objc private func backgroundChanged(_ sender: NSPopUpButton) {
        guard sender.indexOfSelectedItem >= 0 else { return }
        let value = Backdrop.allCases[sender.indexOfSelectedItem]
        preview.backdrop = value
        preview.customBackground = nil
        UserDefaults.standard.set(value.rawValue, forKey: "NoomiMod.backdrop")
        UserDefaults.standard.removeObject(forKey: "NoomiMod.customBackground")
        statusLabel.stringValue = "Background: \(value.rawValue)"
    }

    @objc private func capeChanged(_ sender: NSPopUpButton) {
        guard sender.indexOfSelectedItem >= 0 else { return }
        let value = CapeStyle.allCases[sender.indexOfSelectedItem]
        preview.cape = value
        UserDefaults.standard.set(value.rawValue, forKey: "NoomiMod.cape")
        statusLabel.stringValue = "Cape: \(value.rawValue)"
    }

    @objc private func uploadBackground() {
        let panel = NSOpenPanel()
        panel.title = "Choose a background image"
        panel.message = "Pick an image stored on this Mac. NoomiMod copies it into its own support folder."
        panel.allowedContentTypes = [.image]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        guard panel.runModal() == .OK, let source = panel.url else { return }

        let access = source.startAccessingSecurityScopedResource()
        defer { if access { source.stopAccessingSecurityScopedResource() } }

        guard let image = NSImage(contentsOf: source) else {
            showError("That file could not be opened as an image.")
            return
        }

        do {
            let fileManager = FileManager.default
            let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
                .appendingPathComponent("NoomiMod/Backgrounds", isDirectory: true)
            try fileManager.createDirectory(at: appSupport, withIntermediateDirectories: true)
            let ext = source.pathExtension.isEmpty ? "png" : source.pathExtension.lowercased()
            let destination = appSupport.appendingPathComponent("custom-background.\(ext)")
            if fileManager.fileExists(atPath: destination.path) {
                try fileManager.removeItem(at: destination)
            }
            try fileManager.copyItem(at: source, to: destination)
            preview.customBackground = image
            UserDefaults.standard.set(destination.path, forKey: "NoomiMod.customBackground")
            statusLabel.stringValue = "Uploaded background: \(source.lastPathComponent)"
        } catch {
            showError("Could not save that image: \(error.localizedDescription)")
        }
    }

    @objc private func exportPreview() {
        let panel = NSSavePanel()
        panel.title = "Export NoomiMod preview"
        panel.nameFieldStringValue = "NoomiMod-Preview.png"
        panel.allowedContentTypes = [.png]
        guard panel.runModal() == .OK, let destination = panel.url else { return }
        guard let bitmap = preview.bitmapImageRepForCachingDisplay(in: preview.bounds) else {
            showError("Could not render the preview image.")
            return
        }
        preview.cacheDisplay(in: preview.bounds, to: bitmap)
        guard let data = bitmap.representation(using: .png, properties: [:]) else {
            showError("Could not encode the preview as PNG.")
            return
        }
        do {
            try data.write(to: destination, options: .atomic)
            statusLabel.stringValue = "Exported: \(destination.lastPathComponent)"
        } catch {
            showError("Could not write the PNG: \(error.localizedDescription)")
        }
    }

    private func showError(_ message: String) {
        let alert = NSAlert()
        alert.messageText = "NoomiMod"
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.runModal()
    }
}

let app = NSApplication.shared
let delegate = NoomiModApp()
app.delegate = delegate
app.setActivationPolicy(.regular)
app.run()
