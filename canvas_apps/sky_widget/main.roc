# The sky's widget, as a native program on roc-ray. The app root is main.roc,
# as roc-ray's own examples have it; web.roc beside it is the same app as a page.
app [Model, program] {
	game: "../safari/game.roc",
	lib: "../lib/main.roc",
	native: "../native/main.roc",
	rr: platform "../../../roc-ray/platform/main.roc",
}

import native.CanvasAppRunner
import SkyWidgetApp

Model : CanvasAppRunner.Model(SkyWidgetApp.Model)

Msg : CanvasAppRunner.Msg

program = CanvasAppRunner.program(SkyWidgetApp.canvas_app)
