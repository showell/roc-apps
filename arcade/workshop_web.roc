# Pixel Workshop, as a page: the wasm module a browser runs.
#
# The companion of workshop_native.roc. See snake_web.roc for why the two app
# files sit here rather than in workshop/.
app [Model, program] {
	pf: platform "web/platform/main.roc",
	lib: "lib/main.roc",
}

import lib.GameApp
import workshop/WorkshopGame

Model : WorkshopGame.Model

program = GameApp.program(WorkshopGame.game)
