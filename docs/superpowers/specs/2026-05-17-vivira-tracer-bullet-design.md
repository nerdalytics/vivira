# Vivira iOS Tracer Bullet

**Status:** Draft (awaiting review)
**Date:** 2026-05-17
**Scope:** First end-to-end implementation of the iOS app. The bullet replaces the hello-world `ContentView` with the NotConnected empty state from the UX flow, validating that every architectural layer the final product will touch (SwiftUI app entry, local SPM design system, design tokens, asset catalog, theme environment, semantic-color resolution, snapshot tests) is wired and working. Reads alongside the UX flow design and the design system.

---

## How to use this doc

Read once front-to-back. §1 names the goal. §2 lays out the architecture being traced. §3 enumerates exactly what gets built. §4 sequences the work into two end-to-end passes. §5 defines done. §6 names what is deliberately left out and what to file as follow-ups.

This spec does not duplicate the design system or the UX flow. Where they specify visual treatment or behavior, this spec specifies the thinnest end-to-end implementation that exercises them.

---

## Decisions in one page

| Question | Answer |
|---|---|
| What slice does the bullet cover | NotConnected empty state from UX flow §12.1 |
| Where does the design system live | Local SPM package `Packages/ViviraDesignSystem` |
| How many themes ship in the bullet | All 5, both modes, accent role only (19 colorsets total) |
| How are colorsets authored | Node + Color.js script at `tools/oklch-to-p3.mjs`, invoked via `mise run gen-colors` |
| What testing pattern is established | Pointfree `swift-snapshot-testing`; one snapshot pair (Lumen light + dark) and one `ThemeStorage` round-trip test |
| Sequencing | Vertical slice in two passes: thin column first, then thicken |

---

## 1. Goal

The hello-world `ContentView` is replaced by the NotConnected empty state. The empty state renders correctly in both system color schemes, with the Lumen accent on the primary action. The design system lives in its own SPM package and is consumed by the app target. The theme environment resolves at runtime: changing `ThemeStorage.current` in code changes the accent color on screen, and toggling system appearance changes light/dark independently. One snapshot test pair locks the visual baseline; one unit test locks the storage round-trip.

The bullet does not implement the onboarding wizard. The "Add a server" button logs and returns. The remaining state machine, the networking layer, the photo pipeline, and the design system's other 21 atoms and 22 molecules ship in subsequent passes.

---

## 2. Architecture

### 2.1 Repo layout after the bullet lands

```
vivira/
├── Packages/
│   └── ViviraDesignSystem/
│       ├── Package.swift
│       ├── Sources/ViviraDesignSystem/
│       │   ├── Tokens/
│       │   │   ├── DesignTokens.swift        // CGFloat.vivira.* spacing + radius
│       │   │   ├── Theme.swift               // Theme enum, @Entry env value
│       │   │   ├── ThemeStorage.swift        // UserDefaults round-trip
│       │   │   ├── SemanticColor.swift       // AccentColor: ShapeStyle
│       │   │   └── Typography.swift          // Font.vivira.* bound to Apple text styles
│       │   ├── Atoms/
│       │   │   ├── ViviraButton.swift        // single tinted-accent style
│       │   │   └── Icon.swift                // SF Symbols wrapper
│       │   ├── Molecules/
│       │   │   └── EmptyState.swift
│       │   └── Resources/
│       │       └── ViviraColors.xcassets     // 9 neutrals + (1 accent × 5 themes × 2 modes)
│       └── Tests/ViviraDesignSystemTests/
│           ├── ThemeStorageTests.swift
│           └── EmptyStateSnapshotTests.swift
├── Vivira/
│   ├── ViviraApp.swift                       // installs ThemeStorage, injects env
│   └── ContentView.swift                     // renders EmptyState
├── ViviraTests/
│   └── ViviraTests.swift                     // unchanged smoke
├── tools/
│   ├── colors-source.json                    // oklch + neutrals source of truth
│   └── oklch-to-p3.mjs                       // generator
├── project.yml                               // adds local SPM package dep
└── mise.toml                                 // adds `gen-colors` task
```

