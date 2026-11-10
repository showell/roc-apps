# The bend animals' widget, as a page: the wasm module a browser runs.
app [Model, program] {
	game: "../safari/game.roc",
	lib: "../lib/main.roc",
	pf: platform "../web/platform/main.roc",
	widget: "../widget_kit/main.roc",
}

import lib.WasmApp
import BendAnimalsWidgetApp

Model : BendAnimalsWidgetApp.Model

program = WasmApp.program(BendAnimalsWidgetApp.canvas_app)
