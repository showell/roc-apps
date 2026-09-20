# Camera world, as a page: the wasm module a browser runs.
#
# The companion of camera_native.roc. See snake_web.roc for why the two app
# files sit here rather than in camera/.
app [Model, program] {
	pf: platform "web/platform/main.roc",
	lib: "lib/main.roc",
}

import lib.WasmApp
import camera/CameraApp

Model : CameraApp.Model

program = WasmApp.program(CameraApp.canvas_app)
