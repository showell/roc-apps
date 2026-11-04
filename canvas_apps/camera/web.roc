# Camera world, as a page: the wasm module a browser runs. main.roc beside it
# is the same app on roc-ray.
app [Model, program] {
	lib: "../lib/main.roc",
	pf: platform "../web/platform/main.roc",
}

import lib.WasmApp
import CameraApp

Model : CameraApp.Model

program = WasmApp.program(CameraApp.canvas_app)
