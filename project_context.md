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

- Save user preferences
- Session memory
- Outfit saving
- History tracking
- Retention features
