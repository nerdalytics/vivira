# Vivira UX Flow Design

**Status:** Draft (awaiting user review)
**Date:** 2026-05-16
**Scope:** End-to-end UX flow from first launch through ongoing background sync. Behavior and screens only — not implementation. iOS 26.5 target.

---

## 1. App identity

Vivira is a **shared-album subscriber** for self-hosted Immich. The user subscribes one or more iPhones to one or more Immich albums (typically *shared* albums collaborated on by family or friends) and Vivira keeps those albums reflected on the iPhone. Subscriptions can also send the user's own photos into the same album, making it bidirectional for participatory shared albums.

Vivira is **not** a personal photo backup app. Personal backup is well served by iCloud and by Immich's own mobile clients; Vivira's niche is the shared-album case.

**Three principles**, applied to every screen and interaction:

- **No surprises.** Every state change is announced. Every destructive action confirms. iOS constraints are disclosed in plain language, not hidden.
- **Consistent UX spine.** One page structure, one banner pattern, one destructive pattern, one empty-state pattern. See §12.
- **Photos that are sacred are protected, photos that are mirrored are eligible.** Vivira tracks which iPhone photos arrived via subscription. Only those photos respond to remote changes. Pre-existing photos in the user's library are never touched.

---

## 2. State machine

Five canonical app states. One screen per state. Transitions are explicit; nothing silent.

```
NotConnected ── "Add server" ───────▶ Onboarding (wizard)
Onboarding   ── complete ───────────▶ Connected
Connected    ── add server / album ─▶ Onboarding (sub-flow)
Connected    ── network / auth fail ▶ Connected (Degraded)  [banner, non-blocking]
Connected    ── disconnect last  ───▶ NotConnected
```

**Resumability:** If onboarding is interrupted (process kill, network failure, OS prompt declined), the next launch returns to the exact step the user was on, not to the start of the wizard.

---

## 3. Account model

Vivira supports multiple Immich servers per device. Each server has its own credentials, capabilities, and list of subscriptions.

```
Account
├── settings (app-wide)
│   ├── wifiOnly: Bool                    [default: true]
│   ├── lowPowerDefer: Bool               [default: true; pauses when ProcessInfo.isLowPowerModeEnabled is true]
│   ├── safetyFloorBytes: Int64           [default: 2 GB; editable in advanced settings]
│   ├── notifyOnSpaceEvent: Bool          [default: true; rare events]
│   ├── notifyOnLongTransferComplete: Bool [default: false; opt-in for >1 h transfers]
│   └── notifyOnDownloadReview: Bool      [default: false; for manualReview subscriptions]
└── Servers [0..N]
    ├── id              (stable UUID, local-only)
    ├── nickname        (user-editable; default = hostname)
    ├── url             (Caddy / Immich / proxy URL)
    ├── credentials     (API key in Keychain; or access token from /auth/login)
    ├── capabilities
    │   └── resumableUpload: Bool
    └── subscriptions [0..N]
        ├── id          (stable UUID, local-only)
        ├── sourceAlbumId   (Immich album UUID)
        ├── sourceName  (Immich's album name, read-only mirror)
        ├── localName   (user-editable display label; default = sourceName)
        ├── uploadMode      ( off | auto | manualReview )       [default: off]
        ├── downloadMode    ( off | auto | manualReview )       [default: auto]
        ├── placement       ( photosLibrary | viviraOnly )
        ├── deleteOnRemove  ( ask | auto )
        ├── priority        ( high | normal | low )         [default: normal]
        ├── sendOrder       ( photosFirst | videosFirst | captureOrder )  [default: photosFirst; relevant only when uploadMode = auto ]
        ├── paused: Bool
        └── queueItems [0..N]
            ├── assetRef
            ├── direction   ( upload | download )
            ├── state       ( queued | inFlight | done | deferred | stuck )
            ├── deferReason ( insufficientSpace | awaitingWifi | awaitingCharging | subscriptionPaused )   [if state = deferred]
            └── stuckReason ( sizeExceedsDevice | serverRejected | authExpired | localFileMissing | maxRetriesExceeded ) [if state = stuck]
```

Each server, each subscription is independent. One server can be Caddy-fronted (resumable uploads supported), another can be bare Immich (standard uploads only). The UX adapts per server.

**Device identity:** Vivira generates a stable `deviceId` (UUID) at first launch and stores it in Keychain. This is used as the `deviceId` query parameter in Immich asset upload, dedup, and search calls.

---

## 4. Onboarding — composable mini-flows

Three reusable mini-flows. Three user-facing compositions.

### 4.1 Mini-flow: ServerMini

Three steps. Reused whenever a new server is added.

**Step S1 — Server URL**
- Single text field. Paste detection. URL normalization (trim, infer protocol).
- HTTP accepted (LAN / immich.local). Non-blocking note when HTTP: *"This server is unencrypted. Fine on a local network; risky over the public internet."*
- On Continue: `GET /server/ping`. Specific failures: *unreachable*, *not an Immich server*, *TLS error*.
- Below the field, after a successful ping, show server identity: `GET /server/about` returns version and instance URL; Vivira displays as small confirmation text.

**Step S2 — Authenticate**
- Two segmented options on one screen:
  - **API key** (default) — paste field. Validates via `GET /auth/status` with `x-api-key` header.
  - **Email + password** — two fields. Calls `POST /auth/login`, stores returned access token in Keychain.
