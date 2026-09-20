# The Halloween movie, as a native program on roc-ray.
#
# The same movie in trick_or_treat/, the same lib, and a different runner. roc-ray
# is named as a sibling checkout of roc-apps.
app [Model, program] {
	rr: platform "../../roc-ray/platform/main.roc",
	lib: "lib/main.roc",
}

import native/CanvasAppRunner
import trick_or_treat/TrickOrTreatApp

Model : CanvasAppRunner.Model(TrickOrTreatApp.Model)

Msg : CanvasAppRunner.Msg

program = CanvasAppRunner.program(TrickOrTreatApp.canvas_app)
