# Pong, as a native program on roc-ray.
#
# The companion of pong_web.roc: the same game in pong/, the same lib, and a
# different runner. roc-ray is named as a sibling checkout of roc-apps.
app [Model, program] {
	rr: platform "../../roc-ray/platform/main.roc",
	lib: "lib/main.roc",
}

import native/CanvasAppRunner
import pong/PongApp

Model : CanvasAppRunner.Model(PongApp.Model)

Msg : CanvasAppRunner.Msg

program = CanvasAppRunner.program(PongApp.canvas_app)
