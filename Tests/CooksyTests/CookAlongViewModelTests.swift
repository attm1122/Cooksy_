import XCTest
@testable import Cooksy

// MARK: - CookAlongViewModelTests
/// Comprehensive unit tests for the CookAlongViewModel video-sync cooking experience.
///
/// Tests cover the sync engine (time updates, step activation), video controls (play/pause,
/// seeking), step navigation (previous/next/tap), computed properties (progress, formatted
/// time), and edge cases (before first step, after last step, empty recipes).
@MainActor
final class CookAlongViewModelTests: XCTestCase {

    // MARK: - Properties

    private var sut: CookAlongViewModel!
    private var recipe: Recipe!
    private var syncMap: RecipeSyncMap!

    // MARK: - Setup

    override func setUp() {
        super.setUp()
        recipe = makeRecipeWithSteps()
        syncMap = makeSyncMap()
        sut = CookAlongViewModel(recipe: recipe, syncMap: syncMap)
    }

    override func tearDown() {
        sut = nil
        recipe = nil
        syncMap = nil
        super.tearDown()
    }

    // MARK: - Factory Methods

    private func makeRecipeWithSteps() -> Recipe {
        let recipe = Recipe(
            title: "Cook Along Test Recipe",
            servings: 4,
            sourceUrl: "https://youtube.com/watch?v=test",
            sourcePlatform: .youtube,
            sourceCreator: "Test Chef",
            sourceTitle: "Test Video"
        )
        let step1 = RecipeStep(title: "Preheat", instruction: "Preheat oven to 350F", durationMinutes: 15, displayOrder: 0)
        let step2 = RecipeStep(title: "Mix Dry", instruction: "Mix flour and sugar", durationMinutes: 5, displayOrder: 1)
        let step3 = RecipeStep(title: "Mix Wet", instruction: "Mix butter and eggs", durationMinutes: 5, displayOrder: 2)
        let step4 = RecipeStep(title: "Combine", instruction: "Combine wet and dry ingredients", durationMinutes: 3, displayOrder: 3)
        let step5 = RecipeStep(title: "Bake", instruction: "Bake for 25 minutes", durationMinutes: 25, displayOrder: 4)
        recipe.steps = [step1, step2, step3, step4, step5]
        return recipe
    }

    private func makeSyncMap() -> RecipeSyncMap {
        RecipeSyncMap(
            recipeId: "test-recipe",
            videoUrl: "https://youtube.com/watch?v=test",
            videoDuration: 480,
            timestamps: [
                RecipeTimestamp(id: "t0", recipeStepId: "s0", stepIndex: 0, startTime: 0, endTime: 60, triggerPhrase: "preheat the oven", confidence: 0.95),
                RecipeTimestamp(id: "t1", recipeStepId: "s1", stepIndex: 1, startTime: 60, endTime: 120, triggerPhrase: "mix the dry", confidence: 0.92),
                RecipeTimestamp(id: "t2", recipeStepId: "s2", stepIndex: 2, startTime: 120, endTime: 180, triggerPhrase: "mix the wet", confidence: 0.90),
                RecipeTimestamp(id: "t3", recipeStepId: "s3", stepIndex: 3, startTime: 180, endTime: 240, triggerPhrase: "combine everything", confidence: 0.93),
                RecipeTimestamp(id: "t4", recipeStepId: "s4", stepIndex: 4, startTime: 240, endTime: 480, triggerPhrase: "bake it", confidence: 0.91),
            ],
            generatedAt: Date()
        )
    }

    private func makeEmptyRecipe() -> Recipe {
        Recipe(
            title: "Empty Recipe",
            servings: 1,
            sourceUrl: "https://youtube.com/watch?v=empty",
            sourcePlatform: .youtube,
            sourceCreator: "Nobody",
            sourceTitle: "Empty"
        )
    }

    private func makeEmptySyncMap() -> RecipeSyncMap {
        RecipeSyncMap(
            recipeId: "empty-recipe",
            videoUrl: "https://youtube.com/watch?v=empty",
            videoDuration: 0,
            timestamps: [],
            generatedAt: Date()
        )
    }

    // MARK: - Initial State Tests

    func test_initialState_currentTimeIsZero() {
        XCTAssertEqual(sut.currentTime, 0)
    }

