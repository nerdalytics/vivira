# Vivira Design System

**Status:** Draft (awaiting review)
**Date:** 2026-05-17
**Scope:** The visual, structural, and architectural rules for every screen and component in Vivira. Tokens, atoms, molecules, layout patterns, and the SwiftUI implementation that resolves them. Reads alongside the UX flow design and the UX paradigms — those define *what* Vivira does; this defines how it looks and how it gets built.

---

## How to use this doc

Read once front-to-back, then keep open during component implementation. §1 sets the personality. §2–§7 are the reference layer: token tables, atom signatures, molecule compositions, layout patterns. §8–§12 are the build layer: SwiftUI architecture, Penpot workflow, accessibility, naming. §13–§15 cover what's deliberately not in v1.

This document does not duplicate the UX flow design or the UX paradigms. Where they specify behavior or copy, this spec specifies appearance and structure. When in conflict, the UX paradigms doc wins.

---

## Decisions in one page

| Question | Answer |
|---|---|
| Aesthetic direction | **Foreground language** — clean, technical, photo-first |
| Themes | Five user-selectable: **Lumen** (default), **Pomelo**, **Iris**, **Aqua**, **Magenta** |
| Light + dark | Both shipped together, every token specified in both modes |
| Theme picker | Settings → Appearance only (not in onboarding) |
| Source of truth | **Swift canonical** — token values live in code; Penpot is a hand-maintained mirror |
| Color format | oklch in spec; Display P3 hex baked into Asset Catalog at authoring time |
| Module | One SPM package: `ViviraDesignSystem` |
| Accessibility | Full: Dynamic Type, VoiceOver, high contrast, reduce motion |
| Liquid Glass | Chrome only (toolbars, floating buttons); never on content surfaces |
| List layout default | Vertical photo card with bottom-fade affordance for content lists |

---

## 1. Aesthetic — the Foreground language

Vivira's chrome stays out of the way of the photos. Surfaces are quiet, typography is tight, and the only loud element on any screen is the accent — and even the accent is reserved for the primary action on that screen, not decoration.

Three rules govern every visual decision:

1. **Photos are the content; chrome is the frame.** Anything that competes with the user's photos for attention is wrong, regardless of how elegant it looks in isolation.
2. **Density follows seriousness.** Subscriptions carry real metadata (mode, counts, state). The list surface gives them room to breathe. Settings and utility rows compress; content rows do not.
3. **One loud color per surface.** The accent appears on the primary action, the active state, or one informational badge — not all three at once.

The personality is **Halide's discipline, applied to a sync utility.** Cousins worth referencing during review: Halide, Darkroom, Day One (for typography weight), Apple Photos chrome (for system-native scaffolding). What Vivira is not: brutalist, maximalist, retro, or playful. Distinctive but understated.

---

## 2. Token taxonomy

Six token sets. Each is referenced by every component in the system; nothing in the codebase hard-codes a color, font size, padding, radius, or duration outside these tables.

### 2.1 Color

#### 2.1.1 Neutrals (constant across themes)

| Token | Light hex | Dark hex | Use |
|---|---|---|---|
| `color.bg` | `#F5F7FA` | `#07090C` | Window background |
| `color.surface` | `#FFFFFF` | `#11161C` | Cards, sheets, list rows |
| `color.surface2` | `#EDF1F6` | `#161D26` | Subtle surface step (segmented control track, inline chips on surface) |
| `color.ink` | `#0F1419` | `#E8EDF2` | Primary text, primary button |
| `color.ink2` | `#2D3A47` | `#B5BFC9` | Secondary text |
| `color.muted` | `#5B6770` | `#94A1AD` | Tertiary text, mode lines, captions |
| `color.faint` | `#8A95A2` | `#5C6A76` | Disabled text, count metadata, dividers when text-adjacent |
| `color.line` | `#E1E7EF` | `#1F2832` | Hairline borders, dividers |
| `color.lineStrong` | `#C9D1DA` | `#2A3441` | Strong dividers, field borders |

Neutrals stay the same regardless of which theme the user picks. The light↔dark switch flips them per `ColorScheme`.

#### 2.1.2 Semantic accents (vary per theme)

Each theme defines four semantic colors. All are specified in oklch (perceptually uniform) at authoring time and converted to Display P3 components for the Asset Catalog. Softs are derived at runtime via `color-mix(in oklch, accent N%, surface)`.

The five themes share **the same hue zones** for destructive (red, H ~15–25), warn (amber, H ~75–90), success (green, H ~150–165). Only the accent hue truly varies across themes. Result: red always reads as destructive, regardless of which theme the user picks.

##### Lumen (default) — electric sky blue
| Role | Light oklch | Dark oklch |
|---|---|---|
| `accent` | `oklch(60% 0.18 240)` | `oklch(75% 0.16 240)` |
| `destructive` | `oklch(58% 0.20 25)` | `oklch(72% 0.16 25)` |
| `warn` | `oklch(72% 0.16 80)` | `oklch(82% 0.14 80)` |
| `success` | `oklch(60% 0.16 155)` | `oklch(72% 0.14 155)` |

##### Pomelo — warm coral
| Role | Light oklch | Dark oklch |
|---|---|---|
| `accent` | `oklch(64% 0.18 35)` | `oklch(76% 0.15 35)` |
| `destructive` | `oklch(55% 0.21 358)` | `oklch(70% 0.17 358)` |
| `warn` | `oklch(75% 0.16 90)` | `oklch(83% 0.14 90)` |
| `success` | `oklch(60% 0.15 165)` | `oklch(72% 0.14 165)` |

##### Iris — deep indigo-violet
| Role | Light oklch | Dark oklch |
|---|---|---|
| `accent` | `oklch(52% 0.22 280)` | `oklch(72% 0.19 280)` |
| `destructive` | `oklch(58% 0.21 15)` | `oklch(72% 0.17 15)` |
| `warn` | `oklch(72% 0.17 75)` | `oklch(82% 0.15 75)` |
| `success` | `oklch(58% 0.17 160)` | `oklch(72% 0.15 160)` |

##### Aqua — fresh cyan
| Role | Light oklch | Dark oklch |
|---|---|---|
| `accent` | `oklch(60% 0.16 200)` | `oklch(75% 0.14 200)` |
| `destructive` | `oklch(58% 0.21 15)` | `oklch(72% 0.17 15)` |
| `warn` | `oklch(73% 0.16 75)` | `oklch(82% 0.14 75)` |
| `success` | `oklch(60% 0.18 150)` | `oklch(73% 0.16 150)` |

