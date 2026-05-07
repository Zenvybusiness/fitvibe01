# Project Context (Single Source)

## Architecture
- Flow: UI -> Controller -> Engine -> Persistence.
- UI screens call `AppController` methods.
- `AppController` coordinates learning, recommendation calls, and saves state.
- `DecisionEngine` selects next item from `Dataset` using action history + vibe logic.
- `PersistenceService` stores cross-session values in `SharedPreferences`.

## Folder Structure
- `lib/screens`: `onboarding_screen.dart`, `home_screen.dart`, `saved_screen.dart`, `profile_screen.dart`, `splash_screen.dart`.
- `lib/controller`: `app_controller.dart`.
- `lib/core/engine`: `decision_engine.dart`, `learning_engine.dart`.
- `lib/core/state`: `preference_state.dart`.
- `lib/core/models`: `item.dart`, `user_action.dart`.
- `lib/services`: `persistence_service.dart`.
- `lib/widgets`: `item_card.dart`, `tag_chip.dart`, `feedback_text.dart`, `action_buttons.dart`.
- `lib/data`: `dataset.dart`, `initial_pool.dart`.

## Core Logic Flow
1. App starts in `main.dart`, reads onboarding flag from persistence.
2. Route: onboarding (first time) or home.
3. `HomeScreen.handleAction()` triggers `_controller.onAction(isLike)`.
4. Controller updates streaks/recent history/saved items, asks `DecisionEngine.getNextItem()`.
5. New item set, feedback/score updated, state persisted.

## DecisionEngine Behavior
- Tracks static `vibeWeights`.
- Updates vibe weight by last action (`like` positive, `skip` negative).
- Filters by overlap with previous item + recent repeat control.
- Scores candidates using `PreferenceState` + overlap + vibe balancing.
- Applies exploration moments (`actionCount % 6 == 0`) and streak/confidence rules.
- Enforces like/skip vibe consistency before returning final item.

## Persistence Flow
- `PersistenceService.saveData/loadData` stores:
  - `vibeWeights`, streaks, `confidence`, onboarding flag, selected vibe, saved item ids.
  - score system keys: `score`, `lastUpdatedDay`.
- `AppController` also saves internal controller snapshot (`recentItems`, `recentVibes`, counters, score fields, preferences).

## Onboarding Flow
- `onboarding_screen.dart` collects vibe chips.
- Applies initial preference weights through controller.
- Saves onboarding completed + selected vibe + current state.
- Navigates to `HomeScreen`.

## Score / Progress System
- In `AppController`:
  - `score` starts at `5.5`, `lastDelta` tracks last swipe impact.
  - Like: `+0.2` if top vibe matches item vibe, else `+0.1`.
  - Skip: `-0.05`.
  - Score clamped to `[3.0, 9.0]`.
- Feedback from `getFeedbackMessage()` uses `lastDelta`.
- Daily progress uses `yesterdayScore` and `getProgressMessage()`.
- Session summary shown after 10 actions (`shouldShowSummary`, `resetSession`).
- Comparison text via `getComparisonText()` from percentile mapping.

## Screen Connections
- `main.dart` -> `OnboardingScreen` or `HomeScreen`.
- `HomeScreen` app bar -> `SavedScreen` and `ProfileScreen`.
- `HomeScreen` uses `ItemCard` for swipeable card UI.

## Important Global Rules
- Preserve current architecture and folder structure.
- Make targeted edits only; avoid unrelated refactors.
- Do not rewrite `DecisionEngine` unless explicitly requested.
- Do not add random dependencies.
- Keep feature loop connected: interaction -> learning -> score/progress -> feedback.

## Major Files (What They Do)
- `lib/controller/app_controller.dart`: central app state + action handling.
- `lib/core/engine/decision_engine.dart`: recommendation selection logic.
- `lib/services/persistence_service.dart`: persistent key/value storage.
- `lib/screens/home_screen.dart`: main swipe UI, transitions, action buttons, feedback, summary dialog.
- `lib/widgets/item_card.dart`: card image + tags UI with responsive layout.

## Latest Implemented Changes
- Card UX update:
  - outgoing card exits left, incoming card enters right, smooth 360ms switch, slight rotation/fade.
  - responsive card section with stable buttons and reduced overflow risk.
- Score/progress update:
  - scoring + feedback engine integrated in controller/home flow.
  - score displayed in home app bar.
  - daily progress + session summary after 10 actions.
  - persistence extended with `score` and `lastUpdatedDay`.
- Phase 9.5 Patch 1:
  - added daily streak fields and `updateStreak()` in `AppController`.
  - `updateStreak()` is called during `init()` startup.
  - added `getStreakDays()` getter.
  - this patch only adds runtime streak tracking logic (persistence wiring remains for next patch).
- Phase 9.5 Patch 2:
  - `PersistenceService` now persists `streakDays` and `lastOpenedDay`.
  - `HomeScreen._loadState()` restores streak values into controller.
  - `saveData` call sites updated in `home_screen.dart` and `onboarding_screen.dart`.
