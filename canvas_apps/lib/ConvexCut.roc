## ConvexCut cuts each concave quad and polygon of a frame into triangles, for a
## painter that fills only convex polygons, as roc-ray does. A triangle is always
## convex, and passes through. A canvas fills a concave polygon itself and
## doesn't ask for this. A frame paints the same either way, which the gates'
## ShapesFrame checks.
import Brush
import Point
import Shapes

ConvexCut :: [].{

	## One shape of a cut frame: a shape the cut leaves as it is, or the
	## triangles of one concave quad or polygon, three corners each. Only
	## `cut_shapes` makes these, and only the native runner paints them.
	CutShape : [
		Uncut(Shapes.Shape),
		Triangles({ triangle_corners : List(Point.Point), fill : Brush.Fill }),
	]

	## The frame with each concave quad and polygon cut into triangles.
	cut_shapes : List(Shapes.Shape) -> List(ConvexCut.CutShape)
	cut_shapes = |shapes| shapes.map(
		|shape|
			match shape {
				Quad(q) => cut_shape(
					shape,
					{ corners: [q.first, q.second, q.third, q.fourth], fill: q.fill },
				)
				Polygon(p) => cut_shape(shape, { corners: p.corners, fill: p.fill })
				Triangle(_) | Disc(_) | Blend(_) | View(_) | Image(_) | Text(_) => Uncut(shape)
			},
	)
}

## `shape` as it is when its `corners` are convex, else their triangles.
cut_shape : Shapes.Shape, { corners : List(Point.Point), fill : Brush.Fill } -> ConvexCut.CutShape
cut_shape = |shape, { corners, fill }| {
	plain_corners = corners.map(plain_point)
	if is_convex(plain_corners) {
		Uncut(shape)
	} else {
		Triangles({
			triangle_corners: wound_triangles(triangles(plain_corners)).map(frame_point),
			fill,
		})
	}
}

## A corner as plain numbers, which the cut's arithmetic is done in.
PlainPoint : { x : F64, y : F64 }

plain_point : Point.Point -> PlainPoint
plain_point = |{ x, y }| { x: x.to_f64(), y: y.to_f64() }

frame_point : PlainPoint -> Point.Point
frame_point = |{ x, y }| Point.at(x, y)

## Each triangle wound as roc-ray's convex fill winds one: its second and third
## corners swapped when its signed area is positive.
wound_triangles : List(PlainPoint) -> List(PlainPoint)
wound_triangles = |triangle_corners| {
	triangle_count = triangle_corners.len() // 3
	var $out = List.with_capacity(3 * triangle_count)
	for k in 0..<triangle_count {
		a = corner(triangle_corners, 3 * k)
		b = corner(triangle_corners, 3 * k + 1)
		c = corner(triangle_corners, 3 * k + 2)
		$out = if cross3({ a, b, c }) > 0.0 {
			$out.append(a).append(c).append(b)
		} else {
			$out.append(a).append(b).append(c)
		}
	}
	$out
}

## Corner `i` of a polygon.
corner : List(PlainPoint), U64 -> PlainPoint
corner = |
	corners,
	i,
| corners.get(i) ?? crash "ConvexCut.corner: an index past the end of the corners"

## Twice the signed area of the triangle a b c: positive when it turns one
## way, negative the other, and zero when its corners are in line.
cross3 : {
	a : PlainPoint,
	b : PlainPoint,
	c : PlainPoint,
} -> F64
cross3 = |{ a, b, c }| (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x)

## Twice the signed area, summed as roc-ray's host sums it.
twice_area : List(PlainPoint) -> F64
twice_area = |corners| {
	n = corners.len()
	var $sum = 0.0
	for k in 0..<n {
		next_k = if k + 1 == n {
			0
		} else {
			k + 1
		}
		here = corner(corners, k)
		next = corner(corners, next_k)
		$sum = $sum + here.x * next.y - next.x * here.y
	}
	$sum
}

## A convex boundary reverses its horizontal and vertical direction at most twice
## each.
flip_limit : U64
flip_limit = 2

