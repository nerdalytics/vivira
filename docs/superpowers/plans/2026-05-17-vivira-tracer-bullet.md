# Vivira iOS Tracer Bullet Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the hello-world `ContentView` with the NotConnected empty state, end-to-end through a new local SPM design system package, theme environment, asset catalog (19 colorsets covering all five themes × accent only, plus the nine neutrals), and tests.

**Architecture:** Vertical-slice in two passes. Pass 1 (Tasks 1–7) lands the thinnest end-to-end column with Lumen only, no tests, no generator script. Pass 2 (Tasks 8–14) thickens by adding the Node oklch→P3 generator, the remaining four themes, `ThemeStorage` with `UserDefaults` round-trip, and snapshot tests for the empty state in Lumen light and dark.

**Tech Stack:** Swift 6 + SwiftUI on iOS 26.5. SwiftPM local package `ViviraDesignSystem`. xcodegen-generated app project. mise task runner. Node + `colorjs.io` for one-off colorset regeneration. Pointfree `swift-snapshot-testing` for visual regression.

**Spec:** [`docs/superpowers/specs/2026-05-17-vivira-tracer-bullet-design.md`](../specs/2026-05-17-vivira-tracer-bullet-design.md)

---

## File map

**Created in Pass 1 (Tasks 1–7):**

| File | Responsibility |
|---|---|
| `Packages/ViviraDesignSystem/Package.swift` | SPM manifest, single library target, asset-catalog resource. |
| `Packages/ViviraDesignSystem/Sources/ViviraDesignSystem/Tokens/DesignTokens.swift` | `Color.vivira.*` neutral accessors + `CGFloat.vivira.*` spacing and radius. |
| `Packages/ViviraDesignSystem/Sources/ViviraDesignSystem/Tokens/Typography.swift` | `Font.vivira.*` bound to Apple text styles. |
| `Packages/ViviraDesignSystem/Sources/ViviraDesignSystem/Tokens/Theme.swift` | `Theme` enum + `EnvironmentValues.viviraTheme` via `@Entry`. |
| `Packages/ViviraDesignSystem/Sources/ViviraDesignSystem/Tokens/SemanticColor.swift` | `AccentColor: ShapeStyle` resolving `(theme, colorScheme)` → asset-catalog entry. |
| `Packages/ViviraDesignSystem/Sources/ViviraDesignSystem/Atoms/Icon.swift` | Thin SF Symbols wrapper. |
| `Packages/ViviraDesignSystem/Sources/ViviraDesignSystem/Atoms/ViviraButton.swift` | `.accent` role only; the four other roles ship later. |
| `Packages/ViviraDesignSystem/Sources/ViviraDesignSystem/Molecules/EmptyState.swift` | Icon + body copy + accent button, vertically centered. |
| `Packages/ViviraDesignSystem/Sources/ViviraDesignSystem/Resources/ViviraColors.xcassets/` | 5 colorsets in Pass 1 (`vivira.bg`, `vivira.ink2`, `vivira.faint`, `accent.lumen.light`, `accent.lumen.dark`). |

**Modified in Pass 1:**

| File | Change |
|---|---|
| `project.yml` | Declare local SPM package; depend on `ViviraDesignSystem` from `Vivira` target. |
| `Vivira/ViviraApp.swift` | Inject `\.viviraTheme = .lumen` into the environment. |
| `Vivira/ContentView.swift` | Render `EmptyState(...)` inside a `NavigationStack`. |

**Created in Pass 2 (Tasks 8–14):**

| File | Responsibility |
|---|---|
| `tools/colors-source.json` | Canonical source: 10 accent oklch triples + 9 neutral hex pairs. |
| `tools/oklch-to-p3.mjs` | Node ESM converter, reads source JSON, writes `Contents.json`. |
| `tools/package.json` | Pins `colorjs.io`. |
| `Packages/ViviraDesignSystem/Sources/ViviraDesignSystem/Tokens/ThemeStorage.swift` | `@MainActor ObservableObject` with `UserDefaults` round-trip. |
| `Packages/ViviraDesignSystem/Tests/ViviraDesignSystemTests/ThemeStorageTests.swift` | Round-trip suite. |
| `Packages/ViviraDesignSystem/Tests/ViviraDesignSystemTests/EmptyStateSnapshotTests.swift` | Lumen light + dark snapshots. |
| `Packages/ViviraDesignSystem/Tests/ViviraDesignSystemTests/__Snapshots__/EmptyStateSnapshotTests/*.png` | Reference images, committed. |

**Modified in Pass 2:**

| File | Change |
|---|---|
| `Packages/ViviraDesignSystem/Package.swift` | Add `pointfreeco/swift-snapshot-testing` dep + `.testTarget`. |
| `Packages/ViviraDesignSystem/Sources/ViviraDesignSystem/Tokens/DesignTokens.swift` | Add the remaining 6 neutral accessors. |
| `Packages/ViviraDesignSystem/Sources/ViviraDesignSystem/Resources/ViviraColors.xcassets/` | Regenerate 5 existing + add 14 new colorsets (= 19 total). |
| `Vivira/ViviraApp.swift` | Replace hard-coded `.lumen` with `themeStorage.current`. |
| `mise.toml` | New `gen-colors` task (standalone; no other task depends on it). |

---

## Phase 1 — Pass 1: Thin column

### Task 1: SPM package skeleton with neutral tokens and 5 colorsets

**Files:**
- Create: `Packages/ViviraDesignSystem/Package.swift`
- Create: `Packages/ViviraDesignSystem/Sources/ViviraDesignSystem/Tokens/DesignTokens.swift`
- Create: `Packages/ViviraDesignSystem/Sources/ViviraDesignSystem/Resources/ViviraColors.xcassets/Contents.json`
- Create: 5 colorsets under `Resources/ViviraColors.xcassets/` (each its own folder with a `Contents.json`)

- [ ] **Step 1: Create the SPM package directory tree**

```bash
mkdir -p Packages/ViviraDesignSystem/Sources/ViviraDesignSystem/Tokens
mkdir -p Packages/ViviraDesignSystem/Sources/ViviraDesignSystem/Atoms
mkdir -p Packages/ViviraDesignSystem/Sources/ViviraDesignSystem/Molecules
mkdir -p Packages/ViviraDesignSystem/Sources/ViviraDesignSystem/Resources/ViviraColors.xcassets
```

- [ ] **Step 2: Write `Packages/ViviraDesignSystem/Package.swift`**

