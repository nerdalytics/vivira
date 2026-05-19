# Vivira iOS Tracer Bullet 2 — Appearance section

**Status:** Draft (awaiting review)
**Date:** 2026-05-18
**Scope:** Second end-to-end pass on the iOS app. Bullet 2 adds the theme picker as an inline section on a stub Connected root, wiring `ThemeStorage` (introduced in Bullet 1) end-to-end to user-driven theme switching. It also reconciles the inline-vs-discrete Settings conflict between UX flow §5.3 and design system §3.3 in favor of inline placement.

---

## How to use this doc

Read once front-to-back. §1 names the goal and the placement decision that drives every other section. §2 lays out the architecture being traced. §3 enumerates exactly what gets built. §4 sequences the work into two end-to-end passes. §5 lists the amendments to UX flow, design system, and Bullet 1's follow-up list — applied alongside Bullet 2's code. §6 defines done. §7 names what is deliberately left out and what to file as follow-ups.

This spec does not duplicate the design system or the UX flow. Where they specify visual treatment or behavior, this spec specifies the thinnest end-to-end implementation that exercises them.

---

## Decisions in one page

| Question | Answer |
|---|---|
| What slice does Bullet 2 cover | Inline Appearance section on a stub Connected root |
| Theme picker placement | Inline section on Connected root, between Servers and About. There is no discrete Settings hub. |
| Picker form | Compressed swatch row: 5 circles + caption naming the current theme; donut ring on selected |
| Forward state transition | "Add a server" CTA sets `appState.kind = .connected`. No wizard. |
| Backward state transition | `#if DEBUG` plain `Button` "Disconnect (debug)" in `ConnectedRoot` footer. Compiled out in release. |
| AppState persistence | None. Cold launch always resets to NotConnected. |
| ThemeStorage persistence | Unchanged from Bullet 1. Persists across launches and state transitions. |
| Snapshot test scope | Full 5 × 2 matrix for `ThemePicker`. Single Lumen-light smoke for `HeroStatusCard`. |
| Test scheme fix | Bullet 1 follow-up #10 promoted to in-scope. UIKit-gated snapshots run via `xcodebuild test`. |

---

## 1. Goal

The user can change the theme. Tapping a swatch in the Appearance section swaps the accent across every UI surface in the app, within one frame, with no apply button and no animation. The picker lives where UX flow §5.3 wants the Connected root's inline configuration sections to live: at the bottom of the one-scroll Connected root, beneath the still-stubbed subscription list, alongside the still-deferred Conditions, Servers, and About sections.

Bullet 2 also resolves the conflict between UX flow §5.3 and design system §3.3. The flow doc described a hybrid layout where Conditions, Servers, and About are inline sections on the Connected root. The design-system doc referred to Settings as a discrete destination ("Settings → Appearance only"). Bullet 2 settles this in favor of inline: there is no separate Settings hub. Appearance is an inline section, not a pushed screen. Design system §3.3 is rewritten accordingly. UX flow §5.3 gains the missing Appearance section.

What Bullet 2 does not do: build real onboarding, build the other §5.3 inline sections, build the real subscription list, build the Server detail or Subscription detail screens, or persist `AppState`. The stub Connected root is dressed for testing the picker, not for shipping to users. Real onboarding lands in a later bullet and replaces the stub closure on the empty-state CTA.

---

## 2. Architecture

### 2.1 Repo layout after Bullet 2 lands

```
vivira/
├── Packages/
│   └── ViviraDesignSystem/
│       ├── Sources/ViviraDesignSystem/
│       │   ├── Atoms/
│       │   │   ├── ViviraButton.swift            // unchanged (single .accent style)
│       │   │   ├── Icon.swift                    // unchanged
│       │   │   └── ThemeSwatch.swift             // NEW: 28pt circle, donut ring when selected
│       │   ├── Molecules/
│       │   │   ├── EmptyState.swift              // unchanged
│       │   │   ├── ThemePicker.swift             // NEW: swatch row + current-name caption
│       │   │   └── HeroStatusCard.swift          // NEW: idle-state initializer only
│       │   └── ...
│       └── Tests/ViviraDesignSystemTests/
│           ├── ThemeStorageTests.swift           // unchanged
│           ├── EmptyStateSnapshotTests.swift     // unchanged; now actually runs
│           ├── ThemePickerSnapshotTests.swift    // NEW (5 themes × 2 modes = 10 snapshots)
│           └── HeroStatusCardSnapshotTests.swift // NEW (1 Lumen-light smoke)
├── Vivira/
│   ├── ViviraApp.swift                           // adds @StateObject AppState
│   ├── ContentView.swift                         // switches on AppState.kind
│   ├── ConnectedRoot.swift                       // NEW: hero + placeholder + Appearance section
│   └── AppState.swift                            // NEW: .notConnected | .connected
├── ViviraTests/
│   └── AppStateTests.swift                       // NEW: transition round-trip
└── project.yml                                   // adds ViviraDesignSystemTests to app test scheme
```

