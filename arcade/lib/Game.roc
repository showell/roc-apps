# Game -- what a runner needs from a game, as a type.
#
# Hand-written, and deliberately NOT Movie. A movie is scrubbed: it steps back,
# skips to a scene, reports which scene it is in, and banks its camera. None of
# that means anything to a game, and a movie has no use for a keyboard or a
# speaker. Two small types that each say the truth beat one that carries five
# fields explaining when they do not apply.
#
# What the two share is what a frame IS -- a list of shapes -- and the library
# under that. arcade/ carries its own copy of it, so this directory is a whole
# program and can be lifted out without untangling anything.
import Shapes
import Keys

Game :: [].{
	Game(model) : {
		# How big a frame is, in the game's own coordinates.
		size : { width : F64, height : F64 },

		# How often it is meant to be stepped. The runner paces to this and
		# passes a fixed step, so the rules are deterministic: the same keys
		# at the same ticks play the same game.
		fps : I32,

		init : model,

		# **ONE STEP, GIVEN WHAT THE KEYBOARD LOOKS LIKE NOW.** The snapshot
		# is a value, so the browser's event loop can make one and a test can
		# write one down.
		advance : model, Keys.Snapshot -> model,

		# What to draw.
		frame : model -> List(Shapes.Shape),

		# Which of `tones` the last step set off, as a bit per tone. A game
		# reports that a sound HAPPENED; whether that is a speaker or a widget
		# in the corner of a web page is the runner's business.
		sounds : model -> U32,
		tones : List({ freq : I32, ms : I32 }),

		title : Str,
		stem : Str,
	}
}