```swift
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ViviraDesignSystem",
    platforms: [
        .iOS("26.5"),
        .macOS(.v15)
    ],
    products: [
        .library(name: "ViviraDesignSystem", targets: ["ViviraDesignSystem"])
    ],
    targets: [
        .target(
            name: "ViviraDesignSystem",
            resources: [.process("Resources/ViviraColors.xcassets")]
        )
    ]
)
```

The `.macOS(.v15)` entry is a SwiftPM hint for SourceKit's host-OS index pass — without it the indexer falls back to a pre-SwiftUI macOS minimum (below macOS 10.15) and flags every `Color` reference as unavailable. macOS 15 is well above that threshold and the enum case is guaranteed to exist in any Swift 6.0 toolchain. The library still ships only on iOS 26.5; this line is not a deployment claim.

- [ ] **Step 3: Write the asset-catalog root `Contents.json`**

File: `Packages/ViviraDesignSystem/Sources/ViviraDesignSystem/Resources/ViviraColors.xcassets/Contents.json`

```json
{
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
```

- [ ] **Step 4: Create the `vivira.bg` colorset**

```bash
mkdir -p Packages/ViviraDesignSystem/Sources/ViviraDesignSystem/Resources/ViviraColors.xcassets/vivira.bg.colorset
```

File: `Packages/ViviraDesignSystem/Sources/ViviraDesignSystem/Resources/ViviraColors.xcassets/vivira.bg.colorset/Contents.json`

```json
{
  "colors" : [
    {
      "color" : {
        "color-space" : "srgb",
        "components" : {
          "alpha" : "1.000",
          "blue" : "0xFA",
          "green" : "0xF7",
          "red" : "0xF5"
        }
      },
      "idiom" : "universal"
    },
    {
      "appearances" : [
        {
          "appearance" : "luminosity",
          "value" : "dark"
        }
      ],
      "color" : {
        "color-space" : "srgb",
        "components" : {
          "alpha" : "1.000",
          "blue" : "0x0C",
          "green" : "0x09",
          "red" : "0x07"
        }
      },
      "idiom" : "universal"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
```

Hex values from design system §2.1.1: light `#F5F7FA`, dark `#07090C`.

- [ ] **Step 5: Create the `vivira.ink2` colorset**

```bash
mkdir -p Packages/ViviraDesignSystem/Sources/ViviraDesignSystem/Resources/ViviraColors.xcassets/vivira.ink2.colorset
```

File: `Packages/ViviraDesignSystem/Sources/ViviraDesignSystem/Resources/ViviraColors.xcassets/vivira.ink2.colorset/Contents.json`

```json
{
  "colors" : [
    {
      "color" : {
        "color-space" : "srgb",
        "components" : {
          "alpha" : "1.000",
          "blue" : "0x47",
          "green" : "0x3A",
          "red" : "0x2D"
        }
      },
      "idiom" : "universal"
    },
    {
      "appearances" : [
        {
          "appearance" : "luminosity",
          "value" : "dark"
        }
      ],
      "color" : {
        "color-space" : "srgb",
        "components" : {
          "alpha" : "1.000",
          "blue" : "0xC9",
          "green" : "0xBF",
          "red" : "0xB5"
        }
      },
      "idiom" : "universal"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
```

Hex values from design system §2.1.1: light `#2D3A47`, dark `#B5BFC9`.

- [ ] **Step 6: Create the `vivira.faint` colorset**

```bash
mkdir -p Packages/ViviraDesignSystem/Sources/ViviraDesignSystem/Resources/ViviraColors.xcassets/vivira.faint.colorset
```

File: `Packages/ViviraDesignSystem/Sources/ViviraDesignSystem/Resources/ViviraColors.xcassets/vivira.faint.colorset/Contents.json`

```json
{
  "colors" : [
    {
      "color" : {
        "color-space" : "srgb",
        "components" : {
          "alpha" : "1.000",
          "blue" : "0xA2",
          "green" : "0x95",
          "red" : "0x8A"
        }
      },
      "idiom" : "universal"
    },
    {
      "appearances" : [
        {
          "appearance" : "luminosity",
          "value" : "dark"
        }
      ],
      "color" : {
        "color-space" : "srgb",
        "components" : {
          "alpha" : "1.000",
          "blue" : "0x76",
          "green" : "0x6A",
          "red" : "0x5C"
        }
      },
      "idiom" : "universal"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
```

Hex values from design system §2.1.1: light `#8A95A2`, dark `#5C6A76`.

- [ ] **Step 7: Create the `accent.lumen.light` colorset**

```bash
mkdir -p Packages/ViviraDesignSystem/Sources/ViviraDesignSystem/Resources/ViviraColors.xcassets/accent.lumen.light.colorset
```

File: `Packages/ViviraDesignSystem/Sources/ViviraDesignSystem/Resources/ViviraColors.xcassets/accent.lumen.light.colorset/Contents.json`

```json
{
  "colors" : [
    {
      "color" : {
        "color-space" : "srgb",
        "components" : {
          "alpha" : "1.000",
          "blue" : "0xE0",
          "green" : "0x7A",
          "red" : "0x1F"
        }
      },
      "idiom" : "universal"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
```

Approximation of design system §2.1.2 Lumen light `oklch(60% 0.18 240)` → sRGB `#1F7AE0`. Pass 2's generator (Task 8) replaces this with the precise Display P3 components.

- [ ] **Step 8: Create the `accent.lumen.dark` colorset**

```bash
mkdir -p Packages/ViviraDesignSystem/Sources/ViviraDesignSystem/Resources/ViviraColors.xcassets/accent.lumen.dark.colorset
```

File: `Packages/ViviraDesignSystem/Sources/ViviraDesignSystem/Resources/ViviraColors.xcassets/accent.lumen.dark.colorset/Contents.json`

```json
{
  "colors" : [
    {
      "color" : {
        "color-space" : "srgb",
        "components" : {
          "alpha" : "1.000",
          "blue" : "0xEF",
          "green" : "0xA4",
          "red" : "0x66"
        }
      },
      "idiom" : "universal"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
```

Approximation of design system §2.1.2 Lumen dark `oklch(75% 0.16 240)` → sRGB `#66A4EF`. Pass 2 replaces this with precise components.

- [ ] **Step 9: Write `Packages/ViviraDesignSystem/Sources/ViviraDesignSystem/Tokens/DesignTokens.swift`**

```swift
import SwiftUI

public extension Color {
    enum vivira {
        public static let bg    = Color("vivira.bg",    bundle: .module)
        public static let ink2  = Color("vivira.ink2",  bundle: .module)
        public static let faint = Color("vivira.faint", bundle: .module)
    }
}

public extension CGFloat {
    enum vivira {
        public static let xs:     CGFloat = 4
        public static let sm:     CGFloat = 8
        public static let md:     CGFloat = 16
        public static let mdPlus: CGFloat = 20
        public static let lg:     CGFloat = 24
        public static let xl:     CGFloat = 32
        public static let xxxl:   CGFloat = 48

        public enum radius {
            public static let md: CGFloat = 10
            public static let lg: CGFloat = 14
        }
    }
}
```

