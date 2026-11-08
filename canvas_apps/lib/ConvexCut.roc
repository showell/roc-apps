## ConvexCut cuts each concave polygon of a frame into triangles, for a painter
## that fills only convex polygons, as roc-ray does. A canvas fills a concave
## polygon itself and doesn't ask for this. A frame paints the same either way,
## which the gates' ShapesFrame checks.
import Brush
import Point
import Shapes

ConvexCut :: [].{

	## One shape of a cut frame: a shape the cut leaves as it is, or the
	## triangles of one concave polygon, six numbers each. Only `cut_shapes`
	## makes these, and only the native runner paints them.
	CutShape : [
		Uncut(Shapes.Shape),
		Triangles({ triangle_coordinates : List(F64), fill : Brush.Fill }),
	]

	## The frame with each concave polygon cut into triangles.
	cut_shapes : List(Shapes.Shape) -> List(ConvexCut.CutShape)
	cut_shapes = |shapes| shapes.map(
		|shape|
			match shape {
				Poly(p) =>
					if is_convex(p.coordinates) {
						Uncut(Poly(p))
					} else {
						Triangles({ triangle_coordinates: wound_triangles(triangles(p.coordinates)), fill: p.fill })
					}
				other => Uncut(other)
			},
	)
}

## Each triangle wound as roc-ray's convex fill winds one: its second and third
## corners swapped when its signed area is positive.
wound_triangles : List(F64) -> List(F64)
wound_triangles = |triangle_coordinates| {
	triangle_count = triangle_coordinates.len() // 6
	var $out = List.with_capacity(6 * triangle_count)
	for k in 0..<triangle_count {
		a = corner(triangle_coordinates, 3 * k)
		b = corner(triangle_coordinates, 3 * k + 1)
		c = corner(triangle_coordinates, 3 * k + 2)
		$out = if cross3({ a, b, c }) > 0.0 {
			$out.append(a.x).append(a.y).append(c.x).append(c.y).append(b.x).append(b.y)
		} else {
			$out.append(a.x).append(a.y).append(b.x).append(b.y).append(c.x).append(c.y)
		}
	}
	$out
}

coordinate_at : List(F64), U64 -> F64
coordinate_at = |xs, i| xs.get(i) ?? crash "ConvexCut.coordinate_at:an index past the end of the coordinates"

## Corner `i` of a polygon written as x0, y0, x1, y1 and so on.
corner : List(F64), U64 -> Point.Point
corner = |coordinates, i| { x: coordinate_at(coordinates, 2 * i), y: coordinate_at(coordinates, 2 * i + 1) }

## Twice the signed area of the triangle a b c: positive when it turns one
## way, negative the other, and zero when its corners are in line.
cross3 : { a : Point.Point, b : Point.Point, c : Point.Point } -> F64
cross3 = |{ a, b, c }| (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x)

## Twice the signed area, summed as roc-ray's host sums it.
twice_area : List(F64) -> F64
twice_area = |coordinates| {
	n = coordinates.len() // 2
	var $sum = 0.0
	for k in 0..<n {
		next_k = if k + 1 == n {
			0
		} else {
			k + 1
		}
		$sum = $sum + coordinate_at(coordinates, 2 * k) * coordinate_at(coordinates, 2 * next_k + 1) - coordinate_at(coordinates, 2 * next_k) * coordinate_at(coordinates, 2 * k + 1)
	}
	$sum
}

## A convex boundary reverses its horizontal and vertical direction at most twice
## each.
flip_limit : U64
flip_limit = 2

## Convex when every corner turns the same way and the boundary stays within
## `flip_limit`, which rules out a star whose corners all turn one way.
is_convex : List(F64) -> Bool
is_convex = |coordinates| {
	n = coordinates.len() // 2
	var $sign = 0.0
	var $bad = False
	var $xflips = 0
	var $yflips = 0
	var $xdir = 0.0
	var $ydir = 0.0
	var $k = 0
	while $k < n and !$bad {
		next_k = if $k + 1 >= n {
			$k + 1 - n
		} else {
			$k + 1
		}
		after_next_k = if $k + 2 >= n {
			$k + 2 - n
		} else {
			$k + 2
		}
		here = corner(coordinates, $k)
		next = corner(coordinates, next_k)
		turn = cross3({ a: here, b: next, c: corner(coordinates, after_next_k) })
		$bad = turn * $sign < 0.0
		$sign = if $sign == 0.0 {
			turn
		} else {
			$sign
		}
		dx = next.x - here.x
		dy = next.y - here.y
		$xflips = if dx != 0.0 and $xdir != 0.0 and (dx > 0.0) != ($xdir > 0.0) {
			$xflips + 1
		} else {
			$xflips
		}
		$yflips = if dy != 0.0 and $ydir != 0.0 and (dy > 0.0) != ($ydir > 0.0) {
			$yflips + 1
		} else {
			$yflips
		}
		$xdir = if dx != 0.0 {
			dx
		} else {
			$xdir
		}
		$ydir = if dy != 0.0 {
			dy
		} else {
			$ydir
		}
		$k = $k + 1
	}
	!$bad and $xflips <= flip_limit and $yflips <= flip_limit
}

