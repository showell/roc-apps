# tools

The repository's own scripts, beside `check.shale` at its root.

- `quality.shale` runs Shale's Roc code-quality recipes over every app, in
  report mode: it fails only when a recipe can't run on the code (a file
  Roc's parser refuses, an app roc-types can't type), and it counts what
  the recipes find, per app, against `quality_baseline.tsv`. Its header
  says how to run each tier and what each costs. The baseline is the full
  tier's cache: a run measures again only the apps whose key moved, so a
  run with nothing changed takes seconds, and `fresh=1` measures every app.
- `quality_baseline.tsv` holds those counts, one `app`, `recipe`, `check`
  and `count` a line, and the keys they were measured at: a `parse-key`
  line a project and a `types-key` line an app, each naming its folders
  (separated by commas) and the hash of the tools and of those folders'
  content, and a `typed-file` line for each file of a shared folder (its
  count of provable method calls, then the apps that reach it). `shale tools/quality.shale tier=full baseline=write`
  writes both, and a change that moves a count writes it again in the same
  commit. A key that no longer matches only makes the next full run measure
  its apps again.

The recipes it relies on are in Shale's `cookbook/roc/` (the `cookbook:`
mount): `hunt_names`, `check_stacking`, `find_extra_parens`,
`check_errors`, `find_deep_calls`, `find_unused_imports`,
`check_name_types`, `check_families`, `find_unclear_names`,
`check_boundaries` and `rewrite_method_calls` (its `trials=0` count, and its
`peer_receiver`), with the libraries
`types.shale` and, from the cookbook's top, `times.shale`.
