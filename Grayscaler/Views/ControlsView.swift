import SwiftUI

/// Control panel view with window selection and filter options
struct ControlsView: View {
    @EnvironmentObject var captureState: CaptureState

    var body: some View {
        VStack(spacing: 8) {
            // Row 1: Window picker and Start/Stop button
            HStack {
                Picker("Window", selection: $captureState.selectedWindow) {
                    Text("Select a window").tag(nil as WindowInfo?)
                    ForEach(captureState.availableWindows) { window in
                        Text(window.displayName)
                            .tag(window as WindowInfo?)
                    }
                }
                .labelsHidden()
                .frame(maxWidth: .infinity)

                Button(action: {
                    Task {
                        await captureState.refreshWindowList()
                    }
                }) {
                    Image(systemName: "arrow.clockwise")
                }
                .help("Refresh window list")

                Button(action: {
                    if captureState.isCapturing {
                        captureState.stopCapture()
                    } else {
                        captureState.startCapture()
                    }
                }) {
                    Text(captureState.isCapturing ? "Stop" : "Start")
                        .frame(width: 50)
                }
                .disabled(captureState.selectedWindow == nil && !captureState.isCapturing)
            }

            // Row 2: Grayscale, Flip, and FPS
            HStack(spacing: 16) {
                Toggle("Grayscale", isOn: $captureState.grayscaleEnabled)
                    .toggleStyle(.checkbox)

                Toggle("Flip", isOn: $captureState.flipEnabled)
                    .toggleStyle(.checkbox)

                Spacer()

                HStack(spacing: 4) {
                    Text("FPS:")
                    TextField("", text: $captureState.fpsText)
                        .frame(width: 40)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit {
                            captureState.updateFps()
                        }
                }
            }
        }
        .padding(12)
        .background(Color(nsColor: .controlBackgroundColor))
    }
}

#Preview {
    ControlsView()
        .environmentObject(CaptureState())
        .frame(width: 400)
}
