# Pong, as a page: the wasm module a browser runs.
#
# **WHY THE TWO APP FILES SIT HERE AND NOT IN pong/.** An app file is where
# Roc's package root is, and a relative import may not climb above it. The
# roc-ray app needs `native/CanvasAppRunner`, which touches the platform and so
# cannot live in a package -- a package cannot see one. Both apps therefore sit
# where everything they reach is below them, and the name says which is which.
# Everything that is only about Pong, its page included, is in pong/.
app [Model, program] {
	pf: platform "web/platform/main.roc",
	lib: "lib/main.roc",
}

import lib.WasmApp
import pong/PongApp

Model : PongApp.Model

program = WasmApp.program(PongApp.canvas_app)
