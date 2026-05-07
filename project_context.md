# FITVIBE PROJECT CONTEXT

## 1. SYSTEM OVERVIEW

FitVibe is a behavior-based fashion recommendation system.

It does NOT use heavy AI.
It reacts to user actions (LIKE / SKIP) and adapts in real-time.

Goal:

- Detect user "vibe" and "fit" preference
- Improve recommendations over time
- Feel responsive and intelligent

---

## 2. ARCHITECTURE

Frontend:

- Flutter

Core System:

- DecisionEngine → selects next item
- AppController → manages flow and state

Data:

- Static dataset (100 items)
- Each item has tags:
  - vibe
  - fit
  - color
  - style
  - occasion

---

## 3. FOLDER STRUCTURE

lib/

core/

- models/
- engine/
- state/

controller/

- app_controller.dart

data/

- dataset.dart

screens/

- splash_screen.dart
- onboarding_screen.dart
- home_screen.dart

widgets/

- item_card.dart
- action_buttons.dart
- feedback_text.dart

simulation/

- simulation_test.dart

main.dart

---

## 4. COMPLETED FEATURES

✅ Decision Engine working  
✅ Dataset expanded (~100 items)  
✅ Simulation working (30 steps)  
✅ Basic UI (LIKE / SKIP)  
✅ Splash Screen  
✅ Onboarding Screen

---

## 5. CURRENT SYSTEM BEHAVIOR

- LIKE → mostly same vibe
- SKIP → mostly different vibe
- Some weak alignment exists (acceptable)
- System is functional but not perfect

IMPORTANT:
We are NOT fixing perfection now.

---

## 6. CURRENT TASK

Phase 5 — Product Experience Layer

Working on:

- UI cleanup using widgets
- Feedback message
- Insight / Why display
- Confidence messaging

---

## 7. RULES (CRITICAL)

- Do NOT change architecture
- Do NOT rewrite full files
- Modify only targeted parts
- Keep DecisionEngine stable
- UI must not contain logic
- Controller handles flow

---

## 8. NEXT PHASE

Phase 6:

- Save user pPROJECT: FitVibe

1. Overview

FitVibe is a swipe-based outfit recommendation app.
User likes/skips items → system learns vibe preference → improves recommendations.

---

2. Tech Stack

- Flutter (UI)
- Local Dataset (100 items)
- DecisionEngine (custom logic)
- SharedPreferences (persistence)

---

3. Core System

Controller:

AppController

- manages currentItem
- handles onAction (like/skip)
- tracks:
  - likeStreak
  - skipStreak
  - confidence
  - savedItems

Engine:

DecisionEngine

- selects next item
- uses:
  - vibeWeights
  - recentVibes
  - skipStreak / likeStreak / confidence
- prevents:
  - repeat items
  - vibe loops
  - weak alignment

---

4. Features Completed

Phase 1–3:

- Recommendation engine working
- Simulation test implemented
- Reaction validation added

Phase 4:

- Dataset expanded (100 items)

Phase 5–6:

- UI built (HomeScreen)
- Image loading working (png + jpg)
- Like / Skip buttons working
- Swipe gestures added

Phase 7:

- Onboarding (vibe selection)
- Persistence:
  - vibeWeights
  - confidence
  - streaks
  - selectedVibe
  - onboarding state

Phase 8:

- Saved styles implemented
- Profile screen implemented
- Learning priority fixed (uses learned vibe over onboarding)

---

5. Current Phase (IMPORTANT)

PHASE 9 — UX POLISH

Status:

- Feedback animation: NOT DONE
- Card transition: NOT DONE
- Swipe polish: PARTIAL
- Preloading next item: NOT DONE

---

6. Rules (CRITICAL)

- Do NOT change architecture
- Do NOT rename files
- Do NOT rewrite full files
- Only patch specific parts
- UI and logic must remain separated

---

7. Current Task

Continue Phase 9 UX improvements:

- Animated feedback
- Animated card transition
- Preloading next item
- Gesture smoothness

---

8. Known Issues

- UX feels stiff (no animation)
- Transitions are instant
- No preload → slight delay possible

---references
- Session memory
- Outfit saving
- History tracking
- Retention features
