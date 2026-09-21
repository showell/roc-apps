# Particles, as a native program on roc-ray.
app [Model, program] {
	rr: platform "../../roc-ray/platform/main.roc",
	lib: "lib/main.roc",
}

import native/CanvasAppRunner
import particles/ParticlesApp

Model : CanvasAppRunner.Model(ParticlesApp.Model)

Msg : CanvasAppRunner.Msg

program = CanvasAppRunner.program(ParticlesApp.canvas_app)
