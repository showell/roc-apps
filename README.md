# roc-apps

Safari, our browser screensaver, as Roc: the chapter modules emitted from
the Codex source by rust-codex-compiler's `rocemit`, the spec apps that grade
them against the Codex verdicts, a wasm platform and app that run them in
the browser page the Codex version used, and the first Roc-only flair, a
Roc on the fifth tree on the right of every segment.

## The map

| where | what | written by |
|---|---|---|
| `safari/roc/*.roc` | one type module per Codex chapter, whole, as written; one app per spec (`*Spec.roc`) | `rocemit`, via `safari/emitted.sh` |
| `safari/roc/SafariApp.roc` | the screensaver: the ride as a boxed model, the frame packed into the blitter's words | hand |
| `safari/roc/RocBird.roc` | the bird | hand |
| `safari/roc/FrameBench.roc` | a native loop over the frame, for `perf` | hand |
| `safari/wasm/` | the platform: `platform/main.roc` provides the page's sixteen exports over `Box(Model)`; `platform/host.zig` is the host; `build.zig` builds it against the roc checkout; `build.sh` builds host and app into the PREVIEW root; `drive_smoke.mjs` drives the built module from Node as the page does (first frame, readouts, ms per step, `back`); `run_wasm.mjs` runs any Roc module's `wasm_main` with logged `env` imports | hand |
| `safari/web/` | the demo page: a copy of safari-codex's `blitter.js`, `index.html`, `serve.py`, and `driving/safari.wasm` with its `PROVENANCE`, which only `safari/publish.sh` writes | hand; the module by publish |
| `safari/publish.sh` | THE MANUAL STEP: the previewed module into the demo, with provenance, committed and pushed | hand |
| `ops/` | four systemd --user services: `safari-web` :9201 over `safari/web/` (the safari demo), `safari-web-next` :9203 over `~/build/roc-apps/next/` (the preview of every app), `gallery-web` :9204 over `gpu/live/` (the gallery demo), `games-web` :9205 over `games/live/` (the games demo); `install.sh` | hand |
| `safari/emitted.sh` | THE GATE: every unit emitted, chapter identity checked, roc run two at a time, output against the verdict; a compile error is a FAIL | hand |
| `safari/retest.sh` | the targeted sweep: emit all, diff against the tracked Roc, run only what changed | hand |
| `wasm/*.mjs` | Node drivers: run a module, drive the screensaver headless with timings | hand |
| `docs/codex-subset.md` | the forms safari uses, counted over the 54 IRs | hand |

The units come from `~/showell_repos/safari-codex/units/` (`<Spec>.codex`
resolved, `<Spec>.expected` the verdict the Rust interpreter froze).

## gpu: Cobblestone's WGSL kernels, on the CPU

`gpu/` is the second app: the Codex `[Device]` kernels of Cobblestone's
`apps/*/kernels` (46 chapters the wgsl plug lowers to WebGPU compute
shaders), run in Roc on the CPU, one gid after another, with the pixels put
on a 2d canvas. Started 2026-09-12 with hand ports of plasma and the
fountain; the same day every kernel was emitted and all 39 demo pages
became one gallery module. The essay is `:9100/notes/plasma-in-roc.md`.