##### Magenta — vivid pink-magenta
| Role | Light oklch | Dark oklch |
|---|---|---|
| `accent` | `oklch(62% 0.22 335)` | `oklch(76% 0.18 335)` |
| `destructive` | `oklch(58% 0.21 20)` | `oklch(72% 0.17 20)` |
| `warn` | `oklch(73% 0.16 80)` | `oklch(82% 0.14 80)` |
| `success` | `oklch(60% 0.17 150)` | `oklch(72% 0.15 150)` |

#### 2.1.3 Derived softs (computed at use site)

Each semantic accent has a soft variant for backgrounds (state badges, banner tints, button hover wash). Softs are computed, not stored:

```
accentSoft     = color-mix(in oklch, accent N%, surface)
destructiveSoft = color-mix(in oklch, destructive N%, surface)
warnSoft       = color-mix(in oklch, warn N%, surface)
successSoft    = color-mix(in oklch, success N%, surface)
```

Mix percentages: **16%** in light mode (accent over white surface), **22%** in dark mode (accent over dark surface). These two constants live in `Tokens/DesignTokens.swift`.

#### 2.1.4 P3 hex (Asset Catalog)

The Asset Catalog stores Display P3 components, not oklch. Conversion happens at authoring time via a build-time script (`Sources/ViviraDesignSystem/Scripts/oklch-to-p3.swift`). The oklch values in §2.1.2 are the editable source; the Asset Catalog entries are generated.

When updating a token: edit the oklch value, re-run the script, commit both the oklch source and the regenerated `.colorset` files.

### 2.2 Type

Two faces. **SF Pro** (or its successor, the OS default sans) for display + body; **SF Mono** for numerical and state labels. Type tokens reference Apple's text styles so Dynamic Type just works.

| Token | Style | Weight | Size / Line | Use |
|---|---|---|---|---|
| `font.displayLarge` | Large Title | 700 | 34 / 40 | App nav title; first wizard step title |
| `font.display` | Title 2 | 700 | 22 / 26 | Section headlines |
| `font.headline` | Headline | 600 | 17 / 22 | Subscription title; row title |
| `font.body` | Body | 400 | 15 / 22 | Paragraph copy; form row label |
| `font.bodyBold` | Body | 600 | 15 / 22 | Emphasized body; honest-disclosure copy |
| `font.caption` | Subheadline | 400 | 13 / 18 | Caption, server hostname, secondary meta |
| `font.monoLabel` | — (SF Mono) | 500 | 10 / 14 | Numerical state, mode lines, state badges. **+14% tracking, uppercase.** |

Letter-spacing: `-0.025em` on `displayLarge` and `display`; `-0.01em` on `headline`; default on body; `+0.14em` on `monoLabel`.

### 2.3 Spacing

4pt base. Ten stops cover everything from icon padding to large vertical sections.

| Token | Value | Use |
|---|---|---|
| `space.xxs` | 2pt | Inner image gaps in photo tiles |
| `space.xs` | 4pt | Tight horizontal gaps (between icon and adjacent text) |
| `space.sm` | 8pt | Default gap between adjacent atoms in a row |
| `space.mdMinus` | 12pt | Card inner gap |
| `space.md` | 16pt | Page rhythm; horizontal screen padding |
| `space.mdPlus` | 20pt | Card vertical padding |
| `space.lg` | 24pt | Section separation |
| `space.xl` | 32pt | Major section break |
| `space.xxl` | 40pt | Onboarding wizard step top padding |
| `space.xxxl` | 48pt | Empty-state vertical breathing room |

### 2.4 Radius

| Token | Value | Use |
|---|---|---|
| `radius.sm` | 6pt | Inner chips, pills (rectangular) |
| `radius.md` | 10pt | Buttons, text fields |
| `radius.lg` | 14pt | Cards, banners, photo thumbs |
| `radius.xl` | 22pt | Sheets (Sync Sheet, modal sheets) |
| `radius.pill` | 999pt | State badges, capability chips |

### 2.5 Motion

| Token | Duration | Easing | Use |
|---|---|---|---|
| `motion.fast` | 120ms | `easeOut` | Press feedback, tap state |
| `motion.normal` | 220ms | `easeInOut` | Standard transitions (banner fade, sheet present) |
| `motion.slow` | 360ms | `spring(response: 0.32, damping: 0.8)` | Panel and modal motion |
| `motion.snackbarDwell` | 5000ms | linear | Snackbar persistence before auto-dismiss |
| `motion.bannerDwell` | 3500ms | linear | Success banner persistence before auto-dismiss |

All motion is gated on `@Environment(\.accessibilityReduceMotion)`. When reduce-motion is on, durations drop to 0 and easings become linear instant transitions.

### 2.6 Elevation

Three stops, used sparingly. Vivira's surfaces lean flat; shadows are an accent, not a default.

| Token | Light shadow | Dark shadow | Use |
|---|---|---|---|
| `elevation.flat` | `1px border color.line` | `1px border color.line` | Default for cards and rows |
| `elevation.raised` | `0 1px 2px rgba(15,20,25,0.06)` | step to `color.surface2` (no shadow) | Banners over content, snackbar |
| `elevation.floating` | `0 8px 24px rgba(15,20,25,0.10)` | step to slightly lighter surface | Modal sheets, popovers |

In dark mode, surface lightening replaces shadow elevation — system convention.

### 2.7 Iconography

**SF Symbols subset**, no custom symbols in v1. Sized at 17pt nominal (matches body line height); 22pt for icon-only buttons; 14pt for inline meta icons.

Canonical set used in the app:

```
chevron.right         · disclosure
ellipsis              · row context menu
arrow.up / arrow.down · direction indicators
checkmark             · success state, capability chip
xmark                 · dismiss, error state
plus                  · add server / add subscription
photo                 · photo-related affordances
externaldrive         · server (in ServerRow)
antenna.radiowaves.left.and.right · capability probe
exclamationmark.triangle · warn, stuck, degraded
magnifyingglass       · search
person.2              · shared album subtitle
arrow.uturn.backward  · undo
```

If a screen needs a symbol not on this list, add it to the list first — don't proliferate one-off icons in component code.

