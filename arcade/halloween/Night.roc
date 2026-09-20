# Night -- the sky, the moon, and the ground the walk is on.
#
# Hand-written: the backdrop, which is everything that would still be there if
# nobody had built a house on it. A flat world puts the horizon at eye level
# whatever the eye is doing, so the sky and the lawn are screen rectangles;
# the street and the walkway are ground, and go through the camera like
# anything else.
import lib.Shapes
import lib.Brush
import lib.View
import Panels

Night :: [].{
	sky_high : Brush.Rgba
	sky_high = Brush.opaque(0x090c1c)
	sky_low : Brush.Rgba
	sky_low = Brush.opaque(0x2a2144)
	lawn : Brush.Rgba
	lawn = Brush.opaque(0x121a14)
	path_c : Brush.Rgba
	path_c = Brush.opaque(0x3a3630)
	street_c : Brush.Rgba
	street_c = Brush.opaque(0x24232a)
	moon_c : Brush.Rgba
	moon_c = Brush.opaque(0xf4f0dc)

	# Half the walkway, in metres. Narrow enough that a skeleton standing
	# beside it is standing over the child.
	path_half : F64
	path_half = 0.76

	# The moon is a body a long way off, not a spot on the glass, so it goes
	# behind you when you turn round the same as everything else does.
	moon_at : View.At
	moon_at = { right: 150.0, forward: 360.0, height: 160.0 }

	# The sky down to the horizon, the ground below it, and the moon.
	backdrop : View.View -> List(Shapes.Shape)
	backdrop = |v| {
		horizon = v.height / 2.0
		var $out = [
			Rect({ x: 0.0, y: 0.0, w: v.width, h: horizon + 1.0, fill: Linear({ c0: sky_high, c1: sky_low, o0: 0.0, o1: 1.0, ax: 0.0, ay: 0.0, dx: 0.0, dy: horizon }) }),
			Rect({ x: 0.0, y: horizon, w: v.width, h: v.height - horizon, fill: Flat(lawn) }),
		]
		if View.ahead(v, moon_at) {
			c = View.turn(v, moon_at)
			p = View.flat(v, c)
			List.append($out, Disc({ x: p.x, y: p.y, r: 32.0 * View.pixels_per_metre(v, c.forward), fill: Flat(moon_c), clip: Anywhere }))
		} else {
			$out
		}
	}

	# The street the child came from, which is only ever seen on the way back.
	street : View.View, F64 -> List(Shapes.Shape)
	street = |v, now| Panels.strip(v, 14.0, 0.0 - 9.0 - now, 0.0 - 0.6 - now, Flat(street_c))

	# The walkway, from the pavement to the doorstep.
	path : View.View, F64, F64 -> List(Shapes.Shape)
	path = |v, now, house_at| Panels.strip(v, path_half, 0.0 - now, house_at - now, Flat(path_c))
}
