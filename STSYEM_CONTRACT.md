SYSTEM CONTRACT — MUST FOLLOW

1. DecisionEngine is the ONLY place where:
   - scoring happens
   - selection happens
   - filtering happens

2. No other file is allowed to:
   - rank items
   - filter items
   - change selection logic

3. LearningEngine ONLY updates weights
   - no decision logic
   - no filtering

4. AppController ONLY:
   - receives user actions
   - calls LearningEngine
   - calls DecisionEngine
   - tracks recentItems and recentVibes

5. Dataset is STATIC
   - no dynamic generation
   - no random item creation

6. All randomness MUST exist only inside DecisionEngine

7. Do NOT:
   - rewrite files
   - rename functions
   - change architecture

8. All future patches must:
   - modify only specified sections
   - not introduce new systems unless explicitly instructed

This contract overrides all prompts.