- Continue activates only when the server returns success.
- Failures: *invalid credentials*, *server rejected key*, *network*. Each gets a distinct message.

**Step S3 — Capability probe (passive)**
- Vivira performs an IETF resumable-upload probe (1-byte upload with `Upload-Incomplete: ?1` then HEAD on the upload resource).
- Result displayed inline on the same screen as a small chip:
  - ✓ **Resumable uploads supported** — proceed normally.
  - ⓘ **Standard uploads only** — proceed with a non-blocking warning sentence: *"Large files may need to restart from zero if interrupted."*
- No user action required. Continue is enabled either way.

### 4.2 Mini-flow: SubscriptionMini

Two steps. Reused whenever a new subscription is added (during app onboarding, or later via "+ Subscribe to another album").

**Step P1 — Pick album**
- Live list fetched from `GET /albums`. Shared albums grouped first under a "Shared" header with "shared with N people" subtitle. Owned albums grouped under "Mine".
- Search field at top, multi-select. At least one selection required to continue.
- After multi-select, Step P2 is shown once with a toggle at the top: *"Apply these settings to all N selected albums."* On (default) → one P2 screen creates N identical subscriptions. Off → P2 is repeated once per selected album with its own choices.

**Step P2 — Set behavior** *(per selected album, or batched)*

One screen per album with the decisions below. All pre-filled to sensible defaults so the user can tap Continue without touching anything.

