import SwiftUI

/// View for displaying the captured image with aspect ratio preserved
struct CaptureImageView: View {
    let image: NSImage?

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                Color(nsColor: .windowBackgroundColor)

                if let image = image {
                    Image(nsImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(
                            maxWidth: geometry.size.width,
                            maxHeight: geometry.size.height
                        )
                } else {
                    // Placeholder when no image is captured
                    VStack(spacing: 12) {
                        Image(systemName: "rectangle.dashed")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        Text("Select a window and click \"Start\" to begin capture")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                }
            }
        }
    }
}

#Preview {
    CaptureImageView(image: nil)
        .frame(width: 400, height: 400)
}
