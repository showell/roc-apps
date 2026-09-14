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
