import SwiftUI

/// The main Cook-Along screen.
///
/// Split-screen layout:
/// - Top half: Video player (YouTube/TikTok/Instagram embed)
/// - Drag handle: Pill indicator to resize split
/// - Bottom half: Recipe timeline (auto-synced to video)
/// - Controls bar: Play/pause, prev/next, progress
///
/// Fully accessible with VoiceOver. Supports Dynamic Type.
/// Reduces Motion respected for animations.
struct CookAlongView: View {

    @Bindable var viewModel: CookAlongViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // Local state for drag gesture
    @State private var dragOffset: CGFloat = 0

    var body: some View {
        ZStack {
            // Background
            Color.ink.ignoresSafeArea()

            VStack(spacing: 0) {
                // MARK: - Top Bar
                topBar

                // MARK: - Video Player (resizable)
                videoSection
                    .frame(height: videoHeight)

                // MARK: - Drag Handle
                dragHandle

                // MARK: - Recipe Timeline
                RecipeTimelineView(
                    recipe: viewModel.recipe,
                    syncMap: viewModel.syncMap,
                    viewModel: viewModel
                )

                // MARK: - Controls Bar
                controlsBar
                    .background(Color.ink.opacity(0.95))
            }
        }
        .statusBar(hidden: true)
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(.white.opacity(0.1))
                    .clipShape(Circle())
            }

            Spacer()

            VStack(spacing: 2) {
                Text("Cooking Mode")
                    .font(.system(size: 13, weight: .medium, design: .default))
                    .foregroundStyle(.white.opacity(0.6))
                    .tracking(1)
                Text(viewModel.recipe.title)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
            }

            Spacer()

