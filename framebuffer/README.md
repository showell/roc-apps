# framebuffer

A platform for Codex programs that draw on a screen, run in the browser with no
machine under them: the third of Steve's screen modes, "direct use of the image
code in the browser". The machine's page (`machine/batch/`) is the first, from
boot to image.

A program here is Codex with an opening that reads and writes memory and
reaches no device. rocemit threads `Mem` through it, and every door that reads
or writes memory is an effect. This platform's `roc/Mem.roc` stands in for the
Mem rocemit writes, so each of those doors is a call into the host, which keeps
the bytes.

- **Memory** is the host's: 32 bits of address space in 1 MB pages, each made
  and zeroed the first time the program touches it. An address past 4 GB stops
  the run and names the address. Memory outlives a run.
- **The screen** is part of that memory, as a UEFI GOP framebuffer is part of a
  machine's. The page picks a size; the host publishes it where UEFI's GOP
  protocol and codex-vm do (the framebuffer's base 0xBF000000 at 0x798, its
  size at 0x7A0, width 0x7C4, height 0x7C8, pixel format 0x7CC, stride 0x7E0),
  with a pixel a 0x00RRGGBB word. A program written for the machine's `-gop`
  screen draws here unchanged.
- **The clock** is the platform's own cell, 0x7F0: before each run the page
  writes the frame's time there, in milliseconds.
- **A frame** is one run of the program's opening. The page then asks the host
  for the visible pixels (`present`) and draws them.

| where | what |
|---|---|
| `platform/main.roc` | the platform: `main!` in Echo's shape, the hosted `Echo` and `Heap` doors, and the wasm exports the page calls |
| `platform/Heap.roc`, `platform/Echo.roc` | the hosted doors: a load and a store of 1, 2, 4 or 8 bytes; a line of text |
| `platform/host.zig` | the host: memory in pages, the screen and the clock cells, `run`, `present`, the console |
| `roc/Mem.roc` | the platform's Mem: the bump pointer as a value, every other door through `Heap` |
| `build.sh` | host, then each program emitted from a copy (so a `.vmargs` beside it stays behind), wired to the platform and built for wasm into the preview |
| `frames.mjs` | a program's frames from Node: each frame's time, pixels drawn and a hash of the image |
| `web/index.html` | the page: the programs, Play, one frame at a time, the screen size, the console, the Roc |
| `demos/` | Codex programs written for this platform; `quires.tsv` names the checkout they cite |

    framebuffer/build.sh framebuffer/demos/scene-spin.codex machine/batch/demos/scene-on-screen.codex
    node framebuffer/frames.mjs scene-spin 5
    # the preview: http://143.244.172.148:9203/framebuffer/

| program | what it draws |
|---|---|
| `demos/scene-spin.codex` | `codex/test/engine-software-render`'s scene with Renderer3D, the camera circling it by the clock |
| `machine/batch/demos/scene-on-screen.codex` | the same scene from its test's camera; 48,614 pixels drawn, as on the machine and in the test |

`PERF.md` is what a frame costs and where the time goes.
