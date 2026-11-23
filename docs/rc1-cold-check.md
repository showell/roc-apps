# RC1's slower cold `roc check`: measurements and a bisect

Measured 2026-11-23 on a 2-core Linux x86-64 box (docs/rc1-build-box.txt),
with all other work paused. The raw runs are
[rc1-cold-check-runs.tsv](rc1-cold-check-runs.tsv) and the bisect's probes
[rc1-cold-check-bisect.tsv](rc1-cold-check-bisect.tsv).

## Summary

- **The cold-check slowdown is a one-time cost per cache, about 1 s of
  CPU.** On a cold check, RC1 compiles the whole Builtin module to native
  code for compile-time evaluation (`compiled Builtin: ... 7167 tasks` in
  `--timings`). The hello-world build that "cold" starts from doesn't pay
  this cost, so the first real check does. Once Builtin's image is in the
  cache, RC1 checks these packages faster than the old nightly did.
- **A 10-line app reproduces it:** 0.05 s on the old nightly, 1.00 s on RC1.
- **First slow nightly: 2026-11-18
  ([a520eed](https://github.com/roc-lang/roc/commit/a520eeda6c3745f2543fcdd0fb836d3d1336c5ac)).
  Last fast nightly: 2026-11-15
  ([f25da45](https://github.com/roc-lang/roc/commit/f25da45234ca5db7558f317cef45195e5f8cf429)).**
  The likely cause is [#13086](https://github.com/roc-lang/roc/pull/13086),
  the first merge to main in that range, which made Boxy the default for
  checks and embedded a Builtin unit. This has not been confirmed by
  building the commits.
- **The 2026-11-22 nightly
  ([3350b1c](https://github.com/roc-lang/roc/commit/3350b1cd41cbb4ae7df5aacd723729b1821ae370),
  11 commits after RC1) is still slow.**
- **Separately, roc-chat's root-changed check is about 2x slower on RC1**
  (0.37 → 0.80 s). About half of the growth arrives with a new phase, "Unit
  Keys", between the same two nightlies. The other half came earlier and is
  not bisected (see below).

## How it was measured

- CPU time is user+sys of `roc` and the children it waited for. Each
  condition was run 7 times (roc-chat: 5 cold, 15 root changes), and the
  tables give the median with the min-max range.
- Every run had a fresh ROC_CACHE_DIR and TMPDIR of its own. Nothing was
  niced, and the runs went one at a time.
- Before each repetition the one-minute load was under 0.30. Within a
  repetition it rose to 0.3-0.9 from the measurement's own runs; the TSV
  records the load before every run.
- Conditions:
  - **cold** is Richard's definition: an empty cache, then
    `roc build --opt=dev hello.roc`, then the check.
  - **cold_primed** is the same, plus a check of the reduction below before
    the measured check, so Builtin's image is already cached.
  - **warm** is the same check again, at once.
  - **root_changed** appends a comment to the root module. Each change is
    new text, because RC1 caches by content: repeating the same edit is a
    cache hit, which an earlier run of ours mistook for a fast root change.
- The compilers: the old pin is nightly-2026-11-03
  ([34bd006](https://github.com/roc-lang/roc/commit/34bd0067266d4cd5ac941f044863e6a29671ddc0)),
  and RC1 is 0.1.0_RC1
  ([15177e9](https://github.com/roc-lang/roc/commit/15177e91f62cafddf5336c455e00e9f05427ac16)).
- The trees: for roc-markdown
  ([c3ced12](https://github.com/showell/roc-markdown/commit/c3ced12c13ab465976626969df5bb7d24115a98e)
  → [cd07711](https://github.com/showell/roc-markdown/commit/cd07711f4b256b902ceba4ec89a90e39aa6b4cd2))
  and roc-syntax-color
  ([29517971](https://github.com/showell/roc-syntax-color/commit/2951797124e951fd24f620a93c04f04b5c014bcc)
  → [5ba4459d](https://github.com/showell/roc-syntax-color/commit/5ba4459d1f9cf6fae51180192f727a5672c2eca8)),
  the `.roc` sources are byte-identical. The pin move changed only
  `roc-version`, so the RC1 renames play no part in those numbers.
  roc-chat's tree did change for RC1
  ([bab918d](https://github.com/showell/roc-chat/commit/bab918da7feda2af9ddaf81727599621dec606ab)
  → [c8c532c](https://github.com/showell/roc-chat/commit/c8c532cbac6f08a128a0ba5b6e68d3586f051399)).

## Before and after (CPU seconds, median and range, n=7)

| condition | roc-markdown, old | roc-markdown, RC1 | roc-syntax-color, old | roc-syntax-color, RC1 |
|---|---|---|---|---|
| cold | 0.73 (0.57-0.79) | **1.85** (1.64-2.10) | 0.64 (0.56-0.70) | **1.39** (1.24-1.82) |
| cold_primed | 0.74 (0.61-0.90) | 0.70 (0.47-0.77) | 0.63 (0.57-0.74) | 0.48 (0.39-0.65) |
| warm | 0.06 (0.05-0.07) | 0.02 (0.02-0.03) | 0.05 (0.04-0.05) | 0.02 (0.01-0.02) |
| root_changed | 0.07 (0.06-0.08) | 0.05 (0.04-0.06) | 0.06 (0.05-0.07) | 0.03 (0.02-0.03) |

| condition | reduction, old | reduction, RC1 |
|---|---|---|
| cold | 0.05 (0.04-0.06) | **1.00** (0.95-1.25) |
| cold_primed | 0.03 (0.02-0.03) | 0.01 (0.01-0.01) |

| condition | roc-chat, old ([bab918d](https://github.com/showell/roc-chat/commit/bab918da7feda2af9ddaf81727599621dec606ab)) | roc-chat, RC1 ([c8c532c](https://github.com/showell/roc-chat/commit/c8c532cbac6f08a128a0ba5b6e68d3586f051399)) |
|---|---|---|
| cold (n=5) | 9.05 (8.36-10.27) | 9.05 (8.70-10.36) |
| warm (n=5) | 0.27 (0.26-0.31) | 0.21 (0.15-0.29) |
| root_changed (n=15) | 0.37 (0.31-0.40) | **0.80** (0.70-1.35) |

In roc-chat's runs, RC1 ran second in each repetition, so its runs saw a
somewhat higher load (0.48-0.74 against 0.29-0.63).

## Which phase grew

These are from `roc check --timings` on roc-markdown, cold:

| phase | nightly-11-03 | RC1 |
|---|---|---|
| whole check (wall) | 612 ms | 1.4 s |
| Type Checking | 386 ms | 204 ms |
| Shared Lowering + Compile-Time Eval | 224 ms | 1,229 ms |
| of which: Import Image Selection (summed) | (none) | 1,049 ms |
| of which: x64 Instruction Generation | 12 ms | 1,055 ms |

- **RC1's frontend is faster; all of the growth is in compile-time
  evaluation.** It builds a native image of the whole Builtin module there
  (`boxy-work: compiled Builtin: ... 7167 tasks`). Its "Builtin (restored)"
  row shows the unit restored in 6 ms, but then 381 ms of lowering, 171 ms
  of ARC, 185 ms of codegen and 80 ms of image work follow.
- **Writing the cache is not the cost:** "Checked Cache Writes" takes
  12 ms, and the Boxy units' "Cache Write" 21 ms.
- **RC1 does write different cache data.** After the reduction's cold
  check, the cache holds 9.8 MB on RC1 and 0.48 MB on the old nightly; the
  difference is Builtin's image. After a hello-world build, RC1's cache is
  only 0.27 MB, so the "cold" starting point doesn't hold that image. After
  roc-markdown's cold check, the cache holds 19.6 MB on RC1 and 17.2 MB on
  the old nightly.
- **Once the image is cached, nothing pays the cost again.** On RC1, a
  check of roc-syntax-color right after roc-markdown's cold check, in the
  same cache, took 0.48 s, where it takes 1.39 s cold.

## The reduction

On an empty cache, `roc check main.roc` of this app takes 0.05 s of CPU on
nightly-2026-11-03 and 1.00 s on RC1:

```roc
app [main!] {}

under : List(U8) -> (List(U8) -> Bool)
under = |prefix| |path| path.starts_with(prefix)

is_mine : List(U8) -> Bool
is_mine = under(['/', 'u'])

main! = |_args| {
	echo!(Str.inspect(is_mine(['/', 'u', 'a'])))
	Ok({})
}
```

The trigger is a top-level constant whose value is a function returned by
a call (`is_mine = under(...)`), here a closure over a `List(U8)` that calls
`List.starts_with`. In roc-markdown it is MdSafety's
`user_uploads = MdSafety.uploads_under("/user_uploads/".to_utf8())`.

These variants don't trigger it:
- the same closure over a `Str` with `Str.starts_with`;
- a plain constant that calls `List.starts_with`;
- a constant list, or a `.to_utf8()` constant;
- a function constant that is just another function's name.

The closure triggers it in an imported type module as well as in the app's
root module.

`roc check --specialize=yes` (which RC1's `check` accepts) didn't change it.

## Bisect

The test was the reduction, checked on an empty cache three times per
nightly. It gives two clear groups: fast runs of 0.07-0.18 s with no Builtin
compile, and slow runs of 1.0-1.4 s with one.

| nightly | CPU s | Builtin compiled |
|---|---|---|
| 2026-11-03 ([34bd006](https://github.com/roc-lang/roc/commit/34bd0067266d4cd5ac941f044863e6a29671ddc0), old pin) | 0.06-0.07 | no |
| 2026-11-07 ([ad3a5d2](https://github.com/roc-lang/roc/commit/ad3a5d2830b94fdac878ce1aaa73c64e7c57720f)) | 0.14-0.18 | no |
| 2026-11-14 ([a87808d](https://github.com/roc-lang/roc/commit/a87808d2e79cc5e347871cb17e531ea528bf85df)) | 0.12-0.15 | no |
| **2026-11-15** ([f25da45](https://github.com/roc-lang/roc/commit/f25da45234ca5db7558f317cef45195e5f8cf429), last fast) | 0.11-0.12 | no |
| **2026-11-18** ([a520eed](https://github.com/roc-lang/roc/commit/a520eeda6c3745f2543fcdd0fb836d3d1336c5ac), first slow) | 1.26-1.43 | yes |
| 0.1.0_RC1 ([15177e9](https://github.com/roc-lang/roc/commit/15177e91f62cafddf5336c455e00e9f05427ac16)) | 1.12-1.31 | yes |
| 2026-11-22 ([3350b1c](https://github.com/roc-lang/roc/commit/3350b1cd41cbb4ae7df5aacd723729b1821ae370), after RC1) | 1.03-1.31 | yes |

There were no nightlies on 11-16 or 11-17. The range
[f25da45...a520eed](https://github.com/roc-lang/roc/compare/f25da45234ca5db7558f317cef45195e5f8cf429...a520eeda6c3745f2543fcdd0fb836d3d1336c5ac)
holds 902 commits, with 47 on main's first-parent line. The first merge in
it, **[#13086](https://github.com/roc-lang/roc/pull/13086) "Combine 10 open
pull requests"**
([98bac3cc6](https://github.com/roc-lang/roc/commit/98bac3cc6ac452352372f189c7fe9373853cae47),
merged 2026-11-16), brings in two candidates. Neither was merged on its own;
both landed through #13086:

- **[#12982](https://github.com/roc-lang/roc/pull/12982):** "Cheaper
  type-checking for operators and literals, and boxy by default for
  checks". It includes
  [af673ecd1](https://github.com/roc-lang/roc/commit/af673ecd100c354998a60dd61ed6b13630e92b3c),
  "Make boxy the default for checks and dev builds, resolve closed operators
  directly, defer literal conversions".
- **[#13058](https://github.com/roc-lang/roc/pull/13058):** "Cheaper
  post-check work: redundant work removed, embedded Builtin unit, constants
  stored directly and evaluated during checking, ordered parallel runs,
  build-independent output, and itemized timings". It includes
  [f41c43aa7](https://github.com/roc-lang/roc/commit/f41c43aa7982afd3f4bd09492e035895551750a1),
  "Embed the Builtin module's Boxy unit in the compiler", and
  [c2a507e36](https://github.com/roc-lang/roc/commit/c2a507e362595be28fbb39c574babe65f73c0718),
  "Embed the Builtin module's Boxy digests in the compiler".

The likely story: since #12982, checks evaluate compile-time constants
through Boxy-compiled native code. The embedded Builtin unit (#13058) is
restored, but for a constant like the reduction's, Builtin is still lowered
and compiled whole. This is inferred from the commit names and from
`--timings`. We did not build the individual commits.

Later merges in the range that also change this path:
- [#13099](https://github.com/roc-lang/roc/pull/13099): "Evaluate constants
  during checking, relate stored rows, publish closed row nodes, and fix
  checker and SpecConstr crashes".
- [#13108](https://github.com/roc-lang/roc/pull/13108): "Rebuild only what
  an edit affects, build unit images without an object round trip, and keep
  literal values in function bodies".
- [#13117](https://github.com/roc-lang/roc/pull/13117): "Make Boxy lowering
  cheaper: remember type conversions and row-node readings, and resolve
  statement sources once per region".

Any of these could change the size of the cost, though not, on this
evidence, its cause.

## roc-chat's root-changed check

- **On RC1, the step that takes the time is "Unit Keys".** After one cold
  check, a changed `app/main.roc` takes 0.80 s on RC1 against 0.37 s on the
  old pin. `--timings` puts 634 ms of RC1's 944 ms in compile-time
  evaluation, in "Unit Keys (summed)", across 214 restored units and 67
  import images. The old nightly has no such step; its whole root-changed
  check is 281 ms.
- **On the old tree (bab918d), the Unit Keys step arrives between the
  same two nightlies as the cold-check cost.** This probe is one cold check,
  then three root changes, each new text:

  | nightly | root_changed CPU s | Unit Keys |
  |---|---|---|
  | 2026-11-03-34bd006 (old pin) | 0.28-0.34 | none |
  | 2026-11-07-ad3a5d2 | 1.99-2.01 | none |
  | 2026-11-15-f25da45 | 0.58-0.62 | none |
  | 2026-11-18-a520eed | 0.84-1.00 | 646 ms |

  On RC1's tree (c8c532c) the same probe gives 0.61-0.69 s for
  nightly-2026-11-15, 0.73-0.78 s for 11-18 (Unit Keys 485 ms), 0.73-0.95 s
  for RC1 and 0.77-0.85 s for 11-22.
- **So the 2x has two parts.** About +0.3 s came between 11-03 and 11-15,
  and the cost moved around in that time: 11-07 was far slower. That part
  is not bisected. About +0.3 s more came between 11-15 and 11-18, with the
  new Unit Keys step, in the same range as the cold-check cost.
- **The 11-14 and 11-15 nightlies are poor bisect points for roc-chat.**
  They take about 120 s for its cold check, against about 9 s for the
  others, and both trees end their check with warnings only (exit 2).

## Verdict

- **The cold-check gap is real but small, and it is a one-time cost per
  cache.** RC1 compiles the Builtin module to native code, about 1 s of CPU
  on this box, the first time any check needs to evaluate a compile-time
  constant that is a function built by a call. The hello-world starting
  point of the "cold" definition never pays that cost, so it shows up on
  the first real check. It is the whole of the gap for roc-markdown
  (0.73 → 1.85 s) and roc-syntax-color (0.64 → 1.39 s). Larger projects
  hide it, because RC1 is faster elsewhere (roc-chat: 9.05 s on both).
- **With the image cached, RC1 is as fast or faster.** roc-markdown takes
  0.74 → 0.70 s, and roc-syntax-color 0.63 → 0.48 s.
- **It matters for the first check after installing or upgrading Roc, or
  after clearing the cache, and for CI that starts from an empty cache.** It
  doesn't matter for an edit loop. If the embedded Builtin unit was meant
  to make this compile unnecessary, the reduction is a test case for it.
- **The roc-chat root-changed slowdown matters more day to day.** About
  0.4 s is added to every edit of a 215-module app, in a "Unit Keys" step
  the old nightly didn't have.