The remaining six neutral accessors (`surface`, `surface2`, `ink`, `muted`, `line`, `lineStrong`) land in Pass 2 Task 9.

- [ ] **Step 10: Build the package from the command line**

Run:

```bash
swift build --package-path Packages/ViviraDesignSystem
```

Expected: succeeds with no warnings. The output ends with `Build complete!`.

- [ ] **Step 11: Commit**

```bash
git add Packages/ViviraDesignSystem
git commit -m "feat(ds): SPM package skeleton with neutrals and 5 colorsets"
```

---

### Task 2: Typography and Theme tokens

**Files:**
- Create: `Packages/ViviraDesignSystem/Sources/ViviraDesignSystem/Tokens/Typography.swift`
- Create: `Packages/ViviraDesignSystem/Sources/ViviraDesignSystem/Tokens/Theme.swift`

- [ ] **Step 1: Write `Typography.swift`**

```swift
import SwiftUI

public extension Font {
    enum vivira {
        public static let displayLarge: Font = .system(.largeTitle, design: .default, weight: .bold)
        public static let body:         Font = .system(.body,       design: .default, weight: .regular)
        public static let bodyBold:     Font = .system(.body,       design: .default, weight: .semibold)
        public static let headline:     Font = .system(.headline,   design: .default, weight: .semibold)
    }
}
```

Binding the styles to `largeTitle`, `body`, `headline` inherits Dynamic Type automatically per design system §10.1.

- [ ] **Step 2: Write `Theme.swift`**

```swift
import SwiftUI

public enum Theme: String, CaseIterable, Codable, Sendable {
    case lumen, pomelo, iris, aqua, magenta

    public var displayName: String {
        switch self {
        case .lumen:   return String(localized: "Lumen")
        case .pomelo:  return String(localized: "Pomelo")
        case .iris:    return String(localized: "Iris")
        case .aqua:    return String(localized: "Aqua")
        case .magenta: return String(localized: "Magenta")
        }
    }
}

extension EnvironmentValues {
    @Entry public var viviraTheme: Theme = .lumen
}
```

- [ ] **Step 3: Build the package**

Run:

```bash
swift build --package-path Packages/ViviraDesignSystem
```

Expected: succeeds with no warnings.

- [ ] **Step 4: Commit**

```bash
git add Packages/ViviraDesignSystem/Sources/ViviraDesignSystem/Tokens/Typography.swift \
        Packages/ViviraDesignSystem/Sources/ViviraDesignSystem/Tokens/Theme.swift
git commit -m "feat(ds): typography tokens + Theme enum with environment value"
```

---

### Task 3: AccentColor semantic style

**Files:**
- Create: `Packages/ViviraDesignSystem/Sources/ViviraDesignSystem/Tokens/SemanticColor.swift`

- [ ] **Step 1: Write `SemanticColor.swift`**

```swift
import SwiftUI

public struct AccentColor: ShapeStyle, Sendable {
    public init() {}

    public func resolve(in environment: EnvironmentValues) -> some ShapeStyle {
        let theme = environment.viviraTheme
        let mode = environment.colorScheme == .dark ? "dark" : "light"
        return Color("accent.\(theme.rawValue).\(mode)", bundle: .module)
    }
}

public extension ShapeStyle where Self == AccentColor {
    static var accent: AccentColor { AccentColor() }
}
```

Per design system §8.4. The `resolve(in:)` reads the current `viviraTheme` and `colorScheme` from the SwiftUI environment and returns the matching asset-catalog entry. In Pass 1 only Lumen has entries, so flipping `\.viviraTheme` to other themes will miss the catalog and SwiftUI will log an asset-not-found warning. Pass 2 Task 8 fills in the remaining 8 accent colorsets.

- [ ] **Step 2: Build the package**

Run:

```bash
swift build --package-path Packages/ViviraDesignSystem
```

Expected: succeeds with no warnings.

- [ ] **Step 3: Commit**

```bash
git add Packages/ViviraDesignSystem/Sources/ViviraDesignSystem/Tokens/SemanticColor.swift
git commit -m "feat(ds): AccentColor ShapeStyle resolves (theme, colorScheme) → asset catalog"
```

---

### Task 4: Icon atom

**Files:**
- Create: `Packages/ViviraDesignSystem/Sources/ViviraDesignSystem/Atoms/Icon.swift`

- [ ] **Step 1: Write `Icon.swift`**

```swift
import SwiftUI

public struct Icon: View {
    private let symbol: String
    private let size: CGFloat
    private let weight: Font.Weight

    public init(symbol: String, size: CGFloat = 17, weight: Font.Weight = .regular) {
        self.symbol = symbol
        self.size = size
        self.weight = weight
    }

    public var body: some View {
        Image(systemName: symbol)
            .font(.system(size: size, weight: weight))
            .accessibilityHidden(true)
    }
}
```

`.accessibilityHidden(true)` so VoiceOver treats the icon as decoration; the parent composes the spoken label. The empty state uses one icon at 48pt with `Color.vivira.faint` foreground (applied at the call site via `.foregroundStyle`).

- [ ] **Step 2: Build the package**

Run:

```bash
swift build --package-path Packages/ViviraDesignSystem
```

Expected: succeeds with no warnings.

- [ ] **Step 3: Commit**

```bash
git add Packages/ViviraDesignSystem/Sources/ViviraDesignSystem/Atoms/Icon.swift
git commit -m "feat(ds): Icon atom — SF Symbols wrapper"
```

---

### Task 5: ViviraButton atom (`.accent` role only)

**Files:**
- Create: `Packages/ViviraDesignSystem/Sources/ViviraDesignSystem/Atoms/ViviraButton.swift`

- [ ] **Step 1: Write `ViviraButton.swift`**

