import CoreImage
import CoreGraphics

/// Image processor for applying grayscale and flip effects
class ImageProcessor {
    private let context = CIContext()

    /// Process an image with optional grayscale and flip effects
    /// - Parameters:
    ///   - cgImage: The source CGImage
    ///   - grayscale: Whether to apply grayscale conversion
    ///   - flip: Whether to apply horizontal flip
    /// - Returns: The processed CGImage, or nil if processing failed
    func process(cgImage: CGImage, grayscale: Bool, flip: Bool) -> CGImage? {
        var ciImage = CIImage(cgImage: cgImage)

        // Apply horizontal flip if enabled
        if flip {
            ciImage = ciImage.transformed(
                by: CGAffineTransform(scaleX: -1, y: 1)
                    .translatedBy(x: -ciImage.extent.width, y: 0)
            )
        }

        // Apply grayscale if enabled
        if grayscale {
            ciImage = applyGrayscale(to: ciImage)
        }

        // Convert back to CGImage
        return context.createCGImage(ciImage, from: ciImage.extent)
    }

    /// Apply grayscale using luminosity method
    /// Coefficients: R=0.21, G=0.72, B=0.07 (matching web version)
    private func applyGrayscale(to image: CIImage) -> CIImage {
        // Use CIColorMatrix for precise luminosity conversion
        // This matches the web version's formula: v = 0.21*R + 0.72*G + 0.07*B
        guard let filter = CIFilter(name: "CIColorMatrix") else {
            return image
        }

        // Set up the color matrix for luminosity grayscale
        // Each row outputs: 0.21*R + 0.72*G + 0.07*B
        let luminosityVector = CIVector(x: 0.21, y: 0.72, z: 0.07, w: 0)

        filter.setValue(image, forKey: kCIInputImageKey)
        filter.setValue(luminosityVector, forKey: "inputRVector")
        filter.setValue(luminosityVector, forKey: "inputGVector")
        filter.setValue(luminosityVector, forKey: "inputBVector")
        filter.setValue(CIVector(x: 0, y: 0, z: 0, w: 1), forKey: "inputAVector")
        filter.setValue(CIVector(x: 0, y: 0, z: 0, w: 0), forKey: "inputBiasVector")

        return filter.outputImage ?? image
    }
}
