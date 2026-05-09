import Foundation
import SwiftUI

// MARK: - Deep Link Service
/// Handles all deep linking into the Cooksy app including:
/// - `cooksy://recipe/{id}` - Navigate to a specific recipe
/// - `cooksy://import?url={videoUrl}` - Start an import from a video URL
/// - `cooksy://subscription` - Open the subscription view
/// - `cooksy://profile` - Open the profile view
@Observable
@MainActor
final class DeepLinkService {
    
    // MARK: - Singleton
    
    static let shared = DeepLinkService()
    
    // MARK: - Published State
    
    /// The currently active deep link target, if any.
    /// Views observe this to trigger navigation.
    var activeTarget: DeepLinkTarget?
    
    /// Whether a deep link is currently being processed
    private(set) var isProcessing = false
    
    // MARK: - Types
    
    /// Represents a parsed deep link destination within the app
    enum DeepLinkTarget: Identifiable, Hashable {
        case recipe(id: String)
        case importVideo(url: String)
        case subscription
        case profile
        case settings
        
        var id: String {
            switch self {
            case .recipe(let id): return "recipe-\(id)"
            case .importVideo(let url): return "import-\(url)"
            case .subscription: return "subscription"
            case .profile: return "profile"
            case .settings: return "settings"
            }
        }
    }
    
    // MARK: - URL Handling
    
    /// Handles an incoming URL and converts it to a navigation target.
    /// - Parameter url: The deep link URL
    /// - Returns: Whether the URL was successfully handled
    @discardableResult
    func handle(url: URL) -> Bool {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
              let host = components.host else {
            return false
        }
        
        isProcessing = true
        
        switch host {
        case "recipe":
            handleRecipeDeepLink(path: components.path)
            
        case "import":
            handleImportDeepLink(queryItems: components.queryItems)
            
        case "subscription":
            activeTarget = .subscription
            
        case "profile":
            activeTarget = .profile
            
        case "settings":
            activeTarget = .settings
            
        default:
            isProcessing = false
            return false
        }
        
        isProcessing = false
        return true
    }
    
    /// Handles Universal Links (https://cooksy.app/...) that may come from
    /// Safari, shared links, or other apps.
    /// - Parameter url: The universal link URL
    /// - Returns: Whether the URL was successfully handled
    @discardableResult
    func handleUniversalLink(url: URL) -> Bool {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
              let host = components.host,
              host.contains("cooksy.app") else {
            return false
        }
        
        let pathComponents = components.path
            .split(separator: "/")
            .map(String.init)
        
        guard pathComponents.count >= 2 else { return false }
        
        switch pathComponents[0] {
        case "recipe":
            let recipeId = pathComponents[1]
            activeTarget = .recipe(id: recipeId)
            return true
            
        case "import":
            if let videoUrl = components.queryItems?.first(where: { $0.name == "url" })?.value {
                activeTarget = .importVideo(url: videoUrl)
                return true
            }
            
        default:
            break
        }
        
        return false
    }
    
    /// Clears the active deep link target after navigation has occurred.
    func clearTarget() {
        activeTarget = nil
    }
    
    // MARK: - Private Handlers
    
    private func handleRecipeDeepLink(path: String) {
        // Parse cooksy://recipe/{id}
        let recipeId = path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard !recipeId.isEmpty else { return }
        activeTarget = .recipe(id: recipeId)
    }
    
    private func handleImportDeepLink(queryItems: [URLQueryItem]?) {
        // Parse cooksy://import?url={videoUrl}
        guard let videoUrl = queryItems?.first(where: { $0.name == "url" })?.value else { return }
        activeTarget = .importVideo(url: videoUrl)
    }
    
    // MARK: - URL Generation
    
    /// Generates a shareable deep link for a recipe.
    /// - Parameter recipeId: The recipe's unique identifier
    /// - Returns: A `cooksy://` URL string
    static func recipeLink(recipeId: String) -> String {
        "cooksy://recipe/\(recipeId)"
    }
    
    /// Generates a shareable web link for a recipe.
    /// - Parameter recipeId: The recipe's unique identifier
    /// - Returns: An `https://` URL string
    static func recipeWebLink(recipeId: String) -> String {
        "https://cooksy.app/recipe/\(recipeId)"
    }
    
    /// Generates a deep link to start importing a video.
    /// - Parameter videoUrl: The video URL to import
    /// - Returns: A `cooksy://` URL string
    static func importLink(videoUrl: String) -> String {
        guard let encoded = videoUrl.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return "cooksy://import"
        }
        return "cooksy://import?url=\(encoded)"
    }
}

// MARK: - View Modifier for Deep Link Handling

/// A view modifier that enables deep link handling within a navigation stack.
struct DeepLinkHandler: ViewModifier {
    @State private var deepLinkService = DeepLinkService.shared
    @State private var navigateToRecipe: String?
    @State private var navigateToSubscription = false
    @State private var navigateToProfile = false
    
    func body(content: Content) -> some View {
        content
            .onOpenURL { url in
                DeepLinkService.shared.handle(url: url)
            }
            .onReceive(NotificationCenter.default.publisher(for: .didReceiveDeepLink)) { notification in
                if let url = notification.userInfo?["url"] as? URL {
                    DeepLinkService.shared.handle(url: url)
                }
            }
            .onChange(of: deepLinkService.activeTarget) { _, target in
                guard let target else { return }
                handleTarget(target)
            }
            .navigationDestination(isPresented: $navigateToSubscription) {
                SubscriptionView()
            }
            .navigationDestination(item: $navigateToRecipe) { recipeId in
                // In a real app, you'd fetch the recipe and show RecipeDetailView
                Text("Recipe: \(recipeId)")
            }
    }
    
    private func handleTarget(_ target: DeepLinkService.DeepLinkTarget) {
        switch target {
        case .recipe(let id):
            navigateToRecipe = id
        case .subscription:
            navigateToSubscription = true
        case .profile:
            navigateToProfile = true
        case .importVideo(let url):
            // Handle import - would trigger the import flow
            print("[DeepLinkService] Import video: \(url)")
        case .settings:
            navigateToProfile = true
        }
        
        DeepLinkService.shared.clearTarget()
    }
}

extension View {
    /// Enables deep link handling for this view.
    func handleDeepLinks() -> some View {
        modifier(DeepLinkHandler())
    }
}
