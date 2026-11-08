## A guard rail: a metal bar half a metre up, on thin posts, along a path
## on the ground. Each stretch of bar between two points of the path, and
## each post, is a flat quad, which the depth sort places among the frame's
## other things.
import Pixels
import Distance
import RiderView
import Polygon
import Picture
import Rendered
import lib.RgbColor
import lib.Shapes

GuardRail :: [].{

	## A quad of the rail: its corners and its colour. Its low edge runs along
	## the path from start to end, and its high edge runs above it.
	RailQuad : {
		corners : {
			low_start : RiderView.RaisedPoint,
			low_end : RiderView.RaisedPoint,
			high_end : RiderView.RaisedPoint,
			high_start : RiderView.RaisedPoint,
		},
		color : RgbColor,
	}

	## The rail along `path_points`: the bars, then the posts.
	quads_along : List(RiderView.RiderPoint) -> List(GuardRail.RailQuad)
	quads_along = |path_points| bars(path_points).concat(posts(path_points))

	## A quad as the frame draws it, at its own depth, unless it's wholly
	## behind the camera. A rail quad has no kind for `Pipeline` to ask, so it
	## renders itself.
	quad_rendering : GuardRail.RailQuad, Pixels -> Try(Rendered, [BehindCamera])
	quad_rendering = |quad, focal_length|
		quad_shape(quad, focal_length).map_ok(
			|shape| Rendered.of(quad_depth(quad), Picture.from_shapes([shape])),
		)
}

## How far ahead a quad is, for the depth sort: the mean of its corners'
## distances, summed round the quad from its low start, since a float sum's
## rounding depends on its order. It is negative for a quad behind the rider.
quad_depth : GuardRail.RailQuad -> Distance
quad_depth = |quad| {
	{ low_start, low_end, high_end, high_start } = quad.corners
	sum = low_start.forward.plus(low_end.forward).plus(high_end.forward).plus(high_start.forward)
	sum.divided_by(4.0)
}

## A quad on screen, cut at the camera's near plane, unless it's wholly
## behind the camera.
quad_shape : GuardRail.RailQuad, Pixels -> Try(Shapes.Shape, [BehindCamera])
quad_shape = |quad, focal_length|
	{
		{ low_start, low_end, high_end, high_start } = quad.corners
		corners = [low_start, low_end, high_end, high_start]
		Polygon.clipped_polygon({ color: quad.color, corners }, focal_length)
	}

rail_height : Distance
rail_height = Distance.metres(0.5)

rail_thickness : Distance
rail_thickness = Distance.metres(0.1)

rail_post_width : Distance
rail_post_width = Distance.metres(0.02)

rail_metal : RgbColor
rail_metal = RgbColor.of(0xC2C7CF)

rail_post_metal : RgbColor
rail_post_metal = RgbColor.of(0x9AA0A8)

bar_top : Distance
bar_top = rail_height.plus(rail_thickness.divided_by(2.0))

bar_bottom : Distance
bar_bottom = rail_height.minus(rail_thickness.divided_by(2.0))

post_half_width : Distance
post_half_width = rail_post_width.divided_by(2.0)

## A stretch of bar between each two neighbouring points of `path_points`.
bars : List(RiderView.RiderPoint) -> List(GuardRail.RailQuad)
bars = |path_points| path_points.map2(path_points.drop_first(1), |from, to| bar({ from, to }))

## A post at each point of `path_points`, turned to face along the path from
## the point before it to the point after it. A post at an end of the
## path takes its own point in place of the one it lacks.
posts : List(RiderView.RiderPoint) -> List(GuardRail.RailQuad)
posts = |path_points| {
	before = path_points.take_first(1).concat(path_points.drop_last(1))
	after = path_points.drop_first(1).concat(path_points.take_last(1))
	before.map3(
		path_points,
		after,
		|previous, at, next| post(at, { previous, next }),
	)
}

## A point of the path, at `height` above the ground.
raised_point : RiderView.RiderPoint, Distance -> RiderView.RaisedPoint
raised_point = |point, height| { right: point.right, forward: point.forward, height }

## The bar from `from` to `to`, bottom edge first.
bar : { from : RiderView.RiderPoint, to : RiderView.RiderPoint } -> GuardRail.RailQuad
bar = |{ from, to }| {
	corners: {
		low_start: raised_point(from, bar_bottom),
		low_end: raised_point(to, bar_bottom),
		high_end: raised_point(to, bar_top),
		high_start: raised_point(from, bar_top),
	},
	color: rail_metal,
}

## The post at `at`, half its width to each side of it along the path from
## `previous` to `next`, from the ground to the top of the bar. Two points
## at one place give no direction, and the post then has no width.
post : RiderView.RiderPoint,
{
	previous : RiderView.RiderPoint,
	next : RiderView.RiderPoint,
} -> GuardRail.RailQuad
post = |at, { previous, next }| {
	rightward = next.right.minus(previous.right).to_metres()
	forward = next.forward.minus(previous.forward).to_metres()
	length = (rightward * rightward + forward * forward).sqrt()
	run = if length.to_bits() == 0 {
		1.0
	} else {
		length
	}
	half_right = post_half_width.times(rightward / run)
	half_forward = post_half_width.times(forward / run)
	back = { right: at.right.minus(half_right), forward: at.forward.minus(half_forward) }
	front = { right: at.right.plus(half_right), forward: at.forward.plus(half_forward) }
	{
		corners: {
			low_start: raised_point(back, Distance.zero),
			low_end: raised_point(front, Distance.zero),
			high_end: raised_point(front, bar_top),
			high_start: raised_point(back, bar_top),
		},
		color: rail_post_metal,
	}
}

