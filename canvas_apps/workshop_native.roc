# Pixel Workshop, as a native program on roc-ray.
#
# The same editor in workshop/, the same lib, and a different runner. roc-ray
# is named as a sibling checkout of roc-apps.
app [Model, program] {
	rr: platform "../../roc-ray/platform/main.roc",
	lib: "lib/main.roc",
}

import native/CanvasAppRunner
import workshop/WorkshopApp

Model : CanvasAppRunner.Model(WorkshopApp.Model)

Msg : CanvasAppRunner.Msg

program = CanvasAppRunner.program(WorkshopApp.canvas_app)