## Convex when every corner turns the same way and the boundary stays within
## `flip_limit`, which rules out a star whose corners all turn one way.
is_convex : List(PlainPoint) -> Bool
is_convex = |corners| {
	n = corners.len()
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
		here = corner(corners, $k)
		next = corner(corners, next_k)
		turn = cross3({
			a: here,
			b: next,
			c: corner(corners, after_next_k),
		})
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

## The polygon cut into triangles by ear clipping, three corners a triangle. A
## corner in line with its neighbors is dropped without a triangle. A polygon
## that crosses itself can run out of ears, and what is left is fanned.
triangles : List(PlainPoint) -> List(PlainPoint)
triangles = |corners| {
	n = corners.len()
	winding = if twice_area(corners) >= 0.0 {
		1.0
	} else {
		-1.0
	}
	var $indices = List.from_iter(U64.until(0, n))
	var $out = List.with_capacity(3 * n)
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
		corner_a = corner(corners, a)
		corner_b = corner(corners, b)
		corner_c = corner(corners, c)
		turn = cross3({
			a: corner_a,
			b: corner_b,
			c: corner_c,
		}) * winding
		ear = turn >= 0.0 and !any_inside({
			corners,
			indices: $indices,
			a,
			b,
			c,
			winding,
		})
		$out = if ear and turn > 0.0 {
			$out.append(corner_a).append(corner_b).append(corner_c)
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
	fan({ corners, indices: $indices, out: $out })
}

## Whether a remaining corner other than a, b and c lies strictly inside the
## triangle a b c.
any_inside : {
	corners : List(PlainPoint),
	indices : List(U64),
	a : U64,
	b : U64,
	c : U64,
	winding : F64,
} -> Bool
any_inside = |
	{
		corners,
		indices,
		a,
		b,
		c,
		winding,
	},
| {
	corner_a = corner(corners, a)
	corner_b = corner(corners, b)
	corner_c = corner(corners, c)
	indices.any(
		|p| {
			corner_p = corner(corners, p)
			p != a and p != b and p != c and cross3({
				a: corner_a,
				b: corner_b,
				c: corner_p,
			}) * winding > 0.0 and cross3({
				a: corner_b,
				b: corner_c,
				c: corner_p,
			}) * winding > 0.0 and cross3({
				a: corner_c,
				b: corner_a,
				c: corner_p,
			}) * winding > 0.0
		},
	)
}

## The remaining corners as a fan from the first, onto `out`.
fan : {
	corners : List(PlainPoint),
	indices : List(U64),
	out : List(PlainPoint),
} -> List(PlainPoint)
fan = |{ corners, indices, out }|
	match indices {
		[] => out
		[first, ..] => {
			corner_count = indices.len()
			pf = corner(corners, first)
			var $out = out
			var $k = 1
			while $k + 1 < corner_count {
				p = corner(
					corners,
					indices.get($k) ?? crash "ConvexCut.fan: a corner index out of range",
				)
				q = corner(
					corners,
					indices.get($k + 1) ?? crash "ConvexCut.fan: a corner index out of range",
				)
				$out = $out.append(pf).append(p).append(q)
				$k = $k + 1
			}
			$out
		}
	}

ink : Brush.Fill
ink = Flat({
	r: 32.0,
	g: 32.0,
	b: 32.0,
	a: 1.0,
})

# A square is convex, and the cut leaves it as it is.
expect {
	square = Quad({
		first: Point.at(0.0, 0.0),
		second: Point.at(2.0, 0.0),
		third: Point.at(2.0, 2.0),
		fourth: Point.at(0.0, 2.0),
		fill: ink,
	})
	ConvexCut.cut_shapes([square]) == [Uncut(square)]
}

# An arrowhead is a concave quad, and the cut makes it two triangles.
expect {
	arrowhead = Quad({
		first: Point.at(0.0, 0.0),
		second: Point.at(4.0, 2.0),
		third: Point.at(0.0, 4.0),
		fourth: Point.at(1.0, 2.0),
		fill: ink,
	})
	match ConvexCut.cut_shapes([arrowhead]) {
		[Triangles(t)] => t.triangle_corners.len() == 6 and t.fill == ink
		_ => False
	}
}

# A triangle is convex by construction, and passes through.
expect {
	triangle = Triangle({
		first: Point.at(0.0, 0.0),
		second: Point.at(4.0, 2.0),
		third: Point.at(0.0, 4.0),
		fill: ink,
	})
	ConvexCut.cut_shapes([triangle]) == [Uncut(triangle)]
}

# A pentagon is convex, and the cut leaves it as it is.
expect {
	pentagon = Polygon({
		corners: [
			Point.at(2.0, 0.0),
			Point.at(4.0, 1.5),
			Point.at(3.0, 4.0),
			Point.at(1.0, 4.0),
			Point.at(0.0, 1.5),
		],
		fill: ink,
	})
	ConvexCut.cut_shapes([pentagon]) == [Uncut(pentagon)]
}

# An L of six corners is concave, and the cut makes it four triangles.
expect {
	ell = Polygon({
		corners: [
			Point.at(0.0, 0.0),
			Point.at(2.0, 0.0),
			Point.at(2.0, 1.0),
			Point.at(1.0, 1.0),
			Point.at(1.0, 2.0),
			Point.at(0.0, 2.0),
		],
		fill: ink,
	})
	match ConvexCut.cut_shapes([ell]) {
		[Triangles(t)] => t.triangle_corners.len() == 12 and t.fill == ink
		_ => False
	}
}

# A mark is no polygon, and the cut leaves it as it is.
expect ConvexCut.cut_shapes([Blend(Add)]) == [Uncut(Blend(Add))]
