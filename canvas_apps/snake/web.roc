# Snake, as a page: the wasm module a browser runs.
app [Model, program] {
	lib: "../lib/main.roc",
	pf: platform "../web/platform/main.roc",
}

import lib.WasmApp
import SnakeApp

Model : SnakeApp.Model

program = WasmApp.program(SnakeApp.canvas_app)
