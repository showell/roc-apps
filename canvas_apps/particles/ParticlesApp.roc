## ParticlesApp is the particle fountain as a value the canvas apps can run.
##
## It keeps upstream's controls: the emitter is wherever the pointer is, and
## Space widens the spray. Until the pointer has moved over the canvas, the
## emitter travels upstream's recording figure instead, so the fountain is
## already moving when the page opens.
import lib.CanvasApp
import lib.Input
import Particles

ParticlesApp :: [].{
	Model : Particles.Model

	canvas_app : CanvasApp.CanvasApp(ParticlesApp.Model)
	canvas_app = {
		size: { width: Particles.width, height: Particles.height },
		frames_a_second: 60,
		init: Particles.start,
		model_at_next_step: |model, input, _dt| step(model, input),
		frame_shapes: |model| Particles.shapes(model),
		sounds: |_model| 0,
		tones: [],
		title: "Particles",
	}

	step : ParticlesApp.Model, Input.Snapshot -> ParticlesApp.Model
	step = |model, input| {
		pointer = input.mouse.position()
		# A pointer that has never moved reads as the corner, which is
		# upstream's own test for "nobody is steering".
		at =
			if pointer.x == 0 and pointer.y == 0 {
				Particles.emitter(model.tick)
			} else {
				{ x: F32.to_f64(pointer.x), y: F32.to_f64(pointer.y) }
			}
		spread = if input.key_down(KeySpace) {
			Particles.spread_wide
		} else {
			Particles.spread_narrow
		}
		Particles.advance(model, at, spread)
	}
}
