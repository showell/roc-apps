## The sun through the ride: the sky turns about its pole as the earth does,
## carrying the sun down an arc into the southwest, and it's drawn only while
## the rider faces it. Its height is what the rest of the sunset follows: the
## sky, the mountains and the truck's headlights. It knows its own look too, a
## glow and a disc over it.
import Angle
import Clock
import FarHeight
import Lens
import Pixels
import Screen
import Steps
import lib.Brush
import lib.RgbColor
import lib.Shapes

Sun :: [].{

	## Where the sun stands on the screen, and the focal length of the lens it
	## is seen through, which sizes its glow and disc.
	OnScreen : {
		x : Pixels,
		y : Pixels,
		focal_length : Pixels,
	}

	## The direction the sun stands in: its bearing, and its height above the
	## horizon, a far height, which is how the resting lens holds an elevation.
	Direction : { bearing : Angle.Bearing, height : FarHeight }

	## The sun in a frame: in view at its place, or out of view, too far to
	## the side of where the rider faces.
	Sighting : [InView(Sun.OnScreen), OutOfView]

	## The sun's paint where it stands: a wide glow, and over it a disc.
	Look : { glow : Brush.Fill, disc : Brush.Fill }

	## The sun's direction at `clock`, from where the turning sky has carried
	## it. In the frame of the sky's pole the sun stands `declination` from the
	## sky's equator and `hour_angle_at(clock)` west of the meridian; the pole
	## stands `latitude` above the north horizon. Turning that into the
	## rider's frame is the one piece of spherical trig: the sun's direction
	## as a unit vector, up, north and east.
	direction_at : Clock -> Sun.Direction
	direction_at = |clock| {
		pole = latitude.to_radians()
		from_equator = declination.to_radians()
		hour = hour_angle_at(clock).to_radians()
		up = pole.sin() * from_equator.sin() + pole.cos() * from_equator.cos() * hour.cos()
		north = pole.cos() * from_equator.sin() - pole.sin() * from_equator.cos() * hour.cos()
		east = 0.0 - from_equator.cos() * hour.sin()
		level = (north * north + east * east).sqrt()
		elevation = Angle.Turn.radians(F64.atan2({ x: level, y: up }))
		{
			bearing: Angle.Bearing.radians(F64.atan2({ x: north, y: east })),
			height: Lens.height_at_elevation(elevation),
		}
	}

	## The sun's bearing at `clock`. It starts a little west of south and
	## swings west as it sinks.
	bearing_at : Clock -> Angle.Bearing
	bearing_at = |clock| direction_at(clock).bearing

	## How high the sun stands above the horizon at `clock`; below it once
	## negative.
	height_at : Clock -> FarHeight
	height_at = |clock| direction_at(clock).height

	## The sun's radius as a far height: how far its top stands above its
	## middle, and its bottom below.
	radius_as_height : FarHeight
	radius_as_height = FarHeight.of(radius.to_f64())

	## How high the sun stands above the horizon as the ride starts.
	height_at_start : FarHeight
	height_at_start = height_at(Clock.start)

	## How high the sun stands once it has fully set: its top on the horizon.
	height_when_set : FarHeight
	height_when_set = radius_as_height.opposite()

	## The first step at which the sun has fully set, its whole disc below the
	## horizon. The sky's turning places it; `sunset_climax` in
	## gates/expects/RideExpects.roc holds where the sunset falls in the ride.
	fully_set_at : Clock
	fully_set_at = {
		var $clock = Clock.start
		while height_at($clock) > height_when_set {
			$clock = $clock.next()
		}
		$clock
	}

	## The sun in a frame, for a camera facing `heading` through a lens of
	## `focal_length`. It is in view while it is in front of the camera and its glow
	## reaches the screen.
	sun_in_view : { heading : Angle.Bearing, focal_length : Pixels, .. }, Clock -> Sun.Sighting
	sun_in_view = |camera, clock| {
		direction = direction_at(clock)
		turn_from_view = direction.bearing.turn_from(camera.heading)
		if turn_from_view.abs() >= quarter_turn {
			OutOfView
		} else {
			sun = sun_on_screen({
				turn_from_view,
				height: direction.height,
				focal_length: camera.focal_length,
			})
			if is_glow_on_screen(sun) {
				InView(sun)
			} else {
				OutOfView
			}
		}
	}

	## How far the glow reaches from the sun's middle where it stands.
	glow_radius_on_screen : Sun.OnScreen -> Pixels
	glow_radius_on_screen = |sun| sun_size_on_screen(glow_radius, sun)

	## The disc's radius where the sun stands.
	disc_radius_on_screen : Sun.OnScreen -> Pixels
	disc_radius_on_screen = |sun| sun_size_on_screen(radius, sun)

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
						radius: Sun.disc_radius_on_screen(sun).to_f64(),
						fill: look.disc,
					}),
				]
			}
			OutOfView => []
		}

	## The sun's glow and disc where it stands, sized by its lens.
	look : Sun.OnScreen -> Sun.Look
	look = |sun|
		{
			glow: Brush.glow({
				inner_color: Brush.with_alpha(RgbColor.of(0xFFC980), 0.85),
				middle_color: Brush.with_alpha(RgbColor.of(0xFF965C), 0.32),
				outer_color: Brush.with_alpha(RgbColor.of(0xFF965C), 0.0),
				middle_offset: 0.4,
				center: { x: sun.x.to_f64(), y: sun.y.to_f64() },
				inner_radius: sun_size_on_screen(glow_inner_radius, sun).to_f64(),
				outer_radius: Sun.glow_radius_on_screen(sun).to_f64(),
			}),
			disc: Radial({
				inner_color: Brush.opaque(RgbColor.of(0xFFE6A3)),
				outer_color: Brush.opaque(RgbColor.of(0xFF9D5C)),
				center: { x: sun.x.to_f64(), y: sun.y.to_f64() },
				inner_radius: sun_size_on_screen(disc_inner_radius, sun).to_f64(),
				outer_radius: Sun.disc_radius_on_screen(sun).to_f64(),
			}),
		}
}

