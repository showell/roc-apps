# What a frame costs on the framebuffer platform

A running record of what a frame costs here and where the time goes. Every
number was measured; each says what ran it and how. The machine's screen has
its own log, `machine/batch/PERF.md`.

## The instruments

- **`frames.mjs`** runs a program frame after frame in Node 22, from the wasm
  `build.sh` writes (Roc's dev backend), and prints each frame's time around
  the host's `run` export, the pixels drawn and a hash of the image. The first
  frame of an instance is slower than the rest while the engine compiles the
  module's hot code, so a steady figure is read from frame 1 on.
- **`node --cpu-prof`** over `frames.mjs`, with self time totalled per wasm
  function. Roc writes no name section, so a function is an index until
  something else names it.

## 2026-09-14: the scene, with memory in the host

`machine/batch/demos/scene-on-screen.codex` is the same program on both
platforms: it reads the screen's size from UEFI's GOP cells, renders
engine-software-render's scene into the framebuffer at 0xBF000000, and counts
the pixels it drew. It counts 48,614 on both, and on the machine's page it
takes 1,413 ms (`machine/batch/PERF.md`, after the machine record split).

| host build | scene-on-screen, frames 1 to 3 | scene-spin, frames 1 to 5 |
|---|---|---|
| Debug (zig's default) | 118 to 124 ms | 114 to 135 ms |
| release (`-Drelease`) | 113 to 117 ms | 108 to 113 ms |

The first frame is 195 to 219 ms either way. Wasm memory stays at 15 MB over
20 frames, and the program touches three 1 MB pages: the GOP cells, the heap
where the depth buffer is allocated, and the framebuffer.

Building the host for release saves about 5 ms of 115, so the calls into the
host for every memory read and write are not where the frame goes.

## 2026-09-14: where a frame goes

`roc build --debug` writes a name section, so the profile names the
functions; the frame time is the same as without it (116 to 119 ms). A Roc
procedure is named by its id (`roc__proc_dee`), not by its source name.
scene-on-screen, 20 frames, 2,553 ms sampled:

| what | self time | share |
|---|---|---|
| `roc__proc_dee`, one 61 KB function | 1,145 ms | 44.9% |
| the next eight Roc procedures together | 897 ms | 35.1% |
| the memory doors: `roc_heap_load`, `roc_heap_store`, `host.page` | 61 ms | 2.4% |
| Roc's reference-count helpers | 63 ms | 2.5% |
| `host.present`, the copy the page draws | 4 ms | 0.2% |

The frame is the renderer's own Roc.

## 2026-09-14: the hot function is Renderer3D's column loop

`ROC_LIR_DUMP=` (empty: every procedure) makes `roc build` print the final
LIR of each procedure under its source name, with its calls as `call pN`. The
ids in the wasm are not those numbers, so the two were matched by what each
procedure holds:

| wasm | its constants | LIR procedure | its literals |
|---|---|---|---|
| `roc__proc_dee`, 61 KB | 255, 256, 1000, 65536, 1000000 | `Renderer3D.r3d_scan_cols_sh!`, 1,053 lines, the largest by far | 255, 256, 1000, 65536, 1000000 |
| `roc__proc_df9`, 22 KB, called by `dee` | 255, 256, 1000, 65536 | `Renderer3D.r3d_shade_px`, called by it | 255, 256, 1000, 65536 |
| `roc__proc_e02`, 22 KB, called by `df9` | 255, 1000 | `Renderer3D.r3d_phong_accum`, called by that | 255, 1000 |

Each wasm function also holds 4294967295 (and `dee` 4227), which no LIR
literal has. `r3d_scan_cols_sh!` is the loop along a row of a shaded triangle:
per pixel it works out the barycentric weights and calls `r3d_cover_sh!`, which
the LIR has folded in along with the shadow lookup. Its self-call is already a
loop (`transform=tce`).

Inside it are 15 calls to Roc's `U64.pow`, a checked loop (`unsigned_pow_try_step`
in the LIR). They are Codex's bit shifts: rocemit writes `bit-shr x 16` as
`U64.div_by(x, U64.pow(2, 16))` and `bit-shl` as a multiply by the same, and
`r3d_chan` and every colour packed back together shift once per pixel.

## 2026-09-14: shifts as Roc's shifts

Roc has shifts (`I64.shl_wrap`, `I64.shr_zf_wrap`), and they take the count
modulo the width, as the interpreter's `count & 63` does; a probe over counts
3, 60, 63, 64, 70 and 300 agreed with the interpreter's rule on every one.
rocemit now writes `bit-shl a b` as `I64.shl_wrap(a, I64.to_u8_wrap(b))` and
both right shifts as `I64.shr_zf_wrap`. A shift by 64 or more used to crash in
`U64.pow`; it now shifts as the interpreter does.

| program | before | after |
|---|---|---|
| scene-on-screen, frames 1 to 4 | 113 to 117 ms | 98 to 105 ms |
| scene-spin, frames 1 to 5 | 108 to 113 ms | 95 to 98 ms |

Every frame's hash is the same as before, so the images are identical.

## 2026-09-14: codex-vm's GPU, in zig

The four GPU widget tests and gop-padded-stride, from cobblestone-u60rel's
`codex/test`, on this platform (`platform/gpu.zig`) and on the machine's page
(`MachineGpu`, Roc), both wasm on Roc's dev backend in Node, one run each. Here
the time is frame 1, from `frames.mjs`; on the machine's page it is the whole
run, boot included, from `machine/batch/screenhash.mjs`. Both hash the visible
pixels the same way.

| program | here, a frame | machine page, a run | image hash on both |
|---|---|---|---|
| gpu-panel-border | 30 ms | 2,078 ms | fee5df14 |
| gpu-depth-tree | 32 ms | 1,967 ms | 2c7c1dc1 |
| gpu-gauge-clamp | 25 ms | 2,060 ms | c990fa29 |
| gpu-input-cursor | 30 ms | 2,298 ms | dbf102b2 |
| gop-padded-stride | 18 ms | 1,428 ms | 1989e38f |

The two GPUs agree on every pixel of every image, and every program's console
matches its test's verdict. The widget tests run on this platform's `Machine`
(memory and the GPU's ports); gop-padded-stride reaches only memory and runs on
its `Mem`.

## 2026-09-14: the native checker

`verify.sh` builds each program in `verify.tsv` natively (Roc's dev backend,
x86-64, the host in zig linked with musl) and runs it for its frames; every
hash matched the table. The time is the last frame's, one run each, beside
the same frame in Node from the wasm build.

| program | native | wasm in Node |
|---|---|---|
| gpu-panel-border | 17 ms | 30 ms |
| gpu-depth-tree | 18 ms | 32 ms |
| gpu-gauge-clamp | 16 ms | 25 ms |
| gpu-input-cursor | 25 ms | 30 ms |
| gop-padded-stride | 12 ms | 18 ms |
| scene-on-screen | 69 ms | 104 ms |
| scene-spin, frame 3 | 63 ms | 95 ms |

The whole run of `verify.sh`, the wasm and native builds of all seven included,
took 21 s.

## 2026-09-14: engine-demo, a program that draws in a loop

Cobblestone's `apps/engine-demo` lights and transforms its scene in Codex and
writes 640 x 480's triangles to the GPU, in a loop that never ends; a frame is
a GPU flush. Flushes 1 to 4, one run each:

| build | a flush |
|---|---|
| wasm in Node (`frames.mjs EngineDemo flushes:5`) | 10 to 13 ms |
| native (`-flushes 5`) | 6 to 8 ms |

Every flush's hash is the same in both. The machine's page cannot run it: its
loop reads the keyboard controller's port 0x60, which the machine does not
model. `verify.sh` with engine-demo's 30 flushes added: all eight pass, 15 s.

## 2026-09-15: raytrace-on-screen, where a frame goes

`demos/raytrace-on-screen` traces raytracer-test's scene at 160 x 120 with
Raytracer, then copies the trace onto the screen with one `poke-32` a screen
pixel; it does not use the GPU. At u61-candidate (Raytracer with PR 149), on
the page's default 320 x 240 screen:

| build | a frame, frames 1 to 11 |
|---|---|
| native (`verify.sh`) | 55 ms |
| wasm in Node (`frames.mjs`, a `--debug` build) | 96 to 101 ms |
| the page, in Steve's browser | about 105 ms |

`node --cpu-prof` over 12 frames sampled 1,375 ms. The wasm names a procedure
by id. Each id was matched to a source name from `ROC_LIR_DUMP=` by the
constants it holds and what it calls, read from the module's code section:

| what | wasm | self time |
|---|---|---|
| `Raytracer.rt_intersect_obj`, the sphere and plane tests folded in (both hold 0.001 and 999999) | `roc__proc_313`, 28.7 KB | 21.8% |
| `Raytracer.rt_closest`, two specializations: the walk over the scene for a ray | `roc__proc_312`, `2f0` | 17.2% |
| the demo's `copy_cols!`: `fb-get`, then `poke-32` through `Heap.store!` | `roc__proc_303` | 10.8% |
| `Geometry.geo_sqrt_loop` and `Prelude.ordinal`, the `~` that ends it | `roc__proc_335`, `339` | 10.8% |
| `Raytracer.rt_shade` | `roc__proc_2ee` | 5.6% |
| the opening, holding the scene and `rt-render`'s loop | `roc__proc_2e0` | 4.6% |
| `List.get`, `vec3_subtract`, `rt_normalize`, `vec3_scale`, `col_clamp8` | | 11% |
| Node: `frames.mjs`'s report and hash | | 3.4% |
| the host's `present` and `screen` | | 1.2% |

The frame is Raytracer's own Roc, as scene-on-screen's is Renderer3D's. Two
things in it are this program's shape rather than Roc's:

- `geo-sqrt` is Newton's method written in Codex: it starts from n / 2 + 1 and
  stops when two guesses are within `~`, four ULPs. Cobblestone has no
  square-root builtin, so the loop is the program, and it costs a tenth of the
  frame.
- The copy costs a tenth though the host's store, `roc_heap_store`, is not in
  the top 25: the time is the Roc around each pixel, `fb-get`'s `List.get` on
  the Framebuf and the door's wrapper.

## 2026-09-15: a square root as Roc's

rocemit writes Geometry's `geo-sqrt` and Quaternion's `quat-real-sqrt` as
`F64.sqrt` behind their own guard (rust-codex-compiler `ad24db4`). Every
`verify.sh` hash is the same as before.

| raytrace-on-screen | the Newton loop | Roc's `sqrt` |
|---|---|---|
| a frame, wasm in Node (`frames.mjs`, frames 1 to 11) | 96 to 101 ms | 61 to 69 ms |
| `bench/raybench.sh`, 30 frames of `trace`, native | 0.86 to 1.12 s | 0.58 to 0.60 s |
| `bench/raybench.sh`, 30 frames of `render`, native | 1.26 to 1.35 s | 0.80 to 0.81 s |

`bench/RayBench.roc` is the demo's scene and camera over the modules rocemit
writes for it, without the screen: `trace` finds each pixel's closest hit and
nothing else, `render` is the whole `rt-render`, and each prints a checksum
that stays the same. The case study that goes on from here, what `rt-closest`
carries and what the dev backend's code is, is the essay
`:9100/notes/raytrace-case-study.md`.

## 2026-09-15: the bench with LLVM

`OPT=speed bench/raybench.sh` builds with LLVM in 2 s. The checksums are the
dev build's.

| 30 frames, native | `--opt=dev` | `--opt=speed` |
|---|---|---|
| `trace` | 0.59 to 0.65 s | 0.037 to 0.042 s |
| `render` | 0.84 to 0.88 s | 0.083 to 0.086 s |

The dev backend's frame is sixteen times LLVM's for the closest-hit walk and
ten times for the whole render.
