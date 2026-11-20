# roc-apps

Programs in Roc, run on platforms of our own, in the browser or natively. An
app with a README keeps its map there.

The code here was written by AI coding agents (Claude), with human supervision. Point an agent at this repo to add an app or extend one: `CLAUDE.md` gives it the rules.

Thanks to Damian Tedrow, whose [Cobblestone](https://github.com/damiant3/Cobblestone) inspired Safari.

## The apps

| where | what |
|---|---|
| `canvas_apps/` | Safari, small games and scenes, and the widgets the Safari tutorial embeds: each runs as a page from one set of files, and the apps also run natively on roc-ray (`canvas_apps/native/`, frozen) |
| `delivery/` | Seattle Delivery, a screensaver with an algorithm at its heart: eight trucks deliver a hundred orders across a map of Seattle, planned by a Roc solver under a Zig host, compiled to WebAssembly |
| `dog-park/` | Dog Park, a herding game: drag a dog through a park and herd the cows into one bunch; the physics is Roc under a Zig board, compiled to WebAssembly |
| `fasttrack/` | Fast Track, the board game, ported from Steve's elm-fasttrack: the rules and the whole page in Roc |
| `glue/` | `JsGlue.roc`, the `roc glue` spec that generates a page's frame reader from the compiler's type table |
| `basic/` | a BASIC interpreter written in Roc, a web page that runs it, and the corpora that grade it |
| `book_builder/` | the book builder: a Roc platform and the package a book's app calls; it builds the Safari tutorial and the books book |
| `building-books/` | the books book, *Building a Book with Claude*: how to build a book like the Safari tutorial, with Claude writing (`building-books/MISSION.md`) |
| `site/`, `ops/` | the site that serves the apps (below) |
| `docs/` | `roc-style.md`, how Steve writes Roc; `roc-notes.md`, how the Roc nightly behaves |

## The books

The book builder (`book_builder/`) builds the Safari tutorial
(`canvas_apps/safari/tutorial/`) and the books book (`building-books/`),
which says how to build a book this way. A new book starts from the books
book.

## The site: Steve's Roc Apps

Every app is a static page with relative URLs. One Caddy (`ops/Caddyfile`)
serves them all on three channels, so a page moves from one channel to the
next unchanged. The design is
[notes/roc-web-umbrella.md](https://github.com/showell/essay-repl-server/blob/master/notes/roc-web-umbrella.md).

- **dev**: each app's `build.sh` writes it; `site/build.sh` writes the landing page
  and the site's own pages: `site/web/notes/`, short pages linked at its foot, and
  `site/web/syntax-color/`, roc-syntax-color's showcase.
- **staging**: `site/live/`, tracked, so a clone has the published site.
  `site/publish.sh <app>` copies an app over from dev, with a `PROVENANCE`
  file, and commits it. `site/publish_screensavers.shale` publishes
  roc-screensaver's screensavers.
- **prod**: [roc.lynrummy.com](https://roc.lynrummy.com/), staging's files
  verbatim, copied by `site/deploy.sh`.

```
site/build.sh                         # the landing page into dev
canvas_apps/build.sh safari release   # an app's release build into dev
shale site/check_mobile.shale channel=dev   # the landing page fits a phone
site/publish.sh safari                # dev to staging
site/publish.sh tutorial              # the book, once each widget it frames is published
shale site/publish_screensavers.shale # roc-screensaver's screensavers to staging
site/deploy.sh                        # staging to prod
```

Staging changes only by a publish. Both channels send no-store, so each is
live the moment its file is. Each script's header says the rest.

## The compiler

**One nightly for the whole repository, named in `roc-version`.**
roc-lang/nightlies publishes a release build of the new compiler every day
(`gh release list -R roc-lang/nightlies`). The pinned nightly is installed
side by side with others at `~/tools/roc-<pin>/roc`, and every script runs
that one:

    cd ~/tools
    gh release download <pin> -R roc-lang/nightlies -p 'roc_nightly-linux_x86_64-*.tar.gz'
    tar xzf roc_nightly-linux_x86_64-*.tar.gz && mv roc_nightly-linux_x86_64-<date-sha> roc-<pin>

`shale check.shale` holds the whole repository to the pin: every
source file formatted, and every app in `apps.txt` checked clean
of errors and warnings, with its exceptions named in it. Bash scripts that run Roc source `pinned-roc.sh`
and Shale scripts call `pinned_roc` (`.shale/prelude.shale`); both refuse
any other compiler. ([Shale](https://github.com/showell/shale) is a small
scripting language our agents use in place of bash.) To move the pin:
install the new nightly, change `roc-version` and the two workflows, run
`roc fmt` over the repository and commit that apart, then run every tree's
own checks.

`shale tools/quality.shale` runs Shale's Roc code-quality recipes over the
files changed since master (`tier=full` for every app), and counts what
they find against `tools/quality_baseline.tsv` (`tools/README.md`).

The wasm hosts in `basic/`, `canvas_apps/web/` and `fasttrack/web/` build
against a checkout of the Roc compiler's source, for its `src/builtins`
(`-Droc=<path>` in each `build.zig`).