## How long `size_at_rest`, one of the sun's sizes as the lens at rest draws
## it, is drawn where `sun` stands.
sun_size_on_screen : Pixels, Sun.OnScreen -> Pixels
sun_size_on_screen = |size_at_rest, sun|
	Lens.size_on_screen({
		size: FarHeight.of(size_at_rest.to_f64()),
		focal_length: sun.focal_length,
	})

## How far the sky's pole stands above the north horizon, which is the
## latitude the ride is at: 45°, halfway from the equator to the pole. The
## further from the equator, the more slantwise the sun goes down.
latitude : Angle.Turn
latitude = Angle.Turn.degrees(45.0)

## How far the sun stands south of the sky's equator: as far as it goes, at
## the winter solstice. It makes the year's shortest day, with the sun low at
## noon and setting in the southwest.
declination : Angle.Turn
declination = Angle.Turn.degrees(-23.44)

## How many steps the sky takes to turn an hour, a 24th of a whole turn. The
## ride of about 7,000 steps lasts most of an afternoon and evening.
steps_an_hour : Steps
steps_an_hour = Steps.of(1000)

## How far past noon the ride starts: 10°, forty minutes at the sky's 15° an
## hour.
hour_angle_at_start : Angle.Turn
hour_angle_at_start = Angle.Turn.degrees(10.0)

## How far west of the meridian the sky has turned the sun at `clock`. It
## turns at one steady rate, so the sun climbs and sinks fastest near the
## horizon and lingers near noon.
hour_angle_at : Clock -> Angle.Turn
hour_angle_at = |clock| {
	hours_in = clock.steps_since(Clock.start).to_f64() / steps_an_hour.to_f64()
	hour_angle_at_start.plus(Angle.Turn.degrees(15.0).times(hours_in))
}

## A quarter turn. The camera sees only what is less than this to either side
## of where it faces, in front of it.
quarter_turn : Angle.Turn
quarter_turn = Angle.Turn.radians(F64.pi / 2.0)