### 2.2 Module boundary

Unchanged from Bullet 1. `Vivira` imports `ViviraDesignSystem`. The design-system package owns tokens, atoms, molecules, the asset catalog, and theme storage. The app target owns the scene, the navigation root, app-specific state holders (`AppState`), and screen compositions (`ConnectedRoot`). Bullet 2 adds one atom and two molecules to the package, plus one state holder and one screen view in the app target.

### 2.3 Theme propagation

Theme flow established in Bullet 1, exercised end-to-end in Bullet 2:

```
tap swatch
  → ThemePicker writes selection.wrappedValue = newTheme
  → themeStorage.current setter (@Published) fires
  → UserDefaults round-trip (synchronous; established in Bullet 1)
  → @StateObject notifies SwiftUI
  → ViviraApp.body re-evaluates → .environment(\.viviraTheme, …) updates
  → every AccentColor.resolve(in:) consumer re-renders
```

One frame round-trip. No animation. No apply button. The visible app is the preview, so per-card sample buttons and badges are not needed.

### 2.4 AppState propagation

`AppState` is a `@MainActor public final class AppState: ObservableObject` with `@Published var kind: Kind` where `Kind` is `.notConnected | .connected`. Process-local; not persisted. `ContentView` reads `appState.kind` and switches the visible composition. Mutations come from two places:

- The empty-state CTA action handler in `ContentView`: `appState.kind = .connected`.
- The `#if DEBUG` Disconnect link in `ConnectedRoot`: `appState.kind = .notConnected`.

The forward closure is the integration seam that real onboarding will replace in a later bullet.

---

## 3. Components

### 3.1 Tokens

No new tokens. Every color and font used by the new components already exists in design system §2.1.1 (neutrals), §2.1.2 (per-theme accents), and §2.2 (type). The picker is composition over existing tokens.

### 3.2 Atoms

**`ThemeSwatch(theme:, isSelected:)`.** 28pt circle filled with `accent.<theme>.<colorScheme>`. When `isSelected`, the swatch draws a 2pt `color.ink` ring with a 2pt `color.surface` gap between fill and ring. The gap reads at a glance regardless of accent hue. Hit area is 44pt minimum when used in `ThemePicker` (the picker wraps each swatch in a `Button`; the swatch itself is purely visual). No state, no gestures, no haptics — those live in the picker.

### 3.3 Molecules

**`ThemePicker(selection: Binding<Theme>)`.** Knows `Theme.allCases` internally; no parameter for the theme list. `HStack` of 5 `ThemeSwatch` distributed `.spacedEvenly`, followed by `font.caption` in `color.muted` naming the current selection. On tap: writes the binding (which flows back through `ThemeStorage`) and fires `UIImpactFeedbackGenerator(.light)`, gated on `@Environment(\.accessibilityReduceMotion)`.

**`HeroStatusCard.idle(summary:, hint:)`.** Single initializer at Bullet 2 fidelity. The card surface uses `color.surface` with a 1pt `color.line` border per `elevation.flat`. Summary text is `font.headline` in `color.ink`; hint is `font.caption` in `color.muted`. Active and degraded states (transfer lines, degraded banner) are deferred to later bullets when real transfer state exists to render.

### 3.4 App-target view

**`ConnectedRoot.swift`.** Reads `@EnvironmentObject private var themeStorage: ThemeStorage` and `@EnvironmentObject private var appState: AppState` (both injected at the scene root in `ViviraApp`). Composes the stub Connected root:

