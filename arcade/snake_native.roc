# Snake, as a native program on roc-ray.
#
# The companion of snake_web.roc: the same game in `snake/`, the same library
# in `lib/`, and a different edge. See that file for why an app sits here
# rather than beside the game.
app [Model, program] { rr: platform "../../roc-ray/platform/main.roc" }

import native/GameRunner
import snake/SnakeGame

Model : GameRunner.Model(SnakeGame.Model)

Msg : GameRunner.Msg

program = GameRunner.program(SnakeGame.game)
