## The sun through the ride: it sinks a little with every step, and it's drawn
## only while the rider faces it. Its height is what the rest of the sunset
## follows: the sky, the mountains and the truck's headlights. It knows its own
## look too, a glow and a disc over it.
import Angle
import Camera
import Clock
import FarHeight
import Lens
import Pixels
import Screen
import lib.Brush
import lib.RgbColor
import lib.Shapes

Sun :: [].{

	## Where the sun stands on the screen, and the focal length of the lens it
	## is seen through, which sizes its glow and disc.
	Place : {
		x : Pixels,
		y : Pixels,
		cam_focal : Pixels,
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

	## The sun's radius as a far height: how far its top stands above its
	## middle, and its bottom below.
	radius_as_height : FarHeight
	radius_as_height = FarHeight.of(radius.to_f64())

	## How high the sun stands above the horizon as the ride starts.
	height_at_start : FarHeight
	height_at_start = FarHeight.of(244.0)

	## How high the sun stands once it has fully set: its top on the horizon.
	height_when_set : FarHeight
	height_when_set = radius_as_height.opposite()

	## The step at which the sun has fully set, its whole disc below the
	## horizon, in a ride of about 7,000 steps. The sun sinks at one steady
	## rate, so this step places the sunset in the ride. It is chosen so the
	## sunset's climax falls on the long road west, which `sunset_climax` in
	## CrossModuleExpects holds.
	fully_set_at : Clock
	fully_set_at = Clock.at_step(4735)

	## How high the sun stands above the horizon at `clock`; below it once
	## negative.
	height_at : Clock -> FarHeight
	height_at = |clock| height_at_start.minus(drop_per_step.times(clock.to_f64()))

	## The sun in a frame, for a camera facing `heading` through a lens of
	## `cam_focal`. It is in view while it is in front of the camera and its glow
	## reaches the screen.
	sighting : { heading : Angle.Bearing, cam_focal : Pixels, .. }, Clock -> Sun.Sighting
	sighting = |camera, clock| {
		turn_from_view = bearing.turn_from(camera.heading)
		if turn_from_view.abs() >= quarter_turn {
			OutOfView
		} else {
			sun = place({ turn_from_view, clock, cam_focal: camera.cam_focal })
			if is_glow_on_screen(sun) {
				InView(sun)
			} else {
				OutOfView
			}
		}
	}

	## How far the glow reaches from the sun's middle where it stands.
	glow_radius_drawn : Sun.Place -> Pixels
	glow_radius_drawn = |sun| size_drawn(glow_radius, sun)

	## The disc's radius where the sun stands.
	disc_radius_drawn : Sun.Place -> Pixels
	disc_radius_drawn = |sun| size_drawn(radius, sun)

	## The sun's shapes in a frame: while it is in view, its glow over the
	## rectangle above the horizon and its disc over that, and nothing while it
	## isn't.
	sun_shapes : Sun.Sighting -> List(Shapes.Shape)
	sun_shapes = |sun_sighting|
		match sun_sighting {
			InView(sun) => {
				look = Sun.look(sun)
				[
					Screen.above_horizon_rect(look.glow),
					Disc({
						x: sun.x.to_f64(),
						y: sun.y.to_f64(),
						radius: Sun.disc_radius_drawn(sun).to_f64(),
						fill: look.disc,
					}),
				]
			}
			OutOfView => []
		}

	## The sun's glow and disc where it stands, sized by its lens.
	look : Sun.Place -> Sun.Look
	look = |sun|
		{
			glow: Brush.glow({
				inner_color: Brush.with_alpha(RgbColor.of(0xFFC980), 0.85),
				middle_color: Brush.with_alpha(RgbColor.of(0xFF965C), 0.32),
				outer_color: Brush.with_alpha(RgbColor.of(0xFF965C), 0.0),
				middle_offset: 0.4,
				center: { x: sun.x.to_f64(), y: sun.y.to_f64() },
				inner_radius: size_drawn(glow_inner_radius, sun).to_f64(),
				outer_radius: Sun.glow_radius_drawn(sun).to_f64(),
			}),
			disc: Radial({
				inner_color: Brush.opaque(RgbColor.of(0xFFE6A3)),
				outer_color: Brush.opaque(RgbColor.of(0xFF9D5C)),
				center: { x: sun.x.to_f64(), y: sun.y.to_f64() },
				inner_radius: size_drawn(disc_inner_radius, sun).to_f64(),
				outer_radius: Sun.disc_radius_drawn(sun).to_f64(),
			}),
		}
}

## How long `size_at_rest`, one of the sun's sizes as the lens at rest draws
## it, is drawn where `sun` stands.
size_drawn : Pixels, Sun.Place -> Pixels
size_drawn = |size_at_rest, sun|
	Lens.size_on_screen({ size: FarHeight.of(size_at_rest.to_f64()), cam_focal: sun.cam_focal })

## How far the sun sinks with each step, to fall from where it starts to
## where it has fully set by `fully_set_at`.
drop_per_step : FarHeight
drop_per_step = Sun.height_at_start.minus(Sun.height_when_set).divided_by(Sun.fully_set_at.to_f64())

## A quarter turn. The camera sees only what is less than this to either side
## of where it faces, in front of it.
quarter_turn : Angle.Turn
quarter_turn = Angle.Turn.radians(F64.pi / 2.0)

## Whether any of the glow around `sun` reaches across the screen, as far out
## as the frame is drawn, from `Screen.drawn_left` to `Screen.drawn_right`,
## which every roll of the screen stays inside.
is_glow_on_screen : Sun.Place -> Bool
is_glow_on_screen = |sun| {
	from_middle = sun.x.minus(Screen.center_x).abs()
	reach = Screen.drawn_right.minus(Screen.center_x)
	from_middle.minus(Sun.glow_radius_drawn(sun)) < reach
}

## The sun's radius at rest.
radius : Pixels
radius = Pixels.of(46.0)

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
		x: Camera.x_for_turn({ turn: turn_from_view, cam_focal }),
		y: Lens.y_for_height({ height: Sun.height_at(clock), cam_focal }),
		cam_focal,
	}
}

# The whole disc is below the horizon from `fully_set_at`, and not a step
# before, which CrossModuleExpects holds.
expect Sun.height_at(Sun.fully_set_at) == Sun.height_when_set

# The rider faces the sun, then away from it.
expect
	Sun.sighting({ heading: Sun.bearing, cam_focal: Lens.resting_focal }, Clock.start)
		== InView({
			x: Pixels.of(480.0),
			y: Pixels.of(56.0),
			cam_focal: Lens.resting_focal,
		})

# A lens at half its focal length draws the sun nearer the horizon, and at
# half its size.
expect {
	half_focal = Lens.resting_focal.times(0.5)
	sighting = Sun.sighting({ heading: Sun.bearing, cam_focal: half_focal }, Clock.start)
	half_place = {
		x: Pixels.of(480.0),
		y: Pixels.of(178.0),
		cam_focal: half_focal,
	}
	sighting == InView(half_place) and Sun.disc_radius_drawn(half_place) == radius.times(0.5)
}

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
