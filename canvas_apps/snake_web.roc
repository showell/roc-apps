# Snake, as a page: the wasm module a browser runs.
#
# **WHY THE TWO APP FILES SIT HERE AND NOT IN snake/.** An app file is where
# Roc's package root is, and a relative import may not climb above it. The
# roc-ray app needs `native/CanvasAppRunner`, which touches the platform and so
# cannot live in a package -- a package cannot see one. Both apps therefore sit
# where everything they reach is below them, and the name says which is which.
# Everything that is only about Snake, its page included, is in snake/.
app [Model, program] {
	pf: platform "web/platform/main.roc",
	lib: "lib/main.roc",
}

import lib.WasmApp
import snake/SnakeApp

Model : SnakeApp.Model

program = WasmApp.program(SnakeApp.canvas_app)