```swift
import SwiftUI

public struct ViviraButton<Label: View>: View {
    public enum Role: Sendable {
        case accent
    }

    private let role: Role
    private let action: () -> Void
    private let label: Label

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isPressed = false

    public init(
        role: Role = .accent,
        action: @escaping () -> Void,
        @ViewBuilder label: () -> Label
    ) {
        self.role = role
        self.action = action
        self.label = label()
    }

    public var body: some View {
        Button(action: action) {
            label
                .font(.vivira.bodyBold)
                .lineLimit(1)
                .frame(maxWidth: .infinity, minHeight: 44)
                .padding(.horizontal, .vivira.mdPlus)
                .foregroundStyle(Color.vivira.bg)
                .background(.accent, in: RoundedRectangle(cornerRadius: .vivira.radius.md))
        }
        .buttonStyle(ViviraButtonStyle(reduceMotion: reduceMotion))
        .accessibilityAddTraits(.isButton)
    }
}

private struct ViviraButtonStyle: ButtonStyle {
    let reduceMotion: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.6 : 1.0)
            .animation(reduceMotion ? .none : .easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

public extension ViviraButton where Label == Text {
    init(_ titleKey: LocalizedStringKey, role: Role = .accent, action: @escaping () -> Void) {
        self.init(role: role, action: action) {
            Text(titleKey)
        }
    }
}
```

Only the `.accent` role exists. Adding `.primary`, `.secondary`, `.ghost`, `.destructive` later means extending the `Role` enum, adding cases to `body`, and exhausting the switch — out of scope for the bullet.

- [ ] **Step 2: Build the package**

Run:

```bash
swift build --package-path Packages/ViviraDesignSystem
```

Expected: succeeds with no warnings.

- [ ] **Step 3: Commit**

```bash
git add Packages/ViviraDesignSystem/Sources/ViviraDesignSystem/Atoms/ViviraButton.swift
git commit -m "feat(ds): ViviraButton atom (.accent role)"
```

---

### Task 6: EmptyState molecule

**Files:**
- Create: `Packages/ViviraDesignSystem/Sources/ViviraDesignSystem/Molecules/EmptyState.swift`

- [ ] **Step 1: Write `EmptyState.swift`**

```swift
import SwiftUI

public struct EmptyState: View {
    private let symbol: String
    private let message: LocalizedStringKey
    private let ctaLabel: LocalizedStringKey
    private let action: () -> Void

    public init(
        symbol: String,
        message: LocalizedStringKey,
        ctaLabel: LocalizedStringKey,
        action: @escaping () -> Void
    ) {
        self.symbol = symbol
        self.message = message
        self.ctaLabel = ctaLabel
        self.action = action
    }

    public var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: .vivira.xxxl)

            Icon(symbol: symbol, size: 48)
                .foregroundStyle(Color.vivira.faint)

            Spacer().frame(height: .vivira.lg)

            Text(message)
                .font(.vivira.body)
                .foregroundStyle(Color.vivira.ink2)
                .multilineTextAlignment(.center)

            Spacer().frame(height: .vivira.xl)

            ViviraButton(ctaLabel, action: action)
                .padding(.horizontal, .vivira.md)

            Spacer(minLength: .vivira.xxxl)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
```

`Spacer(minLength:)` at top and bottom plus `Spacer().frame(height:)` between elements gives the molecule the centered-with-rhythm layout from design system §6.5 without depending on geometry readers.

- [ ] **Step 2: Build the package**

Run:

```bash
swift build --package-path Packages/ViviraDesignSystem
```

Expected: succeeds with no warnings.

- [ ] **Step 3: Commit**

```bash
git add Packages/ViviraDesignSystem/Sources/ViviraDesignSystem/Molecules/EmptyState.swift
git commit -m "feat(ds): EmptyState molecule"
```

---

### Task 7: Wire the package into the app and render the empty state

**Files:**
- Modify: `project.yml`
- Modify: `Vivira/ViviraApp.swift`
- Modify: `Vivira/ContentView.swift`

- [ ] **Step 1: Add the local SPM package to `project.yml`**

Replace the entire contents of `project.yml` with:

```yaml
name: Vivira
options:
  bundleIdPrefix: cc
  deploymentTarget:
    iOS: "26.5"
  createIntermediateGroups: true
  generateEmptyDirectories: true
settings:
  base:
    SWIFT_VERSION: "6"
    DEVELOPMENT_TEAM: ""
    MARKETING_VERSION: "0.1.0"
    CURRENT_PROJECT_VERSION: "1"
    SWIFT_APPROACHABLE_CONCURRENCY: YES
    SWIFT_DEFAULT_ACTOR_ISOLATION: MainActor
packages:
  ViviraDesignSystem:
    path: Packages/ViviraDesignSystem
targets:
  Vivira:
    type: application
    platform: iOS
    sources:
      - path: Vivira
    dependencies:
      - package: ViviraDesignSystem
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: cc.vivira
        GENERATE_INFOPLIST_FILE: YES
        INFOPLIST_KEY_UILaunchScreen_Generation: YES
        INFOPLIST_KEY_UIApplicationSceneManifest_Generation: YES
        INFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone: "UIInterfaceOrientationPortrait UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight"
        INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad: "UIInterfaceOrientationPortrait UIInterfaceOrientationPortraitUpsideDown UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight"
        TARGETED_DEVICE_FAMILY: "1,2"
        DEVELOPMENT_ASSET_PATHS: "\"Vivira/Preview Content\""
  ViviraTests:
    type: bundle.unit-test
    platform: iOS
    sources:
      - path: ViviraTests
    dependencies:
      - target: Vivira
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: cc.vivira.tests
        GENERATE_INFOPLIST_FILE: YES
```

Two changes from the original: a `packages:` block declaring `ViviraDesignSystem` at the local path, and a `dependencies: [package: ViviraDesignSystem]` line on the `Vivira` target.

- [ ] **Step 2: Replace `Vivira/ViviraApp.swift`**

```swift
import SwiftUI
import ViviraDesignSystem

@main
struct ViviraApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.viviraTheme, .lumen)
        }
    }
}
```

Pass 1 hard-codes Lumen. Pass 2 Task 12 replaces this with `ThemeStorage`.

- [ ] **Step 3: Replace `Vivira/ContentView.swift`**

```swift
import SwiftUI
import ViviraDesignSystem

struct ContentView: View {
    var body: some View {
        NavigationStack {
            EmptyState(
                symbol: "photo.on.rectangle.angled",
                message: "Vivira keeps Immich shared albums\nin sync with your iPhone.",
                ctaLabel: "Add a server",
                action: { print("add-server tapped") }
            )
            .background(Color.vivira.bg.ignoresSafeArea())
        }
    }
}

#Preview {
    ContentView()
        .environment(\.viviraTheme, .lumen)
}
```

The `NavigationStack` is forward-compatible with the onboarding wizard (UX flow §4) but routes nowhere in the bullet.

- [ ] **Step 4: Regenerate the Xcode project**

Run:

```bash
mise run generate
```

Expected: `xcodegen` reports `Created project at /…/Vivira.xcodeproj`.

