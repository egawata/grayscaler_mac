import SwiftUI

/// Main content view combining image display and controls
struct ContentView: View {
    @StateObject private var captureState = CaptureState()

    var body: some View {
        VStack(spacing: 0) {
            // Image display area (takes remaining space)
            CaptureImageView(image: captureState.capturedImage)

            Divider()

            // Control panel at the bottom
            ControlsView()
                .environmentObject(captureState)
        }
        .frame(minWidth: 300, minHeight: 400)
        .task {
            // Load available windows on launch
            await captureState.refreshWindowList()
        }
    }
}

#Preview {
    ContentView()
        .frame(width: 400, height: 600)
}
