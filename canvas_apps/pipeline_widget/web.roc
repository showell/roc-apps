# The pipeline's widget, as a page: the wasm module a browser runs.
app [Model, program] {
	game: "../safari/game.roc",
	lib: "../lib/main.roc",
	pf: platform "../web/platform/main.roc",
	widget: "../widget_kit/main.roc",
}

import lib.WasmApp
import PipelineWidgetApp

Model : PipelineWidgetApp.Model

program = WasmApp.program(PipelineWidgetApp.canvas_app)
