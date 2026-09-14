# framebuffer

A platform for Codex programs that draw on a screen, run in the browser with no
simulated machine under them: the third of Steve's screen modes, "direct use of
the image code in the browser". The machine's page (`machine/batch/`) is the
first, from boot to image.

The Codex program is Roc that rocemit writes; everything under it is the zig
host. Every door that reads or writes memory, or a port, is an effect in the
emitted Roc, and this platform answers it in the host.

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
- **The keyboard controller** is codex-vm's, at ports 0x60 and 0x64: a queue of
  scancodes the host fills (`key`), empty until the page types. Any other port
  stops the run, naming it and its width.
- **The clock** is the platform's own cell, 0x7F0: before each run the page
  writes the frame's time there, in milliseconds.
- **A frame** is one run of the program's opening, or, for a program that draws
  in a loop of its own and never ends its run, one GPU flush (`programs.tsv`
  says which). The page runs the program in a Web Worker (`web/runner.js`),
  which posts each frame's visible pixels to the page.

A program that reaches only memory threads `Mem` and gets `roc/Mem.roc`; one
that reaches a device threads `Machine` and gets `roc/Machine.roc`, memory and
the ports and nothing else. `build.sh` asks rocemit for `--by-reach`, so the state
follows what the opening can reach rather than every definition its chapters
hold: safe here because the host stops at any address it does not back.

| where | what |
|---|---|
| `platform/main.roc` | the platform: `main!` in Echo's shape, the hosted `Echo`, `Heap` and `Port` doors, and the wasm exports the page calls |
| `platform/Heap.roc`, `platform/Port.roc`, `platform/Echo.roc` | the hosted doors: a load and a store of 1, 2, 4 or 8 bytes; a port read and write of a width; a line of text |
| `platform/core.zig` | what both hosts share: memory in pages, the screen and clock cells, the ports (the GPU and the keyboard controller), a run, the visible pixels and their hash |
| `platform/host.zig` | the browser's host (wasm): the exports the page calls, a flush reported to the page's runner, and a crash kept for the page |
| `platform/native.zig` | the checker's host (x86-64 Linux): runs the program for its runs (`-frames`) or GPU flushes (`-flushes`) and prints the last console and every frame's time and hash |
| `platform/gpu.zig` | codex-vm's GPU over the program's memory |
| `roc/Mem.roc`, `roc/Machine.roc` | the platform's side of the two states: the bump pointer as a value, every other door through the host |
| `build.sh` | host, then each program emitted from a copy (so a `.vmargs` beside it stays behind), wired to the platform and built for wasm into the preview |
| `programs.tsv` | what a frame is for a program, and the screen it expects when its sources name none |
| `frames.mjs` | a program's frames from Node, runs or (`flushes:N`) GPU flushes: each frame's time, pixels drawn and a hash of the image, and the last frame as a PNG |
| `verify.sh`, `verify.tsv` | screen mode 2: every program in the table built natively and run for its runs or flushes; the last frame's hash must be the table's, and a test's console its verdict |
| `web/index.html`, `web/runner.js` | the page: the programs, Play, one frame at a time, the screen size, the console, the Roc; and its runner, the Web Worker that runs the program and posts its frames |
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
| `apps/engine-demo/EngineDemo.codex` | Cobblestone's engine demo: Codex lights and transforms a scene and hands the triangles to the GPU, the camera orbiting in a loop that never ends; a frame is a flush |

Cobblestone's other drawing apps do not run here yet:

| app | what stops it |
|---|---|
| `apps/circuits` | BitmapFont's GPU text path calls `gpu-rect-top`, `gpu-rect-chrome` and `gpu-seq`, which the app defines, so the emitted modules import each other; `roc check` names the cycle and `roc build` crashes on it |
| `apps/fireworks` | `rnd` multiplies a plain `Integer` past 64 bits before the first flush. A plain `Integer` traps on overflow in Cobblestone's x86 code (`int-trap-after`, `int-ty-default` is `OvError`), and Roc's `*` crashes the same way; its `hsh` is declared `wrapping` and `rnd` is not. The cinematic pass, the fade clear and the additive sprites it draws with are in `gpu.zig`, not yet exercised |
| `apps/globe` | loads its earth texture through the GPU's asset ports (0x408-0x40D, 0x417) |
| `apps/c64` | plays its SID through the HDA sound card's MMIO |

`PERF.md` is what a frame costs and where the time goes.