- [ ] **Step 5: Build the app**

Run:

```bash
mise run build
```

Expected: build succeeds. `xcbeautify` reports no errors. Warning count should match the baseline before the bullet started (zero compiler warnings introduced by this task).

- [ ] **Step 6: Run the app on simulator**

```bash
mise run open
```

In Xcode, select the `Vivira` scheme + iPhone 17 simulator, ⌘R. The simulator boots and renders the empty state: photo icon centered, two lines of body copy underneath, the "Add a server" button below in Lumen accent (electric blue).

Verify:
- Toggling system appearance (Settings → Developer → Dark Appearance, or `xcrun simctl ui booted appearance dark`) flips the background, the body copy, the icon, and the accent button to their dark variants.
- Tapping the "Add a server" button prints `add-server tapped` to the Xcode console.

- [ ] **Step 7: Commit**

```bash
git add project.yml Vivira/ViviraApp.swift Vivira/ContentView.swift
git commit -m "feat(app): wire ViviraDesignSystem and render NotConnected empty state"
```

Pass 1 complete: visible end-to-end bullet, Lumen only, no tests yet.

---

## Phase 2 — Pass 2: Thicken

### Task 8: Colorset generator script and full 19-colorset regeneration

**Files:**
- Create: `tools/colors-source.json`
- Create: `tools/package.json`
- Create: `tools/oklch-to-p3.mjs`
- Modify: `mise.toml` (new `gen-colors` task, standalone)
- Replace: all `Contents.json` files under `Packages/ViviraDesignSystem/Sources/ViviraDesignSystem/Resources/ViviraColors.xcassets/` (existing 5 are regenerated; 14 new directories created)

- [ ] **Step 1: Write `tools/colors-source.json`**

```json
{
  "neutrals": {
    "vivira.bg":         { "light": "#F5F7FA", "dark": "#07090C" },
    "vivira.surface":    { "light": "#FFFFFF", "dark": "#11161C" },
    "vivira.surface2":   { "light": "#EDF1F6", "dark": "#161D26" },
    "vivira.ink":        { "light": "#0F1419", "dark": "#E8EDF2" },
    "vivira.ink2":       { "light": "#2D3A47", "dark": "#B5BFC9" },
    "vivira.muted":      { "light": "#5B6770", "dark": "#94A1AD" },
    "vivira.faint":      { "light": "#8A95A2", "dark": "#5C6A76" },
    "vivira.line":       { "light": "#E1E7EF", "dark": "#1F2832" },
    "vivira.lineStrong": { "light": "#C9D1DA", "dark": "#2A3441" }
  },
  "accents": {
    "lumen":   { "light": "oklch(60% 0.18 240)", "dark": "oklch(75% 0.16 240)" },
    "pomelo":  { "light": "oklch(64% 0.18 35)",  "dark": "oklch(76% 0.15 35)"  },
    "iris":    { "light": "oklch(52% 0.22 280)", "dark": "oklch(72% 0.19 280)" },
    "aqua":    { "light": "oklch(60% 0.16 200)", "dark": "oklch(75% 0.14 200)" },
    "magenta": { "light": "oklch(62% 0.22 335)", "dark": "oklch(76% 0.18 335)" }
  }
}
```

Sources: design system §2.1.1 (neutrals) and §2.1.2 (accent oklch).

- [ ] **Step 2: Write `tools/package.json`**

```json
{
  "name": "vivira-color-tools",
  "version": "1.0.0",
  "private": true,
  "type": "module",
  "dependencies": {
    "colorjs.io": "^0.5.2"
  }
}
```

- [ ] **Step 3: Install the Node dependency**

Run:

```bash
cd tools && npm install && cd ..
```

Expected: `node_modules/colorjs.io/` exists. The plan ignores `tools/node_modules` via `.gitignore` (next step).

- [ ] **Step 4: Add `tools/node_modules` to `.gitignore`**

Append to `.gitignore`:

```
# Local Node dependencies for the colorset generator (run `cd tools && npm install` when colors change)
tools/node_modules
```

- [ ] **Step 5: Write `tools/oklch-to-p3.mjs`**

```javascript
#!/usr/bin/env node
// Regenerate the ViviraColors.xcassets colorsets from tools/colors-source.json.
// Reads oklch and hex values, emits Display P3 components into each colorset's Contents.json.

import { readFileSync, writeFileSync, mkdirSync, existsSync } from "node:fs";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import Color from "colorjs.io";

const __dirname = dirname(fileURLToPath(import.meta.url));
const repoRoot = resolve(__dirname, "..");
const assetCatalog = resolve(
  repoRoot,
  "Packages/ViviraDesignSystem/Sources/ViviraDesignSystem/Resources/ViviraColors.xcassets"
);
const source = JSON.parse(
  readFileSync(resolve(__dirname, "colors-source.json"), "utf8")
);

function toP3Components(value) {
  const c = new Color(value).to("p3");
  const [r, g, b] = c.coords.map((v) => Math.max(0, Math.min(1, v)));
  return {
    alpha: "1.000",
    red: r.toFixed(3),
    green: g.toFixed(3),
    blue: b.toFixed(3),
  };
}

function writeColorset(path, contents) {
  if (!existsSync(path)) mkdirSync(path, { recursive: true });
  writeFileSync(resolve(path, "Contents.json"), JSON.stringify(contents, null, 2) + "\n");
}

function neutralColorset(light, dark) {
  return {
    colors: [
      {
        color: {
          "color-space": "display-p3",
          components: toP3Components(light),
        },
        idiom: "universal",
      },
      {
        appearances: [{ appearance: "luminosity", value: "dark" }],
        color: {
          "color-space": "display-p3",
          components: toP3Components(dark),
        },
        idiom: "universal",
      },
    ],
    info: { author: "xcode", version: 1 },
  };
}

function accentColorset(oklch) {
  return {
    colors: [
      {
        color: {
          "color-space": "display-p3",
          components: toP3Components(oklch),
        },
        idiom: "universal",
      },
    ],
    info: { author: "xcode", version: 1 },
  };
}

// Neutrals
for (const [name, variants] of Object.entries(source.neutrals)) {
  const path = resolve(assetCatalog, `${name}.colorset`);
  writeColorset(path, neutralColorset(variants.light, variants.dark));
  console.log(`wrote ${name}.colorset`);
}

// Accents — one colorset per theme × mode
for (const [theme, variants] of Object.entries(source.accents)) {
  for (const mode of ["light", "dark"]) {
    const name = `accent.${theme}.${mode}`;
    const path = resolve(assetCatalog, `${name}.colorset`);
    writeColorset(path, accentColorset(variants[mode]));
    console.log(`wrote ${name}.colorset`);
  }
}

console.log("done.");
```

