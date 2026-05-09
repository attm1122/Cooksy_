import Foundation

enum CooksyError: Error, LocalizedError {
    case invalidURL
    case unsupportedPlatform
    case networkError(Error)
    case serverError(statusCode: Int, message: String)
    case unauthorized
    case recipeNotFound
    case importFailed(String)
    case subscriptionError(String)
    case validationError(String)
    case unknown

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Please enter a valid URL"
        case .unsupportedPlatform: return "Only YouTube, TikTok, and Instagram links are supported"
        case .networkError(let error): return "Network error: \(error.localizedDescription)"
        case .serverError(_, let message): return message
        case .unauthorized: return "Please sign in to continue"
        case .recipeNotFound: return "Recipe not found"
        case .importFailed(let msg): return msg
        case .subscriptionError(let msg): return msg
        case .validationError(let msg): return msg
        case .unknown: return "Something went wrong"
        }
    }
}
