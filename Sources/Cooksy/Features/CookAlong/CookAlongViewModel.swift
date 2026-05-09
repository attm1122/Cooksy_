import SwiftUI
import Combine

@Observable
@MainActor
final class CookAlongViewModel {

    // MARK: - Dependencies
    let recipe: Recipe
    let syncMap: RecipeSyncMap

    // MARK: - Video State
    var currentTime: TimeInterval = 0
    var isPlaying: Bool = false
    var videoDuration: TimeInterval = 0

    // MARK: - Sync State
    var activeStepIndex: Int = 0
    var isSyncEnabled: Bool = true
    var showControls: Bool = true

    // MARK: - UI State
    var videoHeightFraction: CGFloat = 0.5
    var isDraggingDivider: Bool = false
    var showReplayButton: Bool = false

    // MARK: - Computed
    var progress: Double {
        guard videoDuration > 0 else { return 0 }
        return currentTime / videoDuration
    }

    var currentStep: RecipeStep? {
        guard activeStepIndex < recipe.sortedSteps.count else { return nil }
        return recipe.sortedSteps[activeStepIndex]
    }

    var currentStepTimestamp: RecipeTimestamp? {
        syncMap.timestamp(forStepIndex: activeStepIndex)
    }

    var formattedCurrentTime: String {
        formatTime(currentTime)
    }

    var formattedDuration: String {
        formatTime(videoDuration)
    }

    // MARK: - Private
    private var controlHideTask: Task<Void, Never>?

    // MARK: - Init
    init(recipe: Recipe, syncMap: RecipeSyncMap) {
        self.recipe = recipe
        self.syncMap = syncMap
        self.videoDuration = syncMap.videoDuration
    }

    // MARK: - Sync Engine

    /// Called on every video time update (~30Hz from VideoPlatformPlayer)
    func onVideoTimeUpdate(_ time: TimeInterval) {
        self.currentTime = time

        guard isSyncEnabled else { return }

        // Look up active step with 0.5s hysteresis
        if let newIndex = syncMap.activeStepIndex(at: time) {
            if newIndex != activeStepIndex {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    activeStepIndex = newIndex
                    showReplayButton = true
                }
            }
        }
    }

    // MARK: - Navigation

    func tapStep(at index: Int) {
        guard let timestamp = syncMap.timestamp(forStepIndex: index) else { return }

        // Disable auto-sync briefly to prevent immediate snap-back
        isSyncEnabled = false
        activeStepIndex = index
        currentTime = timestamp.startTime

        // Re-enable sync after a delay
        Task {
            try? await Task.sleep(for: .seconds(2))
            isSyncEnabled = true
        }
    }

    func previousStep() {
        let newIndex = max(0, activeStepIndex - 1)
        tapStep(at: newIndex)
    }

    func nextStep() {
        let newIndex = min(recipe.sortedSteps.count - 1, activeStepIndex + 1)
        tapStep(at: newIndex)
    }

    func replayCurrentStep() {
        guard let timestamp = currentStepTimestamp else { return }
        currentTime = timestamp.startTime
        showReplayButton = false
    }

    func seekToProgress(_ fraction: Double) {
        currentTime = fraction * videoDuration
    }

    // MARK: - Controls

    func onTapVideo() {
        showControls = true
        scheduleControlHide()
    }

    private func scheduleControlHide() {
        controlHideTask?.cancel()
        controlHideTask = Task {
            try? await Task.sleep(for: .seconds(3))
            if !Task.isCancelled {
                withAnimation { showControls = false }
            }
        }
    }

    // MARK: - Helpers

    private func formatTime(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }

    func formattedTimeRange(for index: Int) -> String {
        guard let ts = syncMap.timestamp(forStepIndex: index) else { return "" }
        return "\(formatTime(ts.startTime)) – \(formatTime(ts.endTime))"
    }
}