| where | what | written by |
|---|---|---|
| `gpu/roc/Device.roc` | the Device effect as state: buffers by handle and the thread's gid, `load`/`store`/index reads threading the record, `dispatch` over the gids; WGSL's total `div`/`rem`. I32 and F32 throughout, as the plug's WGSL is, and rocemit spells a unit with a kernel in those types with wrapping arithmetic | hand |
| `gpu/roc/*Kernel*.roc`, `DeviceMath.roc`, `Thread.roc`, `ListUtils.roc`, `Tuple.roc` | the 46 kernel chapters and what they cite, one module each; a `[Device]` definition takes the device first and answers `(Device.Device, T)` | `rocemit`, via `gpu/emitted.sh` |
| `gpu/roc/GalleryApp.roc`, `gpu/web/gallery.js` | the gallery: a boxed model of one demo's device; `step(model, demo, frame)` makes the buffers when the demo changes, runs its passes over their gids (ping-pong on odd frames for the simulations) and remembers the buffer the page reads; `view` answers it as words; the manifest names the demos and says how to draw each | `gpu/gallery.py`, from the gpushow pages and kernel sources; a page with two passes, a seeded buffer, a state across frames or a particle draw has its plan as a table in the script; `--table` prints what qualifies and why the rest do not |
| `gpu/roc/Seeds.roc` | what pages upload before their first dispatch, ported from their JavaScript: a procedural texture, an icosahedron, and the four particle states from the pages' own linear congruential generator, emulated in F64 to the word | hand |
| `gpu/roc/{Plasma,CpuParticles}Bench.roc` | two native benches that print a checksum a Python evaluation of the Codex source matches | hand |
| `gpu/wasm/` | the platform: `step(demo, frame)`, `view()` and `bufPtr` over one boxed model, as safari's; host, build.zig as safari's; `smoke.mjs` renders every demo from Node with its checksum and ms per frame, or the named ones | hand |
| `gpu/web/gallery.html` | the page: a demo selector (`?k=plasma`); pixels as an ImageData, particles as additive quads the way each page's vertex shader drew them; no WebGPU, so no secure context | hand |
| `gpu/build.sh` | host + app + page into the preview, `http://<box>:9203/gpu/gallery.html` | hand |
| `gpu/publish.sh`, `gpu/live/` | THE MANUAL STEP for the gallery: the previewed page, manifest and module into `gpu/live/` with a `PROVENANCE`, committed and pushed; `gallery-web` (:9204) serves only that | hand; the files by publish |
| `gpu/emitted.sh` | THE GATE: every kernel under `$KERNELS_ROOT/apps/*/kernels` (default `~/showell_repos/cobblestone-u58`) emitted, chapter identity checked, `roc check`ed; on green, written to `gpu/roc/` | hand |

    gpu/emitted.sh                 # 46 kernels, ~4 s
    gpu/gallery.py                 # after a page or kernel changes: the app and the manifest
    gpu/build.sh                   # ~10 s; the preview at :9203/gpu/
    gpu/publish.sh                 # when the preview looks right: the demo, http://<box>:9204/gallery.html
    node gpu/wasm/smoke.mjs ~/build/roc-apps/next/gpu/gallery.wasm 2   # 39 of 39 render; plasma's frame 0 is 6293600626746
    node gpu/wasm/smoke.mjs ~/build/roc-apps/next/gpu/gallery.wasm 30 cpuparticles swarm   # the named demos; the fountain's frame 0 is 91143764817938

## games: Damian's classic games, with the browser as the platform

`games/` is the third app: the classic games of Cobblestone's `apps/games`,
2048, Minesweeper and Klondike so far (2026-09-12). Each game's engine and wasm
shell chapter are emitted; the seam to the browser is a MESSAGE: the page
turns a key or a click into one small integer and `step(message)` is the
only door into the generated Roc, `view()` answers the board as words.
Damian's own grader for each game runs against our module through his
export contract, which the same host serves over a handle table.

| where | what | written by |
|---|---|---|
| `games/roc/*.roc` (engines, shells, `Rng`, `List`, ...) | the emitted chapters | `rocemit`, via `games/emitted.sh` |
| `games/roc/{G2048App,MinesweeperApp,KlondikeApp}.roc` | the apps: `init(seed)`, `step(message)`, `view`, `drop`, `same`, and the shell's exports under their short names for the grader's door; Klondike's model holds the selection, so a two-click move is two messages and the page only draws | hand |
| `games/gen.py` -> `games/wasm/<game>/` | per game the platform and host from Damian's export table, an export's kind (query, transition, make, pure) read off the emitted shell's signature: the page's door (`newGame`, `step`, `view`, `bufPtr`) over one model, the grader's door (`g2_new`, `ms_open`, `kd_run`, ...) over a table of boxed models, a refused transition answering the same handle by the app's structural `same`; `__heap_reset` | generated; `host_head.zig`/`host_body.zig` are the fixed parts |
| `games/web/<game>.html` | the pages: the key table or the click, the message, the board | hand |
| `games/emitted.sh` | THE GATE: the shell chapters emitted from `$GAMES_ROOT` (cites resolved from the same tree), chapter identity, `roc check`; on green written to `games/roc/` | hand |
| `games/build.sh`, `games/verify.sh` | hosts + apps + pages into the preview, `http://<box>:9203/games/<game>.html`; then Damian's `<xx>-verify.mjs` against each module | hand |
| `games/publish.sh`, `games/live/` | THE MANUAL STEP for the games: the previewed pages and modules into `games/live/` with a `PROVENANCE`, committed and pushed; `games-web` (:9205) serves only that | hand; the files by publish |

    games/emitted.sh
    games/build.sh                 # runs gen.py first
    games/verify.sh                # PASS 20 arms for 2048, 20 for Minesweeper, 42 for Klondike
    games/publish.sh               # when the preview looks right: the demo, http://<box>:9205/2048.html

Adding a game: its row in `gen.py` (from `apps/games/build-wasm.ps1`), its
shell in `emitted.sh`, an app, a page, and its grader in `verify.sh`.

## machine: simulated devices in one Roc value

`machine/` is the start of the devices plan
(`:9100/notes/codex-devices-in-roc.md`, `:9100/notes/roc-machine-emulator.md`):
a Roc machine holding the devices upstream's codex-vm models (memory, PCI
configuration space, a drive, a keyboard queue, a console), each behind a door
that takes the machine and hands it back. Step 1 is a hand-written program on
it, watched by a page. `machine/README.md` is the map.

    machine/build.sh               # host + app + page + disk image into the preview, :9203/machine/machine.html
    node machine/wasm/smoke.mjs ~/build/roc-apps/next/machine