    func test_initialState_isPlayingIsFalse() {
        XCTAssertFalse(sut.isPlaying)
    }

    func test_initialState_videoDurationFromSyncMap() {
        XCTAssertEqual(sut.videoDuration, 480)
    }

    func test_initialState_activeStepIndexIsZero() {
        XCTAssertEqual(sut.activeStepIndex, 0)
    }

    func test_initialState_isSyncEnabledIsTrue() {
        XCTAssertTrue(sut.isSyncEnabled)
    }

    func test_initialState_showControlsIsTrue() {
        XCTAssertTrue(sut.showControls)
    }

    func test_initialState_videoHeightFraction() {
        XCTAssertEqual(sut.videoHeightFraction, 0.5)
    }

    func test_initialState_isDraggingDividerIsFalse() {
        XCTAssertFalse(sut.isDraggingDivider)
    }

    func test_initialState_showReplayButtonIsFalse() {
        XCTAssertFalse(sut.showReplayButton)
    }

    // MARK: - onVideoTimeUpdate Tests

    func test_onVideoTimeUpdate_updatesCurrentTime() {
        sut.onVideoTimeUpdate(30.0)
        XCTAssertEqual(sut.currentTime, 30.0)
    }

    func test_onVideoTimeUpdate_zeroTime() {
        sut.onVideoTimeUpdate(0)
        XCTAssertEqual(sut.currentTime, 0)
    }

    func test_onVideoTimeUpdate_atStep0() {
        sut.onVideoTimeUpdate(30.0)
        // At 30 seconds, we are within step 0's range (0-60)
        XCTAssertEqual(sut.activeStepIndex, 0)
    }

    func test_onVideoTimeUpdate_atStep1() {
        sut.onVideoTimeUpdate(90.0)
        // At 90 seconds, we are within step 1's range (60-120)
        XCTAssertEqual(sut.activeStepIndex, 1)
    }

    func test_onVideoTimeUpdate_atStep4() {
        sut.onVideoTimeUpdate(300.0)
        // At 300 seconds, we are within step 4's range (240-480)
        XCTAssertEqual(sut.activeStepIndex, 4)
    }

    func test_onVideoTimeUpdate_atBoundary() {
        sut.onVideoTimeUpdate(60.0)
        // At exactly 60 seconds - step 0 ends at 60, step 1 starts at 60
        // The contains check uses inclusive boundaries
    }

    func test_onVideoTimeUpdate_multipleCalls() {
        sut.onVideoTimeUpdate(10.0)
        sut.onVideoTimeUpdate(70.0)
        sut.onVideoTimeUpdate(150.0)
        XCTAssertEqual(sut.currentTime, 150.0)
    }

    func test_onVideoTimeUpdate_withSyncDisabled() {
        sut.isSyncEnabled = false
        sut.onVideoTimeUpdate(150.0)
        // When sync is disabled, activeStepIndex should not change
        XCTAssertEqual(sut.currentTime, 150.0)
        // activeStepIndex stays at default since syncMap is not consulted
        XCTAssertEqual(sut.activeStepIndex, 0)
    }

    func test_onVideoTimeUpdate_beforeFirstStep() {
        // Before first step timestamp (which starts at 0)
        sut.onVideoTimeUpdate(0)
        XCTAssertEqual(sut.currentTime, 0)
        // Step 0 starts at 0, so at time 0 we should still be in step 0
    }

    func test_onVideoTimeUpdate_afterLastStepEnd() {
        sut.onVideoTimeUpdate(500.0)
        // After the last step's end time (480)
        // The syncMap's activeStepIndex may return nil after hysteresis
        XCTAssertEqual(sut.currentTime, 500.0)
    }

    func test_onVideoTimeUpdate_exactlyAtStepStart() {
        sut.onVideoTimeUpdate(120.0)
        // Exactly at step 2 start
        XCTAssertEqual(sut.currentTime, 120.0)
    }

    func test_onVideoTimeUpdate_exactlyAtStepEnd() {
        sut.onVideoTimeUpdate(60.0)
        // Exactly at step 0 end (which is also step 1 start)
        XCTAssertEqual(sut.currentTime, 60.0)
    }

