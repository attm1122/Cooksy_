import Foundation

// MARK: - Source
/// Represents the origin of a recipe — the social media video it was extracted from.
///
/// `Source` is a value type (struct) that captures the essential metadata about where a recipe
/// came from: the video URL, the hosting platform, the content creator, and the video title.
///
/// ## Usage
/// ```swift
/// let source = Source(
///     url: "https://youtube.com/watch?v=abc123",
///     platform: .youtube,
///     creator: "Chef John",
///     title: "Amazing Pasta Recipe"
/// )
/// ```
///
/// - Note: This struct is stored inline within the `Recipe` model via the `source` computed property,
///         which maps to the individual stored properties (`sourceUrl`, `sourcePlatform`, etc.) on `Recipe`.
///         This design works around SwiftData's current limitations with complex Codable types.
public struct Source: Codable, Hashable, Sendable {

    // MARK: Properties

    /// The full URL to the original video.
    ///
    /// Example: `"https://youtube.com/watch?v=dQw4w9WgXcQ"`
    public var url: String

    /// The social media platform hosting the video.
    public var platform: SourcePlatform

    /// The name of the content creator or channel.
    ///
    /// Example: `"Joshua Weissman"`
    public var creator: String

    /// The title of the video.
    ///
    /// Example: `"The Best Homemade Pizza You'll Ever Make"`
    public var title: String

    // MARK: Initialization

    /// Creates a new `Source` instance.
    ///
    /// - Parameters:
    ///   - url: The full URL to the original video.
    ///   - platform: The social media platform hosting the video.
    ///   - creator: The name of the content creator or channel.
    ///   - title: The title of the video.
    public init(url: String, platform: SourcePlatform, creator: String, title: String) {
        self.url = url
        self.platform = platform
        self.creator = creator
        self.title = title
    }
}

// MARK: - Source + Display
extension Source {

    /// A formatted display string combining the creator and platform.
    ///
    /// Example: `"By Chef John on YouTube"`
    public var displayAttribution: String {
        "By \(creator) on \(platform.displayName)"
    }

    /// A short display string for compact UI contexts.
    ///
    /// Example: `"Chef John"`
    public var shortAttribution: String {
        creator
    }
}
