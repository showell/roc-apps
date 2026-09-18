# Movie -- what a player needs from a movie, and nothing else.
#
# Hand-written. Safari is an animation over a great many steps, and a player --
# ray/apps/safari/main.roc on roc-ray, blitter.js on the page -- has to step it
# and draw what it says. **Everything else about it is Safari's own business**,
# and this is the line: a player that can step a model and draw the shapes and
# camera a frame reports needs to know nothing about a ride, a sky or a sun,
# and could play a movie of a night drive with no change at all.
#
# The player used to ask SafariRide for the sky at the top of the frame, the
# sky at the horizon and where the sun was, and hand all three back to Shapes
# so it could build the backdrop. That is Safari's backdrop; it belongs in the
# frame Safari reports, not in the vocabulary a player speaks.
#
# A second movie would write its own `Movie.roc` beside its own chapters, and
# the player would not change. That is the test of this file.
import SafariRide
import Shapes
import Raster

Movie :: [].{
	Model : SafariRide.Model

	# What one frame is: the shapes to fill, in scene coordinates, and how the
	# camera is turned. Nothing here names anything in this movie.
	Frame : { shapes : List(Shapes.Shape), roll : F64 }

	init : Movie.Model
	init = SafariRide.init

	advance : Movie.Model -> Movie.Model
	advance = |m| SafariRide.advance(m)

	back : Movie.Model -> Movie.Model
	back = |m| SafariRide.back(m)

	# The frame as shapes a platform fills, with the camera that turns them.
	frame : Movie.Model -> Movie.Frame
	frame = |m| {
		shapes: Shapes.frame(SafariRide.commands(m), SafariRide.sky_top(m), SafariRide.sky_horizon(m), SafariRide.sun(m)),
		roll: SafariRide.roll(m),
	}

	# The same frame painted into pixels, for a player that shows one texture
	# rather than filling shapes.
	pixels : Movie.Model -> List(U32)
	pixels = |m| Raster.paint({
		commands: SafariRide.commands(m),
		roll: SafariRide.roll(m),
		sky_top: SafariRide.sky_top(m),
		sky_horizon: SafariRide.sky_horizon(m),
		sun: SafariRide.sun(m),
	})

	# What the movie is called: the window's title, and the stem a screenshot is
	# named from. The last things a player would otherwise be told by hand.
	title : Str
	title = "Safari"

	stem : Str
	stem = "safari"

	# Where the movie has got to, for a player that wants to name a screenshot.
	# A number that goes up; what it counts is the movie's business.
	clock : Movie.Model -> F64
	clock = |m| m.ride.clock

	# On to the next scene. Safari's scenes are the route's segments, and a
	# player asking for the next one should not have to know that -- nor that
	# reaching it means stepping until the segment changes.
	skip : Movie.Model -> Movie.Model
	skip = |m| {
		from = m.ride.rider.segment
		var $m = SafariRide.advance(m)
		var $guard = 0
		while $m.ride.rider.segment == from and $guard < step_guard {
			$m = SafariRide.advance($m)
			$guard = $guard + 1
		}
		$m
	}

	# A scene is long, but not unbounded: the page bounds the same jump.
	step_guard : I64
	step_guard = 200000
}