1. `HeroStatusCard.idle("✓ Connected · 0 subscriptions", "Add an album to start syncing")`.
2. Dashed placeholder block (`color.surface` with 1pt dashed `color.line` border) labeled "subscription list — Bullet 3". A development-only stand-in for the not-yet-built list.
3. The Appearance section as an inline `private` view: a card surface containing `SectionLabel("Appearance")` followed by `ThemePicker(selection: $themeStorage.current)`. The binding flows back through `ThemeStorage` so each tap writes UserDefaults and refreshes `\.viviraTheme` in the environment.
4. `#if DEBUG` footer: plain SwiftUI `Button { appState.kind = .notConnected }` labeled "Disconnect (debug)", styled `font.caption` in `color.faint`. Compiled out in release.

The Appearance section stays inline-private. It is used in one place; promote it to a reusable molecule when a second consumer appears.

### 3.5 State holder

**`AppState.swift`.**

```swift
@MainActor
public final class AppState: ObservableObject {
    public enum Kind: Equatable, Sendable {
        case notConnected
        case connected
    }

    @Published public var kind: Kind = .notConnected

    public init() {}
}
```

No persistence. No side effects. Two valid values. `Equatable` for unit testing the transitions; `Sendable` for future `Task`-based mutation if needed.

### 3.6 App-target wiring

**`ContentView.swift`.** Switches on `appState.kind`:

```swift
struct ContentView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        switch appState.kind {
        case .notConnected:
            EmptyState(
                symbol: "photo.on.rectangle.angled",
                message: "No servers connected yet.",
                ctaLabel: "Add a server",
                action: { appState.kind = .connected }
            )
        case .connected:
            ConnectedRoot()
        }
    }
}
```

**`ViviraApp.swift`.** Adds the second `@StateObject`. Same shape as Bullet 1:

```swift
@main struct ViviraApp: App {
    @StateObject private var themeStorage = ThemeStorage()
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(themeStorage)
                .environmentObject(appState)
                .environment(\.viviraTheme, themeStorage.current)
        }
    }
}
```

### 3.7 Tests

**`ThemePickerSnapshotTests.swift`** *(new)*. Uses `swift-snapshot-testing` (added in Bullet 1). Renders the picker in a fixed-size container that mirrors the iPhone 17 portrait safe area, once per theme as the selected value, in both color schemes. Ten reference images committed under `Tests/ViviraDesignSystemTests/__Snapshots__/`.

**`HeroStatusCardSnapshotTests.swift`** *(new)*. One snapshot: idle state, Lumen light. Smoke only. The full 5 × 2 matrix lands when active and degraded states ship.

**`AppStateTests.swift`** *(new, in `ViviraTests/`)*. Two unit tests using Swift Testing. `notConnected → connected` via direct mutation; `connected → notConnected` via direct mutation. Pure unit; no SwiftUI.

**`ThemeStorageTests.swift`** *(unchanged)*. Bullet 1's round-trip suite passes against the same `ThemeStorage` it tested then.

**`EmptyStateSnapshotTests.swift`** *(unchanged)*. The two snapshots from Bullet 1 (Lumen light, Lumen dark) now actually run because the test scheme fix in §3.8 lands in Bullet 2.

### 3.8 Project plumbing

**`project.yml`.** Add `ViviraDesignSystemTests` to the Vivira app's test scheme so `xcodebuild test` runs the package's snapshot tests against the iOS simulator. This closes Bullet 1 follow-up #10. The hand-authored colors-source pipeline, the `xcodegen` invocation, and the SPM package reference remain unchanged.

---

## 4. Vertical slice sequencing

Two passes. Each pass is end-to-end and produces working software at its tail.

### Pass 1 — Thin column

Goal: tapping "Add a server" lands on a stub Connected root that shows the swatch row. Tapping a swatch switches the theme. No tests yet.

