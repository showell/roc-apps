## CanvasApp is what a runner needs from an app, as a type. An app is a model
## you can step with a keyboard and a pointer and ask for a picture, and the
## picture is a list of shapes. Games, a world you fly around, a paint program
## and a movie you can scrub are all one of these, and nothing in this file
## names any of them.
##
## It is a record, not a module found by name. Each app says which value it is
## out loud and hands it to a runner, and a runner is a function of one.
import Shapes
import Input

CanvasApp :: [].{

	## A sound an app can set off: a pitch in hertz and a length in
	## milliseconds, which is all either runner needs to make it.
	Tone : { hertz : U32, milliseconds : U32 }

	CanvasApp(model) : {
		# How big a frame is, in the game's own coordinates.
		size : { width : F64, height : F64 },

		# How often it is meant to be stepped. The runner paces to this and
		# passes a fixed step, so the rules are deterministic: the same keys
		# at the same ticks play the same game.
		frames_a_second : U32,

		init : model,

		# One step, given what the keyboard looks like now and how long the
		# step covers. The snapshot is a value, so the browser's event loop
		# can make one and a test can write one down. The seconds are always
		# `1 / frames_a_second`: a runner paces to that and passes it, so no game writes
		# its own sixtieth that might disagree with `frames_a_second`.
		model_at_next_step : model, Input.Snapshot, F32 -> model,

		# What to draw.
		frame_shapes : model -> List(Shapes.Shape),

		# Which of `tones` the last step set off, as a bit per tone. A game
		# reports that a sound happened; whether that is a speaker or a widget
		# in the corner of a web page is the runner's business. The runner
		# learns how many tones there are from `tones`, never by guessing.
		sounds : model -> U32,
		tones : List(CanvasApp.Tone),

		title : Str,
	}

	# A `model_at_next_step` for an app that needs no seconds: a runner passes
	# them as ever, and `step` never sees them. A game whose rules count steps
	# uses it, so real time has no way in.
	untimed_model_at_next_step : (model, Input.Snapshot -> model) -> (model, Input.Snapshot, F32 -> model)
	untimed_model_at_next_step = |step| |model, input, _seconds| step(model, input)
}
