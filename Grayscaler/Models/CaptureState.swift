import SwiftUI
import ScreenCaptureKit
import Combine

/// Window information for display in picker
struct WindowInfo: Identifiable, Hashable {
    let id: CGWindowID
    let title: String
    let appName: String
    let scWindow: SCWindow

    var displayName: String {
        if title.isEmpty {
            return appName
        }
        return "\(appName) - \(title)"
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: WindowInfo, rhs: WindowInfo) -> Bool {
        lhs.id == rhs.id
    }
}

/// Main state management for the capture application
@MainActor
class CaptureState: ObservableObject {
    // Window selection
    @Published var availableWindows: [WindowInfo] = []
    @Published var selectedWindow: WindowInfo?

    // Capture state
    @Published var isCapturing: Bool = false
    @Published var capturedImage: NSImage?

    // Filter settings
    @Published var grayscaleEnabled: Bool = true   // Default ON
    @Published var flipEnabled: Bool = false       // Default OFF
    @Published var fps: Double = 5.0               // Default 5fps
    @Published var fpsText: String = "5"           // For TextField binding

    // Services
    private var captureTimer: Timer?
    private let imageProcessor = ImageProcessor()

    init() {
        // Sync fpsText with fps
        fpsText = String(Int(fps))
    }

    /// Refresh the list of available windows
    func refreshWindowList() async {
        do {
            let content = try await SCShareableContent.excludingDesktopWindows(true, onScreenWindowsOnly: true)

            let ownBundleID = Bundle.main.bundleIdentifier

            let filtered = content.windows.compactMap { window -> WindowInfo? in
                // Exclude windows with empty titles
                guard let title = window.title else { return nil }

                // Exclude own app windows
                if let bundleID = window.owningApplication?.bundleIdentifier,
                   bundleID == ownBundleID {
                    return nil
                }

                // Exclude tiny windows (< 50x50)
                guard window.frame.width > 50 && window.frame.height > 50 else { return nil }

                let appName = window.owningApplication?.applicationName ?? "Unknown"

                return WindowInfo(
                    id: window.windowID,
                    title: title,
                    appName: appName,
                    scWindow: window
                )
            }

            self.availableWindows = filtered

            // Clear selection if selected window is no longer available
            if let selected = selectedWindow,
               !filtered.contains(where: { $0.id == selected.id }) {
                selectedWindow = nil
            }
        } catch {
            print("Failed to load windows: \(error)")
            availableWindows = []
        }
    }

    /// Start capturing the selected window
    func startCapture() {
        guard let window = selectedWindow else {
            print("No window selected")
            return
        }

        print("Starting capture for window: \(window.displayName)")
        isCapturing = true

        // Update fps from text
        if let newFps = Double(fpsText), newFps > 0 && newFps <= 60 {
            fps = newFps
        }

        let interval = 1.0 / fps
        print("Capture interval: \(interval) seconds (fps: \(fps))")

        // Use Timer with RunLoop.main explicitly
        let timer = Timer(timeInterval: interval, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor in
                await self.captureFrame(window: window)
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        captureTimer = timer

        // Capture immediately
        Task {
            await captureFrame(window: window)
        }
    }

    /// Stop capturing
    func stopCapture() {
        captureTimer?.invalidate()
        captureTimer = nil
        isCapturing = false
    }

    /// Capture a single frame from the window
    private func captureFrame(window: WindowInfo) async {
        print("Capturing frame...")
        do {
            let filter = SCContentFilter(desktopIndependentWindow: window.scWindow)
            let config = SCStreamConfiguration()
            config.width = Int(window.scWindow.frame.width)
            config.height = Int(window.scWindow.frame.height)
            config.showsCursor = false
            config.backgroundColor = .clear

            print("Window size: \(config.width) x \(config.height)")

            let cgImage = try await SCScreenshotManager.captureImage(
                contentFilter: filter,
                configuration: config
            )
            print("Captured CGImage: \(cgImage.width) x \(cgImage.height)")

            // Process image (grayscale + flip)
            if let processed = imageProcessor.process(
                cgImage: cgImage,
                grayscale: grayscaleEnabled,
                flip: flipEnabled
            ) {
                print("Processed image: \(processed.width) x \(processed.height)")
                let size = NSSize(width: processed.width, height: processed.height)
                capturedImage = NSImage(cgImage: processed, size: size)
                print("Image set to capturedImage")
            } else {
                print("Image processing failed")
            }
        } catch {
            print("Capture failed: \(error)")
        }
    }

    /// Update FPS from text field
    func updateFps() {
        if let newFps = Double(fpsText), newFps > 0 && newFps <= 60 {
            fps = newFps

            // If currently capturing, restart with new fps
            if isCapturing {
                stopCapture()
                startCapture()
            }
        } else {
            // Reset to valid value
            fpsText = String(Int(fps))
        }
    }
}
