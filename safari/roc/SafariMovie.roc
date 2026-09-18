# SafariMovie -- Safari, as a Movie.
#
# Hand-written: the shim between the ride Safari actually is and the movie a
# player wants. SafariRide holds the ride and the history; Shapes cuts a frame
# into shapes; Raster paints one into pixels. This is the value that says so.
import Movie
import SafariRide
import Shapes
import Raster

SafariMovie :: [].{
	Model : SafariRide.Model

	movie : Movie.Movie(SafariMovie.Model)
	movie = {
		init: SafariRide.init,
		advance: |m| SafariRide.advance(m),
		back: |m| SafariRide.back(m),
		skip: |m| skip(m),
		frame: |m| {
			shapes: Shapes.frame(SafariRide.commands(m), SafariRide.sky_top(m), SafariRide.sky_horizon(m), SafariRide.sun(m)),
			roll: SafariRide.roll(m),
		},
		pixels: |m| Raster.paint({
			commands: SafariRide.commands(m),
			roll: SafariRide.roll(m),
			sky_top: SafariRide.sky_top(m),
			sky_horizon: SafariRide.sky_horizon(m),
			sun: SafariRide.sun(m),
		}),
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
