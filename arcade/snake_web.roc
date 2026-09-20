# Snake, as a page.
#
# **THE FILE NAME IS THE SPLIT.** `snake_web.roc` builds the wasm module a
# browser runs; `snake_native.roc` builds the program roc-ray runs. Both are
# four lines, both name the same game in `snake/`, and the only thing that
# differs is which platform they sit on and which edge they use -- `lib/GameApp`
# here, `native/GameRunner` there.
#
# It lives at the top of arcade/ rather than in snake/ because an app file is
# where Roc's package root is, and a relative import may not climb above it.
# Everything an app reaches -- the game, the library, the platform -- therefore
# sits below this file.
app [Model, program] { pf: platform "web/platform/main.roc" }

import lib/GameApp
import snake/SnakeGame

Model : SnakeGame.Model

program = GameApp.program(SnakeGame.game)
