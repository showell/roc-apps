# Eight Queens, as a page: the wasm module a browser runs.
app [Model, program] {
	chess: "../chess_kit/main.roc",
	lib: "../lib/main.roc",
	pf: platform "../web/platform/main.roc",
}

import lib.WasmApp
import EightQueensApp

Model : EightQueensApp.Model

program = WasmApp.program(EightQueensApp.canvas_app)
