## The convex hull of points on the screen: what wraps around them, clockwise
## from the leftmost. A cone's ring and its apex have a faster way to their
## hull, which keeps the ring's own order rather than sorting it.
import lib.Point

ConvexHull :: [].{

	## The convex hull of a cone's ring on the screen and its apex, as
	## `convex_hull_points` gives it. The ring is convex on the screen and keeps
	## its angle order there, so each of its two arcs from the leftmost point to
	## the rightmost is already left to right, and merging the arcs and the apex
	## puts the points in the hull's order without a sort. Where rounding leaves
	## the merge out of that order, the points are sorted as usual.
	cone_hull_points : List(Point.Point), Point.Point -> List(Point.Point)
	cone_hull_points = |ring_points, apex| {
		count = ring_points.len()
		if count < 2 {
			convex_hull_points(ring_points.append(apex))
		} else {
			ring_hull_points({ ring_points, apex })
		}
	}
}

## The convex hull of `points`, clockwise on the screen from the leftmost:
## Andrew's monotone chain, along the hull's top and back along its bottom.
## Fewer than three points are their own hull.
convex_hull_points : List(Point.Point) -> List(Point.Point)
convex_hull_points = |points|
	if points.len() < 3 {
		points
	} else {
		hull_points_of_sorted(points.sort_with(left_to_right))
	}

## The hull of three or more points already in `left_to_right` order.
hull_points_of_sorted : List(Point.Point) -> List(Point.Point)
hull_points_of_sorted = |sorted| {
	room = sorted.len()
	add_point = |hull, point| trim_hull(hull, point).append(point)
	top_chain = sorted.fold(List.with_capacity(room), add_point)
	bottom_chain = sorted.fold_rev(List.with_capacity(room), |point, hull| add_point(hull, point))
	top_chain.drop_last(1).concat(bottom_chain.drop_last(1))
}

## What `cone_hull_points` gives for a ring of two or more points.
ring_hull_points : { ring_points : List(Point.Point), apex : Point.Point } -> List(Point.Point)
ring_hull_points = |{ ring_points, apex }| {
	count = ring_points.len()
	point_at = |index| ring_points.get(index % count) ?? crash "ConvexHull: a ring index wraps round the ring"
	first_point = point_at(0)
	var $leftmost_index = 0
	var $left_point = first_point
	var $rightmost_index = 0
	var $right_point = first_point
	for index in 1..<count {
		point = point_at(index)
		if is_before(point, $left_point) {
			$leftmost_index = index
			$left_point = point
		} else if is_before($right_point, point) {
			$rightmost_index = index
			$right_point = point
		} else {
			{}
		}
	}
	forward_count = ($rightmost_index + count - $leftmost_index) % count + 1
	back_count = count - forward_count
	var $merged = List.with_capacity(count + 1)
	var $forward_at = 0
	var $back_at = 0
	var $apex_placement = Unplaced
	var $order = InOrder
	var $previous = $left_point
	while $forward_at < forward_count or $back_at < back_count {
		forward_point = point_at($leftmost_index + $forward_at)
		back_point = point_at($leftmost_index + count - 1 - $back_at)
		is_forward_done = $forward_at == forward_count
		is_back_before = $back_at < back_count and is_before(back_point, forward_point)
		takes_back = is_forward_done or is_back_before
		point =
			if takes_back {
				$back_at = $back_at + 1
				back_point
			} else {
				$forward_at = $forward_at + 1
				forward_point
			}
		if $apex_placement == Unplaced and is_before(apex, point) {
			$order = order_after($order, { previous: $previous, point: apex })
			$merged = $merged.append(apex)
			$previous = apex
			$apex_placement = Placed
		} else {
			{}
		}
		$order = order_after($order, { previous: $previous, point })
		$merged = $merged.append(point)
		$previous = point
	}
	if $apex_placement == Unplaced {
		$order = order_after($order, { previous: $previous, point: apex })
		$merged = $merged.append(apex)
	} else {
		{}
	}
	match $order {
		InOrder => hull_points_of_sorted($merged)
		OutOfOrder => convex_hull_points(ring_points.append(apex))
	}
}

## Whether a merge of points has kept them left to right so far.
MergeOrder : [InOrder, OutOfOrder]

## Whether the merge is still in order once `point` follows `previous`.
order_after : MergeOrder, { previous : Point.Point, point : Point.Point } -> MergeOrder
order_after = |order, { previous, point }|
	if is_before(point, previous) {
		OutOfOrder
	} else {
		order
	}

## The order the hull walks points in: left to right, and top to bottom where
## they share an x.
left_to_right : Point.Point, Point.Point -> [Before, Same, After]
left_to_right = |a, b|
	if is_before(a, b) {
		Before
	} else if is_before(b, a) {
		After
	} else {
		Same
	}

## Whether `a` comes before `b`: left of it, or above it at the same x.
is_before : Point.Point, Point.Point -> Bool
is_before = |a, b| a.x < b.x or (a.x == b.x and a.y < b.y)

