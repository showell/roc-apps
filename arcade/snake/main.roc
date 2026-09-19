# roc-ray's examples/snake, on roc-ray again -- but through the arcade's own
# runner, so the rules, the board and the drawing are the same files the page
# runs.
app [Model, program] { rr: platform "roc-ray/platform/main.roc" }

import GameRunner
import SnakeGame

Model : GameRunner.Model(SnakeGame.Model)

Msg : GameRunner.Msg

program = GameRunner.program(SnakeGame.game)
