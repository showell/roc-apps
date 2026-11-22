## ConvexCut cuts each concave quad and polygon of a frame into triangles, for a
## painter that fills only convex polygons, as raylib does. A triangle is always
## convex, and passes through. A canvas fills a concave polygon itself and
## doesn't ask for this. A frame paints the same either way, which the gates'
## ShapesFrame checks.
import Brush
import Point
import Shapes

ConvexCut :: [].{

	## One shape of a cut frame: a shape the cut leaves as it is, or the
	## triangles of one concave quad or polygon, three corners each. Only
	## `cut_shapes` makes these, and ShapesFrame paints them.
	CutShape : [
		Uncut(Shapes.Shape),
		Triangles({ triangle_corners : List(Point), fill : Brush.Fill }),
	]

	## The frame with each concave quad and polygon cut into triangles.
	cut_shapes : List(Shapes.Shape) -> List(ConvexCut.CutShape)
	cut_shapes = |shapes| shapes.map(
		|shape|
			match shape {
				Quad(quad) => cut_shape(
					shape,
					{
						corners: [quad.first, quad.second, quad.third, quad.fourth],
						fill: quad.fill,
					},
				)
				Polygon(polygon) => cut_shape(
					shape,
					{ corners: polygon.corners, fill: polygon.fill },
				)
				Triangle(_) | Disc(_) | Blend(_) | View(_) | Image(_) | Text(_) => Uncut(shape)
			},
	)
}

## `shape` as it is when its `corners` are convex, else their triangles.
cut_shape : Shapes.Shape, { corners : List(Point), fill : Brush.Fill } -> ConvexCut.CutShape
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

plain_point : Point -> PlainPoint
plain_point = |{ x, y }| { x: x.to_f64(), y: y.to_f64() }

frame_point : PlainPoint -> Point
frame_point = |{ x, y }| Point.at(x, y)

## Each triangle wound as roc-ray's convex fill winds one: its second and third
## corners swapped when its signed area is positive.
wound_triangles : List(PlainPoint) -> List(PlainPoint)
wound_triangles = |triangle_corners| {
	triangle_count = triangle_corners.len() // 3
	var $out = List.with_capacity(3 * triangle_count)
	for k in 0..<triangle_count {
		corner_a = corner(triangle_corners, 3 * k)
		corner_b = corner(triangle_corners, 3 * k + 1)
		corner_c = corner(triangle_corners, 3 * k + 2)
		$out = if cross3({
			a: corner_a,
			b: corner_b,
			c: corner_c,
		}) > 0.0 {
			$out.append(corner_a).append(corner_c).append(corner_b)
		} else {
			$out.append(corner_a).append(corner_b).append(corner_c)
		}
	}
	$out
}

## Corner `index` of a polygon.
corner : List(PlainPoint), U64 -> PlainPoint
corner = |
	corners,
	index,
| corners.get(index) ?? crash "ConvexCut.corner: an index past the end of the corners"

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
	corner_count = corners.len()
	var $sum = 0.0
	for k in 0..<corner_count {
		next_k = if k + 1 == corner_count {
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
	corner_count = corners.len()
	var $sign = 0.0
	var $bad = False
	var $x_flips = 0
	var $y_flips = 0
	var $x_direction = 0.0
	var $y_direction = 0.0
	var $k = 0
	while $k < corner_count and !$bad {
		next_k = if $k + 1 >= corner_count {
			$k + 1 - corner_count
		} else {
			$k + 1
		}
		after_next_k = if $k + 2 >= corner_count {
			$k + 2 - corner_count
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
		$x_flips = if dx != 0.0 and $x_direction != 0.0 and (dx > 0.0) != ($x_direction > 0.0) {
			$x_flips + 1
		} else {
			$x_flips
		}
		$y_flips = if dy != 0.0 and $y_direction != 0.0 and (dy > 0.0) != ($y_direction > 0.0) {
			$y_flips + 1
		} else {
			$y_flips
		}
		$x_direction = if dx != 0.0 {
			dx
		} else {
			$x_direction
		}
		$y_direction = if dy != 0.0 {
			dy
		} else {
			$y_direction
		}
		$k = $k + 1
	}
	!$bad and $x_flips <= flip_limit and $y_flips <= flip_limit
}

## The polygon cut into triangles by ear clipping, three corners a triangle. A
## corner in line with its neighbors is dropped without a triangle. A polygon
## that crosses itself can run out of ears, and what is left is fanned.
triangles : List(PlainPoint) -> List(PlainPoint)
triangles = |corners| {
	polygon_corner_count = corners.len()
	winding = if twice_area(corners) >= 0.0 {
		1.0
	} else {
		-1.0
	}
	var $indices = List.from_iter(U64.until(0, polygon_corner_count))
	var $out = List.with_capacity(3 * polygon_corner_count)
	var $position = 0
	var $misses = 0
	while $indices.len() > 3 and $misses < $indices.len() {
		corner_count = $indices.len()
		previous_position = if $position == 0 {
			corner_count - 1
		} else {
			$position - 1
		}
		next_position = if $position + 1 >= corner_count {
			0
		} else {
			$position + 1
		}
		index_a = $indices.get(previous_position) ?? crash "ConvexCut.triangles: a corner index out of range"
		index_b = $indices.get($position) ?? crash "ConvexCut.triangles: a corner index out of range"
		index_c = $indices.get(next_position) ?? crash "ConvexCut.triangles: a corner index out of range"
		corner_a = corner(corners, index_a)
		corner_b = corner(corners, index_b)
		corner_c = corner(corners, index_c)
		turn = cross3({
			a: corner_a,
			b: corner_b,
			c: corner_c,
		}) * winding
		ear = turn >= 0.0 and !any_inside({
			corners,
			indices: $indices,
			a: index_a,
			b: index_b,
			c: index_c,
			winding,
		})
		$out = if ear and turn > 0.0 {
			$out.append(corner_a).append(corner_b).append(corner_c)
		} else {
			$out
		}
		$indices = if ear {
			$indices.drop_at($position)
		} else {
			$indices
		}
		$misses = if ear {
			0
		} else {
			$misses + 1
		}
		$position = if ear {
			if $position >= $indices.len() {
				0
			} else {
				$position
			}
		} else {
			next_position
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
		|other| {
			other_corner = corner(corners, other)
			other != a and other != b and other != c and cross3({
				a: corner_a,
				b: corner_b,
				c: other_corner,
			}) * winding > 0.0 and cross3({
				a: corner_b,
				b: corner_c,
				c: other_corner,
			}) * winding > 0.0 and cross3({
				a: corner_c,
				b: corner_a,
				c: other_corner,
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
			hub_corner = corner(corners, first)
			var $out = out
			var $k = 1
			while $k + 1 < corner_count {
				this_corner = corner(
					corners,
					indices.get($k) ?? crash "ConvexCut.fan: a corner index out of range",
				)
				next_corner = corner(
					corners,
					indices.get($k + 1) ?? crash "ConvexCut.fan: a corner index out of range",
				)
				$out = $out.append(hub_corner).append(this_corner).append(next_corner)
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
		[Triangles(cut)] => cut.triangle_corners.len() == 6 and cut.fill == ink
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
	l_shape = Polygon({
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
	match ConvexCut.cut_shapes([l_shape]) {
		[Triangles(cut)] => cut.triangle_corners.len() == 12 and cut.fill == ink
		_ => False
	}
}

# A mark is no polygon, and the cut leaves it as it is.
expect ConvexCut.cut_shapes([Blend(Add)]) == [Uncut(Blend(Add))]
