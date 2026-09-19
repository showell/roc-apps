# snake on the arcade wasm platform.
#
# Hand-written, and nothing but the name: GameApp.program is the wasm edge for
# any game.
app [Model, program] { pf: platform "../wasm/platform/main.roc" }

import GameApp
import SnakeGame

Model : SnakeGame.Model

program = GameApp.program(SnakeGame.game)
