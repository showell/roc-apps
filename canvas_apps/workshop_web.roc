# Pixel Workshop, as a page: the wasm module a browser runs.
#
# The companion of workshop_native.roc. See snake_web.roc for why the two app
# files sit here rather than in workshop/.
app [Model, program] {
	pf: platform "web/platform/main.roc",
	lib: "lib/main.roc",
}

import lib.WasmApp
import workshop/WorkshopApp

Model : WorkshopApp.Model

program = WasmApp.program(WorkshopApp.canvas_app)
