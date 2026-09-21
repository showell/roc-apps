# Breakout, as a page: the wasm module a browser runs. main.roc beside it
# is the same app on roc-ray.
app [Model, program] {
	pf: platform "../web/platform/main.roc",
	lib: "../lib/main.roc",
}

import lib.WasmApp
import BreakoutApp

Model : BreakoutApp.Model

program = WasmApp.program(BreakoutApp.canvas_app)
