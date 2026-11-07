## Backdrop builds what is behind the ride, as shapes. The vocabulary is in
## lib/Shapes.roc, which every canvas app shares. This module puts together the
## sky's gradient from Sky's two colors, the sun as Sun says it looks, and the
## grass, and lays the frame's shapes over them.
import Clock
import Fraction
import Lens
import lib.Brush
import lib.RgbColor
import Screen
import Sky
import Sun
import lib.Shapes

Backdrop :: [].{

	## The grass, from just above the horizon down.
	grass_color : RgbColor
	grass_color = RgbColor.of(0x4A8F43)

	## How far down to the horizon the sky holds its top colour before it
	## fades to the horizon's.
	sky_top_stop : Fraction
	sky_top_stop = Fraction.of(0.2)

	## What is behind the ride, each part by name.
	BackdropShapes : {
		## The sky's gradient.
		sky : Shapes.Shape,

		## The sun's glow and disc while it is in view, and nothing while it isn't.
		sun_shapes : List(Shapes.Shape),

		## The grass, which covers whatever of the sun has set.
		grass : Shapes.Shape,
	}

	## The backdrop under `sky_colors`, with the sun where `sun_sighting` says.
	backdrop_shapes : {
		sky_colors : Sky.Colors,
		sun_sighting : Sun.Sighting,
	} -> Backdrop.BackdropShapes
	backdrop_shapes = |{ sky_colors, sun_sighting }| {
		sky = Linear({
			stops: {
				start_color: Brush.opaque(sky_colors.top),
				end_color: Brush.opaque(sky_colors.horizon),
				start_offset: sky_top_stop.to_f64(),
				end_offset: 1.0,
			},
			start_point: { x: 0.0, y: 0.0 },
			end_point: { x: 0.0, y: Screen.horizon_y.to_f64() },
		})
		sun_shapes =
			match sun_sighting {
				InView(place) => {
					look = Sun.look(place)
					[
						sky_rect(look.glow),
						Disc({
							x: place.x.to_f64(),
							y: place.y.to_f64(),
							radius: Sun.disc_radius_drawn(place).to_f64(),
							fill: look.disc,
						}),
					]
				}
				OutOfView => []
			}
		# From a pixel above the horizon down past the screen's foot, as wide
		# as the sky.
		margin = Screen.roll_margin
		grass = Rect({
			x: margin.opposite().to_f64(),
			y: Screen.grass_top_y.to_f64(),
			width: Screen.width.plus(margin).plus(margin).to_f64(),
			height: Screen.height.minus(Screen.grass_top_y).plus(margin).to_f64(),
			fill: Flat(Brush.opaque(grass_color)),
		})
		{ sky: sky_rect(sky), sun_shapes, grass }
	}

	## The frame in paint order: the sky, the sun, the grass, then the ride's
	## shapes. The grass covers whatever of the sun has set.
	frame_shapes : List(Shapes.Shape),
	{
		sky_colors : Sky.Colors,
		sun_sighting : Sun.Sighting,
	} -> List(Shapes.Shape)
	frame_shapes = |ride_shapes, backdrop| {
		parts = Backdrop.backdrop_shapes(backdrop)
		[[parts.sky], parts.sun_shapes, [parts.grass], ride_shapes].join()
	}
}

## The sky's rectangle, from `Screen.roll_margin` above the screen down to the
## horizon, painted with `fill`. The margin keeps a rolled frame's corners
## filled, and the sun's glow takes the same rectangle.
sky_rect : Brush.Fill -> Shapes.Shape
sky_rect = |fill| {
	margin = Screen.roll_margin
	Rect({
		x: margin.opposite().to_f64(),
		y: margin.opposite().to_f64(),
		width: Screen.width.plus(margin).plus(margin).to_f64(),
		height: Screen.horizon_y.plus(margin).to_f64(),
		fill,
	})
}

# The sky comes first and the grass after the sun, so the grass covers what of
# the sun has set.
expect {
	sky_colors = Sky.colors_at(Clock.start)
	facing_sun = { heading: Sun.bearing, cam_focal: Lens.resting_focal }
	sun_sighting = Sun.sighting(facing_sun, Clock.start)
	parts = Backdrop.backdrop_shapes({ sky_colors, sun_sighting })
	in_order = [parts.sky].concat(parts.sun_shapes).append(parts.grass)
	framed = Backdrop.frame_shapes([], { sky_colors, sun_sighting })
	parts.sun_shapes.len() == 2 and framed == in_order
}

expect {
	sky_colors = Sky.colors_at(Clock.start)
	Backdrop.backdrop_shapes({ sky_colors, sun_sighting: OutOfView }).sun_shapes == []
}