## The hull with its last points taken off while they don't turn clockwise on
## the way to `point`. The screen's y grows downward, so a positive `turn` is
## clockwise as the eye sees it.
trim_hull : List(Point.Point), Point.Point -> List(Point.Point)
trim_hull = |hull_corners, point|
	match hull_corners {
		[.., a, b] => {
			edge_x = b.x.minus(a.x).to_f64()
			edge_y = b.y.minus(a.y).to_f64()
			reach_x = point.x.minus(a.x).to_f64()
			reach_y = point.y.minus(a.y).to_f64()
			turn = edge_x * reach_y - edge_y * reach_x
			if turn <= 0.0 {
				trim_hull(hull_corners.drop_last(1), point)
			} else {
				hull_corners
			}
		}
		_ => hull_corners
	}

# Of two points at one x the higher comes first, and of two equal points neither does.
expect is_before(Point.at(1.0, 9.0), Point.at(2.0, 0.0))
expect !is_before(Point.at(2.0, 0.0), Point.at(1.0, 9.0))
expect is_before(Point.at(1.0, 2.0), Point.at(1.0, 3.0))
expect !is_before(Point.at(1.0, 3.0), Point.at(1.0, 2.0))
expect !is_before(Point.at(1.0, 2.0), Point.at(1.0, 2.0))

square_and_inside_points : List(Point.Point)
square_and_inside_points = [
	Point.at(0.0, 0.0),
	Point.at(4.0, 0.0),
	Point.at(4.0, 4.0),
	Point.at(0.0, 4.0),
	Point.at(2.0, 2.0),
	Point.at(2.0, 0.0),
]

triangle_points : List(Point.Point)
triangle_points = [
	Point.at(0.0, 0.0),
	Point.at(4.0, 0.0),
	Point.at(2.0, 3.0),
]

line_points : List(Point.Point)
line_points = [
	Point.at(0.0, 0.0),
	Point.at(1.0, 1.0),
	Point.at(2.0, 2.0),
	Point.at(3.0, 3.0),
]

pair_points : List(Point.Point)
pair_points = [Point.at(1.0, 2.0), Point.at(0.0, 0.0)]

repeated_points : List(Point.Point)
repeated_points = [
	Point.at(0.0, 0.0),
	Point.at(0.0, 0.0),
	Point.at(4.0, 0.0),
	Point.at(4.0, 4.0),
]

expect convex_hull_points(square_and_inside_points) == [
	Point.at(0.0, 0.0),
	Point.at(4.0, 0.0),
	Point.at(4.0, 4.0),
	Point.at(0.0, 4.0),
]
expect convex_hull_points(triangle_points) == [
	Point.at(0.0, 0.0),
	Point.at(4.0, 0.0),
	Point.at(2.0, 3.0),
]
expect convex_hull_points(line_points) == [Point.at(0.0, 0.0), Point.at(3.0, 3.0)]
expect convex_hull_points(pair_points) == [Point.at(1.0, 2.0), Point.at(0.0, 0.0)]
expect convex_hull_points([Point.at(9.0, 9.0)]) == [Point.at(9.0, 9.0)]
expect convex_hull_points([]) == []
expect convex_hull_points(repeated_points) == [
	Point.at(0.0, 0.0),
	Point.at(4.0, 0.0),
	Point.at(4.0, 4.0),
]

expect
	square_and_inside_points.sort_with(left_to_right)
		== [
			Point.at(0.0, 0.0),
			Point.at(0.0, 4.0),
			Point.at(2.0, 0.0),
			Point.at(2.0, 2.0),
			Point.at(4.0, 0.0),
			Point.at(4.0, 4.0),
		]

## A ring of 16 points on an ellipse, in angle order from `start`, as a cone's
## ring looks on the screen.
sample_ring_points : U64 -> List(Point.Point)
sample_ring_points = |start| {
	step = F64.tau / 16.0
	var $angle = 0.0
	var $ring = []
	for _ in 0..<16 {
		$ring = $ring.append(Point.at(100.0 + 40.0 * $angle.cos(), 50.0 + 10.0 * $angle.sin()))
		$angle = $angle + step
	}
	$ring.drop_first(start).concat($ring.take_first(start))
}

# The ring's hull with its apex is the convex hull of the points: with the apex
# above the ring, inside it, and below it, from any first point round the ring,
# and with the ring in a shuffled order, where the merge falls back to the sort.
expect {
	apexes = [
		Point.at(100.0, 0.0),
		Point.at(100.0, 50.0),
		Point.at(130.0, 90.0),
	]
	[0, 5, 11].all(
		|start| {
			ring_points = sample_ring_points(start)
			is_hull = |apex| {
				hull_points = ConvexHull.cone_hull_points(ring_points, apex)
				hull_points == convex_hull_points(ring_points.append(apex))
			}
			apexes.all(is_hull)
		},
	)
}
expect {
	top_to_bottom = |a, b| left_to_right({ x: a.y, y: a.x }, { x: b.y, y: b.x })
	shuffled = sample_ring_points(0).sort_with(top_to_bottom)
	apex = Point.at(100.0, 0.0)
	ConvexHull.cone_hull_points(shuffled, apex) == convex_hull_points(shuffled.append(apex))
}