1. Add `AppState.swift` in the app target. Wire `@StateObject` in `ViviraApp` and `EnvironmentObject` consumption in `ContentView`. Change `ContentView` to switch on `appState.kind`.
2. Replace the empty-state CTA action with `appState.kind = .connected`.
3. Add `Atoms/ThemeSwatch.swift` in `ViviraDesignSystem`. Renders fill plus donut ring.
4. Add `Molecules/ThemePicker.swift` in `ViviraDesignSystem`. `Binding<Theme>` parameter, `HStack` of 5 `ThemeSwatch` buttons, caption beneath.
5. Add `Molecules/HeroStatusCard.swift` in `ViviraDesignSystem` with the `.idle` initializer only.
6. Add `ConnectedRoot.swift` in the app target. Compose `HeroStatusCard.idle` + dashed placeholder + Appearance section + `#if DEBUG` Disconnect link.
7. Build and run. Tap "Add a server" → ConnectedRoot. Tap each swatch → theme changes. Tap "Disconnect (debug)" → back to EmptyState. Cold relaunch starts on EmptyState with the persisted theme.

End of Pass 1: visible bullet, all 5 themes selectable, two states reachable, no tests.

### Pass 2 — Thicken

8. Edit `project.yml`: add `ViviraDesignSystemTests` to the Vivira app's test scheme. Run `mise run generate`.
9. Run `mise run test`. Confirm Bullet 1's `EmptyStateSnapshotTests` and `ThemeStorageTests` pass against the simulator now that the scheme is wired.
10. Add `ThemePickerSnapshotTests.swift`. Run the suite to capture 10 reference images (5 themes × 2 modes). Inspect each PNG; commit.
11. Add `HeroStatusCardSnapshotTests.swift`. Capture 1 Lumen-light reference image; commit.
12. Add `AppStateTests.swift` in `ViviraTests/`. Two transition tests.
13. Run `mise run test` and `mise run lint`. Both pass.
14. Apply spec amendments A–H to the UX flow doc, the design-system doc, and Bullet 1's follow-up list. Commit alongside the code.

End of Pass 2: Bullet 2 meets every acceptance criterion in §6.

---

## 5. Spec amendments

Applied to existing docs as part of Bullet 2's commit. Listed here so this design is the single source of truth for what changed and why.

### A. UX flow §3 — account model field rename

Rename the existing field:

- Before: `chargingOnly: Bool                [default: false]`
- After: `lowPowerDefer: Bool               [default: true; pauses when ProcessInfo.isLowPowerModeEnabled is true]`

Rationale: defer-on-low-power is more conservative and more honest than "only while charging". Most users want sync to back off when iOS is in user-chosen Low Power Mode, regardless of plug-in status. "Only while charging" was too restrictive a precondition.

### B. UX flow §5.3 — Conditions toggle label + new Appearance section

In the Conditions section (currently `Wi-Fi only` and `Only while charging`), rename the second toggle:

- Before: `Only while charging`
- After: `Pause while Low Power Mode`

Insert a new section between Servers and About:

> **Appearance**
> A row of 5 swatches, one per theme, in the current colorScheme. The selected theme has a 2pt `color.ink` ring with a 2pt `color.surface` gap (donut style). Tap to switch instantly; no apply button. Caption beneath the row names the current theme.

### C. Design system — Decisions in one page

The theme-picker row in the decisions table:

- Before: `Settings → Appearance only (not in onboarding)`
- After: `Inline section on Connected root (not in onboarding)`

### D. Design system §3.3 — Picker placement (full rewrite)

Replace the existing §3.3 entirely with:

> The theme picker is an inline section on the Connected root (UX flow §5.3), positioned between Servers and About. Onboarding does not include theme selection; the user gets Lumen on first run and changes later.
>
> The section consists of a `SectionLabel("Appearance")` followed by a single row of 5 `ThemeSwatch` circles (one per theme, rendered with `accent.<theme>.<currentMode>`), with a `font.caption` caption beneath naming the currently-selected theme. The selected swatch carries a donut-ring treatment: 2pt `color.ink` outer ring with a 2pt `color.surface` gap between fill and ring. Tap to switch; the change is immediate, no apply button. The per-palette preview cards used during design (palette swatches plus sample button plus badges) remain as the Penpot reference and do not ship as UI.

### E. Design system §6.1 ServerRow note

Drop the "and under Settings" trailing clause:

- Before: `Appears on Connected root §5.3 (Servers section) and under Settings.`
- After: `Appears on Connected root §5.3 (Servers section). No discrete Settings hub — see §3.3.`