## The polygon cut into triangles by ear clipping, six numbers a triangle. A
## corner in line with its neighbors is dropped without a triangle. A polygon
## that crosses itself can run out of ears, and what is left is fanned.
triangles : List(F64) -> List(F64)
triangles = |coordinates| {
	n = coordinates.len() // 2
	winding = if twice_area(coordinates) >= 0.0 {
		1.0
	} else {
		-1.0
	}
	var $indices = List.from_iter(U64.until(0, n))
	var $out = List.with_capacity(6 * n)
	var $i = 0
	var $misses = 0
	while $indices.len() > 3 and $misses < $indices.len() {
		corner_count = $indices.len()
		previous_i = if $i == 0 {
			corner_count - 1
		} else {
			$i - 1
		}
		next_i = if $i + 1 >= corner_count {
			0
		} else {
			$i + 1
		}
		a = $indices.get(previous_i) ?? crash "ConvexCut.triangles: a corner index out of range"
		b = $indices.get($i) ?? crash "ConvexCut.triangles: a corner index out of range"
		c = $indices.get(next_i) ?? crash "ConvexCut.triangles: a corner index out of range"
		corner_a = corner(coordinates, a)
		corner_b = corner(coordinates, b)
		corner_c = corner(coordinates, c)
		turn = cross3({ a: corner_a, b: corner_b, c: corner_c }) * winding
		ear = turn >= 0.0 and !any_inside({ coordinates, indices: $indices, a, b, c, winding })
		$out = if ear and turn > 0.0 {
			$out.append(corner_a.x).append(corner_a.y).append(corner_b.x).append(corner_b.y).append(corner_c.x).append(corner_c.y)
		} else {
			$out
		}
		$indices = if ear {
			$indices.drop_at($i)
		} else {
			$indices
		}
		$misses = if ear {
			0
		} else {
			$misses + 1
		}
		$i = if ear {
			if $i >= $indices.len() {
				0
			} else {
				$i
			}
		} else {
			next_i
		}
	}
	fan({ coordinates, indices: $indices, out: $out })
}

## Whether a remaining corner other than a, b and c lies strictly inside the
## triangle a b c.
any_inside : {
	coordinates : List(F64),
	indices : List(U64),
	a : U64,
	b : U64,
	c : U64,
	winding : F64,
} -> Bool
any_inside = |{ coordinates, indices, a, b, c, winding }| {
	corner_a = corner(coordinates, a)
	corner_b = corner(coordinates, b)
	corner_c = corner(coordinates, c)
	indices.any(
		|p| {
			corner_p = corner(coordinates, p)
			p != a and p != b and p != c and cross3({ a: corner_a, b: corner_b, c: corner_p }) * winding > 0.0 and cross3({ a: corner_b, b: corner_c, c: corner_p }) * winding > 0.0 and cross3({ a: corner_c, b: corner_a, c: corner_p }) * winding > 0.0
		},
	)
}

## The remaining corners as a fan from the first, onto `out`.
fan : { coordinates : List(F64), indices : List(U64), out : List(F64) } -> List(F64)
fan = |{ coordinates, indices, out }|
	match indices {
		[] => out
		[first, ..] => {
			corner_count = indices.len()
			pf = corner(coordinates, first)
			var $out = out
			var $k = 1
			while $k + 1 < corner_count {
				p = corner(coordinates, indices.get($k) ?? crash "ConvexCut.fan: a corner index out of range")
				q = corner(coordinates, indices.get($k + 1) ?? crash "ConvexCut.fan: a corner index out of range")
				$out = $out.append(pf.x).append(pf.y).append(p.x).append(p.y).append(q.x).append(q.y)
				$k = $k + 1
			}
			$out
		}
	}

ink : Brush.Fill
ink = Flat({ r: 32.0, g: 32.0, b: 32.0, a: 1.0 })

# A square is convex, and the cut leaves it as it is.
expect {
	square = Poly({ coordinates: [0.0, 0.0, 2.0, 0.0, 2.0, 2.0, 0.0, 2.0], fill: ink })
	ConvexCut.cut_shapes([square]) == [Uncut(square)]
}

# An L of six corners is concave, and the cut makes it four triangles.
expect {
	ell = Poly({ coordinates: [0.0, 0.0, 2.0, 0.0, 2.0, 1.0, 1.0, 1.0, 1.0, 2.0, 0.0, 2.0], fill: ink })
	match ConvexCut.cut_shapes([ell]) {
		[Triangles(t)] => t.triangle_coordinates.len() == 24 and t.fill == ink
		_ => False
	}
}

# A mark is no polygon, and the cut leaves it as it is.
expect ConvexCut.cut_shapes([Blend(Add)]) == [Uncut(Blend(Add))]
