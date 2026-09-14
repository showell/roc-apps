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

The frame is the renderer's own Roc. Of the hot function's constants, 1000000
is the one the emitted Roc also writes, and it writes it only in Renderer3D's
light contribution and shadow lookups; which procedure that is has not been
established.
