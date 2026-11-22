# Particles, as a page: the wasm module a browser runs.
app [Model, program] {
	lib: "../lib/main.roc",
	pf: platform "../web/platform/main.roc",
}

import lib.WasmApp
import ParticlesApp

Model : ParticlesApp.Model

program = WasmApp.program(ParticlesApp.canvas_app)
