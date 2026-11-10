# Night -- the sky, the moon, and the ground the walk is on.
#
# Hand-written: the backdrop, which is everything that would still be there if
# nobody had built a house on it. A flat world puts the horizon at eye level
# whatever the eye is doing, so the sky and the lawn are screen rectangles;
# the street and the walkway are ground, and go through the camera like
# anything else.
import lib.Pixels
import lib.Point
import lib.Shapes
import lib.Brush
import lib.RgbColor
import Eye
import Panels

Night :: [].{
	sky_high : Brush.Rgba
	sky_high = Brush.opaque_rgba(RgbColor.of(0x090c1c))
	sky_low : Brush.Rgba
	sky_low = Brush.opaque_rgba(RgbColor.of(0x2a2144))
	lawn : Brush.Rgba
	lawn = Brush.opaque_rgba(RgbColor.of(0x121a14))
	path_c : Brush.Rgba
	path_c = Brush.opaque_rgba(RgbColor.of(0x3a3630))
	street_c : Brush.Rgba
	street_c = Brush.opaque_rgba(RgbColor.of(0x24232a))
	moon_c : Brush.Rgba
	moon_c = Brush.opaque_rgba(RgbColor.of(0xf4f0dc))

	# Half the walkway, in metres. Narrow enough that a skeleton standing
	# beside it is standing over the child.
	path_half : F64
	path_half = 0.76

	# The moon is a body a long way off, not a spot on the glass, so it goes
	# behind you when you turn round the same as everything else does.
	moon_at : Eye.At
	moon_at = { right: 150.0, forward: 360.0, height: 160.0 }

	# The sky down to the horizon, the ground below it, and the moon.
	backdrop : Eye.Eye -> List(Shapes.Shape)
	backdrop = |v| {
		horizon = v.height / 2.0
		var $out = [
			Shapes.rectangle({ top_left: Point.at(0.0, 0.0), width: Pixels.of(v.width), height: Pixels.of(horizon + 1.0), fill: Linear({ stops: { start_color: sky_high, end_color: sky_low, start_offset: 0.0, end_offset: 1.0 }, start_point: Point.at(0.0, 0.0), end_point: Point.at(0.0, horizon) }) }),
			Shapes.rectangle({ top_left: Point.at(0.0, horizon), width: Pixels.of(v.width), height: Pixels.of(v.height - horizon), fill: Flat(lawn) }),
		]
		match Eye.sighting(v, moon_at) {
			Ok({ point: p, pixels_per_metre }) => List.append($out, Disc({ center: Point.at(p.x, p.y), radius: Pixels.of(32.0 * pixels_per_metre), fill: Flat(moon_c) }))
			Err(BehindEye) => $out
		}
	}

	# The street the child came from, which is only ever seen on the way back.
	street : Eye.Eye, F64 -> List(Shapes.Shape)
	street = |v, now| Panels.strip(v, 14.0, 0.0 - 9.0 - now, 0.0 - 0.6 - now, Flat(street_c))

	# The walkway, from the pavement to the doorstep.
	path : Eye.Eye, F64, F64 -> List(Shapes.Shape)
	path = |v, now, house_at| Panels.strip(v, path_half, 0.0 - now, house_at - now, Flat(path_c))
}
