# framebuffer

A platform for Codex programs that draw on a screen, run in the browser with no
simulated machine under them: the third of Steve's screen modes, "direct use of
the image code in the browser". The machine's page (`machine/batch/`) is the
first, from boot to image.

The Codex program is Roc that rocemit writes; everything under it is the zig
host. Every door that reads or writes memory, or a GPU port, is an effect in
the emitted Roc, and this platform answers it in the host.

- **Memory** is the host's: 3 GB of RAM in 1 MB pages, each made and zeroed the
  first time the program touches it. At or past 3 GB a machine keeps its device
  registers, and this platform has none, so an address there stops the run and
  names it. Memory outlives a run.
- **The screen** is part of that memory, as a UEFI GOP framebuffer is part of a
  machine's. The page picks a size, or takes the one a program brings as
  codex-vm's `-gop` flags; the host publishes it where UEFI's GOP protocol and
  codex-vm do (the framebuffer's base 0xBF000000 at 0x798, its size at 0x7A0,
  width 0x7C4, height 0x7C8, pixel format 0x7CC, stride 0x7E0), with a pixel a
  0x00RRGGBB word.
- **The GPU** is codex-vm's, ported to zig (`platform/gpu.zig`): ports
  0x400-0x417, the command buffer at 0xBE000000, the depth buffer at
  0xBE800000, triangles filled with interpolated depth and colour, then the
  glow. The host makes those buffers when the page gives the program a screen.
- **The clock** is the platform's own cell, 0x7F0: before each run the page
  writes the frame's time there, in milliseconds.
- **A frame** is one run of the program's opening. The page then asks the host
  for the visible pixels (`present`) and draws them.

A program that reaches only memory threads `Mem` and gets `roc/Mem.roc`; one
that reaches a device threads `Machine` and gets `roc/Machine.roc`, memory and
the GPU and nothing else. `build.sh` asks rocemit for `--by-reach`, so the state
follows what the opening can reach rather than every definition its chapters
hold: safe here because the host stops at any address it does not back.

| where | what |
|---|---|
| `platform/main.roc` | the platform: `main!` in Echo's shape, the hosted `Echo`, `Gpu` and `Heap` doors, and the wasm exports the page calls |
| `platform/Heap.roc`, `platform/Gpu.roc`, `platform/Echo.roc` | the hosted doors: a load and a store of 1, 2, 4 or 8 bytes; a GPU port read and write; a line of text |
| `platform/core.zig` | what both hosts share: memory in pages, the screen and clock cells, the GPU's doors, a run, the visible pixels and their hash |
| `platform/host.zig` | the browser's host (wasm): the exports the page calls, and a crash kept for the page |
| `platform/native.zig` | the checker's host (x86-64 Linux): runs the program for its frames and prints the last console and every frame's time and hash |
| `platform/gpu.zig` | codex-vm's GPU over the program's memory |
| `roc/Mem.roc`, `roc/Machine.roc` | the platform's side of the two states: the bump pointer as a value, every other door through the host |
| `build.sh` | host, then each program emitted from a copy (so a `.vmargs` beside it stays behind), wired to the platform and built for wasm into the preview |
| `frames.mjs` | a program's frames from Node: each frame's time, pixels drawn and a hash of the image |
| `verify.sh`, `verify.tsv` | screen mode 2: every program in the table built natively and run for its frames; the last frame's hash must be the table's, and a test's console its verdict |
| `web/index.html` | the page: the programs, Play, one frame at a time, the screen size, the console, the Roc |
| `demos/` | Codex programs written for this platform; `quires.tsv` names the checkout they cite |

    framebuffer/build.sh framebuffer/demos/scene-spin.codex machine/batch/demos/scene-on-screen.codex
    framebuffer/build.sh ~/showell_repos/cobblestone-u60rel/codex/test/gpu-panel-border.codex
    node framebuffer/frames.mjs scene-spin 5
    framebuffer/verify.sh        # mode 2: the table's programs, natively, against their hashes
    # the preview: http://143.244.172.148:9203/framebuffer/

**Mode 2 checks what mode 3 shows.** The browser's host and the checker's are
two thin roots over one `core.zig` and one `gpu.zig`, so a program draws the
same image in both; `verify.tsv` holds that image's hash, first taken where the
machine page's MachineGpu and this platform's GPU agreed.

| program | what it draws |
|---|---|
| `demos/scene-spin.codex` | `codex/test/engine-software-render`'s scene with Renderer3D, the camera circling it by the clock |
| `machine/batch/demos/scene-on-screen.codex` | the same scene from its test's camera; 48,614 pixels drawn, as on the machine and in the test |
| `codex/test/gpu-panel-border`, `gpu-depth-tree`, `gpu-gauge-clamp`, `gpu-input-cursor` | Cobblestone's widgets, laid out and drawn as triangles by the GPU at 640 x 480; each console matches its verdict, and each image is the machine page's, pixel for pixel |
| `codex/test/gop-padded-stride` | a 320 x 240 screen whose rows are 512 pixels in memory; the hidden ends stay untouched |

`PERF.md` is what a frame costs and where the time goes.