| Field | Default | Options | Notes |
|---|---|---|---|
| Send my photos to this album | Off | Off · Auto · Review first | Auto = silent background upload of matching assets. Review first = nothing leaves the device until the user picks. Off = never sends. |
| Get photos from this album | Auto | Off · Auto · Review first | Auto = new arrivals download in the background. Review first = new arrivals appear in the Sync Sheet as a download queue (lets the user avoid filling storage with content they didn't want). Off = the subscription only sends; remote changes are not tracked locally. |
| Where photos land | Photos library | Photos library · Vivira only | See §10 for tradeoffs. The two-card chooser from §10 is rendered inline. Hidden when downloadMode = Off (nothing lands). |
| When removed from album | Ask before deleting | Ask · Auto-prompt | Only shown when Photos library is selected and downloadMode ≠ Off. *(Vivira-only mode is always auto, shown as info.)* |
| Priority | Normal | High · Normal · Low | Compact segmented control. |
| Send order *(only when uploadMode = Auto)* | Photos first | Photos first · Videos first · Capture order | |

Local label (rename) is **not** asked in this step. Defaults to source name; rename available later from detail screen.

### 4.3 Mini-flow: GlobalMini

Two steps. App-wide, asked exactly once during first-time onboarding.

**Step G1 — Conditions**
- Toggle: Wi-Fi only *(default ON)*
- Toggle: Only while charging *(default OFF)*

**Step G2 — Permissions**
- Photo library access — `PHPhotoLibrary.requestAuthorization(for: .readWrite)`. Required. If declined, app explains why it can't proceed and offers to retry.
- Background Resource Upload Extension consent — only requested if any subscription has Two-way or Send direction. Triggers the system prompt. If declined, sync still works; uploads happen only when the app is foreground. Stated plainly, not retried in a loop.
- Notifications — optional, opt-in. Used for "photos removed remotely" surfacing. Default off. Recoverable from Settings later.

### 4.4 Compositions

**App onboarding (first launch, zero servers configured):**

```
Welcome  →  ServerMini (S1, S2, S3)  →  SubscriptionMini (P1, P2)
        →  GlobalMini (G1, G2)  →  First sync confirmation  →  Done
```

The **First sync confirmation** is a single screen showing per-subscription counts and bytes, broken out by upload and download direction and reflecting whether each side is automatic or review-first:

```
Ready to sync

Family 2026 (Home Immich)
   ↑ 12 of your photos will upload (~32 MB) — automatic
   ↓ 247 photos available (~890 MB) — you'll review before downloading

Vacation Greece (Home Immich)
   ↑ 8 of your photos will upload (~21 MB) — automatic
   ↓ 89 photos (~340 MB) — automatic

[ Start ]
```

Auto sides commit on Start. Review-first sides only announce the queue; nothing downloads until the user picks from the Sync Sheet (§7).

**Add server later (from Account → + Add another server):**

```
ServerMini (S1, S2, S3)  →  "Subscribe to your first album?" (yes / not yet)
                         →  SubscriptionMini (if yes)  →  Done
```

No GlobalMini — conditions and permissions are app-wide and already set.

**Add subscription later (from main list → + Subscribe to another album):**

```
(If multiple servers exist) Server picker  →  SubscriptionMini (P1, P2)  →  Done
```

Single-server users skip the picker.

### 4.5 Visual structure for every onboarding step

- Large title at top
- Optional subtitle
- One focused decision in the body
- Progress dots top-center
- Back chevron top-leading (system style)
- Continue button pinned bottom-trailing
- All inputs validate inline; Continue is disabled until the step is valid

---

## 5. Connected root screen

Hybrid layout: hero status card at top, subscription list as main content, settings sections below. One scrolling screen.

### 5.1 Hero card (always present)

When idle:
```
✓ Connected · 2 servers · 3 active subscriptions
Last synced 2 min ago
```

When active:
```
✓ 2 servers · 3 active subscriptions
↑ Uploading photo 47 / 110             Family 2026
↓ Downloading IMG_3041.heic 412/1200   Hiking Group
↓ Downloading family.heic 88/1200      Family 2026
Queue: 60 photos · 100 videos (videos wait per send-order)
```

When degraded (one server unreachable, auth expired, server returning errors):
```
⚠ Friends Immich: auth expired — tap to renew
✓ Home Immich: 2 subscriptions active
↑ Uploading photo 47 / 110             Family 2026
```

The degraded line is a tappable inline banner — opens the relevant server detail.

### 5.2 Subscription list

Multiple servers → grouped by server with server header. Single server → flat list, no header.

```
Subscriptions
─────────────────────────────────
Home Immich
   Family 2026             shared · 3 people    >
   ↑ Auto · ↓ Review first · In Photos
   12 sent · 27 available · 2 pending delete
   ────
   Vacation Greece         shared · 5 people    >
   ↑ Auto · ↓ Auto · In Photos
   89 sent · 247 fetched

Friends Immich
   Hiking Group            shared · 12 people   >
   ↓ Auto · In Vivira
   1,012 fetched

+ Subscribe to another album
```

Each subscription row shows: local label (top), source name as subtitle if different, **mode line** (upload + download mode with placement), and **counts line** (sent / fetched / available / pending review / pending delete / Stuck — only categories with non-zero counts shown). Off-mode sides are omitted from the mode line (e.g., a Hiking Group with uploadMode=off shows only `↓ Auto`).

Tapping a subscription opens the subscription detail screen (§6). Long-press → Rename / Pause / Unsubscribe context menu.

### 5.3 Sections below the subscription list

**Conditions** (app-wide)
- Wi-Fi only
- Pause while Low Power Mode

**Servers**
- One row per server: nickname, hostname (small), capability badge (✓ resumable / ⚠ standard uploads)
- Tap → server detail screen (rename, edit credentials, disconnect, sign out)
- `+ Add another server` row at bottom

**Appearance** (app-wide)
- A row of 5 swatches, one per theme, rendered in the current colorScheme. The selected theme carries a 2pt `color.ink` ring with a 2pt `color.surface` gap (donut style). Tap to switch instantly; no apply button. Caption beneath the row names the current theme.

**About**
- Version, license, debug log toggle, link to docs.

---

## 6. Subscription detail screen

Pushed from a subscription row in the root list.

```
Family 2026                                    [Pause] [Unsubscribe]
shared · 3 people · on Home Immich
Original on Immich: Familie 2026

Album name on this iPhone        Family 2026                    >
Send my photos to this album     Auto                           >
Get photos from this album       Review first                   >
Where photos land                Photos library                 >
When removed from album          Ask before deleting            >
Priority                         Normal                         >
Send order                       Photos first                   >

Counts
   12 sent
   27 available to download (review queue)
   247 already downloaded
   2 pending your review (delete)
   0 Stuck

Activity                                                         >
   (most recent 5 events inline; tap to see full log)
```

Rows whose preconditions aren't met are hidden (e.g., "Send order" hides when `uploadMode = Off`; "When removed from album" hides when `downloadMode = Off` or placement is Vivira-only; "Where photos land" hides when `downloadMode = Off`).

### 6.1 Album view

A per-subscription screen reached from a *"View album"* row in the subscription detail. Shows every asset in the Immich album with its current sync status on this device, unifying what would otherwise be three separate surfaces (manual review queue, deferred items, stuck items).

```
Family 2026 — Album view                         [Filter ▼]

Showing: All ▼  (All · Not synced · Deferred · Stuck · Awaiting review)

[thumb]  IMG_3041.heic              Synced
[thumb]  family_4k.mov   (200 GB)   Deferred — not enough space
                                       [ Free space and retry ]
[thumb]  beach.mov                  Awaiting your review
                                       [ Download ] [ Skip ]
[thumb]  ski.mov         (300 GB)   Stuck — larger than this device
                                       [ Skip permanently ]
[thumb]  IMG_3042.heic              Downloading 47%
[thumb]  IMG_3043.heic              Not yet synced (queued)
```

- Thumbnails fetched lazily via `GET /assets/{id}/thumbnail`; cached locally. The view does not require the originals to be present on device.
- Each row shows: thumbnail, filename, size *(when relevant — large items only)*, state badge, reason if applicable, inline actions appropriate to the state.
- Filter chip at top toggles between *All*, *Not synced*, *Deferred*, *Stuck*, *Awaiting review*. *Not synced* is the union of every non-Synced state.
- Inline actions follow §8.5's reason-action mapping. *Skip permanently* never appears on Deferred rows — only on Stuck rows where the reason is genuinely permanent (e.g., `sizeExceedsDevice`).
- Tapping a row opens a larger preview with EXIF / capture date / filename / current state. Useful for deciding what to keep when space is tight.

Each row is read-as-current-value, tap to edit. Same row pattern as iOS Settings.

**Rename** lives in the "Album name on this iPhone" row. Editing updates the local label only — Vivira does not rename the album on Immich.

**Source rename detection:** if the Immich-side album name changes (detected during sync), a small badge appears at the top of this screen: *"Source renamed to 'Familie 2026 v2' — tap to adopt"*. User chooses whether to update the local label or keep theirs. Never automatic.

**Pause** halts both upload and download for this subscription. Hero card and root list show paused state. Resume from the same button.

**Unsubscribe** opens a confirmation screen with two paths:
- **Keep photos on this iPhone** (default highlight) — un-tracks them; they become normal user photos.
- **Also remove from this iPhone** — triggers iOS deletion prompt batched across all subscription-tracked photos. Photos library mode subject to system prompt; Vivira-only mode silent.

Unsubscribe never deletes on the Immich side.

---

## 7. Sync Sheet on foreground

The Sync Sheet is the foreground surfacing of pending user-decisions. Shown once per session (or once per cold launch) over the root view, dismissable.

### 7.1 What appears in the sheet

- **Download review:** new photos available in subscriptions where `downloadMode = manualReview`. Only thumbnails have been fetched; nothing is on the device yet.
- **Deletion review:** photos removed by others from subscribed albums that the user needs to confirm removing from this iPhone (Photos library mode only).
- **Deferred (newly surfaced):** items that just transitioned to Deferred since the last session — typically due to insufficient space. Surfaced **once** here as a heads-up; on subsequent sessions they live in the Album view (§6.1), not the Sync Sheet, because they don't need repeated user action.
- **Stuck items:** transfers that have failed permanently or with reasons only the user can resolve (see §8.5 reason taxonomy).
- **Source rename adoption** prompts (only if >0 albums have been renamed remotely since last visit).

Empty state of the sheet (nothing pending in any category) = sheet does not appear.

### 7.2 Layout

Categories are stacked in fixed order (Download review → Deletion review → Stuck → Source rename adoption). Each category section is independently dismissable via Later; remaining categories stay visible.

```
Sync changes

27 photos available to download

[thumb] [thumb] [thumb] [thumb] [thumb] +22

Family 2026 (Home Immich) — 27 photos

[ Download all 27 ]
[ Review and choose ]
Later

────────────────────────────────
3 photos removed by others

[thumb] [thumb] [thumb]

Family 2026 (Home Immich)      — 2 photos
Hiking Group (Friends Immich)  — 1 photo

[ Remove from this iPhone (3) ]   ← primary, batched
[ Review individually ]
Later

────────────────────────────────
1 download deferred — not enough space

   family_4k.mov (200 GB)  · Family 2026
   Your iPhone will be below 2 GB free after this lands.

   [ Free space and retry ]   ← opens iOS Settings → iPhone Storage
   [ See in Album view ]
   Later  *(item moves to Album view; system retries when space frees up)*

────────────────────────────────
1 item Stuck

   ski.mov (300 GB) — larger than this device
      [ Skip permanently ]
```

**Download review section** mirrors the deletion section's structure: a primary "Download all N" button and a secondary "Review and choose" button. Review opens a swipeable thumbnail screen where the user toggles individual photos, then confirms only the selected ones. Items not selected stay in the review queue until next session. Items confirmed for download enter the standard download queue per §8 fairness rules.

**Deferred section** appears only the first session after a deferral event. After the user dismisses it (any of *Free space and retry*, *See in Album view*, or *Later*), deferred items live in the Album view, not the Sync Sheet. The system continues to retry deferred items automatically when conditions allow (§8.6).

**Stuck section** shows only reasons that are genuinely permanent or require user action that can't be auto-resolved. Per-reason actions follow §8.5's mapping. No one-size-fits-all action list.

### 7.3 Batched deletion

**Remove from this iPhone** routes every pending deletion across every subscription into a single `PHPhotoLibrary.performChanges` block with one `deleteAssets` call. iOS shows **one** system confirmation prompt for the entire batch. Multiple deletion sources → one prompt, not many.

**Review individually** opens an expanded view: swipeable thumbnails, tap to toggle "keep this one" (Vivira un-tracks it — it becomes a normal photo, never asked about again). Then "Remove the remaining N" routes back to the batched delete.

**Later** dismisses for this session. Items remain pending. Subscription rows still show "N pending review" badges.

### 7.4 Vivira-only subscriptions

Vivira-only placement mode handles deletes without the sheet — they happen automatically when the sync detects removal. No prompt because the photos never entered the Photos library. The sheet shows them only when there's something else for the user to decide.

### 7.5 Notifications (opt-in)

If notifications are enabled, a local notification fires when the deletion-review queue grows by ≥ 1 since the last sync. Tap → opens the app directly to the Sync Sheet. Default off because most users won't want it; some will.

---

## 8. Queue model

### 8.0 Queue as derived state

The queue is a derived view, recomputed from current truth on every meaningful event: foreground transition, system wake, network reconnect, pause and resume, sync stream tick.

**Stored facts:**

- `done` records, per asset per subscription. *This asset is synced; do not redo.*
- `stuck` records with the `skipped permanently` flag. *This asset is excluded; do not re-queue.*
- `inFlight` reservations. *This asset is mid-transfer; bytes-on-disk and progress are tracked.*
- `deferred` records with reason. *This asset failed a precondition (space, network, charging); retry when conditions allow.*

**Derived membership, recomputed on demand:**

- The contents of `queued`. The reconciler computes this from current local and remote state, subtracting the stored facts above.

**Consequences:**

- **Pause** halts the active transfer slots. The stored facts (`done`, `stuck`, `inFlight`, `deferred`) are not touched.
- **Resume** reconciles against current truth: items deleted remotely during the pause drop out, items added remotely join, items still pending upload remain pending as long as the local file still exists.
- After a long offline period, the reconciler runs against the latest sync stream. The queue from before the disconnect is not replayed.
- Already-synced assets cannot re-download or re-upload. `done` records dedupe downloads. `POST /assets/exist` (§9.3) dedupes uploads.

### 8.1 Concurrency budget

- **Per server:** 2 uploads + 2 downloads simultaneously
- **Across servers:** capped at 4 total transfers
- **On cellular** (when Wi-Fi-only is off, which is non-default): drops to 1 + 1 per server, 2 total
- Not configurable in the UI; tunable via debug menu only

The PhotoKit Background Resource Upload Extension runs concurrently and is system-managed — system decides its own concurrency. Vivira's queue budget governs our URLSession-controlled transfers (the "Upload now" override path, all downloads).

### 8.2 Scheduling rules

Applied in priority order:

1. **Subscription priority** (high / normal / low) — High gets 2× weight in slot allocation, Low gets 0.5×. Weighted round-robin per server.
2. **Within a subscription, asset class order** per the `sendOrder` field — default photosFirst. Videos wait for the photos queue of the same subscription to drain.
3. **Within asset class, FIFO** — oldest queued first.
4. **Anti-starvation bump** — any single item waiting > 24 h is promoted one priority level. Prevents permanent starvation of low-priority videos behind a long stream of higher-priority photos.

### 8.3 Direction fairness

Upload and download queues are independent. They use different bandwidth lanes on most home networks; blocking one to favor the other is wasteful. The 2 + 2 default is the cleanest expression of this. Both run continuously, each governed by the scheduling rules in §8.2.

### 8.4 What the user sees

- **Hero card** (§5.1) shows the *currently active* transfers and a summary queue line.
- **Subscription detail** (§6) shows per-subscription counts but not a full queued list.
- **No "Transfers" inspection screen** in v1 — see §13.

The summary line in the hero ("Queue: 60 photos · 100 videos (videos wait per send-order)") is the honest disclosure of the photos-first default. No mystery about why videos sit.

### 8.5 Stuck and Deferred policy

Transfer-failure states split into two qualitatively different buckets. Same item can transition between them based on cause.

**Deferred** — temporary obstacle, system will keep retrying automatically when conditions change. User does *not* need to act; surfaced to the user as informational, not actionable beyond optional shortcuts. Lives in the Album view (§6.1) after first surfacing.

| Reason | Trigger | Retried when | Inline actions |
|---|---|---|---|
| `insufficientSpace` | Pre-resume check (§8.6) computes residual < safety floor | Free space increases (foreground sweep, periodic check, post-completion of other items) | *Free space and retry* (deep-link to Settings → iPhone Storage) · *See in Album view* |
| `awaitingWifi` | Wi-Fi-only is on and current path is cellular | Wi-Fi connects | *(no action — informational)* |
| `awaitingCharging` | Charging-only is on and device on battery | Charger connects | *(no action — informational)* |
| `subscriptionPaused` | User paused the subscription | User resumes | *Resume subscription* |

**Stuck** — permanently wrong, or only user can fix. Auto-retry stops. Surfaced in the Sync Sheet (§7) and in the Album view until user resolves or skips.

| Reason | Trigger | Inline actions |
|---|---|---|
| `sizeExceedsDevice` | Asset size > total device physical capacity | *Skip permanently* *(only)* |
| `serverRejected` | Server returns 4xx for non-auth reasons (MIME unsupported, size limit, quota) | *Open server settings* · *Skip permanently* |
| `authExpired` | Server returns 401 / 403 | *Renew authentication* · *Skip permanently* |
| `localFileMissing` | Upload: asset no longer exists on device | *Skip permanently* |
| `maxRetriesExceeded` | 3 consecutive non-categorized failures or 72 h of zero progress | *Retry now* · *Skip permanently* |

**Skip permanently** appears only on Stuck rows, never on Deferred. A Skip-Permanent record is per-asset and remembered across launches — Vivira never re-queues it. User can reset via Album view (§6.1) → filter "Stuck (skipped)" → individual unskip.

Single confirmation before recording a Skip-Permanent. Reversible from Album view.

### 8.6 Space management

Reservation alone is not sufficient. Free space on the device can change at any time — App Store installs, photos taken outside Vivira, system caches, OS updates — none of which Vivira controls or knows about in advance. Space must be re-validated **immediately before each download attempt**, not on a periodic timer that runs *during* downloads.

**Definitions:**
- `safetyFloor` = `Account.settings.safetyFloorBytes` (default 2 GB)
- `freeSpace` = current value of `URL.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey])` on the relevant volume
- `inFlightReserved` = sum of `(totalBytes − transferredBytes)` for all in-progress downloads
- `residual(item)` = `freeSpace − inFlightReserved − item.totalBytes − safetyFloor`

**Rules:**

1. **Queue-time pre-flight** — when an item enters the download queue, compute `residual(item)`. If ≥ 0, item is queued as normal. If < 0, item enters `deferred` state with `deferReason = insufficientSpace`.

2. **Pre-resume check — background / wake-based paths.** Every time the system gives bytes to a download via a wake-based mechanism (PhotoKit Background Resource Upload Extension wake, `BGAppRefreshTask` callback, `BGProcessingTask` invocation), the space check runs **first, before any bytes are written**:
   ```
   if freeSpace < remainingBytesOf(item) + safetyFloor:
       transition item to deferred (insufficientSpace)
       end the wake without attempting transfer
   else:
       proceed with transfer for the duration of this wake
   ```
   The wake itself is the unit of work — wakes are short. A single check at start of wake catches the case where space was sufficient when scheduling happened but has since been eaten by another app. **No periodic check during the wake** is needed for these paths because the wake will end on its own.

2b. **Periodic check — foreground / sustained paths.** For `BGContinuedProcessingTask` runs and foreground URLSession transfers, a single pre-flight check is **not** sufficient. These tasks can run for hours without natural checkpoints, and external apps can consume space at any moment during the run. The check therefore runs at start **and periodically during the run** (default interval: 30 s; tunable in advanced settings):
   ```
   on start: pre-flight check (as in rule 2)
   while running:
       every 30 s, repeat the check
       if check fails:
           suspend URLSession upload/download task
           transition item to deferred (insufficientSpace)
           end the BGContinuedProcessingTask
           fire space-event notification
   ```
   This catches the App Store mid-run scenario for sustained transfers, which the wake-based check cannot cover (no wake boundary exists during a continuous run).

3. **Asset size > device physical capacity** — handled at queue-time as a direct transition to `stuck` with `stuckReason = sizeExceedsDevice`, not deferred. There is no future state where the asset fits, so it's correctly Stuck, not Deferred.

4. **Re-evaluation triggers** — Vivira re-checks deferred items in these moments:
   - Any in-flight download completes (released reservation)
   - App foreground transition (assume the user may have just freed space)
   - System wake of any background task
   - User explicitly taps *Free space and retry*

   Re-evaluation walks the deferred queue in priority order (per §8.2) and promotes any item whose `residual ≥ 0` to active. Promoted items wait for an available concurrency slot.

5. **Notification on defer event** — when an item transitions from `inFlight` or `queued` to `deferred` with reason `insufficientSpace`, a local notification fires *(governed by `Account.settings.notifyOnSpaceEvent`, default ON)*. Per-deferral, not per-asset: if 12 items defer in a batch from the same root cause, the user gets one notification summarizing the cause and count.

6. **Multiple volumes** — iOS apps see one logical volume per app sandbox. The `volumeAvailableCapacityForImportantUsageKey` accounts for purgeable caches and system reserves and is the right query for this decision.

The combined effect:

- **Background wake-based path:** a 200 GB download approved at start-of-wake under sufficient space, where the user installs a 50 GB game ten minutes in, is detected at the *next* wake — that wake ends without writing bytes, the item flips to deferred, the user gets one notification, and the next time space frees up, the system resumes from offset (RUFH) or from zero (no RUFH).
- **Foreground sustained path:** the same 200 GB download running via `BGContinuedProcessingTask` is detected at the *next 30 s periodic check* — the URLSession task is suspended on the spot, the item flips to deferred, the BGContinuedProcessingTask ends, and the user gets the same notification. Bytes already written stay on disk (basis for resumption); no bytes are written past the breach.

---

## 9. Upload strategy

### 9.1 Two paths

Both paths are RUFH-aware via URLSession. Whether RUFH actually engages depends on the server's capability (probed in §4.1 S3).

**Default path — silent background:**
- PhotoKit Background Resource Upload Extension (`PHBackgroundResourceUploadExtension`)
- System wakes the extension, processes upload jobs, retries on its own schedule, manages network and power
- Apple states the extension's underlying connection "will attempt to resume the upload using standard HTTP" if the server supports it. Expected behavior with a RUFH-aware proxy in front: drops resume from offset across wakes. Without RUFH support, each wake retries the upload from zero — the "stuck queue" risk that the warning in §4.1 S3 surfaces. Exact extension ↔ URLSession ↔ RUFH interop is verified during implementation (see §14 #1).
- Used for: all uploads, regardless of size, as the steady-state path

**Override path — "Upload now" foreground:**
- `BGContinuedProcessingTask`
- Triggered by explicit user action ("Upload now" in subscription detail, or batched start from the Sync Sheet)
- Shows system Lock Screen progress UI; survives app backgrounding for hours
- Used for: users who want a specific subscription's pending uploads to complete fast, not over multiple background wakes

### 9.2 Strategy interface

Internal protocol (informational, not UX):

```
protocol UploadStrategy {
    func upload(_ asset: PHAsset, to server: Server, in subscription: Subscription) async throws -> AssetMediaResponseDto
}
```

Day-one implementations:
- `BackgroundExtensionStrategy` — the silent default
- `ResumableViaURLSession` — used by the foreground override, also future-proofed for when RUFH is widely supported on the server
- `MonolithicMultipart` — fallback when RUFH probe returns "no support" and the override is invoked

Routing rule:
- Silent path → always `BackgroundExtensionStrategy`
- Foreground "Upload now" → `ResumableViaURLSession` if server has resumable capability, else `MonolithicMultipart`

### 9.3 Dedup before upload

Before submitting any upload job, Vivira batches the candidate asset's `localIdentifier` (Immich's `deviceAssetId`) plus the device's `deviceId` to `POST /assets/exist`. The endpoint returns which assets the server already has. Vivira skips those and marks them as already-synced for the subscription.

