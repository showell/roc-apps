# Snake, as a page: the wasm module a browser runs. main.roc beside it
# is the same app on roc-ray.
app [Model, program] {
	pf: platform "../web/platform/main.roc",
	lib: "../lib/main.roc",
}

import lib.WasmApp
import SnakeApp

Model : SnakeApp.Model

program = WasmApp.program(SnakeApp.canvas_app)
