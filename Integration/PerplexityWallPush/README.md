# Perplexity Wall Registry Push

Pushes measured wall data from the TUDM app into a backend proxy that becomes the source of truth for Perplexity render control.

The rule that makes this safe: **Swift pushes measurements, the backend holds the API key, Perplexity only ever receives validated structure.**

```text
TUDM app on iPad
  -> validates the wall chain locally
  -> POSTs registry JSON (+ optional X-Wall-Push-Token)
  -> backend proxy  [PPLX_API_KEY lives only here]
  -> stores latest registry
  -> optionally forwards a validated summary to Perplexity
```

## Where things live

The app is a Swift Playgrounds package, so all Swift files sit flat inside
`TUDM - PERPLEXITY 4-1.swiftpm/` and no target membership has to be set by hand:

| File | Purpose |
| --- | --- |
| `WallRegistryModels.swift` | `WallRegistryEnvelope`, its nested `WallSegment` / `WallSegmentKind`, `VerticalReferences`, and all validation |
| `WallRegistryPushClient.swift` | `WallRegistryPushClient` (POST), `WallRegistryPushSettings` (endpoint + token), response and error types |
| `WallRegistryWall1Example.swift` | Corrected Wall 1 source of truth, in code |
| `WallRegistryBridge.swift` | Converts the app's own `WallSpec` / `Room` into a registry envelope |
| `WallRegistryPushView.swift` | "Validate Wall" and "Send to Perplexity" screen for an existing wall |
| `WallRegistryChainParser.swift` | Parses a pasted chain string (`C1=8in \| Z1=43in \| …`) into segments |
| `WallRegistryChainDraft.swift` | Editable text-first draft of an envelope, plus all-at-once validation |
| `WallRegistryChainEntryView.swift` | Chain entry / editing screen — rows, paste-import, validate, preview, push |
| `WallRegistryPushSections.swift` | Backend-proxy section, last-push section, payload preview, locked-rules footer, shared by both screens |

Where the chain entry screen is wired in:

- `InteriorAuthorityRootViews.swift`, `RoomDetailView` — the **Perplexity Wall Registry**
  section has a **Chain Entry / Editor** row that opens it seeded with the Wall 1
  template and this room's ID.
- `WallRegistryPushView.swift` — **Edit Chain by Hand…** opens it seeded from the wall
  currently being pushed.

Backend, schema, and JSON reference live here in `Integration/PerplexityWallPush/`
so nothing non-Swift is dragged into the app target.

The hand-edited sync files live at the repo root in `WallRegistrySync/` — one JSON file
per wall plus a floorplan index, kept there so they are the first thing visible when the
repo is opened in Working Copy. See `WallRegistrySync/README.md`.

## Wall 1 source of truth

```text
C1=8in | Z1=43in | C2=8in | Z2=12.75in | Z3A=5in | Z3B=96in | Z3C=5in | Z4=12.75in | C3=8in | Z5=39.5in | C4=8in
```

Total: `246 in`

Locked meaning:

- `Z2` is a clear **left** wall return. It is not part of the window unit.
- `Z4` is a clear **right** wall return. It is not part of the window unit.
- `Z3B` is the window unit and stays `96 in x 60 in`.
- Window panel split stays `22 / 52 / 22`.
- Global structural IDs continue across the room and do not restart wall by wall.

This exists in three places that must stay in agreement:

- `TUDM - PERPLEXITY 4-1.swiftpm/WallRegistryWall1Example.swift`
- `Integration/PerplexityWallPush/examples/wall1_registry_example.json`
- `WallRegistrySync/wall_1_registry.json` — the editable Working Copy file

## How to set the endpoint

There is no endpoint baked into the source, on purpose. Set it at runtime:

1. Open a project, then a room.
2. Scroll to the **Perplexity Wall Registry** section and tap a wall.
3. Under **Backend Proxy**, enter your URL, e.g. `https://your-backend.example.com/wall-registry`.
4. If your backend sets `WALL_PUSH_TOKEN`, enter the same value in the token field.

Both values are saved in `UserDefaults` on that device only. They are never written
into the repo, so there is nothing to accidentally commit from Working Copy.

## How to validate locally

**In the app (no backend needed).** Open the push screen for a wall and tap
**Validate Wall**. It checks:

- room ID and wall ID are non-empty
- there is at least one segment
- every segment has a non-empty global ID and a width greater than zero
- global IDs are unique
- segment widths add up to the wall's expected total
- any panel split adds up to that segment's own width

Tap **Preview Payload** to read the exact JSON that would be sent.

The tolerance is `0.001`, matching the backend, so the app never accepts a wall the
proxy would reject.

**Against the JSON reference.** From `Integration/PerplexityWallPush/`:

```bash
python3 -c "
import json
r = json.load(open('examples/wall1_registry_example.json'))
total = sum(s['width'] for s in r['segments'])
print('total', total, '==', r['expected_total_width'], total == r['expected_total_width'])
"
```

## How to push from the app

1. Enter the endpoint once (above).
2. Tap **Validate Wall** and confirm it is green.
3. Tap **Send to Perplexity**.
4. Read **Last Push** — stored total, timestamp, and the backend's next-step note.

If the backend rejects the push, its own message is shown, not a bare status code.

The push always re-validates before it sends, so **Send to Perplexity** is safe to
tap directly.

## Entering a chain by hand

Use **Chain Entry / Editor** when a wall exists on paper before it exists in the app,
or when a measurement needs correcting straight into the registry. Nothing here
requires editing Swift source.