### 2.2 Module boundary

The `Vivira` app target imports `ViviraDesignSystem`. The DS package owns design tokens, atoms, molecules, the asset catalog, and theme storage. The app target owns the scene, the navigation root, and app-specific state. Swift's module system enforces the boundary; nothing in the DS package depends on the app.

### 2.3 Theme environment

Theme resolution follows design system §8.3:

```
ViviraApp ── @StateObject ThemeStorage ──▶ ContentView
                  │                            │
                  └── writes ──▶ UserDefaults ── reads on init
                  │
                  └── pushes Theme into Environment via @Entry viviraTheme
                                        │
                                        ▼
                AccentColor: ShapeStyle .resolve(in:) reads
                (viviraTheme, colorScheme) → returns Color("accent.<theme>.<mode>", bundle: .module)
```

`ThemeStorage` initializes by reading `UserDefaults.standard` under key `ViviraDesignSystem.theme`, defaulting to `.lumen` if absent or unparseable. The current theme writes into `EnvironmentValues.viviraTheme` via the `@Entry` macro. Semantic colors conform to `ShapeStyle` and read `(viviraTheme, colorScheme)` inside `resolve(in:)` to return the right asset-catalog entry.

The bullet ships without a theme picker. `ThemeStorage` is wired and verifiable in code (a manual override in the Preview or a developer-only flip in the debugger). User-facing selection lands when the Settings → Appearance screen ships.

### 2.4 Asset catalog inside SPM

The asset catalog lives at `Sources/ViviraDesignSystem/Resources/ViviraColors.xcassets`. `Package.swift` registers it with `.process("Resources/ViviraColors.xcassets")`, which causes SwiftPM to generate `Bundle.module` so `Color("name", bundle: .module)` resolves at runtime.

Every colorset uses the Display P3 gamut. The 9 neutrals store both Light and Dark appearances in a single colorset. The 10 accent colorsets (one per theme × mode) store one appearance entry each, addressed by the `<role>.<theme>.<mode>` naming convention from design system §8.5.

### 2.5 oklch → P3 pipeline

`tools/colors-source.json` is the canonical source. It contains the 10 accent oklch triples and the 9 neutral hex pairs, mirroring design system §2.1.2.

`tools/oklch-to-p3.mjs` is a Node ESM script that reads `colors-source.json`, converts each value to Display P3 components via `colorjs.io`, and writes `Contents.json` into the appropriate `.colorset` directories. Generated files are committed.

`mise run gen-colors` invokes the script. The task stands alone; `mise run generate` (xcodegen) does not depend on it. The workflow is: edit `colors-source.json`, run `mise run gen-colors`, then commit both the source JSON and the regenerated `Contents.json` files. A clean clone of the repo builds without Node installed; only contributors who change colors need the Node toolchain.

---

## 3. Components

### 3.1 Tokens

| File | Contents |
|---|---|
| `DesignTokens.swift` | `CGFloat.vivira.{xs, sm, md, mdPlus, lg, xl, xxxl}` for spacing and `.radius.{md, lg}` for corners. Only the tokens the empty state consumes. The rest stay in the design-system spec and land when first used. |
| `Typography.swift` | `Font.vivira.{displayLarge, body, bodyBold, headline}` bound to Apple text styles per design system §2.2. Dynamic Type inherits automatically. `monoLabel` is deferred; the empty state has no mono labels. |
| `Theme.swift` | `enum Theme: String, CaseIterable, Codable, Sendable { case lumen, pomelo, iris, aqua, magenta }` with localized display names. |
| `ThemeStorage.swift` | `@MainActor public final class ThemeStorage: ObservableObject` with `@Published var current: Theme` and `UserDefaults.standard` round-trip under key `ViviraDesignSystem.theme`. Initializer takes an optional `UserDefaults` for test injection. |
| `SemanticColor.swift` | `AccentColor: ShapeStyle, Sendable` with `resolve(in:)` returning `Color("accent.<theme>.<mode>", bundle: .module)`. Exposed as `.accent` via `ShapeStyle where Self == AccentColor`. Declares `EnvironmentValues.viviraTheme` via `@Entry`. |

