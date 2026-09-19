# particles on the movie wasm platform: the same movie the roc-ray app plays,
# on a page.
#
# Hand-written, and nothing but the name: WasmApp.program is the wasm edge for
# any movie, the way MoviePlayer.program is the roc-ray edge for any movie.
# Compare movies/particles/main.roc, which is this file for the other platform.
app [Model, program] { pf: platform "../../wasm/platform/main.roc" }

import WasmApp
import Particles

Model : Particles.Model

program = WasmApp.program(Particles.movie)
