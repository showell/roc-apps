# Breakout, as a page: the wasm module a browser runs.
app [Model, program] {
	lib: "../lib/main.roc",
	pf: platform "../web/platform/main.roc",
}

import lib.WasmApp
import BreakoutApp

Model : BreakoutApp.Model

program = WasmApp.program(BreakoutApp.canvas_app)
