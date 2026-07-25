# WallRegistrySync

Working Copy friendly source-of-truth files for the room. One JSON file per wall, plus
one floorplan index. These are meant to be opened and edited by hand on the iPad in
Working Copy, then committed, so git history becomes the audit trail for every
dimension correction.

| File | What it is |
| --- | --- |
| `wall_1_registry.json` | Wall 1, measured and corrected. **Ready.** |
| `wall_2_registry.json` | Wall 2 template. Not measured yet. |
| `wall_3_registry.json` | Wall 3 template. Not measured yet. |
| `wall_4_registry.json` | Wall 4 template. Not measured yet. |
| `floorplan_registry.json` | Room index: wall order, which file is which, structural ID policy, room-wide rules. |

## Getting these files onto the iPad

1. In Working Copy, open the `TUDM` repository.
2. Pull the `wall-registry-push-integration` branch (checkout that branch first if you
   are sitting on `main`).
3. Browse to `TUDM - PERPLEXITY 4-1.swiftpm/WallRegistrySync/`. All six files are there.

The folder lives inside the `.swiftpm` package so it travels with the app source. The
app target's path is `.`, so `Package.swift` lists `WallRegistrySync` under `exclude` —
otherwise Swift Playgrounds would treat the JSON as unhandled package resources. If
Swift Playgrounds ever regenerates `Package.swift` and drops that line, the build still
works; you just get resource warnings until the `exclude` is put back.

**Working Copy push/pull is git transfer and history only.** It moves these files
between the iPad and GitHub and keeps the audit trail. It does not talk to the backend.
The app's **Sync / Send** flow is the separate path: it POSTs a `ready` wall to the
push endpoint (backend / perplexity). Editing a file in Working Copy does not push it to
the endpoint, and pushing to the endpoint does not commit anything.

## Wall 1 source of truth

```text
C1=8in | Z1=43in | C2=8in | Z2=12.75in | Z3A=5in | Z3B=96in | Z3C=5in | Z4=12.75in | C3=8in | Z5=39.5in | C4=8in
```

Total: `246 in`

- `Z2` and `Z4` are wall returns. They are **not** absorbed into the window unit.
- `Z3B` is the window unit: `96 in x 60 in`, panel split `22 / 52 / 22`.
- `Z3A` / `Z3C` are the window casings, kept separate so the panel split sums to the
  window's own width.

### Approved Wall 1 finish and construction decisions

These are persistent. They live in `wall_1_registry.json` as the wall-level `rules`
array plus per-segment `notes`, and in the app as `WallSegment.wallOneSeedSegments`
and `WallSegment.wallOneSeedNotes`.

**Structure**

- `C1` and `C4` terminate Wall 1. Nothing extends past them.
- Columns are `8 in` wide x `9.25 in` deep.
- Columns read more structurally defined than the wall returns.

**Shelves (`Z1`, `Z5`)**

- Open shelves, `9.25 in` deep, aligned with the column depth.
- Boards attach directly between the flanking columns.
- No bookcase boxes, no inset built-ins, no side panels.
- No base cabinets.
- Shelves read as boards, not cabinets or bookcases. Their registry `kind` is `shelf`,
  not `bookcase`, and the app's segment kind is **Shelf**, not **Bookcase**.

**Wall returns (`Z2`, `Z4`)**

- Flush wall returns, `12.75 in` each.
- Plain plaster, no seams.
- Flat and quiet. Structures, openings, casing, and shelves never absorb a wall return.

**Window (`Z3A` / `Z3B` / `Z3C`)**

- `5 in` casing all around. `Z3A` and `Z3C` are its `5 in` vertical legs.
- Frame and mullions are white.
- Side lights (`22 in` each) carry a grid pattern.
- Center panel (`52 in`) stays clear.

### Terminology

Call `Z2` / `Z4` a **wall return** or **return zone**, not generic wallspace. The chain
shorthand normalizes `WR` to `RZ`, but the semantic label stays "wall return" wherever
a human reads it.

## Editing a wall file

1. Open the file in Working Copy and edit the JSON.
2. Every segment needs `global_id`, `kind`, `label`, and a `width` greater than zero.
3. `expected_total_width` must equal the sum of the segment widths (tolerance `0.001`).
   The app and the backend both reject a mismatch, so this is the field to fix first
   if a push fails.