Two input methods, both editing the same draft:

1. **Row editor.** Each row is global ID, kind, label, width, optional height, and
   optional panel split. Widths accept `43`, `12.75`, `12 3/4`, or `12-3/4`. Use the
   **Edit** button to reorder rows left-to-right along the wall or delete them.
2. **Paste / import.** Paste a chain and tap **Parse Chain String**:

   ```text
   C1=8in | Z1=43in | C2=8in | Z2=12.75in | Z3A=5in | Z3B=96in | Z3C=5in | Z4=12.75in | C3=8in | Z5=39.5in | C4=8in
   ```

   Entries separate on `|`, `;`, `,`, or new lines. Per entry you can add a height
   (`Z3B=96in x 60in`) and a panel split (`Z3B=96in(22/52/22)`). Parsing replaces all
   rows; any ID that matches the Wall 1 source of truth keeps its kind, label, and
   notes, so a re-pasted Wall 1 chain comes back fully described rather than as bare
   widths.

Actions on the screen: **Load Wall 1 Template**, **Parse Chain String**,
**Validate Chain**, **Preview Payload**, **Send to Perplexity**. The endpoint and
token fields are the same `WallRegistryPushSettings` as the per-wall push screen, so
they only need to be entered once per device.

**Validate Chain** reports every problem at once — missing room or wall ID, duplicate
global IDs, unparseable or non-positive widths, a panel split that does not sum to its
segment, and an expected total that does not match the segment total. When the totals
disagree, a one-tap **Set Expected Total to …** button is offered. Rows also show their
own inline error while being typed.

The two locked rules are printed on the screen itself:

- Clear wall returns (`Z2` / `Z4` style) beside a window unit stay separate locked
  zones and are never absorbed into the window unit.
- Global IDs are continuous across the room and do not restart per wall.

This screen edits the **registry payload**, not the app's `WallSpec`. For a wall that
should live in the app permanently, build it with **Add Wall** and let
`WallRegistryBridge` derive the registry.

## Running the backend

From `Integration/PerplexityWallPush/backend/`:

```bash
npm install
cp .env.example .env      # then fill it in
npm start                 # http://localhost:8787
```

Test it without the app:

```bash
curl -X POST http://localhost:8787/wall-registry \
  -H "Content-Type: application/json" \
  --data @../examples/wall1_registry_example.json
```

Expected:

```json
{
  "ok": true,
  "message": "Wall registry received, validated, and stored.",
  "room_id": "family_room",
  "wall_id": "W1",
  "total_width": 246
}
```

Other routes: `GET /health`, `GET /wall-registry/latest`.

To reach it from the iPad on the same network, use your machine's LAN IP
(`http://192.168.x.x:8787/wall-registry`) rather than `localhost`.

For real use, deploy to Render, Railway, Fly.io, a Vercel serverless function, or
your own server, and set `PPLX_API_KEY` as an environment variable there.

## What not to commit

Already covered by the repo's `.gitignore`, but worth knowing:

- `.env` — commit only `.env.example`
- `PPLX_API_KEY` or any Perplexity key, in any file
- `WALL_PUSH_TOKEN` values
- deployment secrets, personal access tokens, `node_modules/`
- `backend/data/` — pushed registry snapshots

The Swift side has nothing to leak: the endpoint and push token are entered in the
app and stored in `UserDefaults`, and there is no Perplexity key in the app at all.

## Working Copy notes

- `WallRegistrySync/` is the folder to edit on the iPad: `wall_1_registry.json` through
  `wall_4_registry.json` and `floorplan_registry.json`. Wall 1 is measured; Walls 2-4 are
  templates marked `"status": "needs_measurement"` so no dimension is ever invented. The
  floorplan file holds wall order and the room-wide structural ID policy.
- Those files use the same field names as the push payload, plus a `sync` block for
  editing metadata. The backend ignores unknown top-level fields, so a wall file whose
  `sync.status` is `ready` can be POSTed as-is.
- Commit whenever a structural chain changes, e.g. `Correct Wall 1 returns and right bookcase`. Git history is the audit trail for dimension corrections.
- Swift Playgrounds shows the `.swiftpm` folder as the app; `Integration/` sits beside it and is invisible to the app target.
- Before committing, glance at the diff for `.env` or any key-shaped string.

## Adding new walls

Build the wall normally in the app. `WallRegistryBridge` derives the registry from
the app's own `WallSpec`, so no second source of truth is needed. Two behaviours are
worth knowing:

- **The app's `label` becomes the registry `global_id`**, and the app's `note`
  becomes the registry `label`. So label a segment `Z2` and note it
  "Left clear wall return".
- **Openings expand into three segments.** A window with casings becomes
  `<id>A` (left casing) / `<id>B` (unit) / `<id>C` (right casing), mirroring
  `Z3A | Z3B | Z3C`. This is what keeps clear wall returns from being absorbed into
  the window unit, and it lets the panel split sum to the window's own width instead
  of the casing-inclusive width. Segments with no casing keep their plain ID.

Panel splits come from the opening's panel `widthShare` values, scaled to the unit
width, with rounding drift absorbed into the last panel so the split always matches.

## Production notes

- Treat photoreal renders as presentation output only. The registry stays the measurement authority.
- Keep `examples/wall1_registry_example.json` as the visible, reviewable measurement reference.
- The renderer may color, texture, shadow, and enhance lines only inside the measured framework.
