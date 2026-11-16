# tools

The repository's own scripts, beside `check.shale` at its root.

- `quality.shale` runs Shale's Roc code-quality recipes over every app, in
  report mode: it fails only when a recipe can't run on the code (a file
  Roc's parser refuses, an app roc-types can't type), and it counts what
  the recipes find, per app, against `quality_baseline.tsv`. Its header
  says how to run each tier and what each costs.
- `quality_baseline.tsv` holds those counts, one `app`, `recipe`, `check`
  and `count` a line. `shale tools/quality.shale tier=full baseline=write`
  writes it, and a change that moves a count writes it again in the same
  commit.

The recipes it relies on are in Shale's `cookbook/roc/` (the `cookbook:`
mount): `hunt_names`, `check_stacking`, `find_extra_parens`,
`check_errors`, `find_deep_calls`, `find_unused_imports`,
`check_name_types`, `check_families`, `find_unclear_names`,
`check_boundaries` and `rewrite_method_calls`, with the libraries
`types.shale` and, from the cookbook's top, `times.shale`.