4. Any `panel_split` must add up to that segment's own width.
5. `global_id` values are unique across the whole room.
6. When a template becomes real, set `sync.status` to `"ready"` and fill in
   `updated_at`.
7. Commit with a message that names the change, e.g.
   `Correct Wall 1 returns and right bookcase`.

`sync.segment_template` in each template file is a copyable segment object. Copy it
into `segments`, renumber, set a real width, delete the `notes` line if it does not
apply.

## Structural ID numbering

Numbering is **continuous across the room**. It does not restart per wall.

Wall 1 consumes `C1`-`C4` and `Z1`-`Z5`, so the next new column anywhere in the room is
`C5` and the next new zone is `Z6`. The templates for Walls 2-4 therefore start at `C5`
/ `Z6` rather than at `C1`. `floorplan_registry.json` holds the authoritative
`next_column_id` / `next_zone_id` — update it when you consume IDs.

An opening with casings consumes one zone number and expands into three segments:
`<id>A` left casing, `<id>B` unit, `<id>C` right casing. That is what keeps a clear wall
return from being swallowed by the window.

## Feeding the Swift chain entry screen

A measured wall file carries `sync.chain`, written in exactly the notation the app's
**Chain Entry / Editor** screen accepts, so the round trip is copy and paste:

1. Copy `sync.chain` out of the wall file in Working Copy.
2. In the app, open the room, tap **Chain Entry / Editor**, paste into the chain field,
   tap **Parse Chain String**, then **Validate Chain**.
3. Any ID that matches the Wall 1 source of truth comes back with its kind, label, and
   notes attached rather than as a bare width.

The chain string carries widths only. To carry a window's height and panel split across
too, append them to that token — `Z3B=96in x 60in(22/52/22)` — which the parser also
accepts. Widths accept carpentry fractions (`12 3/4`, `12-3/4`).

Going the other direction, the payload shown by **Preview Payload** is the same shape as
these files, so it can be pasted back over a wall file's body after an in-app
correction. Keep the `sync` block when you do.

## Relationship to the push integration

These files use the same field names as the push payload documented in
`Integration/PerplexityWallPush/`. Differences:

- A `sync` block is added for editing metadata (`status`, notes, next IDs, template).
  The backend validates the fields it needs and ignores the rest, so a `ready` file can
  be POSTed as-is. Note the push *schema* sets `additionalProperties: false`, so drop the
  `sync` block first if you are validating a file against that schema directly.
- Templates carry `expected_total_width: 0` and an empty `segments` array, which the
  push schema deliberately forbids. That is why they are marked
  `"status": "needs_measurement"` instead of being filled with invented dimensions.

Schemas:

- `Integration/PerplexityWallPush/schema/wall_registry_push.schema.json` — the wire format.
- `Integration/PerplexityWallPush/schema/wall_registry_sync.schema.json` — these wall
  files. A file with `status: ready` must also satisfy the push schema once its `sync`
  block is removed.

## Checking a file before you commit

Syntax:

```bash
python3 -m json.tool "TUDM - PERPLEXITY 4-1.swiftpm/WallRegistrySync/wall_1_registry.json" > /dev/null
```

Totals, for every ready wall:

```bash
python3 -c "
import glob, json
for path in sorted(glob.glob('TUDM - PERPLEXITY 4-1.swiftpm/WallRegistrySync/wall_*_registry.json')):
    r = json.load(open(path))
    if r['sync']['status'] != 'ready':
        print(path, r['sync']['status']); continue
    total = sum(s['width'] for s in r['segments'])
    ok = abs(total - r['expected_total_width']) <= 0.001
    print(path, total, '==', r['expected_total_width'], ok)
"
```

Push a ready file straight at a running local backend:

```bash
curl -X POST http://localhost:8787/wall-registry \
  -H "Content-Type: application/json" \
  --data @"TUDM - PERPLEXITY 4-1.swiftpm/WallRegistrySync/wall_1_registry.json"
```

## No secrets here

These files hold dimensions only. The endpoint URL and push token are entered in the
app and stored in `UserDefaults` on the device, never in the repo. If you ever find a
key-shaped string in this folder, it does not belong.
