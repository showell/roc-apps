# Safari, as a native program on roc-ray.
app [Model, program] {
	rr: platform "../../roc-ray/platform/main.roc",
	lib: "lib/main.roc",
}

import native/CanvasAppRunner
import safari/SafariApp

Model : CanvasAppRunner.Model(SafariApp.Model)

Msg : CanvasAppRunner.Msg

program = CanvasAppRunner.program(SafariApp.canvas_app)
