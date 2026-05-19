# Contributing to Vivira

## Prerequisites

- Xcode matching the project's iOS deployment target (currently iOS 26.5).
- [`mise`](https://mise.jdx.dev/) for task running and tool pinning.
- After cloning: run `mise run bootstrap` to install Homebrew dependencies (`swiftlint`, `xcbeautify`) and generate `Vivira.xcodeproj` from `project.yml`.

## Common tasks

| Task | Purpose |
|---|---|
| `mise run build` | Build the app for the iOS Simulator declared in `mise.toml` (`SIM_DEVICE`). |
| `mise run test` | Run all unit tests. Strict snapshot mode — see below. |
| `mise run test:record` | Re-record snapshot baselines after intentional visual changes. |
| `mise run test:diff` | List snapshot baselines that differ from `HEAD`. |
| `mise run lint` | Run SwiftLint. |
| `mise run open` | Open the regenerated Xcode project. |
| `mise run gen-colors` | Regenerate `ViviraColors.xcassets` from `tools/colors-source.json` (after changing color tokens). |
| `mise run clean` | Remove the generated Xcode project and the app's DerivedData. |

## Snapshot test workflow

Snapshot baselines — the PNG files under `Packages/ViviraDesignSystem/Tests/ViviraDesignSystemTests/__Snapshots__/` — are **committed to git**. They are the source of truth for what the UI looks like at HEAD. Treat them as you would source code: review changes, commit deliberately, justify the diff.

### Two states of a failed snapshot test

A failed snapshot test means one of two things:

1. **The UI regressed.** The change was accidental and the test caught it.
2. **The UI was changed intentionally** and the baselines are stale.

The tooling cannot distinguish these for you. You look at the diff and decide.

### Default behavior: strict

`mise run test` runs with `SNAPSHOT_TESTING_RECORD_MODE=never`. Missing or differing snapshot baselines fail with a clear error — no silent recording. Accidental UI changes cannot sneak into a clean test run.

### When a snapshot test fails

1. **See what changed.** Open Xcode's Test Inspector (`⌘9` → click the failed test → the attached `actual` and `failure` images appear next to the reference). Or run `mise run test:diff` to list which baselines git considers modified.

2. **Decide per failure.**
   - **The change was a regression** — leave the baseline as-is and fix the code. Re-run `mise run test` until green.
   - **The change is intentional** — proceed to step 3.

3. **Re-record the new baselines.**

   ```bash
   mise run test:record
   ```

   This wipes `__Snapshots__/` and runs the tests once with `SNAPSHOT_TESTING_RECORD_MODE=missing`. The test run **fails by design** — the failure is the recording event, not a defect.

4. **Review the recorded PNGs.** Use Finder + Preview to compare each new baseline against the version still in git (`git show HEAD:<path> > /tmp/old.png && open /tmp/old.png`), or push the branch and let the PR diff render the side-by-side image comparison.

5. **Accept or reject per file.**

   ```bash
   # Intentional — keep the new baseline:
   git add Packages/ViviraDesignSystem/Tests/ViviraDesignSystemTests/__Snapshots__/<path>

   # Accidental — restore the previous baseline:
   git restore Packages/ViviraDesignSystem/Tests/ViviraDesignSystemTests/__Snapshots__/<path>
   ```

6. **Confirm.**

   ```bash
   mise run test
   ```

   Strict mode passes when every committed baseline matches the current render.

7. **Commit.** The PNGs go in the same commit as the code change that produced them. The commit message should describe the visual intent, not just the file list.

### Adding a new snapshot test

The first run of a new test has no baseline. `mise run test` fails strictly because the reference is missing. Run `mise run test:record` once, review the recorded PNG, commit. After that, the test joins the strict pipeline.

### Why this works

- **No conflation.** Strict mode keeps "missing baseline" and "UI changed" as separate, recoverable failures.
- **Per-snapshot granularity.** `git add` and `git restore` operate on individual files, so partial acceptance is natural.
- **Audit trail.** Every baseline change is a commit with a message and a reviewer.
- **PR review is visual.** GitHub renders PNG diffs natively. Reviewers see code and visual together without running the test locally.

## Color tokens

Color tokens are defined in `tools/colors-source.json` (oklch values per theme). The accent colorsets in `Packages/ViviraDesignSystem/Sources/ViviraDesignSystem/Resources/ViviraColors.xcassets` are generated from that source via `tools/oklch-to-p3.mjs`.

When changing a token: edit the JSON, run `mise run gen-colors`, commit both the source and the regenerated `Contents.json` files. The Node toolchain is only needed by contributors who change colors — a clean clone builds without it because the generated files are tracked.

## Project layout

| Path | Contents |
|---|---|
| `Vivira/` | App target (`ViviraApp`, `ContentView`, screen-level views, state holders). |
| `ViviraTests/` | App target unit tests. |
| `Packages/ViviraDesignSystem/` | Local SPM package: tokens, atoms, molecules, theme storage, snapshot tests, asset catalog. |
| `docs/superpowers/specs/` | Design specifications, dated. Each is the single source of truth for one slice. |
| `docs/superpowers/plans/` | Implementation plans, dated. Each plan executes against one spec. |
| `tools/` | Build-time scripts (color generator and its `package.json`). |

## Branch and PR workflow

Feature work happens on a `feat/<topic>` branch, typically in a worktree under `.claude/worktrees/<topic>/`. Open a PR against `main` when the slice is ready. The PR is the review surface for both code and snapshot changes.