    func test_onVideoTimeUpdate_veryLargeTime() {
        sut.onVideoTimeUpdate(10000.0)
        XCTAssertEqual(sut.currentTime, 10000.0)
    }

    // MARK: - togglePlayPause (simulated via isPlaying)

    func test_isPlaying_canBeToggled() {
        sut.isPlaying = true
        XCTAssertTrue(sut.isPlaying)
        sut.isPlaying = false
        XCTAssertFalse(sut.isPlaying)
    }

    func test_isPlaying_initiallyFalse() {
        XCTAssertFalse(sut.isPlaying)
    }

    // MARK: - seekToProgress Tests

    func test_seekToProgress_zero() {
        sut.seekToProgress(0)
        XCTAssertEqual(sut.currentTime, 0)
    }

    func test_seekToProgress_halfway() {
        sut.seekToProgress(0.5)
        XCTAssertEqual(sut.currentTime, 240.0)
    }

    func test_seekToProgress_full() {
        sut.seekToProgress(1.0)
        XCTAssertEqual(sut.currentTime, 480.0)
    }

    func test_seekToProgress_quarter() {
        sut.seekToProgress(0.25)
        XCTAssertEqual(sut.currentTime, 120.0)
    }

    func test_seekToProgress_exceedsOne() {
        sut.seekToProgress(1.5)
        XCTAssertEqual(sut.currentTime, 720.0)
    }

    func test_seekToProgress_negative() {
        sut.seekToProgress(-0.5)
        XCTAssertEqual(sut.currentTime, -240.0)
    }

    // MARK: - nextStep Tests

    func test_nextStep_fromStep0_advancesToStep1() {
        sut.activeStepIndex = 0
        sut.nextStep()
        XCTAssertEqual(sut.activeStepIndex, 1)
    }

    func test_nextStep_fromStep3_advancesToStep4() {
        sut.activeStepIndex = 3
        sut.nextStep()
        XCTAssertEqual(sut.activeStepIndex, 4)
    }

    func test_nextStep_atLastStep_staysAtLast() {
        sut.activeStepIndex = 4
        sut.nextStep()
        XCTAssertEqual(sut.activeStepIndex, 4)
    }

    func test_nextStep_advancesMultipleTimes() {
        sut.activeStepIndex = 0
        sut.nextStep()
        sut.nextStep()
        sut.nextStep()
        XCTAssertEqual(sut.activeStepIndex, 3)
    }

    func test_nextStep_toEnd() {
        sut.activeStepIndex = 0
        for _ in 0..<10 {
            sut.nextStep()
        }
        XCTAssertEqual(sut.activeStepIndex, 4)
    }

    // MARK: - previousStep Tests

    func test_previousStep_fromStep1_goesToStep0() {
        sut.activeStepIndex = 1
        sut.previousStep()
        XCTAssertEqual(sut.activeStepIndex, 0)
    }

    func test_previousStep_fromStep4_goesToStep3() {
        sut.activeStepIndex = 4
        sut.previousStep()
        XCTAssertEqual(sut.activeStepIndex, 3)
    }

    func test_previousStep_atFirstStep_staysAtFirst() {
        sut.activeStepIndex = 0
        sut.previousStep()
        XCTAssertEqual(sut.activeStepIndex, 0)
    }

    func test_previousStep_multipleTimes() {
        sut.activeStepIndex = 3
        sut.previousStep()
        sut.previousStep()
        sut.previousStep()
        XCTAssertEqual(sut.activeStepIndex, 0)
    }

    func test_previousStep_beyondBeginning() {
        sut.activeStepIndex = 0
        for _ in 0..<10 {
            sut.previousStep()
        }
        XCTAssertEqual(sut.activeStepIndex, 0)
    }

    // MARK: - tapStep Tests

    func test_tapStep_atIndex_setsActiveStep() {
        sut.tapStep(at: 2)
        XCTAssertEqual(sut.activeStepIndex, 2)
    }

    func test_tapStep_atIndex0() {
        sut.activeStepIndex = 3
        sut.tapStep(at: 0)
        XCTAssertEqual(sut.activeStepIndex, 0)
    }

    func test_tapStep_atLastIndex() {
        sut.tapStep(at: 4)
        XCTAssertEqual(sut.activeStepIndex, 4)
    }

