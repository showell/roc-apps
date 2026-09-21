# Pixel Workshop, as a native program on roc-ray. The app root is main.roc, as
# roc-ray's own examples have it; web.roc beside it is the same app as a page.
app [Model, program] {
	rr: platform "../../../roc-ray/platform/main.roc",
	lib: "../lib/main.roc",
	native: "../native/main.roc",
}

import native.CanvasAppRunner
import WorkshopApp

Model : CanvasAppRunner.Model(WorkshopApp.Model)

Msg : CanvasAppRunner.Msg

program = CanvasAppRunner.program(WorkshopApp.canvas_app)
