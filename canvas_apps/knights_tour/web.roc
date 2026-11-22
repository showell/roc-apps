# The Knight's Tour, as a page: the wasm module a browser runs.
app [Model, program] {
	chess: "../chess_kit/main.roc",
	lib: "../lib/main.roc",
	pf: platform "../web/platform/main.roc",
}

import lib.WasmApp
import KnightsTourApp

Model : KnightsTourApp.Model

program = WasmApp.program(KnightsTourApp.canvas_app)
