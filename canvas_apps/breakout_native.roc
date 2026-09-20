# Breakout, as a native program on roc-ray.
#
# The companion of breakout_web.roc: the same game in breakout/, the same lib, and a
# different runner. roc-ray is named as a sibling checkout of roc-apps.
app [Model, program] {
	rr: platform "../../roc-ray/platform/main.roc",
	lib: "lib/main.roc",
}

import native/CanvasAppRunner
import breakout/BreakoutApp

Model : CanvasAppRunner.Model(BreakoutApp.Model)

Msg : CanvasAppRunner.Msg

program = CanvasAppRunner.program(BreakoutApp.canvas_app)