## Whether any of the glow around `sun` reaches across the screen, as far out
## as the frame is drawn, from `Screen.drawn_left` to `Screen.drawn_right`,
## which every roll of the screen stays inside.
is_glow_on_screen : Sun.OnScreen -> Bool
is_glow_on_screen = |sun| {
	from_middle = sun.x.minus(Screen.center_x).abs()
	reach = Screen.drawn_right.minus(Screen.center_x)
	from_middle.minus(Sun.glow_radius_on_screen(sun)) < reach
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

## Where the sun stands on the screen, `turn_from_view` to the right of where
## the camera faces and `height` above the horizon, through a lens of
## `focal_length`.
sun_on_screen : {
	turn_from_view : Angle.Turn,
	height : FarHeight,
	focal_length : Pixels,
} -> Sun.OnScreen
sun_on_screen = |{ turn_from_view, height, focal_length }| {
	on_screen = Lens.far_point({ turn: turn_from_view, height, focal_length })
	{ x: on_screen.x, y: on_screen.y, focal_length }
}

# Part of the disc is still above the horizon a step before `fully_set_at`,
# which gates/expects/RideExpects.roc holds, and none of it from then on.
expect Sun.height_at(Sun.fully_set_at) <= Sun.height_when_set

# At noon the sun stands due south, as high as it climbs: 90° less the
# latitude, less the declination south of the equator, so 21.56°. The ride
# starts forty minutes later, a little lower and west of south.
expect {
	noon = Lens.height_at_elevation(Angle.Turn.degrees(21.56))
	a_little_lower = Lens.height_at_elevation(Angle.Turn.degrees(20.5))
	start = Sun.direction_at(Clock.start)
	west_of_south = start.bearing.turn_from(Angle.Bearing.radians(F64.pi))
	start.height < noon and start.height > a_little_lower and west_of_south > Angle.straight_ahead
}

# The sun swings west as it sinks, and sinks faster the lower it is: the
# second hour of the ride takes it further down than the first.
expect {
	at_hour = |hour| Sun.direction_at(Clock.at_step(hour * 1000))
	first_drop = at_hour(0).height.minus(at_hour(1).height)
	second_drop = at_hour(1).height.minus(at_hour(2).height)
	at_hour(2).bearing.turn_from(at_hour(1).bearing) > Angle.straight_ahead
		and second_drop > first_drop
}

## Whether `sun_sighting` is in view at `x` across the screen and within a
## thousandth of a pixel of `y` up it, as `focal_length` draws it.
is_in_view_at : Sun.Sighting,
{
	x : F64,
	y : F64,
	focal_length : Pixels,
} -> Bool
is_in_view_at = |sun_sighting, { x, y, focal_length }|
	match sun_sighting {
		InView(sun) => {
			is_near_y = sun.y.minus(Pixels.of(y)).abs() < Pixels.of(0.001)
			sun.x == Pixels.of(x) and is_near_y and sun.focal_length == focal_length
		}
		OutOfView => False
	}

# The rider faces the sun at the start, 262.5 pixels above the horizon through
# the lens at rest.
expect {
	facing_sun = { heading: Sun.bearing_at(Clock.start), focal_length: Lens.resting_focal_length }
	is_in_view_at(
		Sun.sun_in_view(facing_sun, Clock.start),
		{
			x: 480.0,
			y: 37.487,
			focal_length: Lens.resting_focal_length,
		},
	)
}

# A lens at half its focal length draws the sun nearer the horizon, and at
# half its size.
expect {
	half_focal_length = Lens.resting_focal_length.times(0.5)
	facing_sun = { heading: Sun.bearing_at(Clock.start), focal_length: half_focal_length }
	sighting = Sun.sun_in_view(facing_sun, Clock.start)
	half_on_screen = {
		x: Pixels.of(480.0),
		y: Pixels.of(168.744),
		focal_length: half_focal_length,
	}
	is_in_view_at(
		sighting,
		{
			x: 480.0,
			y: 168.744,
			focal_length: half_focal_length,
		},
	)
		and Sun.disc_radius_on_screen(half_on_screen) == radius.times(0.5)
}

# Facing north at the start, the rider faces away from the sun.
expect {
	facing_north = { heading: Angle.north, focal_length: Lens.resting_focal_length }
	Sun.sun_in_view(facing_north, Clock.start) == OutOfView
}

## Whether the sun is in view at the ride's start, for a camera at rest that
## faces `radians` to the left of it.
is_in_view_beside : F64 -> Bool
is_in_view_beside = |radians| {
	heading = Sun.bearing_at(Clock.start).plus(Angle.Turn.radians(0.0 - radians))
	match Sun.sun_in_view({ heading, focal_length: Lens.resting_focal_length }, Clock.start) {
		InView(_) => True
		OutOfView => False
	}
}

# At rest the glow still reaches the screen's margin with the sun 0.95 radians
# to the side, either side, and has left it at 1.0.
expect [0.95, -0.95].all(is_in_view_beside)
expect [1.0, -1.0, 1.5, -1.5, 3.0].all(|radians| !is_in_view_beside(radians))
