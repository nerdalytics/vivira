# Vivira iOS Tracer Bullet 2 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Land the inline Appearance section on a stub Connected root, wiring `ThemeStorage` (built in Bullet 1) end-to-end to user-driven theme switching. Resolve the inline-vs-discrete Settings conflict between UX flow §5.3 and design system §3.3 in favor of inline placement.

**Architecture:** Vertical slice in two passes. Pass 1 (Tasks 1–7) lands the thinnest end-to-end column: AppState, the picker components, the stub Connected root, and a `#if DEBUG` reverse transition. Pass 2 (Tasks 8–12) thickens by wiring the test scheme, adding snapshot suites for the new molecules, and applying the spec amendments that follow from the inline-Settings decision.

**Tech Stack:** Swift 6 + SwiftUI on iOS 26.5. Local SPM package `ViviraDesignSystem` (built in Bullet 1) gains one atom and two molecules. Pointfree `swift-snapshot-testing` ≥ 1.17.0 for visual regression (added in Bullet 1). UIKit `UIImpactFeedbackGenerator` for tap haptics, gated on `#if canImport(UIKit)`.

**Spec:** [`docs/superpowers/specs/2026-05-18-vivira-tracer-bullet-2-design.md`](../specs/2026-05-18-vivira-tracer-bullet-2-design.md)

---

## File map

**Created in Pass 1 (Tasks 1–7):**

| File | Responsibility |
|---|---|
| `Vivira/AppState.swift` | `@MainActor public final class AppState: ObservableObject` with `.notConnected | .connected` kind. Process-local, not persisted. |
| `ViviraTests/AppStateTests.swift` | Swift Testing suite. Two transition round-trips against the public mutator. |
| `Packages/ViviraDesignSystem/Sources/ViviraDesignSystem/Atoms/ThemeSwatch.swift` | 28pt circle filled with `accent.<theme>.<currentMode>`. Donut ring when selected. Purely visual. |
| `Packages/ViviraDesignSystem/Sources/ViviraDesignSystem/Molecules/ThemePicker.swift` | `HStack` of 5 `ThemeSwatch` distributed `.spacedEvenly` + current-theme caption. `Binding<Theme>`. Haptic gated on `#if canImport(UIKit)` and `accessibilityReduceMotion`. |
| `Packages/ViviraDesignSystem/Sources/ViviraDesignSystem/Molecules/HeroStatusCard.swift` | Idle initializer only. `font.headline` summary + `font.caption` hint on `color.surface` card with 1pt `color.line` border. |
| `Vivira/ConnectedRoot.swift` | Composes `HeroStatusCard.idle` + dashed placeholder + inline Appearance section + `#if DEBUG` Disconnect link. Reads `themeStorage` and `appState` from environment. |

**Modified in Pass 1:**

| File | Change |
|---|---|
| `Packages/ViviraDesignSystem/Sources/ViviraDesignSystem/Tokens/Typography.swift` | Add `font.caption` (Subheadline 400) and `font.monoLabel` (SF Mono 500). |
| `Vivira/ViviraApp.swift` | Add `@StateObject private var appState = AppState()` and pass via `.environmentObject(appState)`. |
| `Vivira/ContentView.swift` | Switch on `appState.kind`. Empty-state CTA closure becomes `appState.kind = .connected`. |

**Created in Pass 2 (Tasks 8–12):**

| File | Responsibility |
|---|---|
| `Packages/ViviraDesignSystem/Tests/ViviraDesignSystemTests/ThemePickerSnapshotTests.swift` | 10 snapshots: each of 5 themes selected, in light + dark. |
| `Packages/ViviraDesignSystem/Tests/ViviraDesignSystemTests/HeroStatusCardSnapshotTests.swift` | 1 snapshot: idle state, Lumen light. |
| `Packages/ViviraDesignSystem/Tests/ViviraDesignSystemTests/__Snapshots__/ThemePickerSnapshotTests/*.png` | 10 reference images, committed. |
| `Packages/ViviraDesignSystem/Tests/ViviraDesignSystemTests/__Snapshots__/HeroStatusCardSnapshotTests/*.png` | 1 reference image, committed. |
| `Packages/ViviraDesignSystem/Tests/ViviraDesignSystemTests/__Snapshots__/EmptyStateSnapshotTests/*.png` | 2 reference images (Lumen light + dark), committed at first test run. |

**Modified in Pass 2:**