`Color.vivira.*` accessors for neutrals live as a namespace on `Color` (extension enum) and return `Color("vivira.<name>", bundle: .module)`. The bullet exposes the 9 neutrals enumerated in design system §2.1.1.

The remaining semantic roles (`destructive`, `warn`, `success`) and their soft variants from design system §2.1.3 are not implemented. They land when the first molecule that uses them ships (FailureBanner, SuccessBanner, DegradedBanner, StateBadge).

### 3.2 Atoms

**`ViviraButton(action:, label:)`.** 44pt tall, `radius.md` corners, `space.mdPlus` horizontal padding, `font.bodyBold`, `.lineLimit(1)`. Fill `.accent`, text in `Color.vivira.bg` (contrasts well over the accent in both modes per design system §5.1). Press state: 95% scale and 60% opacity, gated on `accessibilityReduceMotion`. Accessibility: `.isButton` trait, label from content. The button ships with a single tinted-accent style today; a role/style enum will be introduced when a second style lands.

**`Icon(symbol: String, size: CGFloat, foreground: Color)`.** A thin `Image(systemName:)` wrapper. The empty state uses one symbol, `photo.on.rectangle.angled`, at 48pt with `Color.vivira.faint` foreground per design system §6.5.

### 3.3 Molecules

**`EmptyState(symbol:, message:, ctaLabel:, action:)`.** Per design system §6.5 and UX flow §12.1: vertically-centered `Icon` (48pt, `faint`) above body copy (`font.body`, `Color.vivira.ink2`) above `ViviraButton(.accent)`. Stack spacing `space.lg` between icon and copy and `space.xl` between copy and button. Outer container uses `Spacer()` above and below with `space.xxxl` minimum vertical padding so the molecule centers regardless of safe-area size.

### 3.4 Asset catalog (`ViviraColors.xcassets`)

Nine neutral colorsets, each with Light and Dark appearance entries:

```
vivira.bg, vivira.surface, vivira.surface2,
vivira.ink, vivira.ink2, vivira.muted, vivira.faint,
vivira.line, vivira.lineStrong
```

Ten accent colorsets, one entry each:

```
accent.lumen.light, accent.lumen.dark,
accent.pomelo.light, accent.pomelo.dark,
accent.iris.light, accent.iris.dark,
accent.aqua.light, accent.aqua.dark,
accent.magenta.light, accent.magenta.dark
```

All 19 colorsets use Display P3. High-contrast variants are not included in the bullet; they land when the accessibility pass runs.

### 3.5 App target

**`ViviraApp.swift`.** Instantiates `ThemeStorage` as `@StateObject`, passes the storage via `.environmentObject`, and injects `\.viviraTheme` into the environment from `themeStorage.current`.

**`ContentView.swift`.** A `NavigationStack` wrapping the empty state. The `NavigationStack` is forward-compatible with the §4 onboarding wizard but routes nowhere in the bullet. Background uses `Color.vivira.bg`. The button's action logs `"add-server tapped"`; the function pointer is the integration seam the onboarding wizard will replace.

### 3.6 Tooling

**`tools/colors-source.json`.** Canonical source for accents (oklch triples) and neutrals (hex pairs). Editing this file and re-running the generator is how a color changes.

**`tools/oklch-to-p3.mjs`.** Node ESM. Depends on `colorjs.io` from npm; a local `package.json` pins the version. Output writes `Contents.json` files in place under the asset catalog.

**`mise.toml` additions.** New task `gen-colors` runs the Node script. It is invoked manually when colors change; no existing task depends on it. The generated `Contents.json` files are committed and consumed by `xcodegen` and the build like any other resource.

**`project.yml`.** Adds a `packages:` block referencing the local `ViviraDesignSystem` path and lists `ViviraDesignSystem` as a `dependencies:` entry on the `Vivira` target.