The script:
1. Reads the source JSON.
2. For each neutral, writes a single colorset with `any` + `dark` appearance entries in Display P3 components.
3. For each accent, writes two colorsets — `accent.<theme>.light` and `accent.<theme>.dark` — each with one universal entry (the resolver picks which colorset to read based on system color scheme).

- [ ] **Step 6: Add the `gen-colors` task to `mise.toml`**

Append the following at the bottom of `mise.toml`:

```toml
[tasks.gen-colors]
description = "Regenerate ViviraColors.xcassets from tools/colors-source.json (one-off; run when colors change)"
run = """
set -euo pipefail
if [ ! -d tools/node_modules ]; then
  (cd tools && npm install)
fi
node tools/oklch-to-p3.mjs
"""
```

Standalone. The existing `generate` and `build` tasks do not depend on it.

- [ ] **Step 7: Run the generator**

```bash
mise run gen-colors
```

Expected output lists each colorset written:

```
wrote vivira.bg.colorset
wrote vivira.surface.colorset
…
wrote accent.lumen.light.colorset
wrote accent.lumen.dark.colorset
…
wrote accent.magenta.dark.colorset
done.
```

19 colorsets total (9 neutrals + 10 accent variants).

- [ ] **Step 8: Verify the asset catalog is intact**

Run:

```bash
ls Packages/ViviraDesignSystem/Sources/ViviraDesignSystem/Resources/ViviraColors.xcassets/ | sort
```

Expected output:

```
Contents.json
accent.aqua.dark.colorset
accent.aqua.light.colorset
accent.iris.dark.colorset
accent.iris.light.colorset
accent.lumen.dark.colorset
accent.lumen.light.colorset
accent.magenta.dark.colorset
accent.magenta.light.colorset
accent.pomelo.dark.colorset
accent.pomelo.light.colorset
vivira.bg.colorset
vivira.faint.colorset
vivira.ink.colorset
vivira.ink2.colorset
vivira.line.colorset
vivira.lineStrong.colorset
vivira.muted.colorset
vivira.surface.colorset
vivira.surface2.colorset
```

20 entries (1 root `Contents.json` + 19 colorset directories).

- [ ] **Step 9: Build to verify the asset catalog resolves**

```bash
mise run build
```

Expected: build succeeds. The hand-authored `srgb` colorsets from Task 1 have now been replaced by `display-p3` regenerations; the existing `Color.vivira.bg`, `vivira.ink2`, `vivira.faint`, and the resolver's `accent.lumen.light/dark` references still resolve.

- [ ] **Step 10: Run the app and verify visually**

```bash
mise run open
```

In Xcode, run on iPhone 17 simulator. The empty state still renders correctly. The Lumen accent button may look slightly more saturated than before (P3 has a wider gamut than sRGB).

- [ ] **Step 11: Commit**

```bash
git add tools/colors-source.json tools/package.json tools/oklch-to-p3.mjs \
        .gitignore mise.toml \
        Packages/ViviraDesignSystem/Sources/ViviraDesignSystem/Resources/ViviraColors.xcassets
git commit -m "feat(tools): oklch→P3 generator; regenerate all 19 colorsets"
```

---

### Task 9: Add the remaining six neutral tokens

**Files:**
- Modify: `Packages/ViviraDesignSystem/Sources/ViviraDesignSystem/Tokens/DesignTokens.swift`

- [ ] **Step 1: Add the 6 missing neutral accessors**

Replace the `Color.vivira` enum in `DesignTokens.swift` so it lists all 9 neutrals:

```swift
public extension Color {
    enum vivira {
        public static let bg          = Color("vivira.bg",          bundle: .module)
        public static let surface     = Color("vivira.surface",     bundle: .module)
        public static let surface2    = Color("vivira.surface2",    bundle: .module)
        public static let ink         = Color("vivira.ink",         bundle: .module)
        public static let ink2        = Color("vivira.ink2",        bundle: .module)
        public static let muted       = Color("vivira.muted",       bundle: .module)
        public static let faint       = Color("vivira.faint",       bundle: .module)
        public static let line        = Color("vivira.line",        bundle: .module)
        public static let lineStrong  = Color("vivira.lineStrong",  bundle: .module)
    }
}
```

(The `CGFloat.vivira` block above stays as it was.)

- [ ] **Step 2: Build**

```bash
swift build --package-path Packages/ViviraDesignSystem
```

Expected: succeeds. None of these are consumed yet by the empty state, but the resolution at app build verifies all 9 colorsets are reachable.

- [ ] **Step 3: Commit**

```bash
git add Packages/ViviraDesignSystem/Sources/ViviraDesignSystem/Tokens/DesignTokens.swift
git commit -m "feat(ds): expose remaining neutral color tokens"
```

---

### Task 10: Add the test target and the snapshot-testing dependency

**Files:**
- Modify: `Packages/ViviraDesignSystem/Package.swift`
- Create: `Packages/ViviraDesignSystem/Tests/ViviraDesignSystemTests/` (empty for now)

- [ ] **Step 1: Create the empty test directory**

```bash
mkdir -p Packages/ViviraDesignSystem/Tests/ViviraDesignSystemTests
```

- [ ] **Step 2: Replace `Package.swift`**

```swift
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ViviraDesignSystem",
    platforms: [
        .iOS("26.5"),
        .macOS(.v15)
    ],
    products: [
        .library(name: "ViviraDesignSystem", targets: ["ViviraDesignSystem"])
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-snapshot-testing", from: "1.17.0")
    ],
    targets: [
        .target(
            name: "ViviraDesignSystem",
            resources: [.process("Resources/ViviraColors.xcassets")]
        ),
        .testTarget(
            name: "ViviraDesignSystemTests",
            dependencies: [
                "ViviraDesignSystem",
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing")
            ]
        )
    ]
)
```

- [ ] **Step 3: Resolve dependencies and confirm the manifest parses**

```bash
swift package --package-path Packages/ViviraDesignSystem resolve
```

Expected: `Fetching https://github.com/pointfreeco/swift-snapshot-testing` followed by the matching version line and `swift-snapshot-testing` being added to `Package.resolved`. No errors.

- [ ] **Step 4: Commit**

```bash
git add Packages/ViviraDesignSystem/Package.swift \
        Packages/ViviraDesignSystem/Package.resolved \
        Packages/ViviraDesignSystem/Tests
git commit -m "build(ds): add test target with swift-snapshot-testing dep"
```

---

### Task 11: ThemeStorage with TDD