### F. Design system §5 atoms — add §5.24

Insert a new atom entry:

> ### 5.24 ThemeSwatch
>
> `ThemeSwatch(theme:, isSelected:)`. 28pt circle filled with `accent.<theme>.<colorScheme>`. When `isSelected`, draws a 2pt `color.ink` ring with a 2pt `color.surface` gap between fill and ring. Hit area is 44pt minimum when used in `ThemePicker` (the picker wraps each swatch in a `Button`; the swatch itself is purely visual). No state, no gestures, no haptics — those live in the picker.

### G. Design system §6.5 Composed molecules — add ThemePicker

Insert a new molecule entry:

> **ThemePicker** — `HStack` of 5 `ThemeSwatch` atoms distributed `.spacedEvenly`, followed by `font.caption` in `color.muted` naming the current selection. Takes a `Binding<Theme>`; tapping a swatch writes the binding. Light haptic on selection, gated on `@Environment(\.accessibilityReduceMotion)`. Lives in the Appearance section on Connected root (UX flow §5.3). The visible app is the preview — no per-card sample buttons or badges.

### H. Bullet 1 follow-ups — supersede two entries

- §6.2 follow-up #5 ("Build the Settings → Appearance theme picker. Wires ThemeStorage to the user.") — closed by Bullet 2.
- §6.2 follow-up #10 (UIKit-gated snapshot tests) — closed by Bullet 2's `project.yml` edit.

---

## 6. Acceptance criteria

The bullet is done when all of these hold:

- `mise run build` succeeds with no new warnings versus baseline.
- `mise run test` passes, including:
  - Existing Bullet 1 suites (`ThemeStorageTests`, `EmptyStateSnapshotTests`).
  - New `ThemePickerSnapshotTests` (10 snapshots: each theme as the selected value, in light and dark).
  - New `HeroStatusCardSnapshotTests` (1 Lumen-light smoke).
  - New `AppStateTests` (transition round-trip).
- `mise run lint` passes.
- Snapshot tests run via `xcodebuild test` against the iOS simulator, not silently compiled-out on the macOS host. `EmptyStateSnapshotTests` now actually executes and passes.
- App boots on the iPhone 17 simulator declared in `mise.toml`. Lands on `EmptyState` with the current theme's accent on the "Add a server" button.
- Tapping "Add a server" reveals `ConnectedRoot` with hero, placeholder, and Appearance section.
- Tapping each non-current swatch updates the accent across the visible UI; the donut ring moves to the tapped swatch; the caption renames to the new theme. Haptic fires on tap when reduce-motion is off (manual feel-test).
- Tapping "Disconnect (debug)" returns to EmptyState. The chosen theme's accent is on the button, proving storage persisted through the state transition.
- Cold relaunch lands on EmptyState (`AppState` reset) with the last-chosen theme persisted in `ThemeStorage`.
- Spec amendments A–H are applied to the UX flow doc, the design-system doc, and Bullet 1's follow-up list.
- Clean clone succeeds with `mise run bootstrap && mise run build && mise run test`. No further manual steps.

---

## 7. Out of scope

### 7.1 Not in Bullet 2

These were considered and deliberately left out to keep the bullet at end-to-end thinness.

- Real onboarding wizard. The empty-state CTA bypasses it with a stub transition. Wizard work is the next major bullet.
- The other §5.3 inline sections: Conditions (with `lowPowerDefer` toggle), Servers (with `ServerRow` molecule), About. A placeholder block stands in for the subscription list. Appearance is the only inline section Bullet 2 builds.
- Server detail screen, Subscription detail screen, Album view, Sync Sheet, and every molecule used in them.
- Additional `ViviraButton` styles (`.secondary`, `.primary`, `.ghost`, `.destructive`). The debug Disconnect link uses a plain SwiftUI `Button` so the role enum does not have to ship before a real use case calls for it.
- Sync logic, the Immich client, PhotoKit, `BGTask`, `ActivityKit`, Live Activity.
- Persistence of `AppState`. Cold launches always reset to NotConnected. Persisting the state would require a session model, which onboarding builds.
- Localization of the "Appearance" SectionLabel string and the theme display names with `Bundle.module`. Bullet 1 follow-up #9 still pending and lands with the first `.xcstrings` file in the design-system package.
- The full 5 × 2 EmptyState snapshot matrix. Bullet 1 follow-up #4 still pending; Bullet 2 only verifies the existing two snapshots run.
- High-contrast colorset variants for the 19 existing colorsets. Bullet 1 follow-up #3 still pending.
- Soft-mixed semantic colors (`destructiveSoft`, `warnSoft`, `successSoft`, `accentSoft`) and the molecules that consume them.
- Theme transition animation. Design system §13's rule that theme changes are instant remains: cross-fading 49 colorsets is expensive for a settings change.
- HeroStatusCard active and degraded states. Only the idle initializer ships.
- The Penpot-side per-palette preview cards. They stay as design reference; they do not ship as UI.

