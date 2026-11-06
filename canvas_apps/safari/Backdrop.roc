## Backdrop builds what is behind the ride, as shapes. The vocabulary is in
## lib/Shapes.roc, which every canvas app shares. This module knows what is
## behind the ride: the sky's gradient, the grass, and the sun's glow and disc.
import Sky
import lib.Brush
import Screen
import lib.Shapes

Backdrop :: [].{

	## The grass, from just above the horizon down.
	grass_color : I64
	grass_color = 0x4a8f43

	## How far down to the horizon the sky holds its top colour before it
	## fades to the horizon's.
	sky_top_stop : F64
	sky_top_stop = 0.2

	## The sun's paint: a glow out to `glow_radius`, and over it a disc of
	## `disc_radius`.
	SunFills : {
		glow : Brush.Fill,
		glow_radius : F64,
		disc : Brush.Fill,
		disc_radius : F64,
	}

	## The sun's glow and disc where it stands, sized by its scale.
	sun_fills : Sky.SunPlace -> Backdrop.SunFills
	sun_fills = |sun| {
		glow_radius = 340.0 * sun.scale
		disc_radius = Sky.sun_radius_px * sun.scale
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
				x: sun.x,
				y: sun.y,
				r0: 8.0 * sun.scale,
				r1: glow_radius,
			}),
			glow_radius,
			disc: Radial({
				inner: Brush.opaque(0xffe6a3),
				outer: Brush.opaque(0xff9d5c),
				x: sun.x,
				y: sun.y,
				r0: 4.0 * sun.scale,
				r1: disc_radius,
			}),
			disc_radius,
		}
	}

	## The frame in paint order: the sky, the grass, the sun, then the ride's
	## shapes.
	behind : List(Shapes.Shape),
	{
		sky_top_color : I64,
		sky_horizon_color : I64,
		sun_sighting : Sky.SunSighting,
	} -> List(Shapes.Shape)
	behind = |ride_shapes, { sky_top_color, sky_horizon_color, sun_sighting: sun }| {
		var $out = List.with_capacity(List.len(ride_shapes) + 8)
		# Oversized, so the rolled frame's corners stay filled: the top colour to
		# a fifth of the way down to the horizon at y 300, then the fade; the
		# grass from a pixel above the horizon.
		sky = Linear({
			c0: Brush.opaque(sky_top_color),
			c1: Brush.opaque(sky_horizon_color),
			o0: sky_top_stop,
			o1: 1.0,
			ax: 0.0,
			ay: 0.0,
			dx: 0.0,
			dy: Screen.horizon_y,
		})
		$out = List.append(
			$out,
			Rect({
				x: -1080.0,
				y: -1260.0,
				w: 3120.0,
				h: 1560.0,
				fill: sky,
			}),
		)
		$out = List.append(
			$out,
			Rect({
				x: -1080.0,
				y: Screen.grass_top_y,
				w: 3120.0,
				h: 1561.0,
				fill: Flat(Brush.opaque(grass_color)),
			}),
		)
		$out =
			match sun {
				InView(place) => {
					fills = sun_fills(place)
					List.concat(
						$out,
						[
							Rect({
								x: 0.0,
								y: 0.0,
								w: Screen.width,
								h: Screen.horizon_y,
								fill: fills.glow,
							}),
							Disc({
								x: place.x,
								y: place.y,
								r: fills.disc_radius,
								fill: fills.disc,
								clip: Within({
									x: 0.0,
									y: 0.0,
									w: Screen.width,
									h: Screen.horizon_y,
								}),
							}),
						],
					)
				}
				OutOfView => $out
			}
		List.concat($out, ride_shapes)
	}
}