**Files:**
- Create: `Packages/ViviraDesignSystem/Tests/ViviraDesignSystemTests/ThemeStorageTests.swift`
- Create: `Packages/ViviraDesignSystem/Sources/ViviraDesignSystem/Tokens/ThemeStorage.swift`

- [ ] **Step 1: Write the failing test file**

File: `Packages/ViviraDesignSystem/Tests/ViviraDesignSystemTests/ThemeStorageTests.swift`

```swift
import Foundation
import Testing
@testable import ViviraDesignSystem

@MainActor
@Suite struct ThemeStorageTests {

    @Test func defaultsToLumenWhenStorageEmpty() {
        let suite = UserDefaults(suiteName: UUID().uuidString)!
        let storage = ThemeStorage(userDefaults: suite)
        #expect(storage.current == .lumen)
    }

    @Test func writesToUserDefaultsOnSet() {
        let suite = UserDefaults(suiteName: UUID().uuidString)!
        let storage = ThemeStorage(userDefaults: suite)
        storage.current = .iris
        #expect(suite.string(forKey: ThemeStorage.userDefaultsKey) == "iris")
    }

    @Test func readsBackTheStoredTheme() {
        let suiteName = UUID().uuidString
        let writer = UserDefaults(suiteName: suiteName)!
        let storageA = ThemeStorage(userDefaults: writer)
        storageA.current = .magenta

        let reader = UserDefaults(suiteName: suiteName)!
        let storageB = ThemeStorage(userDefaults: reader)
        #expect(storageB.current == .magenta)
    }

    @Test func fallsBackToLumenForInvalidStoredString() {
        let suite = UserDefaults(suiteName: UUID().uuidString)!
        suite.set("not-a-theme", forKey: ThemeStorage.userDefaultsKey)
        let storage = ThemeStorage(userDefaults: suite)
        #expect(storage.current == .lumen)
    }
}
```

- [ ] **Step 2: Run the tests to confirm they fail to compile**

```bash
swift test --package-path Packages/ViviraDesignSystem 2>&1 | head -20
```

Expected: compile error mentioning `cannot find 'ThemeStorage' in scope` or similar. The implementation does not exist yet.

- [ ] **Step 3: Write the minimal implementation**

File: `Packages/ViviraDesignSystem/Sources/ViviraDesignSystem/Tokens/ThemeStorage.swift`

```swift
import Foundation
import SwiftUI

@MainActor
public final class ThemeStorage: ObservableObject {
    public static let userDefaultsKey = "ViviraDesignSystem.theme"

    @Published public var current: Theme {
        didSet {
            userDefaults.set(current.rawValue, forKey: Self.userDefaultsKey)
        }
    }

    private let userDefaults: UserDefaults

    public init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        let stored = userDefaults.string(forKey: Self.userDefaultsKey)
        self.current = Theme(rawValue: stored ?? "") ?? .lumen
    }
}
```

`Theme(rawValue: stored ?? "")` returns `nil` for both the missing-key case and the invalid-string case, so the `?? .lumen` fallback covers both.

- [ ] **Step 4: Run the tests to confirm they pass**

```bash
swift test --package-path Packages/ViviraDesignSystem
```

Expected: `Test Suite 'All tests' passed at …`. Four `@Test` cases pass.

- [ ] **Step 5: Commit**

```bash
git add Packages/ViviraDesignSystem/Sources/ViviraDesignSystem/Tokens/ThemeStorage.swift \
        Packages/ViviraDesignSystem/Tests/ViviraDesignSystemTests/ThemeStorageTests.swift
git commit -m "feat(ds): ThemeStorage with UserDefaults round-trip + tests"
```

---

### Task 12: Wire `ThemeStorage` into `ViviraApp`

**Files:**
- Modify: `Vivira/ViviraApp.swift`

- [ ] **Step 1: Replace `ViviraApp.swift`**

```swift
import SwiftUI
import ViviraDesignSystem

@main
struct ViviraApp: App {
    @StateObject private var themeStorage = ThemeStorage()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.viviraTheme, themeStorage.current)
                .environmentObject(themeStorage)
        }
    }
}
```