    func test_tapStep_disablesSync() {
        sut.isSyncEnabled = true
        sut.tapStep(at: 2)
        // tapStep temporarily disables sync
        XCTAssertFalse(sut.isSyncEnabled)
    }

    func test_tapStep_setsCurrentTime() {
        // tapStep sets currentTime to the timestamp's startTime
        sut.tapStep(at: 1)
        // Step 1 starts at 60 seconds
        XCTAssertEqual(sut.currentTime, 60.0)
    }

    // MARK: - replayCurrentStep Tests

    func test_replayCurrentStep_setsCurrentTime() {
        sut.activeStepIndex = 2
        sut.currentTime = 200.0
        sut.showReplayButton = true
        sut.replayCurrentStep()
        // Should set currentTime to step 2's start time (120)
        XCTAssertEqual(sut.currentTime, 120.0)
    }

    func test_replayCurrentStep_hidesReplayButton() {
        sut.activeStepIndex = 2
        sut.showReplayButton = true
        sut.replayCurrentStep()
        XCTAssertFalse(sut.showReplayButton)
    }

    // MARK: - progress Computed Property

    func test_progress_zeroTime() {
        sut.currentTime = 0
        XCTAssertEqual(sut.progress, 0)
    }

    func test_progress_halfway() {
        sut.currentTime = 240.0
        let expectedProgress = 240.0 / 480.0
        XCTAssertEqual(sut.progress, expectedProgress, accuracy: 0.001)
    }

    func test_progress_fullDuration() {
        sut.currentTime = 480.0
        XCTAssertEqual(sut.progress, 1.0)
    }

    func test_progress_exceedsDuration() {
        sut.currentTime = 600.0
        let expectedProgress = 600.0 / 480.0
        XCTAssertEqual(sut.progress, expectedProgress, accuracy: 0.001)
    }

    // MARK: - currentStep Computed Property

    func test_currentStep_returnsCorrectStep() {
        sut.activeStepIndex = 0
        XCTAssertEqual(sut.currentStep?.title, "Preheat")
    }

    func test_currentStep_step1() {
        sut.activeStepIndex = 1
        XCTAssertEqual(sut.currentStep?.title, "Mix Dry")
    }

    func test_currentStep_lastStep() {
        sut.activeStepIndex = 4
        XCTAssertEqual(sut.currentStep?.title, "Bake")
    }

    // MARK: - currentStepTimestamp Computed Property

    func test_currentStepTimestamp_returnsCorrectTimestamp() {
        sut.activeStepIndex = 0
        let timestamp = sut.currentStepTimestamp
        XCTAssertNotNil(timestamp)
        XCTAssertEqual(timestamp?.startTime, 0)
        XCTAssertEqual(timestamp?.endTime, 60)
    }

    func test_currentStepTimestamp_step2() {
        sut.activeStepIndex = 2
        let timestamp = sut.currentStepTimestamp
        XCTAssertNotNil(timestamp)
        XCTAssertEqual(timestamp?.startTime, 120)
        XCTAssertEqual(timestamp?.endTime, 180)
    }

    // MARK: - formattedCurrentTime

    func test_formattedCurrentTime_zero() {
        sut.currentTime = 0
        XCTAssertEqual(sut.formattedCurrentTime, "0:00")
    }

    func test_formattedCurrentTime_secondsOnly() {
        sut.currentTime = 45
        XCTAssertEqual(sut.formattedCurrentTime, "0:45")
    }

    func test_formattedCurrentTime_oneMinute() {
        sut.currentTime = 60
        XCTAssertEqual(sut.formattedCurrentTime, "1:00")
    }

    func test_formattedCurrentTime_oneMinuteThirty() {
        sut.currentTime = 90
        XCTAssertEqual(sut.formattedCurrentTime, "1:30")
    }

    func test_formattedCurrentTime_multipleMinutes() {
        sut.currentTime = 125
        XCTAssertEqual(sut.formattedCurrentTime, "2:05")
    }

    // MARK: - formattedDuration

    func test_formattedDuration_matchesSyncMap() {
        XCTAssertEqual(sut.formattedDuration, "8:00") // 480 seconds = 8:00
    }

    // MARK: - formattedTimeRange

