# capture_plot on the movie wasm platform: the same movie the roc-ray app plays,
# on a page.
#
# Hand-written, and nothing but the name: WasmApp.program is the wasm edge for
# any movie, the way MoviePlayer.program is the roc-ray edge for any movie.
# Compare movies/capture_plot/main.roc, which is this file for the other platform.
app [Model, program] { pf: platform "../../wasm/platform/main.roc" }

import WasmApp
import CapturePlot

Model : CapturePlot.Model

program = WasmApp.program(CapturePlot.movie)
