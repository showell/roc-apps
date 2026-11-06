# View -- a movie's eye: where a thing in the world lands on the screen.
#
# Hand-written. Safari has a camera of its own, with a 600-pixel screen and an
# adult's 1.2-metre eye baked in, because for a long time there was one movie
# and it was a motorcycle. This is the same arithmetic with those as
# parameters, so a movie can be seen from a child's height on a screen of its
# own size.
#
# **THE WORLD IS THREE NUMBERS**: `right` across, `forward` away, `height` up
# from the ground, all in metres, taken from where the eye is. The screen is
# pixels. `focal` is what turns one into the other -- the pixels a metre
# subtends a metre away -- so a bigger focal is a longer lens and a narrower
# view.
#
# **AND THE EYE CAN TURN.** `heading` is which way it faces, in radians, right
# from straight down the world's forward axis. It is why `seen` exists: a
# quarter turn puts half the world behind the eye, where the arithmetic that
# divides by `forward` says nothing useful, so a polygon is cut against the
# near plane on its way to the screen rather than trusted to it.

View :: [].{
	View : { width : F64, height : F64, eye : F64, focal : F64, heading : F64 }

	At : { right : F64, forward : F64, height : F64 }

	# Nothing nearer than this is drawn: at the eye it would be infinite.
	near : F64
	near = 0.35

	# The point as this eye has it: the world turned the other way by the
	# heading, so `forward` means "in front of this eye" rather than "up the
	# path".
	turn : View.View, View.At -> View.At
	turn = |v, p| {
		c = v.heading.cos()
		s = v.heading.sin()
		{ right: p.right * c - p.forward * s, forward: p.right * s + p.forward * c, height: p.height }
	}

	# A point the eye has already turned, on the screen.
	flat : View.View, View.At -> { x : F64, y : F64 }
	flat = |v, p| {
		x: v.width / 2.0 + p.right / p.forward * v.focal,
		y: v.height / 2.0 - (p.height - v.eye) / p.forward * v.focal,
	}

	project : View.View, View.At -> { x : F64, y : F64 }
	project = |v, p| flat(v, turn(v, p))

	# Whether a point is in front of the eye at all. Anything drawn as a disc
	# or a line has to be asked, because only a polygon can be cut.
	ahead : View.View, View.At -> Bool
	ahead = |v, p| turn(v, p).forward > near

	# How many pixels a metre is, that far away. A figure's size, and the
	# width of anything drawn flat. The distance is the turned one.
	pixels_per_metre : View.View, F64 -> F64
	pixels_per_metre = |v, forward| v.focal / forward

	# A polygon of world points as screen coordinates: turned, cut to what is
	# in front of the eye, and projected. Empty when none of it is.
	seen : View.View, List(View.At) -> List(F64)
	seen = |v, points| {
		kept = clipped(turned(v, points))
		var $out = List.with_capacity(2 * kept.len())
		for point in kept {
			p = flat(v, point)
			$out = $out.append(p.x).append(p.y)
		}
		$out
	}

	turned : View.View, List(View.At) -> List(View.At)
	turned = |v, points| points.map(|p| turn(v, p))

	# **A POLYGON IS CUT, NOT DROPPED.** Dropping one the moment a corner goes
	# behind the eye pops a whole house off the screen while most of it is
	# still in the frame; this walks the boundary and puts a new corner on the
	# near plane wherever an edge crosses it.
	clipped : List(View.At) -> List(View.At)
	clipped = |points| {
		neighbours = points.drop_first(1).concat(points.take_first(1))
		var $out = List.with_capacity(points.len() + 2)
		for (a, b) in points.map2(neighbours, |a, b| (a, b)) {
			a_in = a.forward > near
			b_in = b.forward > near
			if a_in {
				$out = $out.append(a)
			}
			if a_in != b_in {
				$out = $out.append(crossing(a, b))
			}
		}
		$out
	}

	# Where the edge from a to b meets the near plane.
	crossing : View.At, View.At -> View.At
	crossing = |a, b| {
		d = b.forward - a.forward
		t = if d == 0.0 {
			0.0
		} else {
			(near - a.forward) / d
		}
		{ right: a.right + (b.right - a.right) * t, forward: near, height: a.height + (b.height - a.height) * t }
	}
}
