# ParticlesApp -- the fountain as a value the canvas apps can run.
#
# Upstream's controls: the emitter is wherever the pointer is, and Space widens
# the spray. Until the pointer has moved over the canvas, the emitter travels
# upstream's recording figure instead, so the fountain is moving on arrival.
import lib.CanvasApp
import lib.Input
import Particles

ParticlesApp :: [].{
	Model : Particles.Model

	canvas_app : CanvasApp.CanvasApp(ParticlesApp.Model)
	canvas_app = {
		size: { width: Particles.width, height: Particles.height },
		fps: 60,
		init: Particles.start,
		advance: |m, input, _dt| step(m, input),
		frame: |m| Particles.shapes(m),
		sounds: |_m| 0,
		tones: [],
		title: "Particles",
	}

	step : ParticlesApp.Model, Input.Snapshot -> ParticlesApp.Model
	step = |m, input| {
		pointer = input.mouse.position()
		# A pointer that has never moved reads as the corner, which is
		# upstream's own test for "nobody is steering".
		at =
			if pointer.x == 0 and pointer.y == 0 {
				Particles.emitter(m.tick)
			} else {
				{ x: F32.to_f64(pointer.x), y: F32.to_f64(pointer.y) }
			}
		spread = if input.key_down(KeySpace) { Particles.spread_wide } else { Particles.spread_narrow }
		Particles.advance(m, at, spread)
	}
}
