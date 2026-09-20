# Snake, as a native program on roc-ray.
#
# The companion of snake_web.roc: the same game in snake/, the same lib, and a
# different runner. roc-ray is named as a sibling checkout of roc-apps.
app [Model, program] {
	rr: platform "../../roc-ray/platform/main.roc",
	lib: "lib/main.roc",
}

import native/GameRunner
import snake/SnakeGame

Model : GameRunner.Model(SnakeGame.Model)

Msg : GameRunner.Msg

program = GameRunner.program(SnakeGame.game)
