# Seattle Delivery

**Welcome to the Seattle Delivery toy!** Open the page, press **space**, and
watch eight trucks fan out across a deliberately not-to-scale, slightly
winking map of Seattle to deliver a hundred grocery orders. There's no score
and nothing to win: it's a screensaver with an algorithm at its heart, and
the fun is watching the routes make sense. On the dev channel it is
`/delivery/` (`build.shale`, below).

A few keys are all you need:

- **space**: play the day; the trucks drive their routes and drop totes,
  then park.
- **S**: shuffle up a brand-new shift (a fresh random draw of orders). Each
  shift is numbered, so you can say "that one looked weird on S58" and mean
  it.
- **A**: step *through the solver itself*, one move at a time, to watch the
  plan get built. **←/→** scrub either animation; **B** or **Esc** backs out
  to the static map.

Hover a neighborhood to see its name; hover a delivered house to highlight
its truck.

## Under the hood

This is a small, finished **capacitated vehicle-routing (CVRP)** simulator.
It came here from angry-gopher (lynrummy.com/delivery), where the solver was
Zig; here it is Roc.

**The language boundary:** Roc owns the solver, Zig hosts it, TypeScript
draws it.

- **Roc** (`roc/`) has the whole problem: the map and its road graph, the
  day's draw of orders, the domain (a stop's houses, a route, the eight
  trucks and their caps, the plan, the replay's moves), the pain cost,
  construction, local search, the race, the display minutes, and the JSON
  the page reads.
- **Zig** (`src/`) is the host: `roc_seam.zig` gives the Roc its memory
  (one arena a solve, dropped when the next solve starts) and its crashes,
  `wasm.zig` is the page's `solver.wasm` (`solveShift(seed)` and
  `outPtr()`), and `gold_check.zig` and `bench.zig` run the Roc natively.
- **TypeScript** is the display: `main.ts` (canvas, input, animation),
  `map_view.ts` (drawing), `timeline.ts`, and `geography.ts`, `orders.ts`
  and `roadgraph.ts`, which hold the map for the page to draw.

**Why this seam.** The page asks one question, a shift's plan by its seed,
and the solver needs nothing from the page to answer it; so the Roc takes a
seed and answers the page's JSON, and the Zig carries bytes. The road graph
and the gate angles are float geometry, and they are the Roc's too: every
float there is plain IEEE arithmetic, or `atan2` from Roc's own fdlibm port,
which is the same bits on every target, and the gold pins the road graph
(every edge's minutes, every pair's minutes and path) so any drift fails
loudly. Keeping the map in the Zig instead would split the solver's inputs
across the seam and make the Roc read a host table for every gate.

The map is therefore in two languages, the Roc's for the solver and the
TypeScript's for the drawing. That is accepted, as it was with the Zig: the
gold's substrate section holds the two in agreement.

### The algorithm, in one breath

Eight trucks, ~100 orders, asymmetric capacities (the west side carries
more than the east). The solver builds routes with the **Clarke-Wright
savings heuristic**, then improves them with local search (2-opt, or-opt,
exchange, arc-rebalance). Every move is scored against a single **integer
"pain" cost** (`roc/Pain.roc`'s `pain_of`), and that integer-ness is the one
load-bearing trick: no decision turns on a float near a tie, so the
greedy tie-breaks never flip between engines. A 4-way construction **race**
keeps the minimum. Almost everything you watch is emergent from that cost.
The one bit of local knowledge leaned on: Bellevue and Medina, on the
fulfillment center's doorstep across the lake, are left to the end of their
routes.

### Where things live

| where | what |
|---|---|
| `roc/` | the solver: `Seattle.roc` (the map, the fleet, the ring geometry), `RoadGraph.roc`, `Orders.roc`, `Houses.roc` and `Stop.roc` (a stop's houses, packed into one U64), `Route.roc`, `Pain.roc`, `Build.roc` (construction), `Improve.roc` (local search before the trucks are assigned), `SlotSearch.roc` (after), `Solve.roc` (a solve and the race), `Replay.roc`, `PlanJson.roc`, `Gold.roc`, and `delivery.roc`, the app, on `roc/platform/` |
| `src/` | the Zig host and its judges (above) |
| `*.ts`, `web/index.html` | the display, and `solver.ts`, the readable reference the gold is minted from (`goldgen.ts`; it is not in the page's bundle) |
| `zig/` | the Zig solver the Roc replaced, kept as the bench's yardstick, with its own gold check |
| `solver_gold.json`, `solver_frames_gold.json` | the gold corpus: 20 shifts, every route, pain, race variant, the road graph, and every replay frame |
| `tools/` | `page_check.mjs`, the staged page in headless Chromium |
| `build.shale` | the gate, then the page into the dev channel |

Faithfulness to `solver.ts` is in the order things are scanned and
compared: ties go to the first candidate everywhere, JS's Map and Set
insertion order is kept by building lists in that order, the float
epsilons collapse on integer gains (`> 1e-9` is `>= 1`), and each replay
snapshot is taken where the TypeScript takes it (`roc/Replay.roc`,
`roc/Build.roc`'s `force_placed`).

### Building, running, testing

It needs the box's Zig (0.17), the Roc roc-apps pins (`../roc-version`,
found at `~/tools/roc-<pin>/roc`; the build stops on any other), node, and
`npm ci` in this folder once (tsc and esbuild). From roc-apps' root:

    shale delivery/build.shale    # every check, then the page into the dev channel

and, in `delivery/`:

    zig build gold -Droc-opt=dev   # the Roc against the gold, on the fast-to-build backend
    zig build gold                 # the same, as served (LLVM, some two minutes to build)
    zig build wasm-gold            # the page's own solver.wasm against the gold, under node
    zig build roc-test             # Roc's expects and roc fmt --check roc
    zig build bench                # a shift's solve timed natively, the Zig reference against the Roc
    zig build wasm-bench           # the same in the browser's engine: both solver.wasm modules under node

Regenerate the gold (`goldgen.ts`, its header has the command) only on an
intentional change to `solver.ts`'s semantics, never to fit the Roc: a
difference from the gold is a bug in the Roc.

## Status (2026-11-16)

On the `delivery-roc` branch, not merged; on the dev channel at
`/delivery/`, not on staging or prod. The Roc passes the gold, all 20
shifts and 545 replay frames, natively and as the page's `solver.wasm`.

It runs within the 1.5x of the Zig it replaced that it was held to: about
1.3x in the browser's engine (node driving both `solver.wasm` modules) and
about 1.2x natively, each seed's best of eight (`zig build wasm-bench`,
`zig build bench`). What it took is in the solver's hot loop, and the
rules are worth keeping in any change to it:

- **A list one owner at a time.** A `for`, `fold` or `any` over a list,
  and a list a caller keeps while passing it, count the list up and down
  atomically. The pain loop and Route's checks read stops by index, and the
  scans thread their route through `Pain.price_view`.
- **Price a candidate in place.** `Pain.View` reads a route with a run
  reversed or a stop inserted without building it; a scan builds only the
  candidate it keeps.
- **No checked 64-bit multiply in the hot loop.** On wasm32 it is a call to
  a 128-bit multiply; the pain's rate and the tables' indexes use
  `times_wrap`, their factors being a few hundred at most.
- **One arena a solve** (`src/roc_seam.zig`), a bump pointer reset when the
  next solve starts.
