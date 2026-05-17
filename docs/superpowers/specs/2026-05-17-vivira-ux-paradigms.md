# Vivira UX Paradigms

**Status:** Draft (awaiting review)
**Date:** 2026-05-17
**Scope:** The principles that govern every interaction, screen, and copy decision in Vivira. Each one has direct consequences for code and copy.

---

## How to use this doc

Read once. Return to it during design review and before merging UI work. When a violation surfaces, fix it. When you keep one anyway, name it as an exception and write down why.

This document does not reference any other Vivira spec. No other Vivira spec references it. The two are independent on purpose.

---

## When paradigms conflict

Tie-break hierarchy, in priority order:

1. **Sacredness wins.** Pre-existing user data is untouchable, full stop.
2. **Never silent on harm.** Anything that damages trust surfaces with clear naming. Deletion, irreversibility, and data loss are always visible.
3. **Mental model trumps spec.** When the code or copy contorts to fit the platform, restructure the model.

If two paradigms still disagree below that hierarchy, the one whose violation surprises the user more wins.

---

## The paradigms

### Truth and language

1. **No surprises.** Labels and actions match exactly. State transitions are atomic. Cancel exits cleanly, never half-applied, never stranding a record.

2. **Clear language.** Counter-words pair (add/remove, create/delete, subscribe/unsubscribe, send/receive). Pluralization and units stay correct: "1 photo · 32 MB", not "1 photo(s) · 32 mb".

3. **Alarm matches consequence.** Reversible actions stay quiet. The word *destructive* is reserved for things that genuinely cannot be undone. Harmless steps never carry an "Are you sure?" gate.

### Respecting the user

4. **The default path assumes nothing about level.** Onboarding is skippable. Advanced settings are findable without being in the way. The same screen serves a novice and an expert. The user decides which path they take.

5. **Flow coherence.** Within a flow, only the flow speaks. Background events wait or batch. They surface in their own anchor, never as a parallel modal interrupting the current step.

6. **Reversibility scales with consequence.** Routine actions are undoable via snackbar. Typed-confirm appears only where the system literally cannot undo. Friction tracks irreversibility, not the verb on the button.

7. **The tool fits the user's mental model.** Labels, data, and screens follow how the user thinks. Platform constraints (iOS prompts, server quirks, network limits) are disclosed in plain language at the point of decision. They are never papered over by model contortions.

### Visibility and honesty

8. **Sensible defaults; advance without deciding.** Every form pre-fills. Continue works without the user touching anything.

9. **One status, one place.** The user always knows what the app is doing right now, from a single anchor. Status never gets scattered across screens.

10. **Concrete over abstract.** "12 photos will upload (~32 MB) — automatic" beats "syncing in background". Show counts, sizes, names, and costs. Verbs alone hide effort.

11. **Reveal cost before commit.** Settings show their consequence before Save: "This will queue 1,234 photos for upload." The user sees the cost at the moment of the decision.

### Resilience

12. **Resumability everywhere.** Interrupted flows resume at the exact step. Partial work survives process kill, network drop, and declined OS prompts.

13. **Errors are specific, actionable, and persistent.** Name the cause (`auth expired`, `MIME unsupported`). Suggest the fix (`Renew`, `Skip permanently`). The error stays visible until resolved.

14. **Batch platform-imposed friction.** When the platform forces a prompt (iOS delete confirmation), gather pending actions into one prompt instead of many.

### Discretion

15. **Notifications inform; they don't compete.** Opt-in by default. Debounced per event, not per asset. Tapping always lands somewhere useful. Quiet by default; the user controls when they get louder.

16. **Sacredness boundary.** Vivira only touches what Vivira created. Pre-existing user photos stay untouched. Vivira never modifies, moves, or deletes them.

---

## Worked examples

Each example shows a violation and names which paradigms it touches. When an interaction feels off, compare it against these examples first.

### Copy must not mean Move

A button labeled *Copy* that moves the file ambushes the user. The label promised one thing; the action did one more.

Touches: **#1** (no surprises), **#2** (clear language). Clear language is one of the mechanisms that prevents surprise. Naming the action correctly *Move* removes the violation at the source.

### Unsubscribe must not delete the local library

*Unsubscribe* means stop receiving from now on. It does not mean throw away the months of family photos already on this iPhone. A single tap must never silently smuggle a second, much larger action.

Touches: **#1**, **#16** (sacredness boundary).

### Resume must not re-do work already done

After pause, the queue is reconciled against current truth. It is not replayed from a frozen snapshot. Photos already on the device do not download again. Photos already on the server do not upload again. The user paid for those bytes once. Charging them twice would surprise them even when the action (resume) looks innocuous.

Touches: **#1**, **#7** (tool fits mental model). The user's model is "this album should be in sync." Replaying a frozen log is the system's model.

### Renaming a local label must not rename the source album

A row that says "Album name on this iPhone" changes only the local display label. Renaming it never renames the album on the Immich server. The Immich album is a shared resource visible to every other collaborator. *Local* and *source* are separate concepts. The data model and the UI both have to respect that separation.

Touches: **#1**, **#7**, **#16**.

### Pause must not delete cached photos

Halting future work is not the same as discarding past work. If pausing a subscription cleared its locally cached photos, the user's temporary settings tweak would lose data they expected to keep.

Touches: **#1**, **#16**.

### Disabling "Wi-Fi only" must not retroactively reroute in-flight transfers

The setting governs future scheduling eligibility, not active work. If toggling the setting cancelled or restarted current transfers, the user's tap on a switch had a much larger consequence than they signed up for.

Touches: **#1**.