### 7.2 Follow-ups to file when Bullet 2 lands

1. Build real onboarding (`ServerMini` flow, capability probe, etc.). Replaces the stub closure on the empty-state CTA. Touches design system (`WizardStepHeader`, `ViviraTextField`, `CapabilityChip`, `SegmentedPicker`, `InfoCard`) and the app's state model.
2. Build the remaining §5.3 inline sections: Conditions (with `lowPowerDefer` toggle wired to `ProcessInfo.isLowPowerModeEnabled`), Servers (with `ServerRow` molecule), About.
3. Build HeroStatusCard active and degraded states when first real transfer state exists.
4. Persist `AppState` when the session model lands as part of real onboarding.
5. Resume Bullet 1 follow-up #4: full 5 × 2 EmptyState snapshot matrix. Easier to add now that the test scheme is wired.
6. Resume Bullet 1 follow-up #3: high-contrast colorset variants for the 19 existing colorsets.
7. Add the `ViviraButton` role enum when the second style ships. The wizard's "Back" button or the disconnect flow's secondary action are likely candidates. Bullet 1 follow-up #2.
8. Localize "Appearance" SectionLabel string and theme display names properly. Address Bullet 1 follow-up #9 in the same commit that adds the first `.xcstrings` file to `ViviraDesignSystem`.
9. Decide the long-term fate of the per-palette preview cards in Penpot: keep as design-only reference, or retire once the swatch row is shipped and reviewed.

---

## 8. References

### Project

- [Vivira UX flow design](2026-05-16-vivira-ux-flow-design.md) — §5.3 inline sections; §3 account model (where `lowPowerDefer` lands).
- [Vivira design system](2026-05-17-vivira-design-system-design.md) — §2.1.1 neutrals, §2.1.2 accents, §2.2 type, §3 theme system (rewritten in this doc §5.D), §5.21 SectionLabel, §6.2 HeroStatusCard, §13 "theme changes are instant".
- [Vivira UX paradigms](2026-05-17-vivira-ux-paradigms.md) — informs the principle that the visible app is the preview.
- [Vivira iOS Tracer Bullet 1](2026-05-17-vivira-tracer-bullet-design.md) — establishes `ThemeStorage`, the design-system package, and the snapshot-test infrastructure. Bullet 2 supersedes follow-ups #5 and #10.

### Apple

- [`ProcessInfo.isLowPowerModeEnabled`](https://developer.apple.com/documentation/foundation/processinfo/1617047-islowpowermodeenabled) — source of truth for the `lowPowerDefer` semantics. Wires into the Conditions section in a later bullet.
- [`UIImpactFeedbackGenerator`](https://developer.apple.com/documentation/uikit/uiimpactfeedbackgenerator) — `.light` style for swatch tap feedback. Gated on `accessibilityReduceMotion`.
- [SwiftUI `Binding`](https://developer.apple.com/documentation/swiftui/binding) — the protocol `ThemePicker(selection:)` accepts.
- [`@MainActor` and `ObservableObject`](https://developer.apple.com/documentation/swiftui/managing-model-data-in-your-app) — used by `AppState`.

### Tooling

- [`pointfreeco/swift-snapshot-testing`](https://github.com/pointfreeco/swift-snapshot-testing) — snapshot test infrastructure inherited from Bullet 1.
- [xcodegen](https://github.com/yonaskolb/XcodeGen) — `project.yml` source of truth for the Xcode project; gains the `ViviraDesignSystemTests` test scheme entry.