**`Packages/ViviraDesignSystem/Package.swift`.** `swift-tools-version: 6.0`. iOS platform requirement is `.iOS("26.5")` — matches the app's deployment target; no other iOS version is supported. Library product `ViviraDesignSystem`. Test-target dependency on `pointfreeco/swift-snapshot-testing` from `1.17.0`.

### 3.7 Tests

**`ThemeStorageTests.swift`.** Uses Swift Testing (`@Test`). One parameterized test iterates `Theme.allCases`, instantiates `ThemeStorage` with an isolated `UserDefaults(suiteName: UUID().uuidString)`, sets `current = theme`, re-instantiates, and asserts the second instance reads back the same theme.

**`EmptyStateSnapshotTests.swift`.** Uses `swift-snapshot-testing`. Two snapshots:

- `EmptyState` in Lumen light, hosted in a fixed-size container that mirrors the iPhone 17 portrait safe area.
- `EmptyState` in Lumen dark, same dimensions, `.dark` color scheme.

Reference images live under `Tests/ViviraDesignSystemTests/__Snapshots__/`. Both are committed.

**Existing `ViviraTests/ViviraTests.swift`** stays as-is. It confirms the app's test bundle still builds against the new package dependency.

---

## 4. Vertical slice sequencing

Two passes. Each pass is end-to-end and produces working software at its tail.

### Pass 1 — Thin column

Goal: `mise run build && mise run open` shows the empty state on simulator. Lumen only. No theme storage yet, no tests, no generator script.

1. Create `Packages/ViviraDesignSystem/Package.swift` (no test target dependencies yet). Single library target.
2. Hand-author the five colorsets the empty state needs at `Resources/ViviraColors.xcassets`: `vivira.bg`, `vivira.ink2`, and `vivira.faint` (each with both Light and Dark appearance entries) plus `accent.lumen.light` and `accent.lumen.dark` (one appearance entry each). Display P3 components are pre-computed from design system §2.1.1 (neutrals) and §2.1.2 (Lumen oklch) and pasted into `Contents.json` directly. The generator script lands in Pass 2 and replaces these hand-authored values.
3. Add the minimum tokens: `Color.vivira.bg`, `Font.vivira.{displayLarge, body, bodyBold}`, `CGFloat.vivira.{md, lg, xl, xxxl, mdPlus, radius.md}`.
4. Add `Theme.swift` and `EnvironmentValues.viviraTheme` with `@Entry`, defaulting to `.lumen`. `ThemeStorage` does not exist yet.
5. Add `SemanticColor.swift` with `AccentColor.resolve(in:)` reading `(viviraTheme, colorScheme)` and returning the matching asset-catalog entry. Only Lumen has entries to return; the other themes route to a fallback (`Color.accentColor`) until Pass 2.
6. Add `Atoms/ViviraButton.swift` (`.accent` role only) and `Atoms/Icon.swift`.
7. Add `Molecules/EmptyState.swift`.
8. Edit `project.yml` to reference the local SPM package and list it as a dependency of the `Vivira` target. Run `mise run generate`.
9. Replace `ContentView.swift` with the empty-state rendering. `ViviraApp.swift` adds `.environment(\.viviraTheme, .lumen)`.
10. Build and run on simulator. Toggle system appearance light ↔ dark; the screen renders correctly both ways.

End of Pass 1: visible bullet, single theme, single screen, no tests.

### Pass 2 — Thicken

