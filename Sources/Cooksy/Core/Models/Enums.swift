import Foundation

// MARK: - RecipeStatus
/// Represents the processing lifecycle state of a recipe extracted from a video.
///
/// When a user imports a recipe from a video URL, the app processes the content asynchronously.
/// This enum tracks where the recipe is in that pipeline.
public enum RecipeStatus: String, Codable, CaseIterable, Sendable {
    /// The recipe is being analyzed and extracted from the source video.
    case processing
    /// The recipe has been successfully extracted and is ready for use.
    case ready
    /// The extraction process failed; the recipe may need manual review or re-import.
    case failed

    /// A user-friendly display name for each status.
    public var displayName: String {
        switch self {
        case .processing: return "Processing"
        case .ready: return "Ready"
        case .failed: return "Failed"
        }
    }

    /// The SF Symbol icon name associated with each status for UI display.
    public var iconName: String {
        switch self {
        case .processing: return "hourglass"
        case .ready: return "checkmark.circle.fill"
        case .failed: return "exclamationmark.triangle.fill"
        }
    }

    /// The color to use when displaying this status in the UI.
    public var tintColorName: String {
        switch self {
        case .processing: return "orange"
        case .ready: return "green"
        case .failed: return "red"
        }
    }
}

// MARK: - ConfidenceLevel
/// Indicates how confident the AI extraction is about the accuracy of a recipe.
///
/// Used to flag recipes that may need human review before cooking.
/// Apps can surface low-confidence recipes with warnings or suggestions to verify ingredients.
public enum ConfidenceLevel: String, Codable, CaseIterable, Sendable {
    /// High confidence: the AI is very confident in the extracted recipe details.
    case high
    /// Medium confidence: some details may need review, but the recipe is likely usable.
    case medium
    /// Low confidence: the user should double-check ingredients and steps before cooking.
    case low

    /// A user-friendly description of the confidence level.
    public var displayName: String {
        switch self {
        case .high: return "High confidence"
        case .medium: return "May need review"
        case .low: return "Check ingredients and steps"
        }
    }

    /// The SF Symbol icon name associated with each confidence level.
    public var iconName: String {
        switch self {
        case .high: return "checkmark.shield.fill"
        case .medium: return "exclamationmark.shield.fill"
        case .low: return "xmark.shield.fill"
        }
    }
}

// MARK: - SourcePlatform
/// Identifies the social media platform a recipe video was sourced from.
///
/// Cooksy supports importing recipe videos from popular platforms like YouTube, TikTok, and Instagram.
/// Each platform has a distinct icon and display characteristics in the UI.
public enum SourcePlatform: String, Codable, CaseIterable, Sendable {
    /// YouTube video platform.
    case youtube
    /// TikTok short-form video platform.
    case tiktok
    /// Instagram social media platform (including Reels).
    case instagram

    /// A human-readable name for the platform.
    public var displayName: String {
        switch self {
        case .youtube: return "YouTube"
        case .tiktok: return "TikTok"
        case .instagram: return "Instagram"
        }
    }

    /// The SF Symbol icon name to display for each platform.
    public var iconName: String {
        switch self {
        case .youtube: return "play.rectangle.fill"
        case .tiktok: return "music.note"
        case .instagram: return "camera.fill"
        }
    }

    /// The platform's brand color name for UI tinting.
    public var brandColorName: String {
        switch self {
        case .youtube: return "red"
        case .tiktok: return "cyan"
        case .instagram: return "pink"
        }
    }

    /// The base domain URL for the platform.
    public var baseURL: String {
        switch self {
        case .youtube: return "https://youtube.com"
        case .tiktok: return "https://tiktok.com"
        case .instagram: return "https://instagram.com"
        }
    }
}

// MARK: - RecipeCategory
/// Categorizes recipes by the type of meal or course they represent.
///
/// Users can filter and organize their recipes by category for easier browsing.
public enum RecipeCategory: String, Codable, CaseIterable, Sendable {
    /// Morning meal recipes.
    case breakfast
    /// Midday meal recipes.
    case lunch
    /// Evening meal recipes.
    case dinner
    /// Sweet treats and dessert recipes.
    case dessert
    /// Small bites and between-meal recipes.
    case snack
    /// Beverage and drink recipes.
    case drink
    /// Recipes that don't fit the above categories.
    case other

    /// A user-friendly display name for the category.
    public var displayName: String {
        rawValue.capitalized
    }

    /// The SF Symbol icon name associated with each category.
    public var iconName: String {
        switch self {
        case .breakfast: return "sunrise.fill"
        case .lunch: return "sun.max.fill"
        case .dinner: return "moon.fill"
        case .dessert: return "birthday.cake.fill"
        case .snack: return "bag.fill"
        case .drink: return "mug.fill"
        case .other: return "square.grid.2x2.fill"
        }
    }
}
