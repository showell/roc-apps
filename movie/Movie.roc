# Movie -- what a player needs from a movie, as a type.
#
# Hand-written. A movie is a model you can step and ask for a frame, and a
# frame is shapes and a camera. **Nothing in this file names a subject**: no
# ride, no sky, no sun. A player that has one of these can play it, and a
# second movie is a second value of this type.
#
# It is a RECORD, not a module found by name. main.roc says which movie it is
# playing, out loud, and hands it over; the player is a function of it.
#
# (Roc reads `movie.frame(m)` as a method call, so a player binds the field
# first -- `frame = movie.frame` -- and then calls it. That is the one piece of
# friction in doing it this way, and it is worth it.)
import Shapes

Movie :: [].{
	# One frame: the shapes to fill, in scene coordinates, and how the camera
	# is turned. **A movie that does not roll sends zero.**
	Frame : { shapes : List(Shapes.Shape), roll : F64 }

	Movie(model) : {
		# **HOW BIG A FRAME IS, in its own coordinates.** A player sizes its
		# window and aims its camera from this. Safari's was 960 by 600 and the
		# player simply knew that, until a second movie arrived at 640 by 360
		# and drew itself into a corner.
		size : { width : F64, height : F64 },

		# **HOW OFTEN A FRAME IS MEANT TO HAPPEN.** Every movie's motion is
		# written per tick -- a velocity, a gravity, a walk of eight hundred
		# frames -- so the rate is the movie's, and a player that runs at its
		# own rate plays the movie at the wrong speed. It is here for the same
		# reason `size` is: the browser was accidentally paced by the display's
		# refresh and roc-ray ran at raylib's default of 240, so the same movie
		# played four times faster on the desktop.
		fps : I32,

		# Where it starts, and how it moves.
		init : model,
		advance : model -> model,

		# **A MOVIE THAT CANNOT GO BACK RETURNS THE MODEL UNCHANGED**, and
		# that is a fair answer rather than a failure. Safari can, because a
		# frame of it is thirteen numbers and it keeps two thousand of them;
		# capture_plot can, because a frame is a function of its clock;
		# particles cannot, because a particle's velocity accumulates gravity
		# and there is no summary to keep. Keeping rendered frames instead
		# would cost more than it is worth.
		back : model -> model,
		# On to the next scene. What a scene is, is the movie's business.
		skip : model -> model,

		# What to draw.
		frame : model -> Movie.Frame,

		# How far in it is: a number that goes up, for naming a screenshot.
		clock : model -> F64,

		# What it is called, for a window's title and a file's name.
		title : Str,
		stem : Str,
	}
}
