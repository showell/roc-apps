# Panels -- polygons placed in the world rather than on the screen.
#
# Hand-written. Every solid thing in this movie is one of three: a polygon
# whose corners are anywhere (`world`), a polygon on one plane a fixed distance
# away (`face`, and `panel` for its rectangle), or a strip of flat ground
# (`strip`). Each goes through View.seen, which turns the points into the eye's
# own frame, cuts what is behind it against the near plane, and projects the
# rest.
#
# **THE OBVIOUS THING TO PROMOTE TO `lib/`** the day a second app places
# anything in metres. Nothing here knows what a house or a fence is.
import lib.Shapes
import lib.Brush
import lib.View

Panels :: [].{
	# A polygon whose corners are wherever they are: the door leaf turns out of
	# its own plane on its hinge, and a floor lies flat.
	world : View.View, List(View.At), Brush.Fill -> List(Shapes.Shape)
	world = |v, ats, fill| Shapes.polygon(View.seen(v, ats), fill)

	# A polygon given as metres on one plane `fwd` away: right, height, right,
	# height. Everything on the house's face is one of these.
	face : View.View, F64, List(F64), Brush.Fill -> List(Shapes.Shape)
	face = |v, fwd, pts, fill| {
		n = List.len(pts)
		var $ats = List.with_capacity(n // 2)
		var $i = 0
		while $i + 1 < n {
			$ats = List.append($ats, { right: List.get(pts, $i) ?? 0.0, forward: fwd, height: List.get(pts, $i + 1) ?? 0.0 })
			$i = $i + 2
		}
		world(v, $ats, fill)
	}

	# A rectangle on that plane, by its two opposite corners.
	panel : View.View, F64, F64, F64, F64, F64, Brush.Fill -> List(Shapes.Shape)
	panel = |v, fwd, x0, y0, x1, y1, fill| face(v, fwd, [x0, y1, x1, y1, x1, y0, x0, y0], fill)

	# A strip of ground between two distances, `half` metres either side of
	# the middle: the walkway, which is wider the nearer it is.
	strip : View.View, F64, F64, F64, Brush.Fill -> List(Shapes.Shape)
	strip = |v, half, near_f, far_f, fill|
		world(v, [
			{ right: 0.0 - half, forward: near_f, height: 0.0 },
			{ right: half, forward: near_f, height: 0.0 },
			{ right: half, forward: far_f, height: 0.0 },
			{ right: 0.0 - half, forward: far_f, height: 0.0 },
		], fill)
}
