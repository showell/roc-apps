# demos

Codex programs written for the batch page, not tests from Cobblestone: they
have no `.expected`, and nothing grades them. Each cites Cobblestone's chapters
from the checkout `quires.tsv` names, and brings its codex-vm flags as
`.vmargs`, as a test does.

| program | what it does |
|---|---|
| `scene-on-screen.codex` | renders `codex/test/engine-software-render`'s scene (ground, a shiny cube, a red pyramid) into the `-gop` framebuffer with Renderer3D, and prints how many pixels it drew; that test counts 48,614 at the same size |

Build one onto the page with `machine/batch/build.sh machine/batch/demos/scene-on-screen.codex`.
