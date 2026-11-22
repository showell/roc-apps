# Thanksgiving, as a page: the wasm module a browser runs.
app [Model, program] { lib: "../lib/main.roc", pf: platform "../web/platform/main.roc" }

import lib.WasmApp
import ThanksgivingApp

Model : ThanksgivingApp.Model

program = WasmApp.program(ThanksgivingApp.canvas_app)