11. Add `tools/colors-source.json` mirroring design system §2.1.2 (10 accent oklch values + 9 neutral hex pairs).
12. Build `tools/oklch-to-p3.mjs` plus a local `tools/package.json` pinning `colorjs.io`. Generate the full 19 colorsets' `Contents.json` files. Hand-authored values from Pass 1 step 2 are replaced by the generator output.
13. Add a `gen-colors` task to `mise.toml`. The task stands alone — no other task depends on it. Run it once to regenerate the 19 colorsets, then commit the regenerated `Contents.json` files alongside `colors-source.json`.
14. Add the remaining 8 neutral tokens to `Color.vivira`: `surface`, `surface2`, `ink`, `ink2`, `muted`, `faint`, `line`, `lineStrong`.
15. Add `ThemeStorage.swift` with `@MainActor`, `ObservableObject`, `@Published var current: Theme`, and the optional `UserDefaults` initializer. Inject into `ViviraApp` as `@StateObject`. Replace the hard-coded `\.viviraTheme = .lumen` with `\.viviraTheme = themeStorage.current`.
16. Add `swift-snapshot-testing` to `Package.swift` test-target dependencies.
17. Write `ThemeStorageTests.swift`. Round-trip every theme through an isolated `UserDefaults` suite.
18. Write `EmptyStateSnapshotTests.swift`. Two snapshots committed (Lumen light, Lumen dark).
19. Manually verify cross-theme resolution: in a Preview wrapper, flip `\.viviraTheme` through all five values and confirm the button accent changes correctly. The verification is visual, not snapshotted; the 5 × 2 matrix lands later.
20. Run `mise run test` and `mise run lint`. Both pass.

End of Pass 2: bullet meets every acceptance criterion below.

---

## 5. Acceptance criteria

The bullet is done when all of these hold:

- `mise run build` succeeds with no new warnings versus baseline.
- `mise run test` passes, including the `ThemeStorage` round-trip and the two snapshot tests.
- `mise run lint` passes.
- The app boots on the simulator declared in `mise.toml` and renders the empty state per UX flow §12.1.
- Toggling system appearance light ↔ dark changes the colors at runtime, including the accent on the button.
- Manually setting `ThemeStorage.current` to each of the 5 themes from code changes the button's accent color to the matching `accent.<theme>.<mode>` entry.
- `Bundle.module` resolves at runtime; the console emits no asset-not-found warnings.
- A clean clone of the repo succeeds with `mise run bootstrap && mise run build` and no further manual steps. Node is not required for a normal build because the generated `Contents.json` files are committed.

---

## 6. Out of scope

These were considered and deliberately left out to keep the bullet at end-to-end thinness.

### 6.1 Not in the bullet

- All other atoms: TextField, SecureField, TypedConfirmField, Toggle, SegmentedPicker, CapabilityChip, FilterChip, Pill, StateBadge, DirectionGlyph, StepIndicator, LinearProgress, Spinner, Skeleton, Thumbnail, ThumbnailTile, Divider, Chevron, SectionLabel, Snackbar, LiveActivityChip. Additional `ViviraButton` styles (primary, secondary, ghost, destructive) also stay unbuilt.
- All other molecules: SubscriptionRow, ServerRow, FormRow, AlbumViewRow, HeroStatusLine, HeroStatusCard, ModeLine, CountsLine, SuccessBanner, FailureBanner, DegradedBanner, WizardStepHeader, InfoCard, CapabilityRow, HonestDisclosureRow, TwoCardChooser, TypedConfirmBlock, SyncSheetSection, AlbumThumbnailStrip, PermissionsRow, CategoryHeader.
- Layout primitives: `ContentList`, `UtilityList`, `PageScaffold`, the bottom-fade affordance from design system §7.3.
- The destructive, warn, and success semantic roles and their soft variants. The soft-mixing math from design system §2.1.3 is not implemented.
- 30 of the 49 final colorsets (the destructive, warn, and success variants).
- High-contrast colorset variants from design system §10.3.
- The onboarding wizard (UX flow §4) and the state-machine routing it requires.
- Networking, the Immich API client, PhotoKit, `BGTask`, `ActivityKit`, Live Activity.
- Persistence beyond the single `UserDefaults` key for the theme.
- The Settings → Appearance theme picker UI.
- The full 5 × 2 snapshot matrix for `EmptyState`. The bullet commits Lumen light + dark only.
- Per-atom snapshot suites.
- Liquid Glass treatments. The empty state has no chrome that calls for them.
- Localization beyond English, the `tokens.json` export, and the Penpot mirror file.

