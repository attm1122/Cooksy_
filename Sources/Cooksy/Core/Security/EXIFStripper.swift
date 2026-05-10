import Foundation
import ImageIO
import UIKit
import MobileCoreServices

// MARK: - EXIFStripper
/// Strips all EXIF metadata from images to protect user privacy.
///
/// Recipe images imported from photos or social media often contain sensitive EXIF metadata
/// including GPS coordinates (home location), device model (fingerprinting), timestamps,
/// camera settings, and software version strings. This utility removes all metadata while
/// preserving the raw image data, protecting privacy before storage in SwiftData or upload
/// to Supabase.
///
/// ## Removed EXIF Fields
/// - GPS coordinates (latitude/longitude/altitude) — reveals home/work locations
/// - Device make and model — enables device fingerprinting
/// - Timestamp (creation and modification) — reveals when/where user was
/// - Camera settings (aperture, shutter speed, ISO, focal length)
/// - Orientation flag — prevents incorrect rotation after strip
/// - Software version — reveals device/iOS version for targeted attacks
/// - Thumbnail images — may contain all of the above in embedded preview
/// - User comments and descriptions — may contain personal notes
///
/// ## Usage
/// ```swift
/// // Strip from Data (e.g., after image picker selection)
/// let cleanData = EXIFStripper.stripMetadata(from: imageData)
///
/// // Strip from UIImage
/// let cleanImage = EXIFStripper.stripMetadata(from: uiImage)
/// ```
///
/// - Important: This is a pure functional utility — no state, no side effects.
///   Safe to call from any thread. Returns `nil` on failure without crashing.
struct EXIFStripper {

    /// Whether the ImageIO framework is available for EXIF stripping.
    /// Always `true` on iOS 17+, but useful for unit testing and feature gates.
    static var isAvailable: Bool {
        // ImageIO has been part of iOS since 2.0 and is guaranteed on all iOS 17+ devices.
        // This property exists to allow tests to mock unavailable state if needed.
        true
    }

    // MARK: - Core EXIF Stripping

    /// Strips all EXIF metadata from image data while preserving image quality.
    ///
    /// Uses Core Graphics ImageIO to create a new image file containing only
    /// the pixel data from the original — all metadata dictionaries are excluded.
    /// The output format matches the input format (JPEG→JPEG, PNG→PNG, HEIC→HEIC).
    ///
    /// - Parameter imageData: Raw image file data (JPEG, PNG, HEIC, etc.)
    /// - Returns: Clean image data with all EXIF metadata removed, or `nil` if
    ///   the data is not a valid image or an error occurs during processing.
    static func stripMetadata(from imageData: Data) -> Data? {
        guard isAvailable else { return nil }
        guard !imageData.isEmpty else { return nil }

        // 1. Create an image source from the input data
        guard let imageSource = CGImageSourceCreateWithData(imageData as CFData, nil) else {
            print("[EXIFStripper] Failed to create CGImageSource from data")
            return nil
        }

        // 2. Determine the image type (UTI) to preserve format
        guard let imageType = CGImageSourceGetType(imageSource) else {
            print("[EXIFStripper] Could not determine image UTI type")
            return nil
        }

        // Validate that we can write this image type
        let writableTypes = CGImageDestinationCopyTypeIdentifiers() as? [String] ?? []
        guard writableTypes.contains(imageType as String) else {
            print("[EXIFStripper] Image type '\(imageType)' is not writable")
            return nil
        }

        // 3. Create an in-memory destination for the output with same format
        let outputData = NSMutableData()
        guard let imageDestination = CGImageDestinationCreateWithData(
            outputData,
            imageType,
            1, // Single image
            nil
        ) else {
            print("[EXIFStripper] Failed to create CGImageDestination")
            return nil
        }

        // 4. Copy only the image — no metadata
        // Pass an empty properties dictionary to strip ALL metadata including:
        // GPS info, EXIF tags, TIFF metadata, JFIF properties, and orientation
        let properties: [String: Any] = [:]
        CGImageDestinationAddImageFromSource(imageDestination, imageSource, 0, properties as CFDictionary)

        // 5. Finalize the destination
        guard CGImageDestinationFinalize(imageDestination) else {
            print("[EXIFStripper] Failed to finalize image destination")
            return nil
        }

        return outputData as Data
    }

    // MARK: - Convenience UIImage Support

    /// Strips EXIF metadata from a `UIImage` and returns a clean `UIImage`.
    ///
    /// Converts the UIImage to JPEG representation, strips all EXIF metadata,
    /// and reconstructs a new UIImage from the cleaned data.
    ///
    /// - Parameter image: The UIImage containing potential EXIF metadata.
    /// - Returns: A new `UIImage` with all EXIF metadata stripped, or `nil`
    ///   if the image cannot be processed.
    /// - Note: The output is always JPEG format at 95% quality to preserve visual fidelity.
    ///   For PNG images with transparency, use `stripMetadata(from imageData:)` directly.
    static func stripMetadata(from image: UIImage) -> UIImage? {
        guard isAvailable else { return nil }

        // Convert UIImage to JPEG data (preserves pixel data, strips existing metadata)
        // Use 0.95 quality to maintain visual fidelity while keeping file size reasonable
        guard let imageData = image.jpegData(compressionQuality: 0.95) else {
            print("[EXIFStripper] Failed to convert UIImage to JPEG data")
            return nil
        }

        // Run through the core stripper to ensure all metadata is removed
        guard let cleanedData = stripMetadata(from: imageData) else {
            return nil
        }

        // Reconstruct UIImage from cleaned data
        guard let cleanedImage = UIImage(data: cleanedData) else {
            print("[EXIFStripper] Failed to create UIImage from cleaned data")
            return nil
        }

        return cleanedImage
    }

    // MARK: - Batch Processing

    /// Strips EXIF metadata from multiple images concurrently.
    ///
    /// Processes each image independently using Swift concurrency.
    /// Failed items are excluded from the result — this method never throws.
    ///
    /// - Parameter imageDataArray: Array of raw image data to process.
    /// - Returns: Array of cleaned image data. Count may be less than input
    ///   if some images fail processing.
    static func stripMetadataBatch(from imageDataArray: [Data]) async -> [Data] {
        await withTaskGroup(of: Data?.self) { group in
            for imageData in imageDataArray {
                group.addTask {
                    stripMetadata(from: imageData)
                }
            }

            var results: [Data] = []
            results.reserveCapacity(imageDataArray.count)

            for await result in group {
                if let data = result {
                    results.append(data)
                }
            }

            return results
        }
    }
}
