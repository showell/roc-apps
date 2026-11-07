## The sun through the ride: it sinks a little with every step, and it's drawn
## only while the rider faces it. Its height is what the rest of the sunset
## follows: the sky, the mountains and the truck's headlights.
import Angle
import Clock
import Fraction
import Lens
import Pixels
import Screen

Sun :: [].{

	## Where the sun stands on the screen, and how large it is drawn beside
	## its size at rest. The lens only ever widens, so that is never larger.
	Place : {
		x : Pixels,
		y : Pixels,
		scale : Fraction,
	}

	## The sun in a frame: in view at its place, or out of view, too far to
	## the side of where the rider faces.
	Sighting : [InView(Sun.Place), OutOfView]

	bearing : Angle.Bearing
	bearing = Angle.Bearing.radians(-2.2176)

	radius_px : Pixels
	radius_px = Pixels.of(46.0)

	start_px : Pixels
	start_px = Pixels.of(244.0)

	drop_px_per_step : Pixels
	drop_px_per_step = radius_px.times(2.0).times(0.41616).divided_by(625.0)

	fully_set_px : Pixels
	fully_set_px = radius_px.opposite()

	visible_turn_limit : Angle.Turn
	visible_turn_limit = Angle.Turn.radians(1.4)

	## How high the sun stands above the horizon at `clock`, in pixels at
	## rest; below it once negative.
	height_px : Clock -> Pixels
	height_px = |clock| start_px.minus(drop_px_per_step.times(clock.to_f64()))

	## The sun in a frame, for a rider facing `heading`.
	sighting : {
		heading : Angle.Bearing,
		clock : Clock,
		cam_focal : Pixels,
	} -> Sun.Sighting
	sighting = |{ heading, clock, cam_focal }| {
		turn_from_view = bearing.turn_from(heading)
		if turn_from_view.abs() >= visible_turn_limit {
			OutOfView
		} else {
			InView(place({ turn_from_view, clock, cam_focal }))
		}
	}
}

place : {
	turn_from_view : Angle.Turn,
	clock : Clock,
	cam_focal : Pixels,
} -> Sun.Place
place = |{ turn_from_view, clock, cam_focal }| {
	scale = Fraction.of(cam_focal.ratio_to(Lens.resting_focal))
	slope = turn_from_view.to_radians().tan()
	{
		x: Screen.center_x.plus(cam_focal.times(slope)),
		y: Screen.horizon_y.minus(Sun.height_px(clock).times(scale.to_f64())),
		scale,
	}
}

expect Sun.height_px(Clock.at_step(0)).to_f64() == 244.0
expect Sun.start_px.to_f64() == 244.0
expect Sun.radius_px.to_f64() == 46.0
expect Sun.fully_set_px.to_f64() == -46.0
expect Sun.visible_turn_limit.to_radians() == 1.4

# The rider faces the sun, then away from it.
expect
	Sun.sighting({
		heading: Angle.Bearing.radians(-2.2176),
		clock: Clock.start,
		cam_focal: Lens.resting_focal,
	})
		== InView({
			x: Pixels.of(480.0),
			y: Pixels.of(56.0),
			scale: Fraction.whole,
		})

# A lens at half its focal length draws the sun at half its size.
expect
	Sun.sighting({
		heading: Angle.Bearing.radians(-2.2176),
		clock: Clock.start,
		cam_focal: Lens.resting_focal.times(0.5),
	})
		== InView({
			x: Pixels.of(480.0),
			y: Pixels.of(178.0),
			scale: Fraction.of(0.5),
		})

expect
	Sun.sighting({
		heading: Angle.north,
		clock: Clock.start,
		cam_focal: Lens.resting_focal,
	})
		== OutOfView
