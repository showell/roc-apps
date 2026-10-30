# A stale cache entry crashes `roc test` (nightly-2026-10-29)

**Fixed upstream:** roc-lang/roc#12693, by #12704. The fix landed after
nightly-2026-10-29-a0a9fc2. nightly-2026-10-30-0602c5f has it, and roc-chat
and roc-markdown pin that nightly or later.

## What it shows

On nightly-2026-10-29-a0a9fc2, in roc-chat at 607d453 (with roc-markdown at
8b33e2a beside it):

1. `roc check app/main.roc` on an empty cache;
2. append a comment to `app/Store.roc`;
3. `roc test app/main.roc` exits 139, a SIGSEGV in the post-check monotype
   phase (fault address 0x28, a field read through a null pointer).

Without step 2, step 3 passes all 2005 tests. On nightly-2026-10-30-0602c5f
the same three steps pass.

Use a cache of your own, `ROC_CACHE_DIR=<an empty folder>`, for each run.
A cache's location is part of every entry's identity, so a cache copied to
another path only misses.

## Why

A checked module's cache entry (here `app/ConvKey.roc`'s) stores
compile-time constants whose named types point at a type store by module.
For a closed instantiation that store can be a module **downstream** of the
one cached: `Store` imports `ConvKey`, and `ConvKey`'s entry names `Store`.
The entry's key covers only `ConvKey` and what it imports. Editing `Store`
leaves the key unchanged, so the stale entry is reused, and monotype then
looks up a module that is no longer in the program.

`roc check` passes on the same cache: only a test or build goes through
the path that dies. Clearing `~/.cache/roc` hid it, which is why it first
looked like a flaky crash after edits across many modules.

## What helped

- Shrinking the cache: delta debugging over its entries left one, ConvKey's.
- Comparing that entry's bytes with fresh ones: 264 bytes differed, in 8
  named-type records, each naming an older `Store`.
- Asking "is it fixed already?" before reducing further: it was, eight
  hours after our pin (CLAUDE.md §2).
