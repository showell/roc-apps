# CanvasApp -- what a runner needs from an app, as a type.
#
# Hand-written. An app is a model you can step with a keyboard and a pointer
# and ask for a picture, and the picture is a list of shapes. Games, a world
# you fly around, a paint program and a movie you can scrub are all one of
# these; nothing in this file names any of them.
#
# It is a RECORD, not a module found by name. Each app says which value it is
# out loud and hands it to a runner, and a runner is a function of one.
import Shapes
import Input

CanvasApp :: [].{
	CanvasApp(model) : {
		# How big a frame is, in the game's own coordinates.
		size : { width : F64, height : F64 },

		# How often it is meant to be stepped. The runner paces to this and
		# passes a fixed step, so the rules are deterministic: the same keys
		# at the same ticks play the same game.
		fps : I32,

		init : model,

		# **ONE STEP, GIVEN WHAT THE KEYBOARD LOOKS LIKE NOW AND HOW LONG THE
		# STEP COVERS.** The snapshot is a value, so the browser's event loop
		# can make one and a test can write one down. The seconds are always
		# `1 / fps`: a runner paces to that and passes it, rather than each
		# game writing the same sixtieth twice and hoping it matches `fps`.
		advance : model, Input.Snapshot, F32 -> model,

		# What to draw.
		frame : model -> List(Shapes.Shape),

		# Which of `tones` the last step set off, as a bit per tone. A game
		# reports that a sound HAPPENED; whether that is a speaker or a widget
		# in the corner of a web page is the runner's business.
		#
		# **THE WIDTH IS PART OF THE CONTRACT.** A runner that guesses how many
		# tones there are gets it wrong on the first game with more: the page
		# assumed three, Breakout has five, and breaking a brick lit a speaker
		# with no sound coming out of it.
		sounds : model -> U32,
		tones : List({ freq : I32, ms : I32 }),

		title : Str,
	}
}
