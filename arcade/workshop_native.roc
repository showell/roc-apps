# Pixel Workshop, as a native program on roc-ray.
#
# The same editor in workshop/, the same lib, and a different runner. roc-ray
# is named as a sibling checkout of roc-apps.
app [Model, program] {
	rr: platform "../../roc-ray/platform/main.roc",
	lib: "lib/main.roc",
}

import native/GameRunner
import workshop/WorkshopGame

Model : GameRunner.Model(WorkshopGame.Model)

Msg : GameRunner.Msg

program = GameRunner.program(WorkshopGame.game)
