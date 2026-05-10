import SwiftUI
import SafariServices

// MARK: - Safari View
/// A SwiftUI wrapper around `SFSafariViewController` for presenting web content
/// without leaving the app. Used for Terms of Service and Privacy Policy links.
struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        SFSafariViewController(url: url)
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}
