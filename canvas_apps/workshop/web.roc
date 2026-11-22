# Pixel Workshop, as a page: the wasm module a browser runs.
app [Model, program] {
	lib: "../lib/main.roc",
	pf: platform "../web/platform/main.roc",
}

import lib.WasmApp
import WorkshopApp

Model : WorkshopApp.Model

program = WasmApp.program(WorkshopApp.canvas_app)