---

## 3. Theme system

### 3.1 What a "theme" is

A theme is a named set of four semantic colors (accent, destructive, warn, success), each specified per light and dark mode. Neutrals, type, spacing, radius, motion, and elevation tokens do not vary per theme. Picking a theme swaps only the four semantic colors; everything else stays constant.

### 3.2 The five shipped themes

See §2.1.2 for values. Personality summary:

| Theme | Personality |
|---|---|
| **Lumen** *(default)* | Cool electric sky blue. Familiar, professional, native. Photo-app standard. |
| **Pomelo** | Warm coral. Departs from blue-accent norm; photo-album generous. |
| **Iris** | Deep indigo-violet. Editorial, distinctive, slightly upscale. |
| **Aqua** | Fresh cyan. Photo-friendly to skin tones, swimming-pool-clear. |
| **Magenta** | Vivid pink-magenta. Bold, indie-app energy. |

### 3.3 Picker placement

Theme picker lives in **Settings → Appearance**. Onboarding does not include theme selection; the user gets Lumen on first run and can change later.

The Settings → Appearance screen shows five preview cards in a 1-column vertical list, each card identical in structure to the per-palette preview used during design (palette swatches + a contextual button + two badges, in the current light/dark mode the user is in). Tap to select; the change is immediate, no apply button.

### 3.4 Default

New installs default to **Lumen**. The choice is sticky per device — stored in `UserDefaults` under `ViviraDesignSystem.theme`, read on app launch into the environment.

### 3.5 Runtime resolution

Theme is exposed via `@Entry var theme: Theme` in `EnvironmentValues`. Semantic colors are custom `ShapeStyle` types that resolve via both `\.theme` and `\.colorScheme`. See §8 for the SwiftUI implementation.

---

## 4. Light + dark mandate

Both modes are first-class. Every token in §2 has a light and a dark value. Every component is mocked, reviewed, and shipped in both. There is no "design once, theme later" path.

System rules:

- All colors resolve through SwiftUI's `ColorScheme`. No hard-coded `Color(red:green:blue:)` outside the token layer.
- Asset Catalog colorsets store both Any/Light and Dark variants (and the high-contrast variants — see §10).
- Snapshot tests cover both modes per component.
- A new color token is not merged until both light and dark values exist in the spec and the asset catalog.

---

## 5. Element atoms

Twenty-three atoms — the smallest indivisible visual units. Every higher composition uses only these atoms. Adding an atom requires updating this section.

### 5.1 Button

`ViviraButton(role:)` — five role variants. All buttons are 44pt tall (touch target), `radius.md` corners, `space.mdPlus` horizontal padding, `font.bodyBold`, single-line (`.lineLimit(1)`).

| Role | Light fill | Dark fill | Text |
|---|---|---|---|
| `.primary` | `ink` | `ink` | `bg` |
| `.accent` | `accent` | `accent` | `bg` (resolves to white in light, near-black in dark; both contrast well against accent) |
| `.secondary` | transparent + 1pt `lineStrong` | transparent + 1pt `lineStrong` | `ink` |
| `.ghost` | transparent | transparent | `accent` |
| `.destructive` | `destructive` | `destructive` | white (light) / `bg` (dark) |

**States:** rest, pressed (95% scale + 60% opacity), disabled (40% opacity, no press feedback).

**Accessibility:** `accessibilityTraits = .isButton`, full label from role + content text.

### 5.2 TextField

`ViviraTextField(_, placeholder:, state:)`. 44pt tall, `radius.md` corners, `space.md` horizontal padding, `font.body`.

| State | Border | Text color |
|---|---|---|
| `.rest` | `lineStrong` | `ink` (placeholder: `faint`) |
| `.focused` | `accent` + 3pt accent halo at 22% opacity | `ink` |
| `.pasted` | `lineStrong` | `ink`, with `PASTED` chip-inline trailing edge |
| `.error` | `destructive` | `destructive` |

Paste detection: when the field's text changes from empty to >8 chars in a single change event, the chip-inline appears for 1.5s and fades.

### 5.3 SecureField

`ViviraSecureField(_, placeholder:)`. Same chrome as TextField; text rendered as `••••••••`. iOS-native secure entry attributes.

### 5.4 TypedConfirmField

`ViviraTypedConfirmField(expected:)`. Same chrome as TextField but border `destructive`, text `destructive`, `font.monoLabel` style (mono, uppercased, +14% tracking). Reserved for §11 destructive flows.

### 5.5 Toggle

`Toggle` (system). 51×31pt pill knob. Off state `lineStrong`; on state `success` (success connotes "this is on and good"; do not use `accent` because that creates noise when multiple toggles are on the screen). Knob is white in both modes.

### 5.6 SegmentedPicker

`ViviraSegmentedPicker(selection:, options:)`. Background `surface2`, selected item `surface` with `elevation.raised` shadow, 9pt corner radius. Text `font.body` weight 500. 2-segment and 3-segment variants only — no 4+.

### 5.7 CapabilityChip

`CapabilityChip(_ capability:)`. 22pt tall pill, `radius.pill`, `font.monoLabel`. Two states:

- `.resumable`: `successSoft` background, `success` text, prefix `✓`
- `.standard`: `warnSoft` background, `warn` text, prefix `ⓘ`

Per UX flow §4.1 S3.

### 5.8 FilterChip

`FilterChip(_ label:, isSelected:)`. 22pt tall pill. Selected: `ink` fill, `bg` text. Unselected: `surface` fill, 1pt `lineStrong` border, `ink` text.

### 5.9 Pill

`Pill(_ label:)`. Static rectangular label, `radius.sm`, 20pt tall, `font.monoLabel`. Always reads as descriptive metadata, never as a button.

Common labels: `IN PHOTOS`, `IN VIVIRA`, `SHARED · 3 PEOPLE`.

### 5.10 StateBadge

`StateBadge(_ state:)`. 22pt tall pill with 6pt leading colored dot, `font.monoLabel`. Nine canonical states:

| State | Fill / text |
|---|---|
| `.synced` | `successSoft` / `success` |
| `.uploading` | `accentSoft` / `accent` |
| `.downloading` | `accentSoft` / `accent` |
| `.paused` | `surface2` / `muted` |
| `.deferred(reason:)` | `warnSoft` / `warn` |
| `.stuck(reason:)` | `destructiveSoft` / `destructive` |
| `.awaitingWifi` | `surface2` / `muted` |
| `.awaitingCharging` | `surface2` / `muted` |
| `.awaitingReview` | `accentSoft` / `accent` |

