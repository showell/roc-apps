# Safari, as a page: the wasm module a browser runs.
app [Model, program] { lib: "../lib/main.roc", pf: platform "../web/platform/main.roc" }

import lib.WasmApp
import SafariApp

Model : SafariApp.Model

program = WasmApp.program(SafariApp.canvas_app)
