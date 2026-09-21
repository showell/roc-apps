# Camera world, as a native program on roc-ray. The app root is main.roc, as
# roc-ray's own examples have it; web.roc beside it is the same app as a page.
app [Model, program] {
	rr: platform "../../../roc-ray/platform/main.roc",
	lib: "../lib/main.roc",
	native: "../native/main.roc",
}

import native.CanvasAppRunner
import CameraApp

Model : CanvasAppRunner.Model(CameraApp.Model)

Msg : CanvasAppRunner.Msg

program = CanvasAppRunner.program(CameraApp.canvas_app)
