# wasm-ld: "relocations not in offset order" on the dev backend

`roc build --target=wasm32 --opt=dev` compiles `Repro.roc` and then fails at
the link:

```
wasm-ld: error: ~/.cache/roc/nightly-2026-09-11-793f9d8/src/roc_build/roc_app_unsealed_wasm32.o: relocations not in offset order
```

**Filed as [roc-lang/roc#11419](https://github.com/roc-lang/roc/issues/11419),
fixed by [PR #11422](https://github.com/roc-lang/roc/pull/11422)** (open). The
nightly is `nightly-2026-09-11-793f9d8`; the PR is against `main` at
`f58f67d319`.

## Reproduce

```
machine/batch/build.sh            # once, with no units: builds the platform's host.wasm
cd findings/wasm-reloc-order
~/build/roc-nightly/roc build Repro.roc --target=wasm32 --opt=dev --output=/tmp/repro.wasm
```

The platform is `machine/batch/platform`: Echo's shape, `main! : List(Str) =>
Try(_, [Exit(I8), ..])`, with hosted functions. A hello-world app on the same
platform links and runs.

## What it takes

A constant record with two pointer-holding fields whose field order and layout
order disagree: the fields are copied in field order, so the relocations come
out in the opposite order to the bytes. `Repro.roc` reaches that through a
`step` that recurses over the command line and copies a record `R` in each of
seven branches; `R` holds two copies of `Inner`, a nested record, a `List(U64)`
and a tag union with a payload. The smaller shape in #11419 is one record whose
`kind` (8-byte aligned) is laid out before its `id` (a list, 4-byte aligned on
wasm32).

The value must survive compile-time evaluation: an index the host supplies
keeps it as data, and a program whose every use folds away links.

## Where the entries come from

They arrive at `reloc.DATA` from more than one producer, and which one depends
on the day: #11419 traced this value through
`StaticDataBuilder.freezeRelocations`, and by `f58f67d319` it came from the
compile-time path instead, as the export `roc__ctfe_1_1` (offsets +32, +72, +8,
+48). The fix therefore sorts in `WasmModule.encodeRelocationSection`, the one
place that knows the offset each entry is written at.

## Where it came from

`Machine.flags` in `machine/roc/Machine.roc` parsed codex-vm's command line into
a record holding `MachineE1000.E1000` and `MachineHpet.Hpet`. Every emitted unit
that boots the machine failed to link for the browser. `flags` now carries the
e1000 and the HPET beside the record, which links.
