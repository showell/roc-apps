# Trick or Treat, as a page: the wasm module a browser runs.
app [Model, program] {
	lib: "../lib/main.roc",
	pf: platform "../web/platform/main.roc",
}

import lib.WasmApp
import TrickOrTreatApp

Model : TrickOrTreatApp.Model

program = WasmApp.program(TrickOrTreatApp.canvas_app)