### 9.4 Visibility on shared albums

When a subscription has Send or Two-way direction, the uploaded asset is added to the corresponding Immich album via `PUT /albums/{id}/assets` immediately after upload. Send-only and Two-way are otherwise identical from an upload-flow perspective.

---

## 10. Per-subscription deletion semantics

The "Where photos land" choice in subscription onboarding (§4.2 P2) determines deletion behavior. The tradeoff is rendered inline as a two-card chooser:

| | **In Photos library** *(default)* | **In Vivira only** |
|---|---|---|
| Where photos appear | Apple Photos (visible everywhere) | Inside Vivira only |
| Syncs to iCloud / other Apple devices | Yes | No |
| Automatic delete when removed remotely | **No — iOS requires your tap to confirm each batch** | Yes, fully automatic |
| Mental model | Like a Photos album | Like a folder in another app |

This is an iOS constraint (`PHAssetChangeRequest.deleteAssets` always triggers a system prompt), not a Vivira choice. The chooser surfaces it honestly so the user picks with the tradeoff visible.

### 10.1 Photos library mode

- Vivira creates a `PHAssetCollection` matching the subscription's local label, owned by Vivira.
- New assets are added via `PHAssetCreationRequest.creationRequestForAssetFromImage(atFileURL:)` (or `forVideo`) and inserted into the Vivira-owned collection.
- Pre-existing user photos are never modified or moved.
- When the subscription detects remote removal, behavior depends on whether the asset is already on the device:
  - **Already downloaded** → the asset's local identifier is added to the subscription's pending-deletion list.
  - **Still pending review** *(downloadMode = manualReview, never downloaded)* → silently removed from the download review queue. Nothing for the user to confirm; the photo never landed locally. The review queue count decrements.