first_post : List(RiderView.RiderPoint) -> GuardRail.RailQuad
first_post = |route_points| posts(route_points).first() ?? crash "a route of two points has posts"

straight_points : List(RiderView.RiderPoint)
straight_points = [
	{ right: Distance.metres(0.0), forward: Distance.metres(10.0) },
	{ right: Distance.metres(0.0), forward: Distance.metres(20.0) },
	{ right: Distance.metres(0.0), forward: Distance.metres(30.0) },
]

straight_quads : List(GuardRail.RailQuad)
straight_quads = GuardRail.quads_along(straight_points)

first_bar : GuardRail.RailQuad
first_bar = straight_quads.first() ?? crash "a straight route has a rail"

expect straight_quads.len() == 5
expect bars(straight_points).len() == 2
expect posts(straight_points).len() == 3

expect
	straight_quads.map(|quad| quad.color.to_i64())
		== [0xC2C7CF, 0xC2C7CF, 0x9AA0A8, 0x9AA0A8, 0x9AA0A8]
expect
	straight_quads.map(|quad| quad_depth(quad).to_metres())
		== [15.0, 25.0, 10.0, 20.0, 30.0]

behind_bar : GuardRail.RailQuad
behind_bar = bar({
	from: { right: Distance.metres(0.0), forward: Distance.metres(-20.0) },
	to: { right: Distance.metres(0.0), forward: Distance.metres(-10.0) },
})

# A quad stands at its own depth, and one wholly behind the camera isn't drawn.
expect {
	first_bar_depth = GuardRail.quad_rendering(first_bar, Pixels.of(500.0)).map_ok(
		|rendering| rendering.depth().to_metres(),
	)
	first_bar_depth == Ok(15.0)
}
expect GuardRail.quad_rendering(behind_bar, Pixels.of(500.0)).is_err()

# The first bar runs from one post to the next, between the bar's two heights.
expect first_bar.corners.low_start.forward.to_metres() == 10.0
expect first_bar.corners.low_end.forward.to_metres() == 20.0
expect first_bar.corners.high_end.forward.to_metres() == 20.0
expect first_bar.corners.high_start.forward.to_metres() == 10.0
expect first_bar.corners.low_start.height.to_metres() == 0.45
expect first_bar.corners.low_end.height.to_metres() == 0.45
expect first_bar.corners.high_end.height.to_metres() == 0.55
expect first_bar.corners.high_start.height.to_metres() == 0.55

# A post is square to the path, and stands from the ground to the bar's top.
straight_post : GuardRail.RailQuad
straight_post = first_post(straight_points)

expect straight_post.corners.low_start.forward.to_metres() == 9.99
expect straight_post.corners.low_end.forward.to_metres() == 10.01
expect straight_post.corners.high_end.forward.to_metres() == 10.01
expect straight_post.corners.high_start.forward.to_metres() == 9.99
expect straight_post.corners.low_start.height.to_metres() == 0.0
expect straight_post.corners.high_end.height.to_metres() == 0.55
expect straight_post.corners.low_start.right.to_metres() == 0.0
expect straight_post.corners.low_end.right.to_metres() == 0.0

diagonal_post : GuardRail.RailQuad
diagonal_post = first_post([
	{ right: Distance.metres(0.0), forward: Distance.metres(10.0) },
	{ right: Distance.metres(30.0), forward: Distance.metres(50.0) },
])

expect diagonal_post.corners.low_start.right.to_metres() == -0.006
expect diagonal_post.corners.low_end.right.to_metres() == 0.006
expect diagonal_post.corners.low_start.forward.to_metres() == 9.992
expect diagonal_post.corners.low_end.forward.to_metres() == 10.008

doubled_points : List(RiderView.RiderPoint)
doubled_points = [
	{ right: Distance.metres(0.0), forward: Distance.metres(10.0) },
	{ right: Distance.metres(0.0), forward: Distance.metres(10.0) },
]

doubled_post : GuardRail.RailQuad
doubled_post = first_post(doubled_points)

# A path that goes nowhere keeps its posts, each with no width.
expect GuardRail.quads_along(doubled_points).len() == 3
expect doubled_post.corners.low_start.right.to_metres() == 0.0
expect doubled_post.corners.low_end.right.to_metres() == 0.0
expect doubled_post.corners.low_start.forward.to_metres() == 10.0
expect doubled_post.corners.low_end.forward.to_metres() == 10.0
expect doubled_post.corners.high_end.height.to_metres() == 0.55

expect bars([{ right: Distance.metres(0.0), forward: Distance.metres(10.0) }]).len() == 0
