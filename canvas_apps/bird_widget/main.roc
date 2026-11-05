# The bird's widget, as a native program on roc-ray. The app root is main.roc,
# as roc-ray's own examples have it; web.roc beside it is the same app as a page.
app [Model, program] {
	game: "../safari/game.roc",
	lib: "../lib/main.roc",
	native: "../native/main.roc",
	rr: platform "../../../roc-ray/platform/main.roc",
	widget: "../widget_kit/main.roc",
}

import native.CanvasAppRunner
import BirdWidgetApp

Model : CanvasAppRunner.Model(BirdWidgetApp.Model)

Msg : CanvasAppRunner.Msg

program = CanvasAppRunner.program(BirdWidgetApp.canvas_app)