- The Sync Sheet (§7) batches all pending deletions across all subscriptions into one `deleteAssets` call → one iOS prompt.

### 10.2 Vivira-only mode

- Assets are stored in Vivira's app sandbox (e.g., `Documents/subscriptions/<id>/`).
- Visible only inside Vivira (in-app collection viewer, swipe-through, share-out via system share sheet).
- Remote removal triggers automatic local file deletion. No prompt. Fully automatic.
- Trade-off accepted by the user at subscription setup.

---

## 11. Per-server disconnect

Reached from Servers → [server] → Disconnect, in account settings.

Two paths, presented as cards on a single screen:

**1. Disconnect this server only** *(default highlight)*
- Stops all subscriptions on this server.
- Photos already fetched stay on the iPhone (in Photos library or in Vivira, depending on placement).
- Photos already sent to Immich stay on Immich.
- Single confirm button.

**2. Disconnect this server and delete remote contributions**
- Removes Vivira-uploaded photos from Immich (only photos Vivira sent — Vivira tracks which uploads it originated; other contributors' photos in shared albums are untouched).
- Photos on this iPhone are kept.
- Typed-confirm pattern ("type DELETE to confirm").
- Red button.

Local-side deletion on disconnect is **not** offered. To remove subscription content from the iPhone, the user unsubscribes (§6) first; that flow has the "Also remove from this iPhone" option.

When the last server is disconnected, the app returns to the NotConnected state (§13.1) with the "Add a server" empty state.

---

## 12. UX spine (consistent patterns across every screen)

These rules apply everywhere. Codify once, reuse.

| Element | Rule |
|---|---|
| Page structure | Large title, optional subtitle, grouped form sections, primary action pinned bottom-trailing. |
| Destructive | Red tint. Confirmation. Typed-confirm for the most destructive (server disconnect-with-delete, subscription unsubscribe-with-delete). |
| Success feedback | Soft haptic + top-anchored auto-dismissing banner. Never a modal. |
| Failure feedback | Persistent banner with **Retry** + **Details**. Never silent fail. |
| Loading | Inline progress (skeleton or progress bar). Never full-screen spinner over real content. |
| Empty state | One icon, one sentence, one CTA. |
| Background activity | Live Activity when a transfer exceeds 30 s; status bar pill otherwise. |
| Settings change preview | "This will queue 1,234 photos for upload" before Save. |
| Errors persist | Stuck items remain on the hero / Sync Sheet until acknowledged or resolved. |
| Buttons | Primary: filled tinted button. Secondary: bordered. Destructive: red filled. Never two filled-tinted on the same screen. |
| Reversibility | Every action shorter than typed-confirm is undoable for 5 s via a snackbar with Undo. |

### 12.1 NotConnected empty state

Shown only when zero servers are configured:

```
[ icon ]

Vivira keeps Immich shared albums
in sync with your iPhone.

[ Add a server ]
```

Single CTA opens app-level onboarding (§4.4 first composition).

### 12.2 Honest disclosures (recurring copy patterns)

These short phrases appear in fixed places. Not buried, not optional.

- After capability probe (when standard uploads): *"Large files may need to restart from zero if interrupted."*
- During Background Resource Upload Extension consent: *"Photos and videos upload silently in the background. You don't need to keep this app open."*
- In subscription onboarding behavior step, when Photos library is selected: *"Deletes need your tap to confirm."*
- In subscription onboarding behavior step, when Vivira only is selected: *"Visible only inside Vivira. Will not appear in Apple Photos or sync to iCloud."*
- In the queue summary line in the hero: *"Videos wait per send-order."*
- On the Stuck reason for any item: a one-sentence specific cause, never "failed".
- On a space-event notification: *"N item(s) can't sync right now — not enough space. Tap for options."*
- In the Deferred row of the Sync Sheet: *"Your iPhone will be below \[safety floor\] free after this lands."* — names the specific value of the floor, not a generic warning.

### 12.3 No-surprises rules (system invariants)

These are non-negotiable rules baked into the data layer, not just UI copy:

1. **Pre-existing user photos are never modified, never moved, never deleted by Vivira.** Vivira only touches assets it tracked into the library.
2. **No silent destruction.** Remote-triggered local deletion always passes through the Sync Sheet review (Photos library mode) or is fully automatic only in Vivira-only mode (which the user explicitly chose).
3. **No silent retries past a threshold.** After Stuck, items leave the active queue and surface to the user.
4. **No first-sync without confirmation.** The First sync confirmation step in app onboarding is mandatory. Subsequent syncs are automatic.
5. **Background work surfaces.** Live Activity on the Lock Screen when an active transfer exceeds 30 s.
6. **Errors persist until acknowledged.** Stuck items remain visible on the hero / Sync Sheet across launches.

---

## 13. Out of scope (deferred to v1.1+)

These were considered and explicitly excluded from v1 to keep the surface area focused.

- **Caddy / proxy server setup documentation.** Server-side ops is the user's responsibility. Vivira degrades gracefully when RUFH is absent (capability probe + warning).
- **Bandwidth caps** (Mbps limits). Wi-Fi-only and charging-only toggles cover the common case.
- **Per-subscription storage quotas** ("Use at most 5 GB for Hiking Group"). Worth revisiting once we see real usage.
- **Quiet-hours scheduling.** Cellular + Wi-Fi-only already covers most "don't sync now" cases.
- **Transfers detail screen** — full queue inspection with reorder controls. v1 surfaces only currently-active transfers + summary.
- **Global "Pause all" button.** Per-subscription pause is sufficient.
- **Manual share-sheet uploads** ("send this photo to a subscription via iOS share sheet"). Useful but distinct flow; defer.
- **In-app collection viewer for Vivira-only subscriptions.** v1 surfaces them as a tappable detail; full viewer (swipe, share-out, organize) is its own design.
- **Federation / cross-server sharing** of a subscription. Each subscription belongs to one server.

---

## 14. Open implementation questions (not UX)

To resolve during implementation, not blocking this spec:

1. **`caddy-rufh` version pinning** — verify the IETF draft version the module tracks matches what URLSession in our target iOS deploys. Document the tested pair in the project README.
2. **Caddy restart behavior** — verify whether `caddy-rufh` persists in-progress upload state across restart. If not, document for ops.
3. **Server-rename detection cadence** — when to call `GET /albums/{id}` to check for album name changes. On every foreground? On sync stream tick? TBD during implementation.
4. **Asset metadata round-tripping** — Immich's `metadata` field on upload and the `PHAsset` metadata model. Document mapping during implementation.
5. **Live Photos** — Immich accepts `livePhotoVideoId`. Handling of the paired motion-video upload pairing is implementation detail not UX-visible beyond "live photos work."
6. **Album role on contributors** — confirm that uploads to a shared album as a contributor (non-owner) are accepted by Immich's permissions model. Test during implementation.

---

## 15. References

### Apple / iOS

- [Uploading asset resources in the background](https://developer.apple.com/documentation/photokit/uploading-asset-resources-in-the-background) — `PHBackgroundResourceUploadExtension`
- [Finish tasks in the background — WWDC25 Session 227](https://developer.apple.com/videos/play/wwdc2025/227/) — `BGContinuedProcessingTask`
- [Build robust and resumable file transfers — WWDC23 Session 10006](https://developer.apple.com/videos/play/wwdc2023/10006/) — URLSession + IETF resumable uploads
- [PHAssetChangeRequest.deleteAssets](https://developer.apple.com/documentation/photokit/phassetchangerequest/1624062-deleteassets) — system confirmation dialog required

### Immich

- [Immich API — Authentication](https://api.immich.app/authentication)
- [Immich API — Server endpoints](https://api.immich.app/endpoints) (ping, about, config, features)
- [Immich API — Albums endpoints](https://api.immich.app/endpoints) (list, create, add/remove assets)
- [Immich API — Upload asset](https://api.immich.app/endpoints/assets/uploadAsset)
- [Immich API — Check existing assets](https://api.immich.app/endpoints/assets/checkExistingAssets)
- [Immich API — Sync stream](https://api.immich.app/endpoints/sync/getSyncStream)
- [Immich Discussion #23276 — chunked upload feature request status](https://github.com/immich-app/immich/discussions/23276)

### Resumable uploads (IETF draft)

- [draft-ietf-httpbis-resumable-upload](https://datatracker.ietf.org/doc/draft-ietf-httpbis-resumable-upload/)
- [tus/rufh-implementations — implementation registry](https://github.com/tus/rufh-implementations)
- [Murderlon/caddy-rufh — Caddy module](https://github.com/Murderlon/caddy-rufh)
