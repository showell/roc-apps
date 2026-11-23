# tools

The repository's own scripts, beside `check.shale` at its root.

- `chromium.mjs` starts headless Chromium for every page tool here (the
  mobile check, the books' check, the games' page checks and pictures) and
  speaks its DevTools protocol. It is the one home for the browser's flags
  and environment, which keep everything it writes in the run's TMPDIR, as
  Shale's confinement asks; roc-screensaver's `tools/web_shots.mjs` keeps a
  copy on purpose.
- `quality.shale` runs Shale's Roc code-quality recipes (from its
  `cookbook/roc/`, the `cookbook:` mount) over every app, in report mode. It
  fails when a recipe stops on the code (a file Roc's parser refuses, an app
  roc-types refuses to type), and otherwise counts what the recipes find, per
  app, against `quality_baseline.tsv`. The baseline is the full tier's cache:
  a run measures again the apps whose key moved, so an unchanged tree takes
  seconds, and `fresh=1` measures every app. Its header says how to run
  each tier and what each covers.
- `quality_keys.shale` is `quality.shale`'s library: the hashes its keys are
  made of.
- `quality_baseline.tsv` holds the counts, one `app`, `recipe`, `check` and
  `count` a line, and the keys they were measured at. `shale
  tools/quality.shale tier=full baseline=write` writes it, and a change that
  moves a count writes it again in the same commit. A stale key makes the
  next full run measure its apps again.
- `copy_shapes/` holds each way of writing into a list, a record or a dict
  that `docs/roc-notes.md`, "Speed and copying", names: `CopyShapes.roc`,
  one small loop a shape, and `copy_shapes.shale`, which runs them on
  `alloc_ladder.shale` and holds what one more write allocates to
  `expected.txt` (the release build), `expected-dev.txt` and
  `expected-boxy.txt` (`--specialize=no`). A shape that writes in place is
  held to 0, one that copies to its count. `shale check.shale
  copy_shapes=1` runs all three.
- `alloc_ladder.shale` runs an interpreter's or a program's controls at two
  sizes and holds what one more iteration allocates to an expected file,
  counting `roc_alloc` calls with `count_allocs.c`'s breakpoints. Its
  callers are `basic/controls.shale` and `copy_shapes/copy_shapes.shale`.
- `copy_oracle.shale` says where a Roc program copies, from the program
  itself: `count_copies.c` breaks at roc_alloc and at each builtin's entry,
  so each allocation made inside a writing builtin (list_set, the appends,
  the dev build's generic `roc_desc_list_op`) is put down to the Roc
  procedure that called it, named by `roc build --debug`'s debug
  information (by the frame pointers where the build keeps them).
  `copy_shapes/copy_shapes.shale oracle=1` is its first caller.
- `measure_roc_builds.shale` times one repository's `roc check`, `roc
  build` and `roc test` on its old pin and on Roc 0.1.0_RC1, cold, warm and
  after a change to the root or to the most imported module, and appends
  the medians to `docs/rc1-build-stats.tsv`, whose header names every
  column; `docs/rc1-build-box.txt` describes the box they ran on. Its header
  says how to run it.
- `quote_code.shale` quotes code by name for every page that shows code: a
  Roc definition through Roc's parser, or a file, from the tree or at a git
  commit, cut to the pieces a quote asks for. The Safari book's pre-step,
  the security idioms page and the Roc on Shale pages all quote through it.
  A page that quotes another repository keeps a lock beside its builder,
  each quote's commit and text hash, so its check fails, naming the quote,
  when the code under it moves. Its header says the format.
