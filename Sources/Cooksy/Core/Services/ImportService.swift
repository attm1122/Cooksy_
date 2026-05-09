import Foundation
import SwiftData

// MARK: - ImportService
/// Orchestrates the full recipe import pipeline: validate URL, start server-side processing,
/// poll for completion, and persist the result to SwiftData.
///
/// ## State Machine
/// ```
/// idle → validating → starting → processing → completed
///                                      ↓
///                                    failed
/// ```
///
/// ## Task Cancellation
/// Call `cancelImport()` to stop polling and reset to `.idle`.
/// The underlying `URLSessionTask` is also cancelled via cooperative cancellation.
@Observable
@MainActor
final class ImportService {

    // MARK: - Dependencies

    /// The Supabase backend used to start and monitor imports.
    private var supabase: (any SupabaseProtocol)?

    /// The SwiftData context used to persist completed recipes locally.
    private var modelContext: ModelContext?

    // MARK: - State

    /// Whether an import is currently in flight.
    private(set) var isImporting = false

    /// The server-assigned job ID for the current import.
    private(set) var currentJobId: String?

    /// The current phase of the import pipeline.
    private(set) var progress: ImportProgress = .idle

    /// The most recent error, if any.
    private(set) var error: CooksyError?

    // MARK: - Internal Task

    /// The active polling task. Stored so it can be cancelled.
    private var pollingTask: Task<Void, Never>?

    // MARK: - Progress Enumeration

    /// Represents every phase of the import pipeline.
    enum ImportProgress: Equatable {
        case idle
        case validating
        case starting
        case processing(message: String)
        case completed(Recipe)
        case failed(CooksyError)

        static func == (lhs: ImportProgress, rhs: ImportProgress) -> Bool {
            switch (lhs, rhs) {
            case (.idle, .idle): return true
            case (.validating, .validating): return true
            case (.starting, .starting): return true
            case let (.processing(a), .processing(b)): return a == b
            case let (.completed(lhsRecipe), .completed(rhsRecipe)): return lhsRecipe.id == rhsRecipe.id
            case let (.failed(lhsErr), .failed(rhsErr)): return lhsErr.localizedDescription == rhsErr.localizedDescription
            default: return false
            }
        }
    }

    // MARK: - Configuration

    /// Injects the required dependencies. Must be called before `importRecipe(url:)`.
    func configure(supabase: any SupabaseProtocol, modelContext: ModelContext) {
        self.supabase = supabase
        self.modelContext = modelContext
    }

    // MARK: - Import Pipeline

    /// Starts the full import pipeline.
    ///
    /// 1. Validates the URL against supported platforms.
    /// 2. Calls `supabase.importRecipe(url:)` to start server-side processing.
    /// 3. Polls `checkImportStatus` every 3 seconds until the job is `.ready` or `.failed`.
    /// 4. Calls `completeImport` to fetch the full recipe DTO.
    /// 5. Converts the DTO to a SwiftData `Recipe` and inserts it into the local store.
    ///
    /// - Parameter url: The video URL (YouTube, TikTok, or Instagram).
    func importRecipe(url: String) async {
        guard let supabase = supabase else {
            progress = .failed(CooksyError.validationError("ImportService not configured"))
            return
        }

        // Cancel any previous import
        pollingTask?.cancel()

        isImporting = true
        progress = .validating
        error = nil
        currentJobId = nil

        do {
            // 1. Validate URL
            guard Validators.isSupportedURL(url) else {
                throw CooksyError.unsupportedPlatform
            }

            // 2. Start server-side import
            progress = .starting
            let response = try await supabase.importRecipe(url: url)
            currentJobId = response.jobId

            guard !Task.isCancelled else { throw CancellationError() }

            // 3. Poll until ready
            progress = .processing(message: "Extracting recipe from video...")

            var status = response.status
            var pollCount = 0
            let maxPolls = 120 // ~6 minutes maximum (120 * 3s)

            while status != .ready && status != .failed && pollCount < maxPolls {
                try await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds

                if Task.isCancelled {
                    throw CancellationError()
                }

                let check = try await supabase.checkImportStatus(jobId: response.jobId)
                status = check.status
                pollCount += 1

                switch status {
                case .pending:
                    progress = .processing(message: "Waiting in queue...")
                case .processing:
                    progress = .processing(message: "Building your recipe...")
                case .failed:
                    let msg = check.message ?? "Could not extract recipe from this video"
                    throw CooksyError.importFailed(msg)
                case .ready:
                    break // Exit loop and complete
                }
            }

            if status != .ready {
                throw CooksyError.importFailed("Import timed out. Please try again.")
            }

            guard !Task.isCancelled else { throw CancellationError() }

            // 4. Fetch completed recipe
            let recipeDTO = try await supabase.completeImport(jobId: response.jobId)

            guard !Task.isCancelled else { throw CancellationError() }

            // 5. Persist to SwiftData
            if let modelContext = modelContext {
                let recipe = recipeDTO.toModel(context: modelContext)
                recipe.isSaved = true
                modelContext.insert(recipe)
                try modelContext.save()
                progress = .completed(recipe)
            } else {
                // No SwiftData context — create recipe in memory only
                let emptyContext = ModelContext(try! ModelContainer(for: Recipe.self))
                let recipe = recipeDTO.toModel(context: emptyContext)
                recipe.isSaved = true
                progress = .completed(recipe)
            }

        } catch is CancellationError {
            // Clean cancellation — reset to idle without an error
            reset()
            return

        } catch let err as CooksyError {
            progress = .failed(err)
            error = err

        } catch {
            progress = .failed(.unknown)
            self.error = .unknown
        }

        isImporting = false
    }

    /// Cancels any in-flight import and resets state to `.idle`.
    func cancelImport() {
        pollingTask?.cancel()
        // Don't reset immediately; let the Task catch CancellationError
        // and call reset() gracefully. But also reset here for immediate UI feedback.
        reset()
    }

    /// Resets all import state to `.idle`.
    func reset() {
        pollingTask?.cancel()
        pollingTask = nil
        isImporting = false
        currentJobId = nil
        progress = .idle
        error = nil
    }
}
