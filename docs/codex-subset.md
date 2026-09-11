# The Codex subset safari uses

Counted over the 54 frozen units in `safari-codex/units/*.rust.ir`, the IR
rust-codex-compiler emits for each spec with every cited chapter resolved in.
This is what a Codex-to-Roc emitter has to cover to port safari; nothing else.

## Expression forms (every occurrence, all 54 units)

| form | count | Roc |
|---|---|---|
| `record` / `field-val` | 152,156 / 121,181 | record literal |
| `num-lit` / `int-lit` / `text-lit` / `bool-lit` | 153,290 / 6,016 / 1,016 / 2,510 | literals; every Real is an annotated `F64` |
| `name` | 36,873 | a binding |
| `apply` | 22,173 | call; curried in the IR, saturated in the source |
| `binary sub-num/mul-num/add-num/div-num` | 32,297 / 2,111 / 1,530 / 1,312 | `F64` arithmetic |
| `binary add-int/sub-int/mul-int/div-int` | 674 / 396 / 101 / 102 | `I64` arithmetic |
| `binary lt/ge/gt/le/eq/ne` | 598 / 599 / 384 / 342 / 215 / 165 | comparisons |
| `binary append-text` / `append-list` | 1,160 / 447 | `Str.concat` / `List.concat` |
| `binary approx-eq-exact` / `and` | 48 / 1 | `F64.is_float_eq`? / `and` |
| `if` | 2,502 | `if c { a } else { b }` |
| `let` | 2,448 | a binding in a block |
| `match` with `ctor-pat` / `var-pat` | 81 (234 / 42) | `match` on a tag union |
| `list-expr` | 4,330 | list literal |
| `field-access` | 3,329 | `r.field` |
| `negate` | 292 | `-x` |
| `act` / `do-exec` | 54 / 436 | `main!` and `echo!`, in `opening` only |
| `def` | 5,162 (1,852 distinct) | top-level binding |

Absent: lambdas (lifted or never written), `handle`, `try`, `fork`,
`with-timeout`, `field-store`, `lazy`, `induction`, vectors, units.

## Types

records (41 distinct), functions, `int-default` (i64), `list`, `boolean`,
`text`, four sums (`Creature`, `Scheme`, `Shoulder`, `Kind`), `Maybe`, type
variables (the polymorphic ListUtils only), `nothing`, and one effectful row
per unit (`opening`). No bounded, wrapping or unit-typed integer anywhere.

## Builtins

`list-length` 1,312 · `list-at` 1,148 · `show` 580 (on an Integer only) ·
`print-line-uni` 436 · `real-from-int` 236 · `real-abs` 110 · `real-to-int`
75 · `bit-and` 57 · `real-to-bits` 52 · `real-max` 43 · `real-min` 37 ·
`list-push` 24 · `bit-shl` / `bit-or` 12 · `bit-shr` 4. The trig and rounding
come from DeviceMath and Num, which are ordinary chapters in the unit and port
as code, so their f64 results should match Roc's `F64` bit for bit.

## What decides fidelity

The verdicts are graded at tolerance 0.0 on IEEE doubles, so the emitter must
keep every Real an `F64` (Roc's unannotated fraction is a `Dec`), keep the
operation order the IR has, and keep integer arithmetic on `I64` with list
indices converted at the `list-at` boundary. `show` on an Integer is
`I64.to_str`. Codex's `list-at` out of range is a runtime fault; Roc's
`List.get` returns a `Try`, and the emitter picks one policy (`??` with a
crash) and says so.
