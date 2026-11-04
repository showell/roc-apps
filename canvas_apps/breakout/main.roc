# Breakout, as a native program on roc-ray. The app root is main.roc, as
# roc-ray's own examples have it; web.roc beside it is the same app as a page.
app [Model, program] {
	lib: "../lib/main.roc",
	native: "../native/main.roc",
	rr: platform "../../../roc-ray/platform/main.roc",
}

import native.CanvasAppRunner
import BreakoutApp

Model : CanvasAppRunner.Model(BreakoutApp.Model)

Msg : CanvasAppRunner.Msg

program = CanvasAppRunner.program(BreakoutApp.canvas_app)
