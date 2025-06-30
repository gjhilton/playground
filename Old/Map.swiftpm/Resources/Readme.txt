# Project Recap and State – End of Day Summary

## Platform & Environment
- Target: **iPad Swift Playground**, running via `ContentView` using `UIViewControllerRepresentable`.
- UIKit is used instead of SwiftUI to support imperative UIKit-style interaction within a Playground-friendly wrapper.
- Playground file is currently **single-file** for development convenience — later modularization and separation are planned.

---

## Architecture Summary
- **MVC with clean separation of concerns**:
  - `Site`: Immutable data model (ID, name, position, progress).
  - `MapView`: Pure UI component, handles layout and user interaction. Renders sites based on unlock state, and uses delegation to communicate tap events.
  - `MapViewController`: Manages model, unlocking logic, and controls transitions to detail views.
  - `SiteViewController`: Full-screen modal, displays site name and large Lorem Ipsum content, with a back button.

---

## Implemented Features

### 1. Map Screen (`MapViewController`)
- Shows 5 site dots (`Site`), positioned via `CGPoint`.
- Only unlocked sites are tappable.
- Locked sites:
  - Appear gray.
  - Display a white `lock.fill` SF Symbol overlay.
- Unlocked sites:
  - Appear as blue circular buttons.
  - Are tappable to open a detail view.

### 2. Unlocking Logic
- Starts with only the **first site unlocked**.
- When a site is tapped:
  - The site view is presented modally (full screen).
  - Upon presentation, the **next site is unlocked**.
  - Unlock state is tracked in `MapViewController` via a `Set<Int>` of unlocked site IDs.
  - `MapView` is updated after each unlock with `updateUnlockedSites(_:)`.

### 3. Site View (`SiteViewController`)
- Background: black.
- Text color: white.
- Title label centered, displays site name.
- Scrollable content: ~3000 words of Lorem Ipsum using `UITextView`.
- Back button (top-left) dismisses the view.

---

## Constraints Maintained
- ✅ Single responsibility per class/view/controller.
- ✅ Immutability for model layer.
- ✅ Delegation used between view and controller for interaction.
- ✅ No use of `UINavigationController`.
- ✅ Code fully contained in one file, structured for later refactor.

---

## Planned Next Steps (Suggestions)

### 1. Modularization (post-MVP)
- Split models, views, and controllers into separate files.
- Create a `SiteUnlockManager` if logic becomes more complex.

### 2. UI/UX Enhancements
- Add visual feedback on site progress (e.g., ring or fill around dot).
- Animate the unlocking process (optional).
- Add site completion state based on progress.

### 3. State Persistence (optional)
- Use `UserDefaults` to persist unlocked site state across sessions (if Playground allows).

### 4. Testing/Debugging Support
- Add mock testable unlock logic.
- Consider test toggles in Playground UI for development flexibility.

---

## Keywords & Concepts to Retain
- UIKit-only, Swift Playground on iPad  
- Full-screen modal transitions  
- Map as site selector  
- Unlock-on-visit mechanic  
- Grey lock icons for locked sites  
- View delegation → controller ownership  
- Maintain separation of concerns at all costs
