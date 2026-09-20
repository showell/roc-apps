# The Halloween movie, as a page: the wasm module a browser runs.
#
# The companion of halloween_native.roc. See snake_web.roc for why the two app
# files sit here rather than in halloween/.
app [Model, program] {
	pf: platform "web/platform/main.roc",
	lib: "lib/main.roc",
}

import lib.GameApp
import halloween/HalloweenGame

Model : HalloweenGame.Model

program = GameApp.program(HalloweenGame.game)
