# roc-apps

Programs in Roc from the Cobblestone world. Most are Codex emitted as Roc by
rust-codex-compiler's `rocemit` and run on platforms of our own, in the browser
or natively; BASIC is written in Roc by hand. An app with a README keeps its map
there; the others are mapped below.

## The apps

| where | what | map |
|---|---|---|
| `safari/` | our driving screensaver: its Codex chapters emitted as Roc, graded by their specs, run in the browser | `safari/README.md` |
| `ray/` | apps as native programs on roc-ray (raylib), Safari among them, and the Windows and macOS builds | `ray/README.md` |
| `basic/` | a BASIC interpreter written by hand in Roc, a web page that runs it, and the corpora that grade it | `basic/README.md` |
| `gpu/` | Cobblestone's WGSL kernels, on the CPU | below |
| `games/` | Damian's classic games, with the browser as the platform | below |
| `machine/` | simulated devices in one Roc value | `machine/README.md` |
| `framebuffer/` | Codex drawing on a screen, with no machine under it | `framebuffer/README.md` |
| `tests/` | Cobblestone's own suite as the emitter's ladder | below |
| `site/`, `ops/` | the site that serves the apps: dev, staging and prod | below |
| `findings/` | Roc behaviours we found, each with a program that shows it | |
| `docs/` | `roc-notes.md`, how the Roc nightly behaves (the compiler, the language, what copies); the Codex forms safari uses; the machine's memory plan and structures | |

## The site: Cobblestone Roc Projects

Every app is a static page. One Caddy (`ops/Caddyfile`) serves them all, an
app at a path of its own and a channel on a port of its own, so a page moves
from one channel to the next unchanged. The design is
`:9100/notes/roc-web-umbrella.md`.

| channel | where | serves | written by |
|---|---|---|---|
| dev | `http://<box>:9210/` | `~/build/roc-apps/next/` | each app's `build.sh`; `site/build.sh` for the root |
| staging | `http://<box>:9200/` | `site/live/`, tracked | `site/publish.sh`, after an eye test on dev |
| prod | `https://roc.lynrummy.com/` | `/srv/roc-site/` on the prod droplet, staging's files verbatim | `site/deploy.sh`, on Steve's sign-off of staging |

The ports announced before the site redirect: :9201 to prod's `safari/`;
:9203's `basic/` to prod and the rest of :9203 to dev at the same path;
:9204 and :9205, never announced, to staging's `gpu/` and `games/`.

| where | what | written by |
|---|---|---|
| `ops/` | `Caddyfile` and `roc-site.service`: one Caddy serving the site and redirecting the ports announced before it; `install.sh` | hand |
| `site/web/index.html` | the landing page: Finished, In progress, and the date each app on the channel was published | hand |
| `site/web/shared/home.js` | the link home, and the banner on dev (whose root alone has a `channel` file); every page loads it with one relative line | hand |
| `site/build.sh` | the landing page, `shared/` and the `channel` file into dev | hand |
| `site/publish.sh` | THE SIGN-OFF: one app's dev directory over `site/live/<app>/` whole, with a `PROVENANCE`, committed and pushed; `site/publish.sh home` for the landing page and `shared/` | hand |
| `site/live/` | what staging serves, and what prod serves | `site/publish.sh` |
| `site/deploy.sh` | THE PROD DEPLOY: `site/live/` to the droplet with `rsync --delete`, each file's sha256 checked against staging's; the site block installed and validated when it changed; the landing page checked over HTTPS | hand |
| `ops/roc.lynrummy.com.caddy` | prod's site block, imported by the droplet's Caddyfile (angry-gopher's `deploy/Caddyfile`) from `/etc/caddy/sites/` | hand |

    site/build.sh                  # the root into dev, http://<box>:9210/
    site/publish.sh safari         # when dev looks right: staging, http://<box>:9200/safari/
    site/deploy.sh                 # when staging looks right: prod, https://roc.lynrummy.com/

Staging never changes under you: a build goes to dev, and only a publish, a
deliberate copy with a provenance file and a commit, moves it to staging.
Both channels send no-store, so each is live the moment its file is.

Every page's URLs are relative, so the site works under any prefix.

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
| `gpu/build.sh` | host + app + page into the dev channel, `http://<box>:9210/gpu/gallery.html` | hand |
| `gpu/emitted.sh` | THE GATE: every kernel under `$KERNELS_ROOT/apps/*/kernels` (default `~/showell_repos/cobblestone-u61`) emitted, chapter identity checked, `roc check`ed; on green, written to `gpu/roc/` | hand |

    gpu/emitted.sh                 # 46 kernels, ~4 s
    gpu/gallery.py                 # after a page or kernel changes: the app and the manifest
    gpu/build.sh                   # ~10 s; dev at :9210/gpu/
    site/publish.sh gpu            # when dev looks right: staging, http://<box>:9200/gpu/gallery.html
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
| `games/build.sh`, `games/verify.sh` | hosts + apps + pages into the dev channel, `http://<box>:9210/games/<game>.html`; then Damian's `<xx>-verify.mjs` against each module | hand |

    games/emitted.sh
    games/build.sh                 # runs gen.py first
    games/verify.sh                # PASS 20 arms for 2048, 20 for Minesweeper, 42 for Klondike
    site/publish.sh games          # when dev looks right: staging, http://<box>:9200/games/2048.html

Adding a game: its row in `gen.py` (from `apps/games/build-wasm.ps1`), its
shell in `emitted.sh`, an app, a page, its grader in `verify.sh`, and a link
on the landing page.

## machine: simulated devices in one Roc value

`machine/` is the start of the devices plan
(`:9100/notes/codex-devices-in-roc.md`, `:9100/notes/roc-machine-emulator.md`):
a Roc machine holding the devices upstream's codex-vm models (memory, PCI
configuration space, a drive, a keyboard queue, a console), each behind a door
that takes the machine and hands it back. Step 1 is a hand-written program on
it, watched by a page. `machine/README.md` is the map.

    machine/build.sh               # host + app + page + disk image into dev, :9210/machine/machine.html
    node machine/wasm/smoke.mjs ~/build/roc-apps/next/machine

## framebuffer: Codex drawing on a screen, with no machine under it

`framebuffer/` runs a Codex program that only touches memory, with the bytes
kept by the platform's host and the screen a part of them where UEFI's GOP
protocol puts it. The page runs the program once a frame. `framebuffer/README.md`
is the map.

    framebuffer/build.sh framebuffer/demos/scene-spin.codex   # dev, :9210/framebuffer/
    node framebuffer/frames.mjs scene-spin 5

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

Each app's emitted Roc (`safari/roc/`, `gpu/roc/`, `games/roc/`) is generated
and committed, because those files are the point: a diff there is a change in
what the emitter says, reviewed like any other. What staging serves,
`site/live/`, is committed too, each app with its provenance, so a clone has
the published site. Roc's own output, the dev channel and the caches live
under `~/build/roc-apps/`.

`ROCEMIT=~/build/rust-target/debug/rocemit` points the gates and the ladder at
a debug build of the emitter; the default is the release one.

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
