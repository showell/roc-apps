## The sun as the rider sees it: where `SunPath` puts it in the sky lands on
## the screen, and it's drawn only while the rider faces it. It knows its own
## look too, a glow and a disc over it.
import Angle
import Clock
import FarHeight
import Lens
import Pixels
import Screen
import SunPath
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

	## The sun in a frame: in view at its place, or out of view, too far to
	## the side of where the rider faces.
	Sighting : [InView(Sun.OnScreen), OutOfView]

	## The sun's paint where it stands: a wide glow, and over it a disc.
	Look : { glow : Brush.Fill, disc : Brush.Fill }

	## The sun in a frame, for a camera facing `heading` through a lens of
	## `focal_length`. It is in view while it is in front of the camera and its glow
	## reaches the screen.
	sun_in_view : { heading : Angle.Bearing, focal_length : Pixels, .. }, Clock -> Sun.Sighting
	sun_in_view = |camera, clock| {
		direction = SunPath.sun_direction_at(clock)
		far_point = Lens.far_point({
			turn: direction.bearing.turn_from(camera.heading),
			height: direction.height,
			focal_length: camera.focal_length,
		})
		match far_point {
			Ok(point) => {
				sun = {
					x: point.x,
					y: point.y,
					focal_length: camera.focal_length,
				}
				if is_glow_on_screen(sun) {
					InView(sun)
				} else {
					OutOfView
				}
			}
			Err(BehindCamera) => OutOfView
		}
	}

	## How far the glow reaches from the sun's middle where it stands.
	glow_radius_on_screen : Sun.OnScreen -> Pixels
	glow_radius_on_screen = |sun| sun_size_on_screen(glow_radius, sun)

	## The disc's radius where the sun stands.
	disc_radius_on_screen : Sun.OnScreen -> Pixels
	disc_radius_on_screen = |sun| sun_size_on_screen(SunPath.radius, sun)

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
				inner_color: Brush.opaque_rgba(RgbColor.of(0xFFE6A3)),
				outer_color: Brush.opaque_rgba(RgbColor.of(0xFF9D5C)),
				center: { x: sun.x.to_f64(), y: sun.y.to_f64() },
				inner_radius: sun_size_on_screen(disc_inner_radius, sun).to_f64(),
				outer_radius: Sun.disc_radius_on_screen(sun).to_f64(),
			}),
		}
}

## How long `size`, one of the sun's sizes, is drawn where `sun` stands.
sun_size_on_screen : FarHeight, Sun.OnScreen -> Pixels
sun_size_on_screen = |size, sun| Lens.size_on_screen({ size, focal_length: sun.focal_length })

## Whether any of the glow around `sun` reaches across the screen, as far out
## as the frame is drawn, from `Screen.drawn_left` to `Screen.drawn_right`,
## which every roll of the screen stays inside.
is_glow_on_screen : Sun.OnScreen -> Bool
is_glow_on_screen = |sun| {
	from_middle = sun.x.minus(Screen.center_x).abs()
	reach = Screen.drawn_right.minus(Screen.center_x)
	from_middle.minus(Sun.glow_radius_on_screen(sun)) < reach
}

## How far the glow reaches from the sun's middle.
glow_radius : FarHeight
glow_radius = FarHeight.of(340.0)

## Where the glow's fade starts, near the sun's middle.
glow_inner_radius : FarHeight
glow_inner_radius = FarHeight.of(8.0)

## Where the disc's shading from pale to orange starts.
disc_inner_radius : FarHeight
disc_inner_radius = FarHeight.of(4.0)

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
	facing_sun = {
		heading: SunPath.bearing_at(Clock.start),
		focal_length: Lens.resting_focal_length,
	}
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
	facing_sun = { heading: SunPath.bearing_at(Clock.start), focal_length: half_focal_length }
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
		and Sun.disc_radius_on_screen(half_on_screen).to_f64() == SunPath.radius.times(0.5).to_f64()
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
	heading = SunPath.bearing_at(Clock.start).plus(Angle.Turn.radians(0.0 - radians))
	match Sun.sun_in_view({ heading, focal_length: Lens.resting_focal_length }, Clock.start) {
		InView(_) => True
		OutOfView => False
	}
}

# At rest the glow still reaches the screen's margin with the sun 0.95 radians
# to the side, either side, and has left it at 1.0.
expect [0.95, -0.95].all(is_in_view_beside)
expect [1.0, -1.0, 1.5, -1.5, 3.0].all(|radians| !is_in_view_beside(radians))
