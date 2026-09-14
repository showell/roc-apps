# wasm-ld: "relocations not in offset order" on the dev backend

`roc build --target=wasm32 --opt=dev` compiles `Repro.roc` and then fails at
the link:

```
wasm-ld: error: ~/.cache/roc/nightly-2026-09-11-793f9d8/src/roc_build/roc_app_unsealed_wasm32.o: relocations not in offset order
```

The nightly is `nightly-2026-09-11-793f9d8`. Not reported upstream; that is
Steve's call.

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

`step` recurses over the command line and, in each of seven branches, copies a
record `R` with `{ ..r, field: value }`. `R` holds two copies of `Inner`, a
record with a nested record, a `List(U64)` and a tag union with a payload.

- Taking out the tag field still fails, and so does taking out the dictionary
  instead.
- The same function over a record of twelve `U64` fields links, and so does one
  holding two 24-field records.
- A version with lists and a dictionary but no nested record, and with six
  branches, links.

So the ingredient is not one field type. The last reduction step between
linking and failing is not isolated.

## Where it came from

`Machine.flags` in `machine/roc/Machine.roc` parsed codex-vm's command line into
a record holding `MachineE1000.E1000` and `MachineHpet.Hpet`. Every emitted unit
that boots the machine failed to link for the browser. `flags` now carries the
e1000 and the HPET beside the record, which links.
