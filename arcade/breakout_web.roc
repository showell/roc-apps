# Breakout, as a page: the wasm module a browser runs.
#
# **WHY THE TWO APP FILES SIT HERE AND NOT IN breakout/.** An app file is where
# Roc's package root is, and a relative import may not climb above it. The
# roc-ray app needs `native/GameRunner`, which touches the platform and so
# cannot live in a package -- a package cannot see one. Both apps therefore sit
# where everything they reach is below them, and the name says which is which.
# Everything that is only about Breakout, its page included, is in breakout/.
app [Model, program] {
	pf: platform "web/platform/main.roc",
	lib: "lib/main.roc",
}

import lib.GameApp
import breakout/BreakoutGame

Model : BreakoutGame.Model

program = GameApp.program(BreakoutGame.game)
