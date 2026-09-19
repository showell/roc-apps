# SafariMovie -- Safari, as a Movie.
#
# Hand-written: the shim between the ride Safari actually is and the movie a
# player wants. SafariRide holds the ride and the history; Shapes says what a
# frame looks like. This is the value that says so.
#
# Raster still paints a frame into pixels, and ShapesFrame still checks the two
# against each other -- but no PLAYER shows pixels any more, so a movie is not
# asked for them.
import Movie
import SafariRide
import Shapes
import SafariShapes

SafariMovie :: [].{
	Model : SafariRide.Model

	movie : Movie.Movie(SafariMovie.Model)
	movie = {
		size: { width: 960.0, height: 600.0 },
		# **THIRTY, BY EYE.** The drive was paced by how long its own frame
		# took -- one step per animation frame, and a frame it could not fit
		# in a sixtieth of a second -- so it ran at about twenty-five in a
		# browser and faster than that on a desktop. Thirty is the speed it
		# is meant to look like, and now it is that speed on both.
		fps: 30,
		init: SafariRide.init,
		advance: |m| SafariRide.advance(m),
		back: |m| SafariRide.back(m),
		skip: |m| skip(m),
		scene: |m| m.ride.rider.segment,
		scenes: 19,
		frame: |m| SafariShapes.frame(SafariRide.commands(m), SafariRide.sky_top(m), SafariRide.sky_horizon(m), SafariRide.sun(m)),
		roll: |m| SafariRide.roll(m),
		clock: |m| m.ride.clock,
		title: "Safari",
		stem: "safari",
	}

	# Safari's scenes are the route's segments, and reaching the next one means
	# stepping until the segment changes. A player asking for the next scene
	# should not have to know either of those.
	skip : SafariMovie.Model -> SafariMovie.Model
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