- Phase 9.5 Patch 3:
  - added compact status line above recommendations in `HomeScreen`.
  - status shows score, streak days, and progress trend.
- Phase 9.5 Patch 4:
  - session summary dialog now includes a calm return hook message.
  - message changes to "Don't lose your streak" when streak is 3+ days.
- Phase 9.5 Patch 5:
  - status section is visible at open before card browsing content.
  - recommendation card area remains below status for continuity-first flow.
  - startup load now persists refreshed streak day state immediately.
- Phase 10 Patch 1:
  - created `lib/ui/screens/stylist_screen.dart`.
  - added clean, responsive screen structure with:
    - app bar title "Improve My Style"
    - top insight text
    - "Curated for your style" section
    - placeholder recommendation list with save buttons
  - no AI/stylist logic added yet (UI scaffold only).
- Phase 10 Patch 2:
  - added `getStylistRecommendations()` in `AppController`.
  - recommendations reuse existing signals (`DecisionEngine.getTopVibe()`, preferred vibe, saved tags consistency).
  - returns a curated, non-random list limited to 4 items.
- Phase 10 Patch 3:
  - `StylistScreen` now renders real recommendation cards from controller.
  - each card shows image, tags, and a short insight line.
  - layout is scrollable, rounded, and spaced to avoid overflow.
- Phase 10 Patch 4:
  - added `getRecommendationReason(Item item)` in `AppController`.
  - reasons:
    - strongest vibe match
    - preferred fit consistency
    - style-range expansion
  - reason text is displayed in each stylist card.
- Phase 10 Patch 5:
  - stylist cards now support save action using existing saved-items architecture.
  - duplicate saves are blocked.
  - save confirmation message: "Saved to your style collection".
  - saved ids persist through existing `PersistenceService.saveData` flow.
- Phase 10 Patch 6:
  - added Home entry point button "Improve My Style".
  - navigation connected: `HomeScreen` -> `StylistScreen`.
  - existing navigation architecture remains unchanged.
- Phase 11 Patch 1:
  - created `lib/ui/screens/analyze_screen.dart` with clean, responsive structure.
  - sections: upload, analysis result, hairstyle recommendations, improvement tips.
  - placeholder state: "Upload a photo to begin analysis".
- Phase 11 Patch 2:
  - added `image_picker` dependency.
  - Analyze screen supports local gallery/camera image pick and image preview.
  - added compact loading state: "Analyzing style...".
- Phase 11 Patch 3:
  - added `analyzeStyle()` in `AppController` with stable mock analysis output:
    - vibe, fit, confidence, face shape.
  - output is derived from existing app signals (vibe, preferences, score/confidence trend).
- Phase 11 Patch 4:
  - Analyze screen now displays calm result cards with:
    - Detected Style
    - Confidence
    - Preferred Fit
    - Face Shape
- Phase 11 Patch 5:
  - added `getHairstyleSuggestions()` in controller.
  - suggestions are tied to analyzed vibe, face shape, and confidence band.
  - shown in "Recommended Hairstyles" section with short explanation text.
- Phase 11 Patch 6:
  - added `getImprovementTips()` in controller.
  - tips are practical and tied to vibe + score + confidence + analysis context.
  - shown in "Style Improvement Tips" section.
- Phase 11 Patch 7:
  - added `applyAnalysisToSystem(...)` in controller.
  - analysis subtly reinforces vibe/fit weights and blends into current memory.
  - persists updates without replacing existing learned behavior.
- Phase 11 Patch 8:
  - added Home entry point button "Analyze My Style".
  - navigation connected: `HomeScreen` -> `AnalyzeScreen` -> back.
  - architecture remains lightweight and stable.
- Phase 12 Patch 1:
  - created `lib/ui/screens/main_navigation_screen.dart` as the main navigation architecture shell.
  - added 5 tabs with premium bottom navigation container:
    - HOME (`HomeScreen`)
    - DISCOVER (placeholder)
    - STYLIST (placeholder)
    - WARDROBE (placeholder)
    - PROFILE (`ProfileScreen`)
  - bottom bar uses rounded container, subtle shadow, compact spacing, uppercase labels, and soft neutral colors.
  - updated app entry in `main.dart` to use `MainNavigationScreen` after onboarding.
  - updated onboarding completion route to open `MainNavigationScreen` so flow remains consistent.
- Phase 12 Patch 2:
  - upgraded `lib/ui/screens/stylist_screen.dart` into a real AI stylist output layer.
  - `StylistScreen` now supports standalone tab usage (`StylistScreen()`) and existing controller injection usage.
  - recommendations are curated from `DecisionEngine.getTopVibe()` + `Dataset` (non-random), shown as 3 horizontal premium cards.
  - each card includes image, title, vibe label, short reason, and score-impact text.
  - added compact "Style Insight" section below cards.
  - added empty-state safety when no vibe is available.
  - connected Stylist tab in `MainNavigationScreen` to `StylistScreen()` (replacing placeholder).