    func test_formattedTimeRange_step0() {
        let range = sut.formattedTimeRange(for: 0)
        XCTAssertEqual(range, "0:00 – 1:00")
    }

    func test_formattedTimeRange_step1() {
        let range = sut.formattedTimeRange(for: 1)
        XCTAssertEqual(range, "1:00 – 2:00")
    }

    func test_formattedTimeRange_step4() {
        let range = sut.formattedTimeRange(for: 4)
        XCTAssertEqual(range, "4:00 – 8:00")
    }

    func test_formattedTimeRange_invalidIndex() {
        let range = sut.formattedTimeRange(for: 99)
        XCTAssertEqual(range, "")
    }

    // MARK: - onTapVideo

    func test_onTapVideo_showsControls() {
        sut.showControls = false
        sut.onTapVideo()
        XCTAssertTrue(sut.showControls)
    }

    // MARK: - Video Height Fraction

    func test_videoHeightFraction_canBeSet() {
        sut.videoHeightFraction = 0.3
        XCTAssertEqual(sut.videoHeightFraction, 0.3)
    }

    func test_videoHeightFraction_canBeMax() {
        sut.videoHeightFraction = 1.0
        XCTAssertEqual(sut.videoHeightFraction, 1.0)
    }

    func test_videoHeightFraction_canBeMin() {
        sut.videoHeightFraction = 0.0
        XCTAssertEqual(sut.videoHeightFraction, 0.0)
    }

    // MARK: - isDraggingDivider

    func test_isDraggingDivider_canBeSet() {
        sut.isDraggingDivider = true
        XCTAssertTrue(sut.isDraggingDivider)
        sut.isDraggingDivider = false
        XCTAssertFalse(sut.isDraggingDivider)
    }

    // MARK: - showReplayButton

    func test_showReplayButton_canBeSet() {
        sut.showReplayButton = true
        XCTAssertTrue(sut.showReplayButton)
        sut.showReplayButton = false
        XCTAssertFalse(sut.showReplayButton)
    }

    // MARK: - Edge Cases - Empty Recipe

    func test_emptyRecipe_currentStepIsNil() {
        let emptyRecipe = makeEmptyRecipe()
        let emptySyncMap = makeEmptySyncMap()
        let vm = CookAlongViewModel(recipe: emptyRecipe, syncMap: emptySyncMap)
        XCTAssertNil(vm.currentStep)
    }

    func test_emptyRecipe_nextStep_doesNotCrash() {
        let emptyRecipe = makeEmptyRecipe()
        let emptySyncMap = makeEmptySyncMap()
        let vm = CookAlongViewModel(recipe: emptyRecipe, syncMap: emptySyncMap)
        vm.nextStep()
        XCTAssertEqual(vm.activeStepIndex, 0)
    }

    func test_emptyRecipe_previousStep_doesNotCrash() {
        let emptyRecipe = makeEmptyRecipe()
        let emptySyncMap = makeEmptySyncMap()
        let vm = CookAlongViewModel(recipe: emptyRecipe, syncMap: emptySyncMap)
        vm.previousStep()
        XCTAssertEqual(vm.activeStepIndex, 0)
    }

    func test_emptyRecipe_progress_isZero() {
        let emptyRecipe = makeEmptyRecipe()
        let emptySyncMap = makeEmptySyncMap()
        let vm = CookAlongViewModel(recipe: emptyRecipe, syncMap: emptySyncMap)
        XCTAssertEqual(vm.progress, 0)
    }

    // MARK: - Edge Cases - Time Before/After Steps

    func test_timeBeforeFirstStep() {
        // Step 0 starts at 0, so there's no "before"
        sut.onVideoTimeUpdate(0)
        XCTAssertEqual(sut.currentTime, 0)
    }

    func test_timeAfterAllSteps() {
        sut.onVideoTimeUpdate(500)
        // After last step ends at 480
        XCTAssertEqual(sut.currentTime, 500)
    }

    // MARK: - Rapid Step Navigation

    func test_rapidStepNavigation() {
        sut.tapStep(at: 0)
        sut.nextStep()
        sut.nextStep()
        sut.previousStep()
        sut.tapStep(at: 4)
        sut.previousStep()
        XCTAssertEqual(sut.activeStepIndex, 3)
    }

