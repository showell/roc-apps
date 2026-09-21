# The Halloween movie, as a page: the wasm module a browser runs.
#
# The companion of trick_or_treat_native.roc. See snake_web.roc for why the two app
# files sit here rather than in trick_or_treat/.
app [Model, program] {
	pf: platform "web/platform/main.roc",
	lib: "lib/main.roc",
}

import lib.WasmApp
import trick_or_treat/TrickOrTreatApp

Model : TrickOrTreatApp.Model

program = WasmApp.program(TrickOrTreatApp.canvas_app)