## Why any of this exists

[`BUGHUNT.md`](BUGHUNT.md) is the short version for someone arriving from a
roc-lang issue: what Cobblestone and Codex are, what the corpus is, how we
run it against Roc, and what we have filed.

## tests: Cobblestone's own suite as the emitter's ladder

`tests/ladder.sh` emits every program in `codex/test` that sits beside an
`.expected` verdict, runs it on the Echo platform and diffs the output:
597 programs in about forty seconds. It is where rocemit's next rung comes
from, and where a wrong emission shows up as a wrong number rather than a
compile error.

    tests/ladder.sh                # the whole corpus; writes tests/ledger.txt
    tests/ladder.sh effect-smoke   # named units

Outcomes are counted apart, because they mean different things: PASS,
FAIL (wrong output, or roc printed an error), REFUSED with the reason,
SKIP for a diagnostic test, DIVERGES for a verdict that pins a semantics
Roc does not have, CRASH, TIMEOUT. **A verdict is compared as text**: 86 of
the files begin with a stray `0x01` byte and 46 carry carriage returns,
the console capture's rather than the program's.

At 2026-09-12: 160 pass, 0 fail, 410 refused by reason, 24 diagnostic tests
skipped, 2 named divergences, 1 stack overflow. The essay is
`:9100/notes/the-corpus-that-argues-back.md`.

**The divergence, which is not a bug:** a Codex list is written in place and
a Roc list is a value, so a program that writes a list through one name and
reads it through another cannot be ported. The emitter refuses the clearest
shape by name (a definition that writes one of its own list parameters and
answers something else, as the foreword's bignum does), and the ladder
names the rest. Nothing we ship does this.

## The Roc is tracked; everything else the tools write is not

`safari/roc/` is generated and committed, because those files are the point.
A full `emitted.sh` rewrites every emitted file and leaves the hand-written
ones; a diff there is a change in what the emitter says, reviewed like any
other. The published module `safari/web/driving/safari.wasm` is committed
too, with its provenance, so a clone has the demo. Roc's own output, the
previewed module and the caches live under `~/build/roc-apps/`.

## The loop

    safari/emitted.sh              # 54 units, ~10-27 s; the gate before a commit of safari/roc
    safari/retest.sh               # after a rocemit change: only what changed
    safari/wasm/build.sh           # host + app -> the preview, http://<box>:9203/, ~15 s
    wasm/drive_smoke.mjs ~/build/roc-apps/next/driving/safari.wasm 120   # frame bytes, stages, ms per frame
    safari/publish.sh              # when the preview looks right: the demo, http://<box>:9201/

The demo never changes under you: a build goes to the preview, and only a
publish, a deliberate copy with a provenance file and a commit, moves it to
the demo. Both pages send no-store, so each is live the moment its file is.

`ROCEMIT=~/build/rust-target/debug/rocemit` points the sweeps at a debug
build of the emitter; the default is the release one.

## The compiler

**Use the nightly.** roc-lang/nightlies publishes a release build of the new
compiler every day (`gh release list -R roc-lang/nightlies`); the tarball's
`roc` is installed as `~/build/roc-nightly/roc` and is what everything here
uses. roc-lang/roc's own releases page is the OLD compiler.

    cd ~/build/roc-nightly
    gh release download <tag> -R roc-lang/nightlies -p 'roc_nightly-linux_x86_64-*.tar.gz'
    tar xzf roc_nightly-linux_x86_64-<tag>.tar.gz
    ln -sfn roc_nightly-linux_x86_64-<tag>/roc roc

The checkout `~/showell_repos/roc` (main, zig 0.16.0 at `~/zig-0.16.0/zig`)
is for working ON the compiler, and the wasm host builds against its
`src/builtins`. Its debug build goes to `~/build/roc/out/bin/roc`:

    cd ~/showell_repos/roc
    ~/zig-0.16.0/zig build --prefix ~/build/roc/out --cache-dir ~/build/roc/zig-cache --global-cache-dir ~/build/zig-global

`-Doptimize=ReleaseFast` does not link on this 8 GB box. The debug build's
checker is quadratic in a file's literals (the nightly's is not); Roc's eval
suite is its installation check (`zig build run-test-eval`, 47 minutes).

## What is known to be slow, and why

`http://143.244.172.148:9100/notes/what-is-slow.md`. In one line: a Codex
list built by `x & f rest` is quadratic in Roc, and the emitter writes an
accumulator loop for that shape; everything else is the nightly. (The
stills were once strings with a decoder, because the debug compiler's
checker was quadratic in a file's literals; the nightly's is linear and
they are literals again, 2026-09-12.)
