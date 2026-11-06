# Safari, as a page: the wasm module a browser runs. main.roc beside it
# is the same app on roc-ray.
app [Model, program] { lib: "../lib/main.roc", pf: platform "../web/platform/main.roc" }

import lib.WasmApp
import SafariApp

Model : SafariApp.Model

program = WasmApp.program(SafariApp.canvas_app)
