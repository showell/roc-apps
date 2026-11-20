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
