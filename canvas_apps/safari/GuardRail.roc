## A guard rail: a metal bar half a metre up, on thin posts, along a path
## on the ground. Each stretch of bar between two points of the path, and
## each post, is a flat quad, which the depth sort places among the frame's
## other things.
import Pixels
import Camera
import Distance
import Geom
import Picture
import Rendered
import lib.RgbColor
import lib.Shapes

GuardRail :: [].{

	## A quad of the rail: its corners and its colour.
	RailQuad : { corners : List(Geom.RaisedPoint), color : RgbColor }

	## The rail along `path_points`: the bars, then the posts.
	quads_along : List(Geom.RiderPoint) -> List(GuardRail.RailQuad)
	quads_along = |path_points| bars(path_points).concat(posts(path_points))

	## A quad as the frame draws it, at its own depth, unless it's wholly
	## behind the camera. A rail quad has no kind for `Pipeline` to ask, so it
	## renders itself.
	quad_rendering : GuardRail.RailQuad, Pixels -> Try(Rendered, [BehindCamera])
	quad_rendering = |quad, cam_focal|
		quad_shape(quad, cam_focal).map_ok(
			|shape| Rendered.of(quad_depth(quad), Picture.from_shapes([shape])),
		)
}

## How far ahead a quad is, for the depth sort: the mean of its corners'
## distances, summed from the first corner to the last, since a float
## sum's rounding depends on its order. It is negative for a quad behind
## the rider.
quad_depth : GuardRail.RailQuad -> Distance
quad_depth = |quad| {
	corners = quad.corners
	first = corners.first() ?? crash "GuardRail.quad_depth: a quad has corners"
	sum = corners.drop_first(1).fold(first.forward, |total, corner| total.plus(corner.forward))
	sum.divided_by(corners.len().to_f64())
}

## A quad on screen, cut at the camera's near plane, unless it's wholly
## behind the camera.
quad_shape : GuardRail.RailQuad, Pixels -> Try(Shapes.Shape, [BehindCamera])
quad_shape = |quad, cam_focal|
	Camera.clipped_polygon({ color: quad.color, corners: quad.corners }, cam_focal)

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
bars : List(Geom.RiderPoint) -> List(GuardRail.RailQuad)
bars = |path_points| path_points.map2(path_points.drop_first(1), |from, to| bar({ from, to }))

## A post at each point of `path_points`, turned to face along the path from
## the point before it to the point after it. A post at an end of the
## path takes its own point in place of the one it lacks.
posts : List(Geom.RiderPoint) -> List(GuardRail.RailQuad)
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
raised_point : Geom.RiderPoint, Distance -> Geom.RaisedPoint
raised_point = |point, height| { right: point.right, forward: point.forward, height }

## The bar from `from` to `to`, bottom edge first.
bar : { from : Geom.RiderPoint, to : Geom.RiderPoint } -> GuardRail.RailQuad
bar = |{ from, to }| {
	corners: [
		raised_point(from, bar_bottom),
		raised_point(to, bar_bottom),
		raised_point(to, bar_top),
		raised_point(from, bar_top),
	],
	color: rail_metal,
}

## The post at `at`, half its width to each side of it along the path from
## `previous` to `next`, from the ground to the top of the bar. Two points
## at one place give no direction, and the post then has no width.
post : Geom.RiderPoint, { previous : Geom.RiderPoint, next : Geom.RiderPoint } -> GuardRail.RailQuad
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
		corners: [
			raised_point(back, Distance.zero),
			raised_point(front, Distance.zero),
			raised_point(front, bar_top),
			raised_point(back, bar_top),
		],
		color: rail_post_metal,
	}
}

first_post : List(Geom.RiderPoint) -> GuardRail.RailQuad
first_post = |route_points| posts(route_points).first() ?? crash "a route of two points has posts"

corner_at : GuardRail.RailQuad, U64 -> Geom.RaisedPoint
corner_at = |quad, i| quad.corners.get(i) ?? crash "a quad has four corners"

straight_points : List(Geom.RiderPoint)
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
expect straight_quads.all(|quad| quad.corners.len() == 4)

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
expect first_bar.corners.map(|corner| corner.forward.to_metres()) == [10.0, 20.0, 20.0, 10.0]
expect first_bar.corners.map(|corner| corner.height.to_metres()) == [0.45, 0.45, 0.55, 0.55]

# A post is square to the path, and stands from the ground to the bar's top.
expect
	first_post(straight_points).corners.map(|corner| corner.forward.to_metres())
		== [9.99, 10.01, 10.01, 9.99]
expect corner_at(first_post(straight_points), 0).height.to_metres() == 0.0
expect corner_at(first_post(straight_points), 2).height.to_metres() == 0.55
expect corner_at(first_post(straight_points), 0).right.to_metres() == 0.0
expect corner_at(first_post(straight_points), 1).right.to_metres() == 0.0

diagonal_post : GuardRail.RailQuad
diagonal_post = first_post([
	{ right: Distance.metres(0.0), forward: Distance.metres(10.0) },
	{ right: Distance.metres(30.0), forward: Distance.metres(50.0) },
])

expect corner_at(diagonal_post, 0).right.to_metres() == -0.006
expect corner_at(diagonal_post, 1).right.to_metres() == 0.006
expect corner_at(diagonal_post, 0).forward.to_metres() == 9.992
expect corner_at(diagonal_post, 1).forward.to_metres() == 10.008

doubled_points : List(Geom.RiderPoint)
doubled_points = [
	{ right: Distance.metres(0.0), forward: Distance.metres(10.0) },
	{ right: Distance.metres(0.0), forward: Distance.metres(10.0) },
]

doubled_post : GuardRail.RailQuad
doubled_post = first_post(doubled_points)

# A path that goes nowhere keeps its posts, each with no width.
expect GuardRail.quads_along(doubled_points).len() == 3
expect corner_at(doubled_post, 0).right.to_metres() == 0.0
expect corner_at(doubled_post, 1).right.to_metres() == 0.0
expect corner_at(doubled_post, 0).forward.to_metres() == 10.0
expect corner_at(doubled_post, 1).forward.to_metres() == 10.0
expect corner_at(doubled_post, 2).height.to_metres() == 0.55

expect bars([{ right: Distance.metres(0.0), forward: Distance.metres(10.0) }]).len() == 0
