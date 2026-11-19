## This module is roc-ray's Pixel Workshop as a value that canvas_apps can run.
## It is written by hand: the editor is Rules.roc and the drawing is
## WorkshopDraw.roc, so this module holds the size, the rate, the tones and the
## name.
##
## The five tones are upstream's five pitches. Upstream generates one 520 Hz
## tone and plays it back at 0.7 to restore the design and at 0.8 plus 0.18 a
## palette to paint. A tone here is a pitch and a length, so those five pitches
## are these five frequencies.
import lib.CanvasApp
import lib.Input
import Rules
import WorkshopDraw

WorkshopApp :: [].{
	Model : { world : Rules.World, sounds : U32 }

	canvas_app : CanvasApp.CanvasApp(WorkshopApp.Model)
	canvas_app = {
		size: { width: 800.0, height: 600.0 },
		frames_a_second: 60,
		init: { world: Rules.start, sounds: 0 },
		model_at_next_step: |model, input, _dt| step(model, input),
		frame_shapes: |model| WorkshopDraw.frame_shapes(model.world),
		sounds: |model| model.sounds,
		tones: [
			{ hertz: 364, milliseconds: 35 },
			{ hertz: 416, milliseconds: 35 },
			{ hertz: 510, milliseconds: 35 },
			{ hertz: 603, milliseconds: 35 },
			{ hertz: 697, milliseconds: 35 },
		],
		title: "Pixel Workshop",
	}

	step : WorkshopApp.Model, Input.Snapshot -> WorkshopApp.Model
	step = |model, input| {
		next = Rules.step(model.world, input)
		{ world: next.world, sounds: next.sounds }
	}
}