            // Sync toggle
            Button(action: { viewModel.isSyncEnabled.toggle() }) {
                Image(systemName: viewModel.isSyncEnabled ? "link.circle.fill" : "link.circle")
                    .font(.system(size: 20))
                    .foregroundStyle(viewModel.isSyncEnabled ? Color.brand : .white.opacity(0.5))
            }
            .accessibilityLabel(viewModel.isSyncEnabled ? "Auto-sync enabled" : "Auto-sync disabled")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.ink.opacity(0.95))
    }

    // MARK: - Video Section

    private var videoSection: some View {
        ZStack {
            VideoPlatformPlayer(
                videoUrl: viewModel.syncMap.videoUrl,
                platform: viewModel.recipe.source.platform,
                currentTime: $viewModel.currentTime,
                isPlaying: $viewModel.isPlaying,
                duration: $viewModel.videoDuration,
                onTimeUpdate: { time in
                    viewModel.onVideoTimeUpdate(time)
                }
            )

            // Tap overlay for controls
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture { viewModel.onTapVideo() }

            // Play/pause overlay (fades out)
            if viewModel.showControls {
                playPauseOverlay
                    .transition(.opacity)
            }

            // Progress bar overlay
            VStack {
                Spacer()
                videoProgressBar
            }
        }
    }

    // MARK: - Play/Pause Overlay

    @ViewBuilder
    private var playPauseOverlay: some View {
        Button(action: {
            // Toggle play/pause via view model
            viewModel.isPlaying.toggle()
        }) {
            Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                .font(.system(size: 32, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 64, height: 64)
                .background(.ultraThinMaterial)
                .clipShape(Circle())
        }
        .accessibilityLabel(viewModel.isPlaying ? "Pause" : "Play")
    }

    // MARK: - Video Progress Bar

    private var videoProgressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                // Background track
                Capsule()
                    .fill(.white.opacity(0.2))
                    .frame(height: 4)

                // Fill
                Capsule()
                    .fill(Color.brand)
                    .frame(width: geo.size.width * viewModel.progress, height: 4)
                    .animation(reduceMotion ? nil : .linear(duration: 0.1), value: viewModel.progress)
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let fraction = max(0, min(1, value.location.x / geo.size.width))
                        viewModel.seekToProgress(fraction)
                    }
            )
        }
        .frame(height: 12)
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Video progress")
        .accessibilityValue("\(Int(viewModel.progress * 100)) percent, \(viewModel.formattedCurrentTime) of \(viewModel.formattedDuration)")
    }

    // MARK: - Drag Handle

    private var dragHandle: some View {
        HStack {
            Spacer()
            Capsule()
                .fill(.white.opacity(0.3))
                .frame(width: 40, height: 4)
            Spacer()
        }
        .frame(height: 20)
        .background(Color.ink)
        .gesture(
            DragGesture()
                .onChanged { value in
                    dragOffset = value.translation.height
                }
                .onEnded { value in
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        let screenHeight = UIScreen.main.bounds.height
                        let currentHeight = videoHeight + dragOffset
                        let fraction = currentHeight / screenHeight
                        // Snap to 40%, 50%, or 60%
                        if fraction < 0.45 {
                            viewModel.videoHeightFraction = 0.4
                        } else if fraction > 0.55 {
                            viewModel.videoHeightFraction = 0.6
                        } else {
                            viewModel.videoHeightFraction = 0.5
                        }
                        dragOffset = 0
                    }
                }
        )
        .accessibilityLabel("Resize video and recipe panels")
        .accessibilityHint("Drag up to enlarge recipe, drag down to enlarge video")
    }

    // MARK: - Controls Bar

    private var controlsBar: some View {
        HStack(spacing: 24) {
            // Previous step
            Button(action: { viewModel.previousStep() }) {
                VStack(spacing: 4) {
                    Image(systemName: "backward.fill")
                        .font(.system(size: 20, weight: .semibold))
                    Text("Prev")
                        .font(.system(size: 11, weight: .medium))
                }
                .foregroundStyle(.white.opacity(0.8))
            }
            .disabled(viewModel.activeStepIndex == 0)
            .accessibilityLabel("Previous step")

            // Play/Pause (large)
            Button(action: { viewModel.isPlaying.toggle() }) {
                Image(systemName: viewModel.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(Color.brand)
            }
            .accessibilityLabel(viewModel.isPlaying ? "Pause" : "Play")

            // Next step
            Button(action: { viewModel.nextStep() }) {
                VStack(spacing: 4) {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 20, weight: .semibold))
                    Text("Next")
                        .font(.system(size: 11, weight: .medium))
                }
                .foregroundStyle(.white.opacity(0.8))
            }
            .disabled(viewModel.activeStepIndex >= viewModel.recipe.sortedSteps.count - 1)
            .accessibilityLabel("Next step")

            // Time display
            VStack(alignment: .trailing, spacing: 2) {
                Text(viewModel.formattedCurrentTime)
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white)
                Text(viewModel.formattedDuration)
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.5))
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
    }

    // MARK: - Computed

    private var videoHeight: CGFloat {
        let base = UIScreen.main.bounds.height * viewModel.videoHeightFraction
        return max(200, min(base + dragOffset, UIScreen.main.bounds.height - 300))
    }
}

// MARK: - Preview

#Preview {
    let recipe = Recipe(
        title: "Creamy Garlic Parmesan Pasta",
        heroNote: "A rich and creamy pasta dish",
        servings: 4, prepTimeMinutes: 5, cookTimeMinutes: 15, totalTimeMinutes: 20,
        status: .ready, confidence: .high, confidenceScore: 92,
        confidenceNote: "High confidence extraction",
        isSaved: true,
        sourceUrl: "https://youtube.com/watch?v=demo",
        sourcePlatform: .youtube,
        sourceCreator: "Chef John",
        sourceTitle: "Easy Pasta Recipe"
    )
    let syncMap = RecipeSyncMap.mock(for: recipe.id.uuidString)
    let vm = CookAlongViewModel(recipe: recipe, syncMap: syncMap)

    CookAlongView(viewModel: vm)
}