| File | Change |
|---|---|
| `project.yml` | Add `schemes:` block declaring `ViviraDesignSystemTests` as a test target of the `Vivira` scheme so the package's snapshot suite runs on the iOS simulator. |
| `mise.toml` | Drop the standalone `swift test --package-path` invocation in `[tasks.test]`; `xcodebuild test` now exercises the package tests via the scheme. |
| `docs/superpowers/specs/2026-05-16-vivira-ux-flow-design.md` | Spec amendments A (§3 field rename) and B (§5.3 toggle rename + new Appearance section). |
| `docs/superpowers/specs/2026-05-17-vivira-design-system-design.md` | Spec amendments C (decisions table), D (§3.3 rewrite), E (§6.1 ServerRow note), F (new §5.24 ThemeSwatch), G (§6.5 ThemePicker). |
| `docs/superpowers/specs/2026-05-17-vivira-tracer-bullet-design.md` | Spec amendment H (close §6.2 follow-ups #5 and #10). |

---

## Phase 1 — Pass 1: Thin column

Goal at the end of Pass 1: tapping "Add a server" on the empty state lands on a stub Connected root that shows the swatch row. Tapping a swatch switches the theme across every visible accent surface in the app. Tapping "Disconnect (debug)" returns to the empty state with the chosen theme persisted. No snapshot tests yet; manual simulator verification only.

### Task 1: Add `font.caption` and `font.monoLabel` typography tokens

**Files:**
- Modify: `Packages/ViviraDesignSystem/Sources/ViviraDesignSystem/Tokens/Typography.swift`

The new components in this bullet need two type tokens that already exist in design system §2.2 but were never implemented in code (Bullet 1 only added `displayLarge`, `body`, `bodyBold`, `headline` because the empty state did not need anything else). Add them now so subsequent tasks compile.

- [ ] **Step 1: Open the file and confirm current contents**

```bash
cat Packages/ViviraDesignSystem/Sources/ViviraDesignSystem/Tokens/Typography.swift
```

Expected (current state):

```swift
import SwiftUI

public extension Font {
    enum vivira {
        public static let displayLarge: Font = .system(.largeTitle, design: .default, weight: .bold)
        public static let body:         Font = .system(.body,       design: .default, weight: .regular)
        public static let bodyBold:     Font = .system(.body,       design: .default, weight: .semibold)
        public static let headline:     Font = .system(.headline,   design: .default)
    }
}
```

- [ ] **Step 2: Replace the file with the expanded set**

File: `Packages/ViviraDesignSystem/Sources/ViviraDesignSystem/Tokens/Typography.swift`

```swift
import SwiftUI

public extension Font {
    enum vivira {
        public static let displayLarge: Font = .system(.largeTitle, design: .default, weight: .bold)
        public static let headline:     Font = .system(.headline,   design: .default)
        public static let body:         Font = .system(.body,       design: .default, weight: .regular)
        public static let bodyBold:     Font = .system(.body,       design: .default, weight: .semibold)
        public static let caption:      Font = .system(.subheadline, design: .default, weight: .regular)
        public static let monoLabel:    Font = .system(size: 10, weight: .medium, design: .monospaced)
    }
}
```

Token mapping back to design system §2.2:

- `caption` → Subheadline, 400 weight, 13/18 — for captions, server hostnames, secondary meta.
- `monoLabel` → SF Mono, 500 weight, size 10. Per §2.2 it carries `+14% tracking` and uppercases — those are applied per-use via `.tracking(1.4)` and `.textCase(.uppercase)` rather than baked into the token, so a future numerical-label use that isn't uppercase still works.

- [ ] **Step 3: Build to confirm both new tokens compile**

Run: `mise run build`
Expected: build succeeds, no new warnings vs baseline.

- [ ] **Step 4: Commit**

```bash
git add Packages/ViviraDesignSystem/Sources/ViviraDesignSystem/Tokens/Typography.swift
git commit -m "feat(ds): add font.caption and font.monoLabel tokens"
```

---

### Task 2: `AppState` state holder with TDD

**Files:**
- Create: `Vivira/AppState.swift`
- Create: `ViviraTests/AppStateTests.swift`

A trivial process-local state holder. Two values, `.notConnected | .connected`, no persistence. Test the public mutator round-trips by direct mutation. Pure unit, no SwiftUI.

- [ ] **Step 1: Write the failing test file**

File: `ViviraTests/AppStateTests.swift`

```swift
// AppState transition tests.
import Testing
@testable import Vivira

@MainActor
@Suite struct AppStateTests {

    @Test func defaultsToNotConnected() {
        let state = AppState()
        #expect(state.kind == .notConnected)
    }

    @Test func transitionsForwardToConnected() {
        let state = AppState()
        state.kind = .connected
        #expect(state.kind == .connected)
    }

    @Test func transitionsBackwardToNotConnected() {
        let state = AppState()
        state.kind = .connected
        state.kind = .notConnected
        #expect(state.kind == .notConnected)
    }
}
```

- [ ] **Step 2: Run the tests to confirm they fail**

Run: `mise run test`
Expected: compilation fails — `AppState` is not defined in the `Vivira` module.

- [ ] **Step 3: Implement `AppState`**

File: `Vivira/AppState.swift`

```swift
import Foundation
import SwiftUI

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

`Equatable` is required by `#expect(state.kind == .notConnected)` so the test compiles. `Sendable` lets the enum cross actor boundaries in case a future `Task` mutates it. `@MainActor` ensures the `@Published` write happens on the main run loop where SwiftUI observes it.

- [ ] **Step 4: Re-run the tests to confirm they pass**

Run: `mise run test`
Expected: `AppStateTests` reports 3 passing tests. Bullet 1's suites (`ThemeStorageTests`, `ViviraTests.smoke`) also continue to pass.

- [ ] **Step 5: Commit**

```bash
git add Vivira/AppState.swift ViviraTests/AppStateTests.swift
git commit -m "feat: AppState state holder with transition tests"
```

---

### Task 3: Wire `AppState` into `ViviraApp` and `ContentView`

**Files:**
- Modify: `Vivira/ViviraApp.swift`
- Modify: `Vivira/ContentView.swift`

Inject `AppState` at the scene root. Change `ContentView` to switch on `appState.kind`. Keep the `.connected` branch as a temporary `Text` placeholder until `ConnectedRoot` lands in Task 7. The empty-state CTA action becomes `appState.kind = .connected`. The existing empty-state message stays as-is; only the action closure changes.

- [ ] **Step 1: Update `ViviraApp.swift` to install the second `@StateObject`**

File: `Vivira/ViviraApp.swift`

```swift
import SwiftUI
import ViviraDesignSystem

@main
struct ViviraApp: App {
    @StateObject private var themeStorage = ThemeStorage()
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.viviraTheme, themeStorage.current)
                .environmentObject(themeStorage)
                .environmentObject(appState)
        }
    }
}
```

- [ ] **Step 2: Rewrite `ContentView.swift` to switch on `appState.kind` with a placeholder for `.connected`**

File: `Vivira/ContentView.swift`

```swift
import SwiftUI
import ViviraDesignSystem

struct ContentView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        NavigationStack {
            switch appState.kind {
            case .notConnected:
                EmptyState(
                    symbol: "photo.on.rectangle.angled",
                    message: "Vivira keeps Immich shared albums\nin sync with your iPhone.",
                    ctaLabel: "Add a server",
                    action: { appState.kind = .connected }
                )
                .background(Color.vivira.bg.ignoresSafeArea())
            case .connected:
                Text("Connected — ConnectedRoot lands in Task 7")
                    .font(.vivira.body)
                    .foregroundStyle(Color.vivira.ink2)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.vivira.bg.ignoresSafeArea())
            }
        }
    }
}

#Preview {
    ContentView()
        .environment(\.viviraTheme, .lumen)
        .environmentObject(ThemeStorage())
        .environmentObject(AppState())
}
```

The placeholder line is intentionally ugly — it makes the wrong-state easy to spot before Task 7 replaces it. The `#Preview` block needs all three environment injections because the new switch reads `appState.kind`.

- [ ] **Step 3: Build to confirm the wiring compiles**

Run: `mise run build`
Expected: build succeeds.

- [ ] **Step 4: Manual simulator verification**

Run: `mise run open` then build-and-run from Xcode (`⌘R`) on the iPhone 17 simulator.
Expected:
- App opens on the empty state (current theme's accent on "Add a server").
- Tap "Add a server" → screen replaces with the `Text("Connected — ConnectedRoot lands in Task 7")` placeholder.
- Force-quit the app from the simulator, relaunch → back on the empty state (AppState resets, ThemeStorage persists).

- [ ] **Step 5: Commit**

```bash
git add Vivira/ViviraApp.swift Vivira/ContentView.swift
git commit -m "feat: wire AppState into scene; ContentView switches on kind"
```

---

### Task 4: `ThemeSwatch` atom

**Files:**
- Create: `Packages/ViviraDesignSystem/Sources/ViviraDesignSystem/Atoms/ThemeSwatch.swift`

Single atom: 28pt circle filled with the theme's accent in the current color scheme. When `isSelected`, draws a 2pt `color.ink` ring with a 2pt `color.surface` gap (donut style). Purely visual — no state, no gestures, no haptics. Tap handling lives in `ThemePicker`.

- [ ] **Step 1: Write `ThemeSwatch.swift`**

File: `Packages/ViviraDesignSystem/Sources/ViviraDesignSystem/Atoms/ThemeSwatch.swift`

```swift
// Single 28pt theme-color circle with donut-style selection ring.
// Purely visual; the picker wraps it in a Button for tap handling.
import SwiftUI

public struct ThemeSwatch: View {
    public static let diameter: CGFloat = 28
    public static let ringWidth: CGFloat = 2
    public static let ringGap: CGFloat = 2

    private let theme: Theme
    private let isSelected: Bool

    @Environment(\.colorScheme) private var colorScheme

    public init(theme: Theme, isSelected: Bool) {
        self.theme = theme
        self.isSelected = isSelected
    }

    public var body: some View {
        let fill = swatchColor(theme: theme, colorScheme: colorScheme)

        Circle()
            .fill(fill)
            .frame(width: Self.diameter, height: Self.diameter)
            .overlay(selectionRing)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(theme.displayName)
            .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }

    @ViewBuilder
    private var selectionRing: some View {
        if isSelected {
            Circle()
                .stroke(Color.vivira.ink, lineWidth: Self.ringWidth)
                .frame(
                    width:  Self.diameter + (Self.ringGap + Self.ringWidth) * 2,
                    height: Self.diameter + (Self.ringGap + Self.ringWidth) * 2
                )
        }
    }

    private func swatchColor(theme: Theme, colorScheme: ColorScheme) -> Color {
        let mode = colorScheme == .dark ? "dark" : "light"
        return Color("accent.\(theme.rawValue).\(mode)", bundle: .module)
    }
}
```

Notes:

- The fill uses the same `accent.<theme>.<mode>` asset-catalog naming that `AccentColor.resolve(in:)` uses in `SemanticColor.swift`. Reading the asset directly here (rather than going through `AccentColor`) keeps the swatch decoupled from the live `\.viviraTheme` environment: each swatch always paints its OWN theme, regardless of which theme is currently selected app-wide.
- The selection ring sits OUTSIDE the 28pt fill, offset by `ringGap + ringWidth`. The visible "gap" between fill and ring is rendered by the parent's `color.surface` background showing through. The total visual footprint when selected is `28 + 2*(2+2) = 36pt`; the tap target is set by the picker (44pt).
- Accessibility: the swatch announces its theme name and exposes `.isSelected` when active. The picker's `Button` wrapper adds `.isButton`; the additional trait here is defensive.

- [ ] **Step 2: Build to confirm `ThemeSwatch` compiles**

Run: `mise run build`
Expected: build succeeds.

- [ ] **Step 3: Commit**

```bash
git add Packages/ViviraDesignSystem/Sources/ViviraDesignSystem/Atoms/ThemeSwatch.swift
git commit -m "feat(ds): add ThemeSwatch atom"
```

---

### Task 5: `ThemePicker` molecule

**Files:**
- Create: `Packages/ViviraDesignSystem/Sources/ViviraDesignSystem/Molecules/ThemePicker.swift`

`HStack` of 5 `ThemeSwatch` buttons distributed evenly across the row, followed by `font.caption` / `color.muted` text naming the current selection. Takes a `Binding<Theme>` so the parent (`ConnectedRoot`) can hand it `$themeStorage.current` and theme changes flow back through `ThemeStorage` automatically. Light haptic on tap, gated on `#if canImport(UIKit)` and `@Environment(\.accessibilityReduceMotion)`.

- [ ] **Step 1: Write `ThemePicker.swift`**

File: `Packages/ViviraDesignSystem/Sources/ViviraDesignSystem/Molecules/ThemePicker.swift`

```swift
// Inline theme picker: row of 5 swatch buttons + current-name caption.
// Lives in the Connected root's Appearance section (UX flow §5.3, design system §3.3).
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

public struct ThemePicker: View {
    @Binding private var selection: Theme

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(selection: Binding<Theme>) {
        self._selection = selection
    }

    public var body: some View {
        VStack(spacing: .vivira.sm) {
            HStack(spacing: 0) {
                ForEach(Theme.allCases, id: \.self) { theme in
                    Button {
                        select(theme)
                    } label: {
                        ThemeSwatch(theme: theme, isSelected: theme == selection)
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(theme.displayName)
                }
            }

            Text(selection.displayName)
                .font(.vivira.caption)
                .foregroundStyle(Color.vivira.muted)
        }
    }

    private func select(_ theme: Theme) {
        guard theme != selection else { return }
        selection = theme
        fireHaptic()
    }

    private func fireHaptic() {
        guard !reduceMotion else { return }
        #if canImport(UIKit)
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred()
        #endif
    }
}
```

Notes:

- `HStack(spacing: 0)` with each cell `.frame(maxWidth: .infinity, minHeight: 44)` distributes the five swatches across the row's full width and gives each a 44pt minimum hit target. The visible swatch is still 28pt; the extra area is invisible but tappable. This is the standard SwiftUI pattern for "big tap target around a small visual".
- `.contentShape(Rectangle())` ensures the whole cell, not just the visible circle, fires the button.
- `.buttonStyle(.plain)` disables the default system styling so the swatch's own visuals are not overridden.
- The `guard theme != selection` short-circuit avoids re-writing the binding and re-firing the haptic when the user taps the already-selected swatch.
- `import UIKit` is wrapped in `#if canImport(UIKit)` so the package still compiles for macOS-host previews and SourceKit indexing, even though haptics only fire on iOS.

- [ ] **Step 2: Build to confirm `ThemePicker` compiles**

Run: `mise run build`
Expected: build succeeds.

- [ ] **Step 3: Commit**

```bash
git add Packages/ViviraDesignSystem/Sources/ViviraDesignSystem/Molecules/ThemePicker.swift
git commit -m "feat(ds): add ThemePicker molecule"
```

---

### Task 6: `HeroStatusCard` molecule (idle initializer only)

**Files:**
- Create: `Packages/ViviraDesignSystem/Sources/ViviraDesignSystem/Molecules/HeroStatusCard.swift`

Single state for Bullet 2. Summary text + optional hint in a card-surface container with a 1pt `color.line` border. Active and degraded states are deferred until real transfer state exists; the API is shaped so they can be added later as additional static factories without breaking the idle call site.

- [ ] **Step 1: Write `HeroStatusCard.swift`**

File: `Packages/ViviraDesignSystem/Sources/ViviraDesignSystem/Molecules/HeroStatusCard.swift`

```swift
// Hero status card — idle initializer only at Bullet 2 fidelity.
// Active and degraded states land when real transfer state exists.
// Per design system §6.2.
import SwiftUI

public struct HeroStatusCard: View {
    private let summary: LocalizedStringKey
    private let hint: LocalizedStringKey?

    public static func idle(
        summary: LocalizedStringKey,
        hint: LocalizedStringKey? = nil
    ) -> HeroStatusCard {
        HeroStatusCard(summary: summary, hint: hint)
    }

    private init(summary: LocalizedStringKey, hint: LocalizedStringKey?) {
        self.summary = summary
        self.hint = hint
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: .vivira.xs) {
            Text(summary)
                .font(.vivira.headline)
                .foregroundStyle(Color.vivira.ink)

            if let hint {
                Text(hint)
                    .font(.vivira.caption)
                    .foregroundStyle(Color.vivira.muted)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vivira.md)
        .background(
            RoundedRectangle(cornerRadius: .vivira.radius.lg, style: .continuous)
                .fill(Color.vivira.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: .vivira.radius.lg, style: .continuous)
                .stroke(Color.vivira.line, lineWidth: 1)
        )
    }
}
```

Notes:

- The `idle` static factory keeps Bullet 2's call site short (`HeroStatusCard.idle(summary: "…", hint: "…")`) and reserves room for `HeroStatusCard.active(lines:)` and `HeroStatusCard.degraded(banner:)` in later bullets without breaking source compatibility.
- `LocalizedStringKey` (not `String`) matches the pattern `EmptyState` uses, so future `.xcstrings` localization (Bullet 1 follow-up #9) catches the strings automatically.

- [ ] **Step 2: Build to confirm `HeroStatusCard` compiles**

Run: `mise run build`
Expected: build succeeds.

- [ ] **Step 3: Commit**

```bash
git add Packages/ViviraDesignSystem/Sources/ViviraDesignSystem/Molecules/HeroStatusCard.swift
git commit -m "feat(ds): add HeroStatusCard idle initializer"
```

---

### Task 7: `ConnectedRoot` composition and replace the `.connected` placeholder

**Files:**
- Create: `Vivira/ConnectedRoot.swift`
- Modify: `Vivira/ContentView.swift`

Compose the four parts of the Connected root: hero card, dashed subscription-list placeholder, inline Appearance section (private wrapper around `Text("Appearance")` label + `ThemePicker`), and a `#if DEBUG` Disconnect link. Replace the `Text` placeholder in `ContentView` with `ConnectedRoot()`.

- [ ] **Step 1: Write `ConnectedRoot.swift`**

File: `Vivira/ConnectedRoot.swift`

```swift
import SwiftUI
import ViviraDesignSystem

struct ConnectedRoot: View {
    @EnvironmentObject private var themeStorage: ThemeStorage
    @EnvironmentObject private var appState: AppState

    var body: some View {
        ScrollView {
            VStack(spacing: .vivira.md) {
                HeroStatusCard.idle(
                    summary: "✓ Connected · 0 subscriptions",
                    hint: "Add an album to start syncing"
                )

                SubscriptionListPlaceholder()

                AppearanceSection(selection: $themeStorage.current)

                #if DEBUG
                Button {
                    appState.kind = .notConnected
                } label: {
                    Text("Disconnect (debug)")
                        .font(.vivira.caption)
                        .foregroundStyle(Color.vivira.faint)
                }
                .padding(.top, .vivira.md)
                #endif
            }
            .padding(.vivira.md)
        }
        .background(Color.vivira.bg.ignoresSafeArea())
    }
}

private struct SubscriptionListPlaceholder: View {
    var body: some View {
        Text("subscription list — Bullet 3")
            .font(.vivira.caption)
            .foregroundStyle(Color.vivira.faint)
            .italic()
            .frame(maxWidth: .infinity, minHeight: 80)
            .background(
                RoundedRectangle(cornerRadius: .vivira.radius.lg, style: .continuous)
                    .fill(Color.vivira.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: .vivira.radius.lg, style: .continuous)
                    .stroke(style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    .foregroundStyle(Color.vivira.line)
            )
    }
}

private struct AppearanceSection: View {
    @Binding var selection: Theme

    var body: some View {
        VStack(alignment: .leading, spacing: .vivira.md) {
            Text("Appearance")
                .font(.vivira.monoLabel)
                .tracking(1.4)
                .textCase(.uppercase)
                .foregroundStyle(Color.vivira.muted)

            ThemePicker(selection: $selection)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vivira.md)
        .background(
            RoundedRectangle(cornerRadius: .vivira.radius.lg, style: .continuous)
                .fill(Color.vivira.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: .vivira.radius.lg, style: .continuous)
                .stroke(Color.vivira.line, lineWidth: 1)
        )
    }
}

#Preview("Connected — Lumen light") {
    ConnectedRoot()
        .environment(\.viviraTheme, .lumen)
        .environmentObject(ThemeStorage())
        .environmentObject({
            let state = AppState()
            state.kind = .connected
            return state
        }())
}
```

Notes:

- `ScrollView` is used because §5.3 specifies one-scroll. With only the hero, placeholder, and Appearance card in this bullet, scrolling is unnecessary on most devices, but keeping it ensures the layout matches the final Connected root's container.
- `SubscriptionListPlaceholder` is `private` and uses a dashed `color.line` border to read as "not real". The text is italicized so reviewers can tell at a glance this is a stub.
- `AppearanceSection` is `private` per the spec ("used in one place; promote when reused"). The section label is inlined (no `SectionLabel` atom yet) and applies `.tracking(1.4)` (= 14% of 10pt) + `.textCase(.uppercase)` per design system §2.2's `font.monoLabel` notation.
- `#if DEBUG` gates the Disconnect link so it compiles out in release builds. Using a plain SwiftUI `Button` (not `ViviraButton`) avoids expanding the design system's role enum prematurely (Bullet 1 follow-up #2 stays open).
- The Preview closes over a one-shot constructor that flips `appState.kind = .connected` before injecting, so the Connected layout renders in Xcode's canvas immediately.

- [ ] **Step 2: Replace the `Text` placeholder in `ContentView.swift`**

File: `Vivira/ContentView.swift`

```swift
import SwiftUI
import ViviraDesignSystem

struct ContentView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        NavigationStack {
            switch appState.kind {
            case .notConnected:
                EmptyState(
                    symbol: "photo.on.rectangle.angled",
                    message: "Vivira keeps Immich shared albums\nin sync with your iPhone.",
                    ctaLabel: "Add a server",
                    action: { appState.kind = .connected }
                )
                .background(Color.vivira.bg.ignoresSafeArea())
            case .connected:
                ConnectedRoot()
            }
        }
    }
}

#Preview {
    ContentView()
        .environment(\.viviraTheme, .lumen)
        .environmentObject(ThemeStorage())
        .environmentObject(AppState())
}
```

- [ ] **Step 3: Build to confirm the composition compiles**

Run: `mise run build`
Expected: build succeeds.

- [ ] **Step 4: Manual simulator verification of the full Pass 1 loop**

Run: `mise run open` then build-and-run from Xcode on the iPhone 17 simulator.
Expected:
- App opens on the empty state. The "Add a server" button is filled with the current theme's accent (Lumen on first launch).
- Tap "Add a server" → `ConnectedRoot` appears: hero card reads "✓ Connected · 0 subscriptions" / "Add an album to start syncing"; the dashed placeholder reads "subscription list — Bullet 3"; the Appearance card shows the section label "APPEARANCE" plus a row of 5 circles with the current theme's swatch ringed and "Lumen" as the caption.
- Tap each non-current swatch: the donut ring moves, the caption text changes, and the simulator's `accent.<theme>.<mode>` colors update across the visible UI within one frame (verifiable by leaving the simulator and noting the "Add a server" button accent later).
- Toggle the simulator's appearance light ↔ dark (`⌘⇧A`): all swatches update to their `.dark` variants; the hero card surface flips; the ring contrast still reads against the new surface.
- Tap "Disconnect (debug)" → returns to the empty state. The CTA accent now reflects the last-chosen theme.
- Force-quit the simulator app, relaunch → starts on the empty state (`AppState` reset) with the last-chosen theme's accent persisted (`ThemeStorage` survives).

- [ ] **Step 5: Commit**

```bash
git add Vivira/ConnectedRoot.swift Vivira/ContentView.swift
git commit -m "feat: ConnectedRoot with inline Appearance section"
```

---

## Phase 2 — Pass 2: Thicken

Goal at the end of Pass 2: every acceptance criterion in spec §6 holds. Snapshot suites are committed for the new molecules and run via `xcodebuild test`. The spec amendments are applied to the UX flow, design system, and Bullet 1 follow-up list.

### Task 8: Wire `ViviraDesignSystemTests` into the Vivira test scheme

**Files:**
- Modify: `project.yml`
- Modify: `mise.toml`

Bullet 1 follow-up #10 noted that the package's snapshot tests are gated by `#if canImport(UIKit)` and never actually run on the macOS host. The fix is to add the package's `ViviraDesignSystemTests` target to the Vivira app's test scheme via xcodegen's `schemes:` block. Once the scheme is wired, `xcodebuild test` runs both `ViviraTests` AND `ViviraDesignSystemTests` against the iOS simulator, and the snapshot tests stop compiling to nothing.

The `mise.toml` `[tasks.test]` runner also gets simplified: with the scheme covering everything, the separate `swift test --package-path Packages/ViviraDesignSystem` line is redundant.

- [ ] **Step 1: Add a `schemes:` block to `project.yml`**

File: `project.yml` — append the following block at the end of the document (after the `targets:` map):

```yaml
schemes:
  Vivira:
    build:
      targets:
        Vivira: all
    test:
      targets:
        - ViviraTests
        - package: ViviraDesignSystem/ViviraDesignSystemTests
      gatherCoverageData: false
      coverageTargets: []
    run:
      executable: Vivira
    profile:
      executable: Vivira
    analyze: {}
    archive: {}
```

The `package: ViviraDesignSystem/ViviraDesignSystemTests` syntax tells xcodegen to reference the `ViviraDesignSystemTests` test product from the local SPM package named `ViviraDesignSystem` (declared earlier under `packages:` in this file). When the scheme is generated, Xcode picks this up as a test action target alongside the app's `ViviraTests` bundle.

- [ ] **Step 2: Simplify `mise.toml`'s `[tasks.test]` runner**

File: `mise.toml` — replace the `[tasks.test]` block with the simpler version that drops the separate `swift test --package-path` invocation:

```toml
[tasks.test]
description = "Run unit tests on $SIM_DEVICE (Vivira app + design system package)"
depends = ["generate"]
run = '''
set -euo pipefail

xcodebuild test \
  -project $PROJECT_NAME.xcodeproj \
  -scheme $SCHEME \
  -destination "platform=iOS Simulator,name=$SIM_DEVICE" \
  OTHER_SWIFT_FLAGS="\$(inherited) $EXTRA_SWIFT_FLAGS" \
  | xcbeautify
'''
```

Delete the trailing `swift test --package-path Packages/ViviraDesignSystem` invocation and the explanatory comment that justified it — both are now obsolete.

- [ ] **Step 3: Regenerate the Xcode project**

Run: `mise run generate`
Expected: `xcodegen generate` succeeds with no schema errors.

- [ ] **Step 4: Run the tests via the new scheme**

Run: `mise run test`
Expected:
- The build phase succeeds for both targets.
- `ViviraTests` runs (smoke test + `AppStateTests` from Task 2).
- `ViviraDesignSystemTests` runs (the four `ThemeStorageTests` cases + the two `EmptyStateSnapshotTests` cases).
- The two `EmptyStateSnapshotTests` cases record their reference PNGs on this first run (under `Packages/ViviraDesignSystem/Tests/ViviraDesignSystemTests/__Snapshots__/EmptyStateSnapshotTests/`). `swift-snapshot-testing` reports `noReferenceImageFailureLabel` on the first run, then the second run will be a clean pass.
- Re-run `mise run test`. Now all tests pass green.

If the first run fails with `Schema validation failed: package: ViviraDesignSystem/ViviraDesignSystemTests`, the xcodegen version is too old for the package-test-product syntax. Update xcodegen via `brew upgrade xcodegen` and re-run.

- [ ] **Step 5: Inspect the recorded `EmptyState` snapshots**

Open both PNGs under `Packages/ViviraDesignSystem/Tests/ViviraDesignSystemTests/__Snapshots__/EmptyStateSnapshotTests/`. Verify:

- `test_emptyState_lumen_light.png` shows the empty state on the light `vivira.bg` background, Lumen accent on the button, dark `ink2` body copy.
- `test_emptyState_lumen_dark.png` shows the inverse: dark background, lighter Lumen accent on the button, lighter body copy.

If either looks wrong, stop and investigate before continuing. These two references are the visual baseline future passes regress against.

- [ ] **Step 6: Commit**

```bash
git add project.yml mise.toml
git add Packages/ViviraDesignSystem/Tests/ViviraDesignSystemTests/__Snapshots__
git commit -m "build: run package tests via xcodebuild scheme; record EmptyState baseline"
```

The commit bundles the scheme wiring, the mise simplification, and the two newly-recorded EmptyState reference PNGs.

---

### Task 9: `ThemePicker` snapshot tests (5 × 2 matrix)

**Files:**
- Create: `Packages/ViviraDesignSystem/Tests/ViviraDesignSystemTests/ThemePickerSnapshotTests.swift`
- Create: 10 reference PNGs under `Packages/ViviraDesignSystem/Tests/ViviraDesignSystemTests/__Snapshots__/ThemePickerSnapshotTests/`

The picker's purpose is to render all five themes, so its snapshot matrix covers all five themes — each as the currently-selected value — in both light and dark mode. Ten snapshots committed.

- [ ] **Step 1: Write the test file**

File: `Packages/ViviraDesignSystem/Tests/ViviraDesignSystemTests/ThemePickerSnapshotTests.swift`

```swift
// ThemePicker snapshot baseline tests — 5 themes × 2 modes = 10 snapshots.
#if canImport(UIKit)
import SnapshotTesting
import SwiftUI
import XCTest
@testable import ViviraDesignSystem

@MainActor
final class ThemePickerSnapshotTests: XCTestCase {

    // Lumen
    func test_themePicker_lumen_light() { assertPicker(selected: .lumen, scheme: .light) }
    func test_themePicker_lumen_dark()  { assertPicker(selected: .lumen, scheme: .dark)  }

    // Pomelo
    func test_themePicker_pomelo_light() { assertPicker(selected: .pomelo, scheme: .light) }
    func test_themePicker_pomelo_dark()  { assertPicker(selected: .pomelo, scheme: .dark)  }

    // Iris
    func test_themePicker_iris_light() { assertPicker(selected: .iris, scheme: .light) }
    func test_themePicker_iris_dark()  { assertPicker(selected: .iris, scheme: .dark)  }

    // Aqua
    func test_themePicker_aqua_light() { assertPicker(selected: .aqua, scheme: .light) }
    func test_themePicker_aqua_dark()  { assertPicker(selected: .aqua, scheme: .dark)  }

    // Magenta
    func test_themePicker_magenta_light() { assertPicker(selected: .magenta, scheme: .light) }
    func test_themePicker_magenta_dark()  { assertPicker(selected: .magenta, scheme: .dark)  }

    private func assertPicker(
        selected: Theme,
        scheme: ColorScheme,
        file: StaticString = #file,
        testName: String = #function,
        line: UInt = #line
    ) {
        struct Host: View {
            @State var selection: Theme
            var body: some View {
                ThemePicker(selection: $selection)
                    .padding(.vivira.md)
                    .frame(width: 360, alignment: .center)
                    .background(Color.vivira.surface)
            }
        }

        let view = Host(selection: selected)
            .preferredColorScheme(scheme)

        assertSnapshot(
            of: view,
            as: .image(layout: .fixed(width: 360, height: 96)),
            file: file,
            testName: testName,
            line: line
        )
    }
}
#endif
```

Notes:

- The 360×96 fixed container approximates the picker's container on iPhone 17 (393pt wide, minus 16pt side padding × 2 = 361pt; rounded to 360). Height 96pt covers the 44pt swatch row + 8pt spacing + 18pt caption + 16pt vertical padding × 2 with a few points of slack.
- The `Host` wrapper supplies a `Binding<Theme>` via `@State` because `ThemePicker` requires a binding; `selected` is the initial value of that state.
- The surface is `color.surface` so the donut ring's `surface` gap reads correctly against the actual surface color (not the page background).

- [ ] **Step 2: Run the tests to record the 10 reference images**

Run: `mise run test`
Expected:
- All 10 new tests report `noReferenceImageFailureLabel` on this first run (snapshot-testing records on first failure).
- The reference PNGs are now on disk under `Packages/ViviraDesignSystem/Tests/ViviraDesignSystemTests/__Snapshots__/ThemePickerSnapshotTests/`.
- Re-run `mise run test`. All 10 cases now pass green.

- [ ] **Step 3: Inspect every recorded snapshot**

Open all 10 PNGs. For each, verify:

- All 5 swatches are present in a row.
- The named theme's swatch carries the donut ring.
- The other 4 swatches do not.
- The caption beneath reads the named theme.
- The accent colors match the design-system §2.1.2 oklch sources (Lumen blue, Pomelo coral, Iris indigo-violet, Aqua cyan, Magenta pink — adjusted for color scheme).
- Light-mode shots use lighter/clearer accents; dark-mode shots use the lighter dark-variant accents per §2.1.2.

If any snapshot looks wrong, stop and fix the picker or the swatch rather than committing.

- [ ] **Step 4: Commit**

```bash
git add Packages/ViviraDesignSystem/Tests/ViviraDesignSystemTests/ThemePickerSnapshotTests.swift
git add Packages/ViviraDesignSystem/Tests/ViviraDesignSystemTests/__Snapshots__/ThemePickerSnapshotTests
git commit -m "test(ds): ThemePicker snapshot matrix (5 themes × 2 modes)"
```

---

### Task 10: `HeroStatusCard` smoke snapshot

**Files:**
- Create: `Packages/ViviraDesignSystem/Tests/ViviraDesignSystemTests/HeroStatusCardSnapshotTests.swift`
- Create: 1 reference PNG under `Packages/ViviraDesignSystem/Tests/ViviraDesignSystemTests/__Snapshots__/HeroStatusCardSnapshotTests/`

A single Lumen-light smoke shot of the idle state. Full 5 × 2 matrix lands when active and degraded states ship — at that point the card is doing real work and per-theme snapshots earn their keep.

- [ ] **Step 1: Write the test file**

File: `Packages/ViviraDesignSystem/Tests/ViviraDesignSystemTests/HeroStatusCardSnapshotTests.swift`

```swift
// HeroStatusCard idle-state smoke snapshot. Active and degraded states land later.
#if canImport(UIKit)
import SnapshotTesting
import SwiftUI
import XCTest
@testable import ViviraDesignSystem

@MainActor
final class HeroStatusCardSnapshotTests: XCTestCase {

    func test_heroStatusCard_idle_lumen_light() {
        let view = HeroStatusCard.idle(
            summary: "✓ Connected · 0 subscriptions",
            hint: "Add an album to start syncing"
        )
        .padding(.vivira.md)
        .frame(width: 393)
        .background(Color.vivira.bg)
        .preferredColorScheme(.light)
        .environment(\.viviraTheme, .lumen)

        assertSnapshot(
            of: view,
            as: .image(layout: .fixed(width: 393, height: 120))
        )
    }
}
#endif
```

- [ ] **Step 2: Run the test to record the reference**

Run: `mise run test`
Expected: the new test reports `noReferenceImageFailureLabel` once; the PNG is now on disk; re-running passes.

- [ ] **Step 3: Inspect the recorded snapshot**

Open `Packages/ViviraDesignSystem/Tests/ViviraDesignSystemTests/__Snapshots__/HeroStatusCardSnapshotTests/test_heroStatusCard_idle_lumen_light.png`.
Verify:
- White `surface` card with hairline `line` border on the `bg` page background.
- Headline-weighted summary "✓ Connected · 0 subscriptions" in `ink`.
- Caption-weighted hint "Add an album to start syncing" in `muted` beneath.
- Padding and corner radius read clean against the page.

- [ ] **Step 4: Commit**

```bash
git add Packages/ViviraDesignSystem/Tests/ViviraDesignSystemTests/HeroStatusCardSnapshotTests.swift
git add Packages/ViviraDesignSystem/Tests/ViviraDesignSystemTests/__Snapshots__/HeroStatusCardSnapshotTests
git commit -m "test(ds): HeroStatusCard idle-state smoke snapshot"
```

---

### Task 11: Apply spec amendments A–H

**Files:**
- Modify: `docs/superpowers/specs/2026-05-16-vivira-ux-flow-design.md`
- Modify: `docs/superpowers/specs/2026-05-17-vivira-design-system-design.md`
- Modify: `docs/superpowers/specs/2026-05-17-vivira-tracer-bullet-design.md`

Apply the eight amendments enumerated in Bullet 2 spec §5 to the three docs they touch. Each sub-step is a single text edit. Bundle the eight edits into one commit at the end.

- [ ] **Step 1: Amendment A — UX flow §3 field rename**

File: `docs/superpowers/specs/2026-05-16-vivira-ux-flow-design.md`

Find (around line 48):

```
│   ├── chargingOnly: Bool                [default: false]
```

Replace with:

```
│   ├── lowPowerDefer: Bool               [default: true; pauses when ProcessInfo.isLowPowerModeEnabled is true]
```

- [ ] **Step 2: Amendment B — UX flow §5.3 toggle rename and new Appearance section**

File: `docs/superpowers/specs/2026-05-16-vivira-ux-flow-design.md`

Find (around line 269):

```
- Only while charging
```

Replace with:

```
- Pause while Low Power Mode
```

Then find the **Servers** subsection of §5.3 (around line 270) and the **About** subsection that follows (around line 275). Insert this new **Appearance** subsection BETWEEN them (after the `+ Add another server` row of Servers, before `**About**`):

```
**Appearance** (app-wide)
- A row of 5 swatches, one per theme, rendered in the current colorScheme. The selected theme carries a 2pt `color.ink` ring with a 2pt `color.surface` gap (donut style). Tap to switch instantly; no apply button. Caption beneath the row names the current theme.

```

(Note the trailing blank line — it keeps the existing **About** heading's whitespace consistent with the rest of §5.3.)

- [ ] **Step 3: Amendment C — Design system decisions table**

File: `docs/superpowers/specs/2026-05-17-vivira-design-system-design.md`

Find (around line 24):

```
| Theme picker | Settings → Appearance only (not in onboarding) |
```

Replace with:

```
| Theme picker | Inline section on Connected root (not in onboarding) |
```

- [ ] **Step 4: Amendment D — Design system §3.3 full rewrite**

File: `docs/superpowers/specs/2026-05-17-vivira-design-system-design.md`

Find the entire `### 3.3 Picker placement` section (lines 246–250 in the current file). The two paragraphs read:

```
### 3.3 Picker placement

Theme picker lives in **Settings → Appearance**. Onboarding does not include theme selection; the user gets Lumen on first run and can change later.

The Settings → Appearance screen shows five preview cards in a 1-column vertical list, each card identical in structure to the per-palette preview used during design (palette swatches + a contextual button + two badges, in the current light/dark mode the user is in). Tap to select; the change is immediate, no apply button.
```

Replace with:

```
### 3.3 Picker placement

The theme picker is an inline section on the Connected root (UX flow §5.3), positioned between Servers and About. Onboarding does not include theme selection; the user gets Lumen on first run and changes later.

The section consists of a `SectionLabel("Appearance")` followed by a single row of 5 `ThemeSwatch` circles (one per theme, rendered with `accent.<theme>.<currentMode>`), with a `font.caption` caption beneath naming the currently-selected theme. The selected swatch carries a donut-ring treatment: 2pt `color.ink` outer ring with a 2pt `color.surface` gap between fill and ring. Tap to switch; the change is immediate, no apply button. The per-palette preview cards used during design (palette swatches plus sample button plus badges) remain as the Penpot reference and do not ship as UI.
```

- [ ] **Step 5: Amendment E — Design system §6.1 ServerRow note**

File: `docs/superpowers/specs/2026-05-17-vivira-design-system-design.md`

Find (around line 429):

```
**ServerRow** *(utility row)* — Server `Icon(.externaldrive)` 44pt avatar left, `Headline` server name, `caption` hostname, `CapabilityChip` status badge below name, `Chevron` right. Appears on Connected root §5.3 (Servers section) and under Settings.
```

Replace with:

```
**ServerRow** *(utility row)* — Server `Icon(.externaldrive)` 44pt avatar left, `Headline` server name, `caption` hostname, `CapabilityChip` status badge below name, `Chevron` right. Appears on Connected root §5.3 (Servers section). No discrete Settings hub — see §3.3.
```

- [ ] **Step 6: Amendment F — Design system §5 atoms: add §5.24 ThemeSwatch**

File: `docs/superpowers/specs/2026-05-17-vivira-design-system-design.md`

Find the end of `### 5.23 LiveActivityChip` (around lines 413–417). After the paragraph that ends with "the design system supplying the color and type tokens." and the blank line that follows, insert a new section:

```
### 5.24 ThemeSwatch

`ThemeSwatch(theme:, isSelected:)`. 28pt circle filled with `accent.<theme>.<colorScheme>`. When `isSelected`, draws a 2pt `color.ink` ring with a 2pt `color.surface` gap between fill and ring. Hit area is 44pt minimum when used in `ThemePicker` (the picker wraps each swatch in a `Button`; the swatch itself is purely visual). No state, no gestures, no haptics — those live in the picker.

```

Make sure the insertion preserves the trailing `---` separator that closes §5 (do not move it).

- [ ] **Step 7: Amendment G — Design system §6.5 Composed molecules: add ThemePicker**

File: `docs/superpowers/specs/2026-05-17-vivira-design-system-design.md`

Find the end of `### 6.5 Composed molecules`. The current entries end with `**CategoryHeader**` (around line 477). Insert after `**CategoryHeader**`'s paragraph and BEFORE the `### 6.6 Where molecules compose into organisms` heading:

```
**ThemePicker** — `HStack` of 5 `ThemeSwatch` atoms distributed `.spacedEvenly`, followed by `font.caption` in `color.muted` naming the current selection. Takes a `Binding<Theme>`; tapping a swatch writes the binding. Light haptic on selection, gated on `@Environment(\.accessibilityReduceMotion)`. Lives in the Appearance section on Connected root (UX flow §5.3). The visible app is the preview — no per-card sample buttons or badges.

```

- [ ] **Step 8: Amendment H — Bullet 1 follow-ups #5 and #10 closure**

File: `docs/superpowers/specs/2026-05-17-vivira-tracer-bullet-design.md`

Find item #5 in `### 6.2 Follow-ups to file when the bullet lands` (around line 277):

```
5. Build the Settings → Appearance theme picker. Wires `ThemeStorage` to the user.
```

Replace with:

```
5. ~~Build the Settings → Appearance theme picker. Wires `ThemeStorage` to the user.~~ **Closed by [Tracer Bullet 2](2026-05-18-vivira-tracer-bullet-2-design.md):** picker lives inline on the Connected root, not as a discrete Settings screen.
```

Find item #10 in the same section (around line 282) — the long paragraph about `EmptyStateSnapshotTests` being UIKit-gated. Add a closure line at the end of that paragraph (after the sentence "Until this lands, snapshot regression coverage is provided by manual simulator verification."):

```
**Closed by [Tracer Bullet 2](2026-05-18-vivira-tracer-bullet-2-design.md):** `project.yml` now declares a `schemes:` block that includes the package's `ViviraDesignSystemTests` test target; `xcodebuild test` runs the snapshot suite against the iOS simulator.
```

- [ ] **Step 9: Verify all three docs still render cleanly**

Run a quick visual scan of all three files (open in your editor; markdown preview if available). Confirm:

- No broken markdown tables.
- No accidental code-fence mismatches from the edits.
- §5.24 sits immediately after §5.23 and before the §5-closing `---` separator.
- The new ThemePicker entry sits within §6.5, not in §6.6.

- [ ] **Step 10: Commit the amendments**

```bash
git add docs/superpowers/specs/2026-05-16-vivira-ux-flow-design.md
git add docs/superpowers/specs/2026-05-17-vivira-design-system-design.md
git add docs/superpowers/specs/2026-05-17-vivira-tracer-bullet-design.md
git commit -m "docs: apply tracer bullet 2 amendments to UX flow, design system, bullet 1"
```

---

### Task 12: Final acceptance verification

**Files:** none modified

Run the full acceptance pass from spec §6. If anything fails, fix it inline and add a follow-up step rather than rolling back.

- [ ] **Step 1: Clean build**

```bash
mise run clean
mise run bootstrap
mise run build
```

Expected: build succeeds with no new warnings versus the baseline before Bullet 2 started.

- [ ] **Step 2: Full test suite**

```bash
mise run test
```

Expected (all green):
- `ViviraTests.smoke` — 1 case.
- `AppStateTests` — 3 cases.
- `ThemeStorageTests` — 4 cases.
- `EmptyStateSnapshotTests` — 2 cases (Lumen light + dark).
- `ThemePickerSnapshotTests` — 10 cases (5 themes × 2 modes).
- `HeroStatusCardSnapshotTests` — 1 case.

Total: 21 test cases.

- [ ] **Step 3: Lint**

```bash
mise run lint
```

Expected: SwiftLint passes with no new violations.

- [ ] **Step 4: Manual simulator verification per spec §6**

```bash
mise run open
```

Build-and-run on the iPhone 17 simulator. Run through the full §6 acceptance script:

1. App boots to EmptyState. CTA accent matches current theme.
2. Tap "Add a server" → ConnectedRoot appears with hero, placeholder, Appearance section.
3. Tap each non-current swatch:
   - Donut ring moves.
   - Caption renames.
   - Accent updates across visible UI.
   - Light haptic fires (turn reduce-motion off in Settings → Accessibility to feel it).
4. Tap "Disconnect (debug)" → returns to EmptyState; CTA accent reflects chosen theme.
5. Force-quit + relaunch → starts on EmptyState; theme persists.
6. Toggle simulator appearance (`⌘⇧A`) on both screens — light ↔ dark renders cleanly.

- [ ] **Step 5: Clean-clone simulation**

In a separate scratch directory (NOT the working repo):

```bash
git clone <repo-url> /tmp/vivira-clean-clone
cd /tmp/vivira-clean-clone
mise run bootstrap
mise run build
mise run test
```

Expected: bootstrap installs deps, build succeeds, tests pass. No manual steps required between `bootstrap` and `test`.

If any step prompts the user, that's a regression — file it and address before declaring the bullet done.

- [ ] **Step 6: Done. No commit needed for this task (verification only)**

If acceptance passes, Bullet 2 is complete.

If anything failed in Step 1–5, stop here and triage. Each failure either reveals a bug introduced by Bullet 2 (fix in a new commit) or a previously hidden bug surfaced by the new test scheme (also fix in a new commit, and add a follow-up if it's out of scope).

---

## Self-review notes

Verified before this plan was committed:

- Spec §1 (Goal): covered by Tasks 1–7 (Pass 1) and reconciled doc layer in Task 11.
- Spec §2.1 (Repo layout): every file listed there is created or modified by an enumerated task.
- Spec §2.2 (Module boundary): Tasks 4–6 land DS additions; Tasks 2, 3, 7 land app additions.
- Spec §2.3 (Theme propagation): exercised end-to-end in Task 7's manual verification; covered by Task 9 snapshots.
- Spec §2.4 (AppState propagation): covered by Tasks 2 (unit) + 7 (manual integration).
- Spec §3.1 (No new tokens): not literally true at the code layer — Task 1 adds `font.caption` and `font.monoLabel` to `Typography.swift`. The spec means "no new tokens in the design system spec", which is correct. The Typography.swift additions implement existing §2.2 entries.
- Spec §3.2 (ThemeSwatch): Task 4.
- Spec §3.3 (ThemePicker + HeroStatusCard): Tasks 5 and 6.
- Spec §3.4 (ConnectedRoot): Task 7.
- Spec §3.5 (AppState): Task 2.
- Spec §3.6 (ContentView + ViviraApp wiring): Task 3 (placeholder) → Task 7 (real).
- Spec §3.7 (Tests): Tasks 9 (ThemePicker snapshots), 10 (HeroStatusCard snapshot), 2 (AppStateTests). `EmptyStateSnapshotTests` reference images recorded in Task 8 (which is when they first actually run).
- Spec §3.8 (project.yml scheme): Task 8.
- Spec §4 (Sequencing): Tasks 1–7 = Pass 1; Tasks 8–12 = Pass 2.
- Spec §5 (Amendments A–H): all in Task 11.
- Spec §6 (Acceptance criteria): Task 12.
- Spec §7 (Out of scope, follow-ups): no tasks; honored by what the plan does NOT include.

The one judgment call worth flagging during execution: Bullet 2 does not promote `SectionLabel` to a reusable atom — the section label is inlined in `ConnectedRoot`'s private `AppearanceSection`. Reason: YAGNI; the label is used in exactly one place. Promote it to a DS atom when Bullet 3 adds the second §5.3 inline section (Conditions or Servers).