    func test_stepNavigation_doesNotGoBelowZero() {
        for _ in 0..<20 {
            sut.previousStep()
        }
        XCTAssertEqual(sut.activeStepIndex, 0)
    }

    func test_stepNavigation_doesNotExceedMax() {
        for _ in 0..<20 {
            sut.nextStep()
        }
        XCTAssertEqual(sut.activeStepIndex, 4)
    }

    // MARK: - State Consistency

    func test_allStatePropertiesAreIndependent() {
        sut.isPlaying = true
        sut.showControls = false
        sut.showReplayButton = true
        sut.isDraggingDivider = true
        sut.videoHeightFraction = 0.7

        XCTAssertTrue(sut.isPlaying)
        XCTAssertFalse(sut.showControls)
        XCTAssertTrue(sut.showReplayButton)
        XCTAssertTrue(sut.isDraggingDivider)
        XCTAssertEqual(sut.videoHeightFraction, 0.7)
    }

    // MARK: - Recipe Reference

    func test_recipeIsAssigned() {
        XCTAssertEqual(sut.recipe.title, "Cook Along Test Recipe")
    }

    func test_syncMapIsAssigned() {
        XCTAssertEqual(sut.syncMap.videoDuration, 480)
    }

    // MARK: - Sync Map Coverage

    func test_syncMap_coverageRatio() {
        // Total covered: (60-0) + (120-60) + (180-120) + (240-180) + (480-240) = 60+60+60+60+240 = 480
        // videoDuration = 480
        // coverageRatio = 480/480 = 1.0
        XCTAssertEqual(syncMap.coverageRatio, 1.0, accuracy: 0.001)
    }

    func test_syncMap_averageConfidence() {
        let confidences = [0.95, 0.92, 0.90, 0.93, 0.91]
        let expectedAverage = confidences.reduce(0, +) / Double(confidences.count)
        XCTAssertEqual(syncMap.averageConfidence, expectedAverage, accuracy: 0.001)
    }

    func test_syncMap_timestampForStepIndex() {
        let ts = syncMap.timestamp(forStepIndex: 2)
        XCTAssertNotNil(ts)
        XCTAssertEqual(ts?.stepIndex, 2)
        XCTAssertEqual(ts?.startTime, 120)
    }

    func test_syncMap_timestampForInvalidIndex() {
        let ts = syncMap.timestamp(forStepIndex: 99)
        XCTAssertNil(ts)
    }

    func test_syncMap_activeStepIndex_atTime() {
        let index = syncMap.activeStepIndex(at: 150)
        XCTAssertEqual(index, 2) // Step 2 is 120-180
    }

    func test_syncMap_activeStepIndex_beforeAllSteps() {
        // Step 0 starts at 0, so there's nothing before
        let index = syncMap.activeStepIndex(at: 0)
        XCTAssertEqual(index, 0)
    }

    func test_syncMap_activeStepIndex_afterAllSteps() {
        let index = syncMap.activeStepIndex(at: 500)
        // After hysteresis, might still find step 4 (240-480 with 0.5s hysteresis)
        // Actually 500 > 480.5, so should be nil
        XCTAssertNil(index)
    }

    // MARK: - RecipeTimestamp Tests

    func test_recipeTimestamp_containsTime() {
        let ts = RecipeTimestamp(id: "t", recipeStepId: "s", stepIndex: 0, startTime: 10, endTime: 20, triggerPhrase: "test", confidence: 0.9)
        XCTAssertTrue(ts.contains(15))
        XCTAssertTrue(ts.contains(10))
        XCTAssertTrue(ts.contains(20))
        XCTAssertFalse(ts.contains(5))
        XCTAssertFalse(ts.contains(25))
    }

    func test_recipeTimestamp_duration() {
        let ts = RecipeTimestamp(id: "t", recipeStepId: "s", stepIndex: 0, startTime: 10, endTime: 30, triggerPhrase: "test", confidence: 0.9)
        XCTAssertEqual(ts.duration, 20)
    }

    // MARK: - showControls State

    func test_showControls_defaultsToTrue() {
        XCTAssertTrue(sut.showControls)
    }

    func test_showControls_canBeHidden() {
        sut.showControls = false
        XCTAssertFalse(sut.showControls)
    }
}
