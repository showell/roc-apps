## Backdrop builds what is behind the ride, as shapes. The vocabulary is in
## lib/Shapes.roc, which every canvas app shares. This module knows what is
## behind the ride: the sky's gradient, the sun's glow and disc, and the grass.
import Fraction
import HexColor
import Pixels
import lib.Brush
import lib.RgbColor
import Screen
import Sun
import lib.Shapes

Backdrop :: [].{

	## The grass, from just above the horizon down.
	grass_color : RgbColor
	grass_color = RgbColor.of(0x4a8f43)

	## How far down to the horizon the sky holds its top colour before it
	## fades to the horizon's.
	sky_top_stop : Fraction
	sky_top_stop = Fraction.of(0.2)

	## The sun's paint: a glow out to `glow_radius`, and over it a disc of
	## `disc_radius`.
	SunFills : {
		glow : Brush.Fill,
		glow_radius : Pixels,
		disc : Brush.Fill,
		disc_radius : Pixels,
	}

	## The sun's glow and disc where it stands, sized by its scale.
	sun_fills : Sun.Place -> Backdrop.SunFills
	sun_fills = |sun| {
		scale = sun.scale.to_f64()
		glow_radius = Pixels.of(340.0).times(scale)
		disc_radius = Sun.radius_px.times(scale)
		{
			glow: Glow({
				c0: {
					r: 255.0,
					g: 201.0,
					b: 128.0,
					a: 0.85,
				},
				c1: {
					r: 255.0,
					g: 150.0,
					b: 92.0,
					a: 0.32,
				},
				c2: {
					r: 255.0,
					g: 150.0,
					b: 92.0,
					a: 0.0,
				},
				x: sun.x.to_f64(),
				y: sun.y.to_f64(),
				r0: 8.0 * scale,
				r1: glow_radius.to_f64(),
			}),
			glow_radius,
			disc: Radial({
				inner: Brush.opaque(RgbColor.of(0xffe6a3)),
				outer: Brush.opaque(RgbColor.of(0xff9d5c)),
				x: sun.x.to_f64(),
				y: sun.y.to_f64(),
				r0: 4.0 * scale,
				r1: disc_radius.to_f64(),
			}),
			disc_radius,
		}
	}

	## The frame in paint order: the sky, the sun, the grass, then the ride's
	## shapes. The grass covers whatever of the sun has set.
	frame_shapes : List(Shapes.Shape),
	{
		sky_top_color : HexColor.Rgb,
		sky_horizon_color : HexColor.Rgb,
		sun_sighting : Sun.Sighting,
	} -> List(Shapes.Shape)
	frame_shapes = |ride_shapes, { sky_top_color, sky_horizon_color, sun_sighting: sun }| {
		var $out = List.with_capacity(ride_shapes.len() + 8)
		# The top colour to a fifth of the way down to the horizon at y 300,
		# then the fade.
		sky = Linear({
			c0: Brush.opaque(HexColor.pack(sky_top_color)),
			c1: Brush.opaque(HexColor.pack(sky_horizon_color)),
			o0: sky_top_stop.to_f64(),
			o1: 1.0,
			ax: 0.0,
			ay: 0.0,
			dx: 0.0,
			dy: Screen.horizon_y.to_f64(),
		})
		$out = $out.append(sky_rect(sky))
		$out =
			match sun {
				InView(place) => {
					fills = sun_fills(place)
					$out.concat([
						sky_rect(fills.glow),
						Disc({
							x: place.x.to_f64(),
							y: place.y.to_f64(),
							r: fills.disc_radius.to_f64(),
							fill: fills.disc,
						}),
					])
				}
				OutOfView => $out
			}
		# From a pixel above the horizon, oversized as the sky is.
		$out = $out.append(
			Rect({
				x: -1080.0,
				y: Screen.grass_top_y.to_f64(),
				w: 3120.0,
				h: 1561.0,
				fill: Flat(Brush.opaque(grass_color)),
			}),
		)
		$out.concat(ride_shapes)
	}
}

## The sky's rectangle down to the horizon, painted with `fill`. It is oversized,
## so a rolled frame's corners stay filled, and the sun's glow takes it too.
sky_rect : Brush.Fill -> Shapes.Shape
sky_rect = |fill|
	Rect({
		x: -1080.0,
		y: -1260.0,
		w: 3120.0,
		h: 1560.0,
		fill,
	})
