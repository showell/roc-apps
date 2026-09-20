# Camera world, as a native program on roc-ray.
#
# The same game in camera/, the same lib, and a different runner. roc-ray is
# named as a sibling checkout of roc-apps.
app [Model, program] {
	rr: platform "../../roc-ray/platform/main.roc",
	lib: "lib/main.roc",
}

import native/CanvasAppRunner
import camera/CameraApp

Model : CanvasAppRunner.Model(CameraApp.Model)

Msg : CanvasAppRunner.Msg

program = CanvasAppRunner.program(CameraApp.canvas_app)