### 6.2 Follow-ups to file when the bullet lands

1. Add destructive, warn, success semantic roles and the soft-mixer math. Required by FailureBanner, SuccessBanner, DegradedBanner, TypedConfirmBlock, and StateBadge.
2. Add a role/style enum to `ViviraButton` when a second style ships. Required by every wizard step's pinned action and by the disconnect flow.
3. Add high-contrast colorset variants for the 19 existing colorsets (and for any added later). The design system §10.3 a11y mandate covers all colorsets.
4. Add the 5 × 2 snapshot matrix for `EmptyState` plus per-atom snapshot tests.
5. ~~Build the Settings → Appearance theme picker. Wires `ThemeStorage` to the user.~~ **Closed by [Tracer Bullet 2](2026-05-18-vivira-tracer-bullet-2-design.md):** picker lives inline on the Connected root, not as a discrete Settings screen.
6. Decide the long-term home for `oklch-to-p3.mjs`: keep the Node script or port to Swift per design system §14 #1.
7. Add the remaining atoms and molecules in roughly the order the onboarding wizard needs them (`WizardStepHeader`, `ViviraTextField`, `CapabilityChip`, `SegmentedPicker`, `InfoCard`, `Toggle`).
8. Set the runtime contract for "Vivira only touches what Vivira created" (UX paradigm §16, UX flow §12.3 rule 1). This lives in the app data layer, not the design system, and is a candidate for an early architecture spec of its own.
9. Wire localization against the package bundle. The five `String(localized:)` calls in `Theme.displayName` currently omit `bundle:`, so they fall through to `Bundle.main`. This has no observable impact while the package ships no localization files, but when the first `.xcstrings` or `.strings` file lands in `ViviraDesignSystem`, add `bundle: Bundle.module` to all five call sites in the same commit that adds the strings file.
10. **Wire `EmptyStateSnapshotTests` to actually run.** The snapshot tests are gated with `#if canImport(UIKit)` because swift-snapshot-testing's `.image(layout:)` only exists on UIKit-bearing platforms; `swift test` on the macOS host now compiles them to nothing. To actually run them, add the package's `ViviraDesignSystemTests` target to the Vivira app's test scheme in `project.yml` so `xcodebuild test` runs them against the iOS simulator. (Alternatively: move the snapshot tests into the `ViviraTests` app target.) Until this lands, snapshot regression coverage is provided by manual simulator verification. **Closed by [Tracer Bullet 2](2026-05-18-vivira-tracer-bullet-2-design.md):** `project.yml` now declares a `schemes:` block that includes the package's `ViviraDesignSystemTests` test target; `xcodebuild test` runs the snapshot suite against the iOS simulator.

---

## 7. References

### Project

- [Vivira UX flow design](2026-05-16-vivira-ux-flow-design.md) — §12.1 NotConnected empty state copy is the source for the bullet's screen.
- [Vivira design system](2026-05-17-vivira-design-system-design.md) — §2 tokens, §5 atoms, §6 molecules, §8 SwiftUI architecture, §10 accessibility.
- [Vivira UX paradigms](2026-05-17-vivira-ux-paradigms.md) — informs the language for the empty-state copy.

### Apple

- [Swift Package Manager — Resources](https://developer.apple.com/documentation/packagedescription/resource) — `.process` rule, `Bundle.module`.
- [`@Entry` macro guide](https://www.donnywals.com/adding-values-to-the-swiftui-environment-with-entry/) — environment-value declarations.
- [SwiftUI `ShapeStyle`](https://developer.apple.com/documentation/swiftui/shapestyle) — the protocol the semantic colors conform to.

### Tooling

- [`colorjs.io`](https://colorjs.io/) — oklch ↔ Display P3 conversion library used by the generator.
- [`pointfreeco/swift-snapshot-testing`](https://github.com/pointfreeco/swift-snapshot-testing) — snapshot test infrastructure.
- [xcodegen](https://github.com/yonaskolb/XcodeGen) — already in use; `project.yml` is the source of truth for the Xcode project.