`ThemeStorage` is owned by the app via `@StateObject` (the canonical pattern for `ObservableObject` instances owned by a view's lifecycle). `\.viviraTheme` reads from `themeStorage.current`, and `.environmentObject(themeStorage)` makes the storage itself available to descendants (the future theme picker will toggle it).

- [ ] **Step 2: Build and run**

```bash
mise run build
mise run open
```

Run on iPhone 17. The empty state renders identically to the end of Task 7 (theme defaults to Lumen because `UserDefaults` is empty on a fresh install).

- [ ] **Step 3: Verify cross-theme resolution by temporary edit**

For each of the 5 themes, temporarily change the env injection in `ViviraApp.swift` from `themeStorage.current` to a hard-coded theme, rebuild, and observe the simulator. Do this once for each theme:

```swift
.environment(\.viviraTheme, .pomelo)    // electric coral on the button
.environment(\.viviraTheme, .iris)      // deep indigo-violet
.environment(\.viviraTheme, .aqua)      // fresh cyan
.environment(\.viviraTheme, .magenta)   // vivid pink-magenta
```

Toggle system appearance light ↔ dark for each theme and confirm both modes render. After the 5-theme sweep, restore the original line `.environment(\.viviraTheme, themeStorage.current)` and rebuild once more. This is a manual smoke test that exits as it entered — no temporary edits should remain.

- [ ] **Step 4: Commit**

```bash
git add Vivira/ViviraApp.swift
git commit -m "feat(app): wire ThemeStorage as the source of \\.viviraTheme"
```

---

### Task 13: EmptyState snapshot tests (Lumen light + dark)

**Files:**
- Create: `Packages/ViviraDesignSystem/Tests/ViviraDesignSystemTests/EmptyStateSnapshotTests.swift`
- Create: `Packages/ViviraDesignSystem/Tests/ViviraDesignSystemTests/__Snapshots__/EmptyStateSnapshotTests/emptyState_lumen_light.1.png`
- Create: `Packages/ViviraDesignSystem/Tests/ViviraDesignSystemTests/__Snapshots__/EmptyStateSnapshotTests/emptyState_lumen_dark.1.png`

- [ ] **Step 1: Write the snapshot test file**

```swift
import SnapshotTesting
import SwiftUI
import Testing
@testable import ViviraDesignSystem

@MainActor
@Suite struct EmptyStateSnapshotTests {

    @Test func emptyState_lumen_light() {
        let view = EmptyState(
            symbol: "photo.on.rectangle.angled",
            message: "Vivira keeps Immich shared albums\nin sync with your iPhone.",
            ctaLabel: "Add a server",
            action: {}
        )
        .environment(\.viviraTheme, .lumen)
        .background(Color.vivira.bg)
        .frame(width: 393, height: 852)
        .preferredColorScheme(.light)

        assertSnapshot(of: view, as: .image)
    }

    @Test func emptyState_lumen_dark() {
        let view = EmptyState(
            symbol: "photo.on.rectangle.angled",
            message: "Vivira keeps Immich shared albums\nin sync with your iPhone.",
            ctaLabel: "Add a server",
            action: {}
        )
        .environment(\.viviraTheme, .lumen)
        .background(Color.vivira.bg)
        .frame(width: 393, height: 852)
        .preferredColorScheme(.dark)

        assertSnapshot(of: view, as: .image)
    }
}
```

Dimensions 393 × 852 match the iPhone 17 portrait safe area approximately.

- [ ] **Step 2: First run records the reference snapshots**

Snapshot tests fail on the first run because no reference image exists; the library writes the image to disk so the next run can compare. Tell the engineer this explicitly so the first failure does not look like a real regression.

Run:

```bash
mise run test
```

Expected on the first run: tests fail with messages like:

```
Snapshot 'emptyState_lumen_light' was not found on disk. Use 'record: true' or run the test again to record.
…
```

The library records the image at `Packages/ViviraDesignSystem/Tests/ViviraDesignSystemTests/__Snapshots__/EmptyStateSnapshotTests/emptyState_lumen_light.1.png` and the dark counterpart.

- [ ] **Step 3: Inspect the recorded images manually**

Open the two PNGs in any image viewer and confirm:
- Light snapshot shows the photo icon (faint grey on a near-white background), two lines of body copy (dark ink), and the Lumen accent button (electric blue).
- Dark snapshot shows the same composition with dark background, lighter ink, and the dark-mode Lumen accent.

If either image is wrong (e.g., wrong color, missing element), delete both PNGs, fix the implementation, and re-run.

- [ ] **Step 4: Re-run to verify the tests pass against the recorded baseline**

```bash
mise run test
```

Expected: `Test Suite 'All tests' passed`. The snapshot tests now compare against the recorded baseline.

- [ ] **Step 5: Commit**

```bash
git add Packages/ViviraDesignSystem/Tests/ViviraDesignSystemTests/EmptyStateSnapshotTests.swift \
        Packages/ViviraDesignSystem/Tests/ViviraDesignSystemTests/__Snapshots__
git commit -m "test(ds): EmptyState snapshot baseline — Lumen light + dark"
```

---

### Task 14: Final verification against acceptance criteria

**Files:**
- (none — this is a verification task that produces no edits unless something is broken)

- [ ] **Step 1: Build**

```bash
mise run build
```

Expected: succeeds with no new warnings versus baseline.

- [ ] **Step 2: Test**

```bash
mise run test
```

Expected: passes including 4 `ThemeStorage` cases + 2 `EmptyState` snapshots + the existing `Vivira/ViviraTests.swift` smoke. Output line ends with `Test Suite 'All tests' passed`.

- [ ] **Step 3: Lint**

```bash
mise run lint
```

Expected: SwiftLint reports zero violations. If new violations were introduced (rare for the bullet's content but possible), fix them and re-run.

- [ ] **Step 4: Cold-run a clean simulator boot**

```bash
xcrun simctl shutdown booted 2>/dev/null || true
xcrun simctl erase "iPhone 17"
mise run open
```

In Xcode, hit ⌘R. Verify:
- The empty state renders without any console output mentioning "No image named" or asset-not-found warnings.
- Toggling system appearance (Control Center → light/dark) animates the colors live.
- Tapping the "Add a server" button logs `add-server tapped` and does nothing else.

- [ ] **Step 5: Verify the clean-clone story**

Stash any local untracked artifacts, then simulate a clean clone in a scratch directory:

```bash
SCRATCH=$(mktemp -d)
git clone . "$SCRATCH/vivira"
cd "$SCRATCH/vivira"
mise run bootstrap
mise run build
```

Expected: `bootstrap` installs `swiftlint` + `xcbeautify`, generates `Vivira.xcodeproj`, and `build` succeeds end-to-end. No `gen-colors` step is needed because the `Contents.json` files are committed. Node is not required.

After verification, return to the working tree and remove the scratch:

```bash
cd -
rm -rf "$SCRATCH"
```

- [ ] **Step 6: Bullet complete — no commit needed unless a fix was made**

If steps 1–5 all passed without changes, the bullet meets every acceptance criterion in spec §5. If a fix was needed, commit it with a message like `fix(<area>): <one-line>` and re-run the relevant verification step.

---

## End-of-bullet checklist (mirror of spec §5)

- [ ] `mise run build` succeeds with no new warnings.
- [ ] `mise run test` passes (4 `ThemeStorage` + 2 `EmptyStateSnapshotTests` + existing `ViviraTests.smoke`).
- [ ] `mise run lint` passes.
- [ ] The app boots on iPhone 17 simulator and renders the empty state per UX flow §12.1.
- [ ] Toggling system appearance light ↔ dark changes the colors at runtime, including the accent on the button.
- [ ] Manually setting `\.viviraTheme` to each of the 5 themes in code changes the button's accent color (verified via temporary edit in Task 12 Step 3).
- [ ] `Bundle.module` resolves — no asset-not-found warnings in the console.
- [ ] A clean clone succeeds with `mise run bootstrap && mise run build` and no further manual steps.

## Follow-up issues to file once the bullet lands

These come from spec §6.2 and should be filed as separate issues, not folded into the bullet:

1. Implement destructive, warn, success semantic roles + their soft mixers (needed for FailureBanner, SuccessBanner, DegradedBanner, TypedConfirmBlock, StateBadge).
2. Build the remaining four `ViviraButton` roles (`.primary`, `.secondary`, `.ghost`, `.destructive`).
3. Add high-contrast colorset variants for the 19 existing colorsets.
4. Add the 5 × 2 snapshot matrix for `EmptyState` plus per-atom snapshot tests.
5. Build the Settings → Appearance theme picker.
6. Decide the long-term home for `oklch-to-p3.mjs` — Node script or Swift port.
7. Add atoms and molecules the onboarding wizard needs (`WizardStepHeader`, `ViviraTextField`, `CapabilityChip`, `SegmentedPicker`, `InfoCard`, `Toggle`).
8. Define the runtime contract for "Vivira only touches what Vivira created" — UX paradigm §16 / UX flow §12.3 rule 1. Lives in the app data layer; candidate for its own spec.
