# Pong, as a page: the wasm module a browser runs.
app [Model, program] {
	lib: "../lib/main.roc",
	pf: platform "../web/platform/main.roc",
}

import lib.WasmApp
import PongApp

Model : PongApp.Model

program = WasmApp.program(PongApp.canvas_app)
