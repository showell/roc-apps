## The sun through the ride: it sinks a little with every step, and it's drawn
## only while the rider faces it. Its height is what the rest of the sunset
## follows: the sky, the mountains and the truck's headlights. It knows its own
## look too, a glow and a disc over it.
import Angle
import Clock
import Fraction
import Lens
import Pixels
import Screen
import lib.Brush
import lib.RgbColor

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

	## The sun's paint where it stands: a wide glow, and over it a disc.
	Look : { glow : Brush.Fill, disc : Brush.Fill }

	## The direction the sun stands in, about 127° left of north: the
	## southwest, a little to the left of the west range's middle. The ride
	## starts facing away from it.
	bearing : Angle.Bearing
	bearing = Angle.Bearing.radians(-2.2176)

	## The sun's radius at rest.
	radius : Pixels
	radius = Pixels.of(46.0)

	## How high the sun stands above the horizon as the ride starts.
	height_at_start : Pixels
	height_at_start = Pixels.of(244.0)

	## How high the sun stands once it has fully set: its top on the horizon.
	height_when_set : Pixels
	height_when_set = radius.opposite()

	## The step at which the sun has fully set, its whole disc below the
	## horizon, in a ride of about 7,000 steps. The sun sinks at one steady
	## rate, so this step is what places the sunset in the ride.
	fully_set_at : Clock
	fully_set_at = Clock.at_step(4735)

	## How high the sun stands above the horizon at `clock`, in pixels at
	## rest; below it once negative.
	height : Clock -> Pixels
	height = |clock| height_at_start.minus(drop_per_step.times(clock.to_f64()))

	## The sun in a frame, for a camera aimed as `aim` says. It is in view while
	## it is in front of the camera and its glow reaches the screen.
	sighting : Lens.CameraAim, Clock -> Sun.Sighting
	sighting = |aim, clock| {
		turn_from_view = bearing.turn_from(aim.heading)
		if turn_from_view.abs() >= quarter_turn {
			OutOfView
		} else {
			sun = place({ turn_from_view, clock, cam_focal: aim.cam_focal })
			if is_glow_on_screen(sun) {
				InView(sun)
			} else {
				OutOfView
			}
		}
	}

	## How far the glow reaches from the sun's middle where it stands.
	glow_radius_drawn : Sun.Place -> Pixels
	glow_radius_drawn = |sun| glow_radius.times(sun.scale.to_f64())

	## The disc's radius where the sun stands.
	disc_radius_drawn : Sun.Place -> Pixels
	disc_radius_drawn = |sun| radius.times(sun.scale.to_f64())

	## The sun's glow and disc where it stands, sized by its scale.
	look : Sun.Place -> Sun.Look
	look = |sun| {
		scale = sun.scale.to_f64()
		{
			glow: Brush.glow({
				inner_color: Brush.with_alpha(RgbColor.of(0xFFC980), 0.85),
				middle_color: Brush.with_alpha(RgbColor.of(0xFF965C), 0.32),
				outer_color: Brush.with_alpha(RgbColor.of(0xFF965C), 0.0),
				middle_offset: 0.4,
				center: { x: sun.x.to_f64(), y: sun.y.to_f64() },
				inner_radius: glow_inner_radius.times(scale).to_f64(),
				outer_radius: Sun.glow_radius_drawn(sun).to_f64(),
			}),
			disc: Radial({
				inner_color: Brush.opaque(RgbColor.of(0xFFE6A3)),
				outer_color: Brush.opaque(RgbColor.of(0xFF9D5C)),
				center: { x: sun.x.to_f64(), y: sun.y.to_f64() },
				inner_radius: disc_inner_radius.times(scale).to_f64(),
				outer_radius: Sun.disc_radius_drawn(sun).to_f64(),
			}),
		}
	}
}

## How far the sun sinks with each step, to fall from where it starts to
## where it has fully set by `fully_set_at`.
drop_per_step : Pixels
drop_per_step = Sun.height_at_start.minus(Sun.height_when_set).divided_by(Sun.fully_set_at.to_f64())

## A quarter turn. The camera sees only what is less than this to either side
## of where it faces, in front of it.
quarter_turn : Angle.Turn
quarter_turn = Angle.Turn.radians(F64.pi / 2.0)

## Whether any of the glow around `sun` reaches across the screen, as far out
## as `Screen.roll_margin`, which every roll of the screen stays inside.
is_glow_on_screen : Sun.Place -> Bool
is_glow_on_screen = |sun| {
	from_middle = sun.x.minus(Screen.center_x).abs()
	reach = Screen.width.divided_by(2.0).plus(Screen.roll_margin)
	from_middle.minus(Sun.glow_radius_drawn(sun)) < reach
}

## How far the glow reaches from the sun's middle at rest.
glow_radius : Pixels
glow_radius = Pixels.of(340.0)

## Where the glow's fade starts, near the sun's middle, at rest.
glow_inner_radius : Pixels
glow_inner_radius = Pixels.of(8.0)

## Where the disc's shading from pale to orange starts, at rest.
disc_inner_radius : Pixels
disc_inner_radius = Pixels.of(4.0)

## Where the sun stands at `clock`, `turn_from_view` to the right of where
## the camera faces, through a lens of `cam_focal`.
place : {
	turn_from_view : Angle.Turn,
	clock : Clock,
	cam_focal : Pixels,
} -> Sun.Place
place = |{ turn_from_view, clock, cam_focal }| {
	{
		x: Lens.x_for_turn({ turn: turn_from_view, cam_focal }),
		y: Lens.y_for_height({ height: Sun.height(clock), cam_focal }),
		scale: Lens.scale_for(cam_focal),
	}
}

# The sun's lower edge touches the horizon at step 3,233, and the whole disc
# is below it from `fully_set_at`.
expect Sun.height(Clock.at_step(3232)) > Sun.radius
expect Sun.height(Clock.at_step(3233)) < Sun.radius
expect Sun.height(Sun.fully_set_at.previous()) > Sun.height_when_set
expect Sun.height(Sun.fully_set_at) == Sun.height_when_set

# The rider faces the sun, then away from it.
expect
	Sun.sighting({ heading: Sun.bearing, cam_focal: Lens.resting_focal }, Clock.start)
		== InView({
			x: Pixels.of(480.0),
			y: Pixels.of(56.0),
			scale: Fraction.whole,
		})

# A lens at half its focal length draws the sun at half its size.
expect
	Sun.sighting({ heading: Sun.bearing, cam_focal: Lens.resting_focal.times(0.5) }, Clock.start)
		== InView({
			x: Pixels.of(480.0),
			y: Pixels.of(178.0),
			scale: Fraction.of(0.5),
		})

expect {
	facing_north = { heading: Angle.north, cam_focal: Lens.resting_focal }
	Sun.sighting(facing_north, Clock.start) == OutOfView
}

## Whether the sun is in view at the ride's start, for a camera at rest that
## faces `radians` to the left of it.
is_in_view_beside : F64 -> Bool
is_in_view_beside = |radians| {
	heading = Sun.bearing.plus(Angle.Turn.radians(0.0 - radians))
	match Sun.sighting({ heading, cam_focal: Lens.resting_focal }, Clock.start) {
		InView(_) => True
		OutOfView => False
	}
}

# At rest the glow still reaches the screen's margin with the sun 0.95 radians
# to the side, either side, and has left it at 1.0.
expect [0.95, -0.95].all(is_in_view_beside)
expect [1.0, -1.0, 1.5, -1.5, 3.0].all(|radians| !is_in_view_beside(radians))
