# The beacons' widget, as a page: the wasm module a browser runs. main.roc beside
# it is the same app on roc-ray.
app [Model, program] {
	game: "../safari/game.roc",
	lib: "../lib/main.roc",
	pf: platform "../web/platform/main.roc",
	widget: "../widget_kit/main.roc",
}

import lib.WasmApp
import BeaconWidgetApp

Model : BeaconWidgetApp.Model

program = WasmApp.program(BeaconWidgetApp.canvas_app)
