# tools

The repository's own scripts, beside `check.shale` at its root.

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
