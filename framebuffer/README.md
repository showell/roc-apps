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
  A triangle with texture coordinates samples the texture the program uploads
  (0x408-0x40B), shaded by codex-vm's globe shader under the light and eye of
  0x404-0x407, or modulating its colour.
- **Files** a program reads through codex-vm's asset loader (0x40C, 0x40D,
  0x417) come, natively, from the working directory, as codex-vm finds them
  (`verify.sh` runs each program from the checkout), and in the browser and
  `frames.mjs` from the preview's `assets/`, where `build.sh` copies the files
  `programs.tsv` names.
- **The keyboard controller** is codex-vm's, at ports 0x60 and 0x64: a queue of
  scancodes the host fills (`key`), empty until the page types. Any other port
  stops the run, naming it and its width.
- **The clock** is the platform's own cell, 0x7F0: before each run the page
  writes the frame's time there, in milliseconds.
- **Keys and the mouse** reach a running program through memory the page shares
  with its runner (a SharedArrayBuffer, so the page must be cross-origin
  isolated, which `safari/web/serve.py` asks for, and a secure context: from
  another machine, open it through a tunnel, `ssh -N -L 9203:localhost:9203`,
  as `http://localhost:9203/framebuffer/`). A key's set-1 make code lands
  in the key cell at 28680, where codex-vm's keyboard interrupt leaves it, and
  in the keyboard controller's queue; the mouse's position and buttons land in
  codex-vm's mouse ports. The runner hands them to the host before each run and
  at every GPU flush. codex-vm's relative mouse packet at 28684, which the
  globe reads to drag, is not modelled.
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
| `platform/native.zig` | the checker's host (x86-64 Linux): runs the program for its runs (`-frames`) or GPU flushes (`-flushes`) and prints the last console and every frame's time and hash; `-key` and `-mouse` hand it input before the first run, as the page's runner does, and `-ppm` writes the last frame |
| `platform/gpu.zig` | codex-vm's GPU over the program's memory |
| `roc/Mem.roc`, `roc/Machine.roc` | the platform's side of the two states: the bump pointer as a value, every other door through the host |
| `build.sh` | host, then each program emitted from a copy (so a `.vmargs` beside it stays behind), wired to the platform and built for wasm into the preview |
| `programs.tsv` | what a frame is for a program, the screen it expects when its sources name none, and the files its asset loads read |
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
| `apps/cvmm/GuiOpening.codex` | cvmm's GuiOS desktop at 1024 x 768, its widgets drawn through the GPU; a frame is a flush |
| `demos/shadow-spin.codex` | `codex/test/engine-shadow`'s cube and plane with Renderer3D's shadow map, the light circling the cube by the clock |
| `demos/meshes-spin.codex` | `codex/test/engine-mesh-gen`'s sphere, cylinder, cone and torus, Gouraud shaded, the camera circling them |
| `demos/widgets-on-screen.codex` | a panel of widgets drawn by GopComposite onto the screen, as `codex/test/gop-composite-kinds` draws them into memory, the gauge filling with the clock |
| `demos/qr-on-screen.codex` | `codex/test/qr-encode`'s payload encoded by GopQr and drawn with GopDraw's fill |
| `demos/sketch-on-screen.codex` | what `codex/test/rasterizer-test` and `sprite-test` draw, in one 80 x 60 Framebuf copied to the screen: lines, a rectangle, a filled circle and a triangle, keyed and flipped sprites, a blinking face |
| `demos/raytrace-on-screen.codex` | `codex/test/raytracer-test`'s spheres and floor traced by Raytracer at 160 x 120 and copied to the screen, the red sphere bobbing by the clock; the spheres are lit at the ambient level alone and the floor at its full grey |
| `demos/glyphs-on-screen.codex` | the glyph for A in `codex/test/truetype-render-test`'s embedded font, a single triangle, rasterized by GlyphRasterizer plain and anti-aliased at 16, 24 and 32 pixels to the em, each glyph pixel a 3 by 3 block |
| `apps/globe/GlobeDemo.codex` | Cobblestone's globe: an icosphere wrapped in the 2048 x 1024 earth image it loads from disk, shaded by codex-vm's globe shader, turning; with no image it paints a planet in Codex. Its wasm needs more stack than a browser gives: `gtris` and `gtris-next`, which only forwards back to `gtris`, call each other once a visible triangle |

Drawing these showed three things about the chapters under them:

- Raytracer's `rt-pixel-ray` reaches sideways half the camera's field of view
  against a forward reach of 1, so `raytracer-test`'s field of 1000 sees nearly
  half the sphere of directions; `raytrace-on-screen` uses a field of 1. With a
  forward reach of 1000, `raytracer-test`'s 16 x 12 render hits 110 pixels, not
  81.
- Raytracer's `rt-shade` divides its diffuse and specular terms by 1000, and
  for a unit normal they reach at most one, so a sphere is lit at the scene's
  ambient level alone wherever the light stands: `raytracer-test`'s verdict,
  rgb(51, 0, 0), pins it, and without the division it is rgb(92, 0, 0).
  `raytracer-test`'s floor normal is 1000 long, so the floor's terms are a
  thousand times larger and it draws at its full grey. Both are the scale of
  the fixed-point Raytracer, where a unit vector was 1000 long and `vec3-dot`
  divided by 1000, left in place when Update 26 made its geometry Real.
  Cobblestone PR 149 proposes the fix; under it `raytrace-on-screen` passes a
  field of 1000 and a unit floor normal.
- GlyphRasterizer's `gr-make-row` builds a glyph's buffer by pushing onto its
  own recursive call, as deep as the buffer is long, and the 4 x 4 supersampled
  buffer of an anti-aliased glyph overflowed the browser's stack. rocemit now
  writes that shape as a loop.

Cobblestone's other drawing apps do not run here yet:

| app | what stops it |
|---|---|
| `apps/circuits` | BitmapFont's GPU text path calls `gpu-rect-top`, `gpu-rect-chrome` and `gpu-seq`, which the app defines, so the emitted modules import each other; `roc check` names the cycle and `roc build` crashes on it |
| `apps/fireworks` | `rnd` multiplies a plain `Integer` past 64 bits before the first frame, where a plain `Integer` traps (COMPILER-36), as Roc's `*` does. Cobblestone PR 151 makes it wrap; built with that change the app runs its whole 3,900-frame cycle here, through the cinematic pass and the additive sprites |
| `apps/c64` | plays its SID through the HDA sound card's MMIO |

`PERF.md` is what a frame costs and where the time goes.
