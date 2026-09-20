# WorkshopApp -- roc-ray's Pixel Workshop as a value canvas_apps can run.
#
# Hand-written: the editor is Rules.roc and the drawing is WorkshopDraw.roc,
# so what is left is the size, the rate, the tones and the name.
#
# **THE FIVE TONES ARE UPSTREAM'S FIVE PITCHES.** It generates one 520 Hz tone
# and plays it back at 0.7 to restore the design and at 0.8 plus 0.18 a palette
# to paint; a tone here is a pitch and a length, so those five pitches are
# these five frequencies. Nothing about the seam had to change.
import lib.CanvasApp
import lib.Input
import Rules
import WorkshopDraw

WorkshopApp :: [].{
	Model : { world : Rules.World, sounds : U32 }

	canvas_app : CanvasApp.CanvasApp(WorkshopApp.Model)
	canvas_app = {
		size: { width: 800.0, height: 600.0 },
		fps: 60,
		init: { world: Rules.start, sounds: 0 },
		advance: |m, input, _dt| step(m, input),
		frame: |m| WorkshopDraw.frame(m.world),
		sounds: |m| m.sounds,
		tones: [
			{ freq: 364, ms: 35 },
			{ freq: 416, ms: 35 },
			{ freq: 510, ms: 35 },
			{ freq: 603, ms: 35 },
			{ freq: 697, ms: 35 },
		],
		title: "Pixel Workshop",
	}

	step : WorkshopApp.Model, Input.Snapshot -> WorkshopApp.Model
	step = |m, input| {
		next = Rules.step(m.world, input)
		{ world: next.world, sounds: next.sounds }
	}
}
