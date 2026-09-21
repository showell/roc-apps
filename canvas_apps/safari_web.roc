# Safari, as a page: the wasm module a browser runs.
app [Model, program] {
	pf: platform "web/platform/main.roc",
	lib: "lib/main.roc",
}

import lib.WasmApp
import safari/SafariApp

Model : SafariApp.Model

program = WasmApp.program(SafariApp.canvas_app)
