# roc-apps

Programs in Roc, run on platforms of our own, in the browser or natively. An
app with a README keeps its map there; the others are mapped below.

Thanks to Damian Tedrow, whose [Cobblestone](https://github.com/damiant3/Cobblestone) inspired Safari.

## The apps

| where | what | map |
|---|---|---|
| `canvas_apps/` | eight small interactive programs that run as a page and, as a spike not kept current, natively on roc-ray, from one set of files: Safari, snake, pong, breakout, particles, a camera world, a pixel paint program, and a movie you can scrub | `canvas_apps/README.md`, `canvas_apps/safari/README.md` |
| `fasttrack/` | Fast Track, the board game, ported from Steve's elm-fasttrack: the rules and the whole page in Roc, drawn by a thin page script that patches the board | `fasttrack/README.md` |
| `glue/` | `JsGlue.roc`, the `roc glue` spec that generates a page's frame reader from the compiler's type table | `glue/README.md` |
| `ray/` | `fetch_exes.sh`, which pulls the canvas apps' Windows executables to a Windows machine | `ray/README.md` |
| `cbor-pets/` | CBOR as a Roc format, from the Zulip thread "CBOR serialization": `Cbor.parse`/`Cbor.to_bytes` work for a profile through derived `parser_for`/`encoder_for`, with its picture (an `ImageBlob`) a byte string and its pet ages an array | `cbor-pets/README.md` |
| `basic/` | a BASIC interpreter written by hand in Roc, a web page that runs it, and the corpora that grade it | `basic/README.md` |
| `site/`, `ops/` | the site that serves the apps: dev, staging and prod | below |
| `findings/` | Roc behaviours we found, each with a program that shows it | |
| `docs/` | `roc-style.md`, how Steve writes Roc (tags, records, opaque types for what's validated, one workhorse at the edge); `roc-notes.md`, how the Roc nightly behaves (the compiler, the language, what copies) | |

## The Safari book, the prototype

The Safari tutorial (`canvas_apps/safari/tutorial/`) was the prototype book. The books after it fork its machinery rather than share it: the Shale book (in the `shale` repo) began from a copy of its MISSION.md, and its general gates, starting with `canvas_apps/safari/gates/book_negatives.shale`, are being copied into Shale's cookbook as recipes. The originals here are kept as they are, so they go stale. For a new book, start from Shale's cookbook and the Shale book, not from these copies.

## The site: Steve's Roc Apps

Every app is a static page. One Caddy (`ops/Caddyfile`) serves them all, an
app at a path of its own and a channel on a port of its own, so a page moves
from one channel to the next unchanged. The design is
[notes/roc-web-umbrella.md](https://github.com/showell/essay-repl-server/blob/master/notes/roc-web-umbrella.md).

| channel | where | serves | written by |
|---|---|---|---|
| dev | `http://<box>:9210/` | `~/build/roc-apps/next/` | each app's `build.sh`; `site/build.sh` for the root |
| staging | `http://<box>:9200/` | `site/live/`, tracked | `site/publish.sh`, after an eye test on dev, which takes only a canvas app's release build |
| prod | `https://roc.lynrummy.com/` | `/srv/roc-site/` on the prod droplet, staging's files verbatim | `site/deploy.sh`, on Steve's sign-off of staging |

The ports announced before the site redirect: :9201 to prod's `safari/`;
:9203's `basic/` to prod and the rest of :9203 to dev at the same path.

| where | what | written by |
|---|---|---|
| `ops/` | `Caddyfile` and `roc-site.service`: one Caddy serving the site and redirecting the ports announced before it; `install.sh` | hand |
| `site/web/index.html` | the landing page: Canvas apps, Interpreters, In progress, and the date each app on the channel was published | hand |
| `site/web/shared/home.js` | the link home, and the banner on dev (whose root alone has a `channel` file); every page loads it with one relative line | hand |
| `site/build.sh` | the landing page, `shared/` and the `channel` file into dev | hand |
| `site/publish.sh` | THE SIGN-OFF: one app's dev directory over `site/live/<app>/` whole, with a `PROVENANCE`, committed and pushed; `site/publish.sh home` for the landing page and `shared/`; `site/publish.sh tutorial` for the Safari Ride book, after the widgets it frames, and never dropping a page staging has | hand |
| `site/live/` | what staging serves, and what prod serves | `site/publish.sh` |
| `site/deploy.sh` | THE PROD DEPLOY: `site/live/` to the droplet with `rsync --delete`, each file's sha256 checked against staging's; the site block installed and validated when it changed; the landing page checked over HTTPS | hand |
| `ops/roc.lynrummy.com.caddy` | prod's site block, imported by the droplet's Caddyfile (angry-gopher's `deploy/Caddyfile`) from `/etc/caddy/sites/` | hand |

    site/build.sh                  # the root into dev, http://<box>:9210/
    canvas_apps/build.sh safari release   # or safari's gates/publish.shale: release wasm into dev
    site/publish.sh safari         # when dev looks right: staging, http://<box>:9200/safari/
    site/publish.sh tutorial       # the book, once each widget it frames is published
    site/deploy.sh                 # when staging looks right: prod, https://roc.lynrummy.com/

Staging never changes under you: a build goes to dev, and only a publish, a
deliberate copy with a provenance file and a commit, moves it to staging.
Both channels send no-store, so each is live the moment its file is.

Every page's URLs are relative, so the site works under any prefix.

## What's tracked

What staging serves, `site/live/`, is committed, each app with its provenance,
so a clone has the published site. Roc's own output, the dev channel and the
caches live under `~/build/roc-apps/`.

## The compiler

**One nightly for the whole repository, named in `roc-version`.**
roc-lang/nightlies publishes a release build of the new compiler every day
(`gh release list -R roc-lang/nightlies`); roc-lang/roc's own releases page
is the old compiler. The pinned nightly is installed side by side with
others at `~/tools/roc-<pin>/roc`, and nothing uses `roc` from the PATH:

    cd ~/tools
    gh release download <pin> -R roc-lang/nightlies -p 'roc_nightly-linux_x86_64-*.tar.gz'
    tar xzf roc_nightly-linux_x86_64-*.tar.gz && mv roc_nightly-linux_x86_64-<date-sha> roc-<pin>

`shale check.shale` holds the whole repository to the pin: every
hand-written file formatted, and every app checked with no errors or
warnings, apart from the trees it names and says why. Every bash script
that runs Roc sources `pinned-roc.sh`, which refuses a compiler whose
`roc version` isn't the pin; every Shale script asks `pinned_roc` in the
repository's prelude, `.shale/prelude.shale`, which makes the same
refusals, and the Windows and macOS workflows name the same tag. To move the pin: install
the new nightly, change `roc-version` and the two workflows, run `roc fmt`
over the repository and commit that apart, then run every tree's own
checks.

The checkout `~/showell_repos/roc` (main, zig 0.16.0 at `~/zig-0.16.0/zig`)
is for working ON the compiler, and the wasm host builds against its
`src/builtins`. Its debug build goes to `~/build/roc/out/bin/roc`:

    cd ~/showell_repos/roc
    ~/zig-0.16.0/zig build --prefix ~/build/roc/out --cache-dir ~/build/roc/zig-cache --global-cache-dir ~/build/zig-global

`-Doptimize=ReleaseFast` does not link on this 8 GB box. The debug build's
checker is quadratic in a file's literals (the nightly's is not); Roc's eval
suite is its installation check (`zig build run-test-eval`, 47 minutes).
