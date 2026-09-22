# Fast Track, as a page: the wasm module a browser runs.
app [Model, program] {
	pf: platform "web/platform/main.roc",
}

import FastTrack
import RulesTests

Model : FastTrack.Model

program = FastTrack.program
