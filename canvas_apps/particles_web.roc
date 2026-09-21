# Particles, as a page: the wasm module a browser runs.
app [Model, program] {
	pf: platform "web/platform/main.roc",
	lib: "lib/main.roc",
}

import lib.WasmApp
import particles/ParticlesApp

Model : ParticlesApp.Model

program = WasmApp.program(ParticlesApp.canvas_app)