Badge text always carries the specific cause, per UX paradigm #13 ("Errors are specific, actionable, and persistent"). Never the word *failed*.

### 5.11 DirectionGlyph

`DirectionGlyph(_ direction:)`. Inline glyph rendered as `↑` (`.up`) or `↓` (`.down`), `accent` colored, `font.monoLabel` weight 700, +2pt size bump.

### 5.12 StepIndicator

`StepIndicator(current:, total:)`. Horizontal row of dots. Each dot 7×7pt, `lineStrong` color. The current step dot expands to 22×7pt rounded pill in `ink` color. `space.sm` gap between dots.

### 5.13 LinearProgress

`LinearProgress(value:)`. 4pt tall, `radius.pill`, `line` track, `accent` fill. Implicit animation on value change.

### 5.14 Spinner

System `ProgressView()` with `.tint(accent)`. 18pt nominal size for inline use.

### 5.15 Skeleton

`Skeleton(width:, height:)`. Linear gradient from `line` → `surface2` → `line`, animated 1.4s shimmer. Used during loading states; never accompanies real content.

### 5.16 Thumbnail (single)

`Thumbnail(asset)`. Square or aspect-fit photo at requested size, `radius.lg` corners, `surface2` placeholder while loading. Size is set by the consumer: 44pt in utility rows (AlbumViewRow, AlbumThumbnailStrip), full container in content cards (SubscriptionRow's 1-photo variant).

### 5.17 ThumbnailTile

`ThumbnailTile(assets:, count:)`. Composite tile that auto-arranges 1, 2, 3, or 4 photos. See §7.2 for the arrangement rules.

### 5.18 Icon

`Icon(_ symbol:)`. System Image with size and weight tokens; resolves currentColor via `\.foregroundStyle`. Subset enumerated in §2.7.

### 5.19 Divider

`Divider`. 1pt `line` (light hairline) or 1pt `lineStrong` (separator between visually-different groups). Vivira does not use full-width dividers between rows when rows are already in `surface` cards — rely on card edges instead.

### 5.20 Chevron

`Chevron`. System `chevron.right` symbol at 14pt, `faint` color. Indicates row is depth-tappable. Never appears on rows that don't push a screen.

### 5.21 SectionLabel

`SectionLabel(_ text:)`. Plain text, `font.monoLabel`, `muted` color. Sits above a group of cards/rows. No padding within itself; consumer applies surrounding `space.sm` padding.

### 5.22 Snackbar

`Snackbar(message:, undoAction:?)`. Floating capsule, `ink` fill, `bg` text. Height ≥ 44pt; `radius.lg` corners; `space.md` horizontal padding; `space.sm` between message and Undo action.

Undo action (when present): `accent` text, `font.monoLabel`. 5s dwell, then auto-dismiss. Per UX paradigm #6 (reversibility scales with consequence).

In dark mode, snackbar is inverted: `surface` (light bg) with `ink` (dark) text — Apple convention for floating toasts.

### 5.23 LiveActivityChip

`LiveActivityChip(direction:, progress:, subscriptionName:)`. Per the Dynamic Island appearance, not a SwiftUI primitive. Rendered via WidgetKit's `ActivityKit` Live Activity, with the design system supplying the color and type tokens.

Per UX flow §12: appears when a transfer exceeds 30s.

---

## 6. Molecules

Twenty-two molecules — combinations of atoms with a single purpose. Each is named, defines its composition, and lists where it appears in the UX flow.

### 6.1 Row patterns

**SubscriptionRow** *(content list)* — `ThumbnailTile` 150pt tall + body containing `Headline` title, `Pill` placement indicator (top-right), `DirectionGlyph + monoLabel` mode line, count line OR `StateBadge` when attention needed. See §7.1 for the layout. Appears on Connected root screen (§5 of UX flow) and as the row pattern for the Sync Sheet sections.

**ServerRow** *(utility row)* — Server `Icon(.externaldrive)` 44pt avatar left, `Headline` server name, `caption` hostname, `CapabilityChip` status badge below name, `Chevron` right. Appears on Connected root §5.3 (Servers section) and under Settings.

**FormRow** *(iOS Settings style)* — `body` label left, `caption` value + `Chevron` right. Appears on Subscription Detail §6.

**AlbumViewRow** — `Thumbnail` 44pt (single, not tile), `body` filename, `StateBadge` below, inline action `Button(.secondary, .small)` right. Used in the per-subscription Album View §6.1.

### 6.2 Status molecules

**HeroStatusLine** — `DirectionGlyph` + `monoLabel` activity description (flexed to fill, ellipsizes) + `monoLabel` subscription label (right-aligned, small). One line of the hero card.

**HeroStatusCard** *(organism, lives here for proximity)* — `surface` card containing: headline row (`Icon(.checkmark)` in `success` + `Headline` summary text), 0..N `HeroStatusLine` rows, optional `monoLabel` queue summary. Active state shows transfer lines; idle state shows just headline + "Last synced X ago"; degraded state inlines a tappable `DegradedBanner` line.

**ModeLine** — `DirectionGlyph + monoLabel` × 1 or 2 (up + down direction), with `monoLabel` separator (`·`). Used inside SubscriptionRow body and SubscriptionDetail header.

**CountsLine** — sequence of `monoLabel` values with `·` separators. Only non-zero counts are rendered (per UX flow §5.2).

### 6.3 Banners

**SuccessBanner** — `successSoft` fill, `success` text + `Icon(.checkmark)`, `body` message. Auto-dismiss after `motion.bannerDwell` (3.5s). Top-anchored in screen.

**FailureBanner** — `destructiveSoft` fill, `destructive` text + `Icon(.warn)`, `body` message, two `Button(.secondary)` actions trailing (Retry + Details). Persistent; never auto-dismisses.

**DegradedBanner** — `warnSoft` fill, `warn` text + `Icon(.warn)`, `body` message, `Chevron` trailing. Tappable; opens the recovery flow for the source. Used inline in HeroStatusCard and as standalone toast.

### 6.4 Onboarding molecules

**WizardStepHeader** — `StepIndicator` top, `displayLarge` step title, `body` subtitle. Sits at top of every onboarding step.

**InfoCard** — `Icon` 32pt avatar in `accentSoft` square, `Headline` title, `body` explanation, `Button(.accent)` primary CTA. Used for permission asks and standalone informational screens.

**CapabilityRow** — `CapabilityChip` + `body` explanation. Appears after the capability probe in §4.1 S3.

**HonestDisclosureRow** — `Icon(.warn)` 14pt + `body` short copy. Specific copy phrases enumerated in UX flow §12.2.

### 6.5 Composed molecules

**EmptyState** — `Icon` 48pt at `faint` color, `body` one-sentence explanation, `Button(.accent)` single CTA. Vertically centered in available space. Per UX flow §12 spine rule.

**TwoCardChooser** — 1×2 grid of selectable cards, each `surface` background with `lineStrong` border (selected state: `accent` border + `accentSoft` fill). Each card: `Headline` title, `caption` 1–2 line description. Used for "Where photos land" and "Disconnect server" decisions (UX flow §10, §11).

**TypedConfirmBlock** — `destructiveSoft` callout box with `body` warning copy, `TypedConfirmField` below, `Button(.destructive)` below (disabled until field matches). Reserved for the most destructive flows.

**SyncSheetSection** — `Headline` category title with `SectionLabel` source attribution trailing, `AlbumThumbnailStrip` (below), `caption` context line, `Button(.accent)` primary + `Button(.secondary)` review + `monoLabel` "LATER" tertiary text-action. One per category in the Sync Sheet (§7 of UX flow).

**AlbumThumbnailStrip** — Horizontal flex of 5 `Thumbnail` 44pt items + overflow `Pill`-style "+N" badge. Used in SyncSheetSection.

**PermissionsRow** — `Headline` title + `body` description + status indicator (`Toggle` or `StateBadge`). Used in §4.3 G2 of UX flow.

**CategoryHeader** — `Headline` category name + `monoLabel` count trailing. Used at the top of each SyncSheetSection.

### 6.6 Where molecules compose into organisms

Organisms are screen-level compositions of molecules. They are not new atoms; they are arrangements:

- **Connected root screen** (UX flow §5) = HeroStatusCard + SectionLabel + (SubscriptionRow × N) + SectionLabel + (ServerRow × N) + utility sections
- **Subscription detail** (§6) = navigation header + (FormRow × N) + CountsLine block + activity preview
- **Album view** (§6.1) = filter chip row + (AlbumViewRow × N)
- **Sync Sheet** (§7) = navigation header + (SyncSheetSection × N)
- **Wizard step** (§4) = WizardStepHeader + body slot + pinned `Button(.accent)`
- **Disconnect screen** (§11) = navigation header + (TwoCardChooser) + (TypedConfirmBlock for delete-card)

Organisms are not enumerated as separate spec entries because they're 100% determined by the molecule composition and the UX flow doc.

---

## 7. Layout patterns

### 7.1 Vertical card list (content lists)

Used for: subscription list (root screen §5.2), album view (§6.1), Sync Sheet sections (§7), onboarding album picker (§4.2 P1).

Card anatomy:

```
┌────────────────────────────────────┐
│                                    │
│       PHOTO TILE — 150pt high     │   thumb-band
│       full card width             │
│                                    │
├────────────────────────────────────┤
│ Title              [Pill]          │   body
│ ↑Mode · ↓Mode                      │
│ Count · Count · State              │   meta-line-2
└────────────────────────────────────┘
   total height ≈ 220pt
```

Specs:
- Card: `surface` fill, 1pt `line` border, `radius.lg` (14pt) corners, no shadow
- Thumb band: 150pt tall, full card width, `surface2` placeholder
- Body padding: 10pt top, 14pt sides, 12pt bottom
- Title row: `font.headline`, `space.sm` gap to Pill (right-aligned)
- Mode line: `font.monoLabel`, `muted` color, `accent` direction glyphs
- Meta line 2: `font.monoLabel`, `faint` color; replaced by `StateBadge` when subscription needs attention (stuck, deferred, pendingReview > 0)

Spacing between cards: `space.sm` (8pt). The list extends to the bottom of the scroll area with the bottom-fade affordance (§7.3).

### 7.2 Photo tile arrangements

The `ThumbnailTile` atom (§5.17) auto-selects an arrangement based on `photoCount` and (when applicable) aspect ratios.

| Count | Arrangement | Notes |
|---|---|---|
| 0 | Placeholder fill | `surface2` with centered `Icon(.photo)` at `faint`. Only happens on fresh subscriptions with `downloadMode = .off`. |
| 1 | Single full-bleed | Photo fills the entire tile, `object-fit: cover`. |
| 2 | Split (orientation auto-picked) | **Vertical split (L \| R)** when dominant assets are portrait. **Horizontal split (T / B)** when dominant assets are landscape. Default to horizontal when unclear. |
| 3 | Mosaic | Canonical: **top-full + bottom-split** (one photo spans the top half, two split the bottom half). Alternative: **left-full + right-split** (supported but not default). |
| 4+ | 2×2 grid | When 5+ photos exist, use the four most recent. |

Inter-photo gap: `space.xxs` (2pt). Tile corners follow the host card's `radius.lg`.

### 7.3 Bottom fade affordance

Content lists that extend past the viewport fade their bottom edge into the page background, with a soft shadow at the top of the fade. This is the iOS "there is more" convention; no separate "load more" affordance.

Implementation (SwiftUI):

```swift
ScrollView {
    LazyVStack(spacing: .vivira.sm) { /* cards */ }
}
.mask(LinearGradient(stops: [
    .init(color: .black, location: 0.0),
    .init(color: .black, location: 0.85),
    .init(color: .clear, location: 1.0),
], startPoint: .top, endPoint: .bottom))
.overlay(alignment: .bottom) {
    LinearGradient(
        colors: [.clear, .vivira.bg.opacity(0.7), .vivira.bg],
        startPoint: .top, endPoint: .bottom
    )
    .frame(height: 130)
    .shadow(radius: 6, y: -6)
    .allowsHitTesting(false)
}
```

The mask creates the fade; the overlay paints the matching solid bg under it and contributes the inset shadow.

### 7.4 Horizontal utility row (utility lists)

Used for: server list, settings rows, app-wide settings (Conditions, About).

The web-style "thumb-left, text-right" row is fine here because utility lists are not content-driven. ServerRow and FormRow follow this pattern. Touch target ≥ 44pt; trailing `Chevron` if the row pushes a screen.

Utility rows always nest inside a grouped card (rounded `surface` with internal dividers between rows), not as free-floating cards on a `bg` background.

### 7.5 Page structure (every screen)

Per UX flow §12:

```
┌────────────────────────────────────┐
│ status bar (system)                │
├────────────────────────────────────┤
│ NavBar — large title + plus / ‹    │
├────────────────────────────────────┤
│                                    │
│   (sections, cards, rows)         │
│   space.md horizontal padding     │
│                                    │
│   bottom fade if list overflows   │
├────────────────────────────────────┤
│ Pinned primary action (if any)    │
└────────────────────────────────────┘
```

The pinned primary action sits inside the safe area, `space.md` horizontal padding, full-width `Button(.accent)` when there's exactly one primary action for the screen.

---

## 8. SwiftUI architecture

### 8.1 Module layout

Single SPM package `ViviraDesignSystem`. Single library target. No sub-modules at v1; revisit if compile times become a problem.

```
Sources/ViviraDesignSystem/
├── Tokens/
│   ├── DesignTokens.swift        // oklch source values, computed P3 components
│   ├── Theme.swift               // Theme enum, @Entry env value, ThemeStorage
│   ├── SemanticColor.swift       // ShapeStyle types: .accent, .destructive, etc
│   ├── Typography.swift          // Font tokens, Dynamic Type bindings
│   ├── Spacing.swift             // CGFloat space tokens
│   ├── Radius.swift              // Shape tokens
│   ├── Motion.swift              // Animation tokens
│   └── Elevation.swift           // Shadow modifier tokens
├── Atoms/
│   ├── Buttons/ViviraButton.swift
│   ├── Fields/ViviraTextField.swift
│   ├── Fields/ViviraSecureField.swift
│   ├── Fields/TypedConfirmField.swift
│   ├── Chips/CapabilityChip.swift
│   ├── Chips/FilterChip.swift
│   ├── Chips/Pill.swift
│   ├── Badges/StateBadge.swift
│   ├── Indicators/DirectionGlyph.swift
│   ├── Indicators/StepIndicator.swift
│   ├── Indicators/LinearProgress.swift
│   ├── Thumbs/Thumbnail.swift
│   ├── Thumbs/ThumbnailTile.swift
│   ├── Misc/Snackbar.swift
│   └── Misc/LiveActivityChip.swift
├── Molecules/
│   ├── Rows/SubscriptionRow.swift
│   ├── Rows/ServerRow.swift
│   ├── Rows/FormRow.swift
│   ├── Rows/AlbumViewRow.swift
│   ├── Status/HeroStatusCard.swift
│   ├── Banners/SuccessBanner.swift
│   ├── Banners/FailureBanner.swift
│   ├── Banners/DegradedBanner.swift
│   ├── Onboarding/WizardStepHeader.swift
│   ├── Onboarding/InfoCard.swift
│   ├── Onboarding/CapabilityRow.swift
│   ├── Onboarding/HonestDisclosureRow.swift
│   ├── Composed/EmptyState.swift
│   ├── Composed/TwoCardChooser.swift
│   ├── Composed/TypedConfirmBlock.swift
│   └── Composed/SyncSheetSection.swift
├── Layout/
│   ├── ContentList.swift          // Vertical card list scaffolding + bottom fade
│   ├── UtilityList.swift          // Grouped row container
│   └── PageScaffold.swift         // NavBar + pinned-action structure
├── Resources/
│   └── ViviraColors.xcassets     // Raw palette colorsets, P3 gamut
└── Scripts/
    └── oklch-to-p3.swift          // Build-time conversion (referenced from spec, not bundled)

Tests/ViviraDesignSystemTests/
├── SnapshotTests/                 // Per-atom and per-molecule, light + dark, all 5 themes
└── TokenResolutionTests/          // Verify Theme + ColorScheme resolution
```

### 8.2 Token implementation

Tokens are Swift constants/properties grouped on a `vivira` namespace exposed via extensions on the base types:

```swift
public extension Color {
    enum vivira {
        public static let bg          = Color("vivira.bg", bundle: .module)
        public static let surface     = Color("vivira.surface", bundle: .module)
        public static let surface2    = Color("vivira.surface2", bundle: .module)
        public static let ink         = Color("vivira.ink", bundle: .module)
        // ... neutrals continue
    }
}

public extension CGFloat {
    enum vivira {
        public static let xxs:    CGFloat = 2
        public static let xs:     CGFloat = 4
        public static let sm:     CGFloat = 8
        public static let md:     CGFloat = 16
        // ... etc
    }
}
```

Semantic accents do **not** appear here as static `Color` values — they're theme-dependent. They're `ShapeStyle` types resolved at use site. See §8.4.

### 8.3 Theme storage and environment

```swift
public enum Theme: String, CaseIterable, Codable, Sendable {
    case lumen, pomelo, iris, aqua, magenta

    public var displayName: String { /* localized */ }
}

extension EnvironmentValues {
    @Entry public var viviraTheme: Theme = .lumen
}

@MainActor
public final class ThemeStorage: ObservableObject {
    @Published public var current: Theme {
        didSet { UserDefaults.standard.set(current.rawValue, forKey: "ViviraDesignSystem.theme") }
    }
    public init() {
        let stored = UserDefaults.standard.string(forKey: "ViviraDesignSystem.theme") ?? Theme.lumen.rawValue
        self.current = Theme(rawValue: stored) ?? .lumen
    }
}
```

App root binds storage into environment:

```swift
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

### 8.4 Semantic color as ShapeStyle

Each semantic role (accent, destructive, warn, success) and their softs are `ShapeStyle` types that resolve in environment:

```swift
public struct AccentColor: ShapeStyle, Sendable {
    public init() {}

    public func resolve(in environment: EnvironmentValues) -> some ShapeStyle {
        let theme = environment.viviraTheme
        let scheme = environment.colorScheme
        let key = "accent.\(theme.rawValue).\(scheme == .dark ? "dark" : "light")"
        return Color(key, bundle: .module)
    }
}

public extension ShapeStyle where Self == AccentColor {
    static var accent: AccentColor { AccentColor() }
}
```

Usage in components:

```swift
Button("Continue") { /* action */ }
    .buttonStyle(.borderedProminent)
    .tint(.accent) // resolves to current theme's accent in current mode
```

`DestructiveColor`, `WarnColor`, `SuccessColor` and their soft variants follow the same pattern.

### 8.5 Asset catalog naming

Asset catalog entries follow `<role>.<theme>.<mode>` for semantic roles, `<token>` for neutrals.

Neutrals (light + dark in one colorset, Any/Dark appearance):

```
vivira.bg
vivira.surface
vivira.surface2
vivira.ink
vivira.ink2
vivira.muted
vivira.faint
vivira.line
vivira.lineStrong
```

Semantic accents (one colorset per theme × mode):

```
accent.lumen.light
accent.lumen.dark
accent.pomelo.light
accent.pomelo.dark
...
destructive.lumen.light
destructive.lumen.dark
...
warn.<theme>.<mode>
success.<theme>.<mode>
```

Total colorsets: 9 neutrals + (4 semantic × 5 themes × 2 modes) = 9 + 40 = **49 colorsets**.

All colorsets use the **Display P3** gamut option in Xcode. The P3 component values are generated from the oklch source via `oklch-to-p3.swift`.

### 8.6 Component contract

Every atom and molecule:

- Is `public` and lives in its own file
- Uses only tokens from §2 — no inline `Color(red:green:blue:)`, no magic numbers for spacing/radius/duration
- Declares `accessibilityLabel`, `accessibilityHint`, and traits where applicable
- Has a SwiftUI Preview that renders all states in light and dark, in Lumen (because Previews don't resolve `@Entry` env outside an app) — themed previews via snapshot tests

### 8.7 Liquid Glass policy

`.glassEffect(.regular.tint(.accent))` applies **only to chrome**:

- Bottom-pinned primary action containers when they sit over scrolling content
- Floating action buttons (none in v1)
- NavBar background when scrolled

Surfaces — cards, banners, sheets — stay solid. Tinting all content surfaces is the anti-pattern Apple calls out in WWDC25-323.

---

## 9. Penpot workflow

Penpot is a **visual sketchpad and reference file**, not part of the build pipeline. Token values in code are canonical. Penpot is updated manually when tokens change.

Workflow:

1. Design exploration happens in Penpot (loose mockups, color experimentation, layout sketching).
2. Once a design decision lands, the value is encoded in `Tokens/DesignTokens.swift` and the asset catalog.
3. The Penpot file is updated to match, by hand, as part of the same task that updated the code.
4. The Penpot file ships with the repo at `design/vivira.penpot` (mirror of canonical values; useful for design conversations but not load-bearing).

Penpot's native token export is in Tokens Studio format (multi-set JSON with `$themes` / `$metadata` envelope, not pure W3C DTCG). We do not consume this export; the export path can be revisited if Penpot adopts strict DTCG.

A `tokens.json` dump (DTCG-shaped) can be generated from `DesignTokens.swift` as documentation; not required for v1.

---

## 10. Accessibility

Full scope at v1. Every shipped component clears these bars before merge.

### 10.1 Dynamic Type

All text styles in §2.2 bind to Apple text styles (`largeTitle`, `title2`, `headline`, `body`, `subheadline`, `caption1`). Components use `.font(.vivira.body)` which under the hood applies the bound text style. Dynamic Type just works.

Two carve-outs:

- `font.monoLabel` does not scale (it carries numerical state; scaling distorts tabular alignment). Mono labels are 10pt fixed.
- Photo thumbnails do not scale (they are content, not chrome).

The hero card, every form row, every banner, every button label scales. Vivira passes the standard Dynamic Type test (xxLarge → AX5) without truncation or layout collapse.

### 10.2 VoiceOver

Every interactive component declares:

- `accessibilityLabel` — what it is (e.g., "Family 2026, subscription")
- `accessibilityValue` — current state (e.g., "27 photos available to download, 2 pending review")
- `accessibilityHint` — what tapping does (e.g., "Opens subscription detail")
- `accessibilityTraits` — `.isButton`, `.isImage`, `.updatesFrequently` for transfer rows, etc.

State badges read their state as text, not as a colored dot. A SubscriptionRow with a `.stuck` badge reads: "Hiking Group, subscription, 1 photo stuck because it is larger than this device."

Composite molecules combine children's labels into a single VoiceOver announcement to avoid forcing the user to swipe through 4 sub-elements per row.

### 10.3 High contrast

Every colorset in the asset catalog includes an **Increase Contrast** variant for both Any and Dark appearances. The high-contrast variant uses a stronger version of the same token (e.g., `muted` → `ink2` at high contrast, `line` → `lineStrong`).

Generated at build time alongside the standard variants by `oklch-to-p3.swift`; reviewed manually for WCAG AAA at the accent level and AA at the body-text level.

### 10.4 Reduce motion

All animations in §2.5 gate on `@Environment(\.accessibilityReduceMotion)`:

```swift
@Environment(\.accessibilityReduceMotion) private var reduceMotion

.animation(reduceMotion ? .none : .vivira.normal, value: state)
```

When reduce motion is on: durations collapse to 0, easings become linear instant transitions. The skeleton shimmer in §5.15 stops; the spinner stops rotating (shows static partial ring with the `.updatesFrequently` accessibility trait instead).

### 10.5 Hit targets

All interactive components are ≥ 44×44pt (Apple HIG minimum). Inline chips and badges that look interactive but are not (Pill, CapabilityChip) get `.accessibilityHidden(true)` when their content is also read by a parent — they're decorative summaries, not separate items.

---

## 11. Liquid Glass policy

iOS 26.5's Liquid Glass material is for navigation chrome. Vivira uses it only in three places:

1. **NavBar background when scrolled** — applies `.glassEffect(.regular)` once content scrolls past the top edge.
2. **Pinned primary action container** at the bottom of a screen when content scrolls behind it — `.glassEffect(.regular.tint(.accent))` so the action's tint reads even over busy content.
3. **System-supplied surfaces** (sheets, popovers) — Apple's defaults already use the material; we don't override.

Vivira does **not** apply glass to:

- Cards (subscription cards, server rows, hero status card)
- Banners
- Buttons (other than the pinned-action wrapper)
- Sheets' content area (Apple's sheet chrome is already glass; the content stays opaque)
- Backgrounds of the Sync Sheet sections

Tinting every chrome element with the theme accent (the "rainbow chrome" anti-pattern) does not happen in Vivira. Tint is reserved for the **one** primary action of the screen.

---

## 12. Naming and conventions

### 12.1 Module and type naming

- Public type prefix: **none.** Types are organized by directory/namespace, not by prefix. `ViviraButton`, `ViviraTextField` use the `Vivira` prefix only when the unprefixed name (`Button`, `TextField`) would shadow SwiftUI. State badges, chips, and composed molecules use plain names: `StateBadge`, `Pill`, `SubscriptionRow`.
- Internal types are not prefixed.
- File name == primary type name. One public type per file.

### 12.2 Token naming

- Token namespace: `vivira` (lowercase). Accessed as `.vivira.bg`, `.vivira.md`, `.vivira.normal`.
- Color tokens: `<role>` for neutrals (`bg`, `surface`, `ink`); `<role>.<theme>.<mode>` for semantic accents in the asset catalog only; semantic accents at the API surface are `ShapeStyle` types accessed as `.accent`, `.destructive`, `.warn`, `.success`.
- Spacing tokens: `xxs`, `xs`, `sm`, `mdMinus`, `md`, `mdPlus`, `lg`, `xl`, `xxl`, `xxxl`.
- Radius tokens: `sm`, `md`, `lg`, `xl`, `pill`.
- Motion tokens: `fast`, `normal`, `slow`, plus duration-named tokens for dwell timers (`snackbarDwell`, `bannerDwell`).

### 12.3 Asset catalog naming

Match the SwiftUI key one-to-one (§8.5). No hyphens; dots as separators. Display P3 gamut on every colorset.

### 12.4 Test naming

Snapshot tests: `<Component>_<state>_<mode>_<theme>.png` (e.g., `SubscriptionRow_stuck_dark_lumen.png`). Snapshot diff threshold: 0.01 (pixel-exact).

### 12.5 File header

Every Swift file in the package opens with one-line description, no copyright block, no author tag. The package's `LICENSE` covers attribution.

---

## 13. Out of scope for v1

These were considered and explicitly excluded:

- **More than 5 themes.** Adding themes is cheap (one row in `Theme` + 8 colorsets); deferring it keeps the picker visually manageable.
- **User-custom accent colors.** No "pick any hex" picker. Five curated themes only.
- **Per-subscription theming.** All subscriptions render in the global theme.
- **Theme animation when switching.** Theme changes are instant; cross-fading 49 colorsets is expensive for a settings change.
- **Custom SF Symbols.** All icons come from system Symbols; the day we need a glyph that doesn't exist there is the day we revisit.
- **Glass-tinted content surfaces.** Per §11.
- **Localization beyond English.** Strings are wrapped in `String(localized:)` so adding locales is mechanical, but no other locale ships in v1.
- **Right-to-left (RTL) mirroring.** SwiftUI handles most of it automatically; manual audit deferred.
- **Penpot → SwiftUI build pipeline.** Manual sync only (§9).
- **Token JSON export.** Documentation-only artifact; can be generated later from `DesignTokens.swift`.
- **Component library catalog app.** Snapshot test gallery covers internal review needs.

---

## 14. Open implementation questions

To resolve during implementation, not blocking this spec:

1. **oklch → P3 conversion algorithm.** Use Color.js (JavaScript) at authoring time, or write a Swift port. JS is faster to integrate; Swift keeps the toolchain homogeneous. Default to JS for v1 unless Swift port lands cheaply.
2. **Snapshot test infrastructure.** Pointfree's `swift-snapshot-testing` or `swift-testing` with custom snapshot harness. Pointfree's library is the default unless v6 testing-macro story changes the equation.
3. **High-contrast WCAG audit gate.** Whether the build fails on contrast regressions or just warns. Default to warn for v1, fail for v1.1 after the regression workflow is proven.
4. **Theme picker preview rendering.** Each card in Settings → Appearance shows the four semantic colors plus a sample button. Verify it doesn't allocate 5 themes' worth of `ShapeStyle` per render; cache or render statically.
5. **Live Activity colors in light mode.** Dynamic Island is always dark; the LiveActivityChip's accent color must come from the dark-mode resolution regardless of system color scheme. Confirm during ActivityKit implementation.
6. **Bottom-fade SwiftUI implementation cost.** The mask gradient and overlay in §7.3 each cost a render pass. Profile on the lowest-target device; if cost is meaningful, simplify to single overlay or pre-rendered image.

---

## 15. References

### Apple

- [SwiftUI ShapeStyle](https://developer.apple.com/documentation/swiftui/shapestyle) — base protocol for theming via environment
- [Color.RGBColorSpace.displayP3](https://developer.apple.com/documentation/swiftui/color/rgbcolorspace/displayp3) — P3 gamut Color init
- [Liquid Glass — WWDC25 Session 323](https://developer.apple.com/videos/play/wwdc2025/323/) — chrome-only material guidance
- [Asset Catalog Named Colors](https://developer.apple.com/library/archive/documentation/Xcode/Reference/xcode_ref-Asset_Catalog_Format/Named_Color.html) — light/dark/contrast resolution
- [ActivityKit](https://developer.apple.com/documentation/activitykit) — Live Activity rendering

### Tokens and color

- [W3C Design Tokens Community Group spec](https://design-tokens.github.io/community-group/format/) — DTCG format (Penpot exports are Tokens Studio shape, not strict DTCG)
- [Tokens Studio + Penpot announcement](https://tokens.studio/blog/tokens-studio-penpot-bringing-native-open-standard-design-tokens-to-everyone) — native Penpot token integration
- [oklch color picker](https://oklch.com/) — for editing oklch values during design

### SwiftUI design system patterns

- [@Entry macro guide](https://www.donnywals.com/adding-values-to-the-swiftui-environment-with-entry/) — back-deployable env values
- [Custom Environment Colors](https://freiwald.dev/posts/custom-environment-colors/) — ShapeStyle + Environment theming pattern
- [ColorTokensKit-Swift](https://github.com/metasidd/ColorTokensKit-Swift) — runtime oklch math in Swift (optional, not used in v1)

### Project

- [Vivira UX flow design](2026-05-16-vivira-ux-flow-design.md) — behavior, screens, copy
- [Vivira UX paradigms](2026-05-17-vivira-ux-paradigms.md) — principles that govern UX decisions
