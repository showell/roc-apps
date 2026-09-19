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
import Trig

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
		c = Trig.r_cos(v.heading)
		s = Trig.r_sin(v.heading)
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
	seen = |v, pts| {
		kept = clipped(turned(v, pts))
		n = List.len(kept)
		var $out = List.with_capacity(2 * n)
		var $i = 0
		while $i < n {
			p = flat(v, List.get(kept, $i) ?? { right: 0.0, forward: 1.0, height: 0.0 })
			$out = List.append($out, p.x)
			$out = List.append($out, p.y)
			$i = $i + 1
		}
		$out
	}

	turned : View.View, List(View.At) -> List(View.At)
	turned = |v, pts| {
		n = List.len(pts)
		var $out = List.with_capacity(n)
		var $i = 0
		while $i < n {
			$out = List.append($out, turn(v, List.get(pts, $i) ?? { right: 0.0, forward: 1.0, height: 0.0 }))
			$i = $i + 1
		}
		$out
	}

	# **A POLYGON IS CUT, NOT DROPPED.** Dropping one the moment a corner goes
	# behind the eye pops a whole house off the screen while most of it is
	# still in the frame; this walks the boundary and puts a new corner on the
	# near plane wherever an edge crosses it.
	clipped : List(View.At) -> List(View.At)
	clipped = |pts| {
		n = List.len(pts)
		var $out = List.with_capacity(n + 2)
		var $i = 0
		while $i < n {
			a = List.get(pts, $i) ?? { right: 0.0, forward: 1.0, height: 0.0 }
			b = List.get(pts, if $i + 1 == n { 0 } else { $i + 1 }) ?? { right: 0.0, forward: 1.0, height: 0.0 }
			a_in = a.forward > near
			b_in = b.forward > near
			$out = if a_in { List.append($out, a) } else { $out }
			$out = if a_in == b_in { $out } else { List.append($out, crossing(a, b)) }
			$i = $i + 1
		}
		$out
	}

	# Where the edge from a to b meets the near plane.
	crossing : View.At, View.At -> View.At
	crossing = |a, b| {
		d = b.forward - a.forward
		t = if d == 0.0 { 0.0 } else { (near - a.forward) / d }
		{ right: a.right + (b.right - a.right) * t, forward: near, height: a.height + (b.height - a.height) * t }
	}
}
