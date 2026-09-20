# The Halloween movie, as a native program on roc-ray.
#
# The same movie in halloween/, the same lib, and a different runner. roc-ray
# is named as a sibling checkout of roc-apps.
app [Model, program] {
	rr: platform "../../roc-ray/platform/main.roc",
	lib: "lib/main.roc",
}

import native/GameRunner
import halloween/HalloweenGame

Model : GameRunner.Model(HalloweenGame.Model)

Msg : GameRunner.Msg

program = GameRunner.program(HalloweenGame.game)
