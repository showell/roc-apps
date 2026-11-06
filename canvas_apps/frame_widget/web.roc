# The paused frame's widget, as a page: the wasm module a browser runs.
app [Model, program] {
	game: "../safari/game.roc",
	lib: "../lib/main.roc",
	pf: platform "../web/platform/main.roc",
	widget: "../widget_kit/main.roc",
}

import lib.WasmApp
import FrameWidgetApp

Model : FrameWidgetApp.Model

program = WasmApp.program(FrameWidgetApp.canvas_app)
