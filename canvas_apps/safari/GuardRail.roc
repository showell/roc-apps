## A guard rail: a metal bar half a metre up, on thin posts, along a path
## on the ground. Each stretch of bar between two points of the path, and
## each post, is a flat quad, which the depth sort places among the frame's
## other things.
import Pixels
import Camera
import Distance
import Geom
import Paint
import lib.Shapes

GuardRail :: [].{

	## A quad of the rail: its corners, its colour, and how far ahead it
	## is, the mean of its corners' distances, for the depth sort. That mean
	## is negative for a quad behind the rider.
	RailQuad : {
		corners : List(Geom.RaisedPoint),
		color : I64,
		forward : Distance,
	}

	rail_height : Distance
	rail_height = Distance.metres(0.5)

	rail_thickness : Distance
	rail_thickness = Distance.metres(0.1)

	rail_post_width : Distance
	rail_post_width = Distance.metres(0.02)

	rail_metal : I64
	rail_metal = 0xC2C7CF

	rail_post_metal : I64
	rail_post_metal = 0x9AA0A8

	## How many metres the rail runs on, a post a metre, past each end of
	## a bend.
	rail_runout : U32
	rail_runout = 10

	## The most quads one rail draws.
	max_rail_quads : U64
	max_rail_quads = 3072

	bar_top : Distance
	bar_top = rail_height.plus(rail_thickness.divided_by(2.0))

	bar_bot : Distance
	bar_bot = rail_height.minus(rail_thickness.divided_by(2.0))

	half_post : Distance
	half_post = rail_post_width.divided_by(2.0)

	## The rail along `path`: the bars, then the posts, at most
	## `max_rail_quads` quads in all. A path of fewer than two points has
	## no rail.
	quads_along : List(Geom.RiderPoint) -> List(GuardRail.RailQuad)
	quads_along = |path|
		if path.len() < 2 {
			[]
		} else {
			GuardRail.bars(path).concat(GuardRail.posts(path)).take_first(max_rail_quads)
		}

	## A stretch of bar between each two neighbouring points of `path`.
	bars : List(Geom.RiderPoint) -> List(GuardRail.RailQuad)
	bars = |path| path.map2(path.drop_first(1), |from, to| bar({ from, to }))

	## A post at each point of `path`, turned to face along the path from
	## the point before it to the point after it. A post at an end of the
	## path takes its own point in place of the one it lacks.
	posts : List(Geom.RiderPoint) -> List(GuardRail.RailQuad)
	posts = |path| {
		before = path.take_first(1).concat(path.drop_last(1))
		after = path.drop_first(1).concat(path.take_last(1))
		before.map3(
			path,
			after,
			|previous, at, next| post(at, { previous, next }),
		)
	}

	## A quad on screen, cut at the camera's near plane; a quad with fewer
	## than three corners left in front of the camera draws nothing.
	draw : GuardRail.RailQuad, Pixels -> List(Shapes.Shape)
	draw = |quad, cam_focal| {
		in_front = Geom.clip_near(quad.corners)
		if in_front.len() < 3 {
			[]
		} else {
			Paint.polygon(quad.color, Camera.project_all(in_front, cam_focal))
		}
	}
}

## A quad with these corners, in `color`.
rail_quad : List(Geom.RaisedPoint), I64 -> GuardRail.RailQuad
rail_quad = |corners, color| { corners, color, forward: mean_forward(corners) }

## The mean of the corners' distances ahead, summed from the first corner
## to the last; a float sum's rounding depends on its order.
mean_forward : List(Geom.RaisedPoint) -> Distance
mean_forward = |corners| {
	first = corners.first() ?? crash "GuardRail: a quad has corners"
	sum = corners.drop_first(1).fold(first.forward, |total, corner| total.plus(corner.forward))
	sum.divided_by(corners.len().to_f64())
}

## A point of the path, at `height` above the ground.
raised_point : Geom.RiderPoint, Distance -> Geom.RaisedPoint
raised_point = |point, height| { right: point.right, forward: point.forward, height }

## The bar from `from` to `to`, bottom edge first.
bar : { from : Geom.RiderPoint, to : Geom.RiderPoint } -> GuardRail.RailQuad
bar = |{ from, to }|
	rail_quad(
		[
			raised_point(from, GuardRail.bar_bot),
			raised_point(to, GuardRail.bar_bot),
			raised_point(to, GuardRail.bar_top),
			raised_point(from, GuardRail.bar_top),
		],
		GuardRail.rail_metal,
	)

## The post at `at`, half its width to each side of it along the path from
## `previous` to `next`, from the ground to the top of the bar. Two points
## at one place give no direction, and the post then has no width.
post : Geom.RiderPoint, { previous : Geom.RiderPoint, next : Geom.RiderPoint } -> GuardRail.RailQuad
post = |at, { previous, next }| {
	dr = next.right.minus(previous.right).to_metres()
	df = next.forward.minus(previous.forward).to_metres()
	length = (dr * dr + df * df).sqrt()
	run = if length.to_bits() == 0 {
		1.0
	} else {
		length
	}
	half_right = GuardRail.half_post.times(dr / run)
	half_forward = GuardRail.half_post.times(df / run)
	back = { right: at.right.minus(half_right), forward: at.forward.minus(half_forward) }
	front = { right: at.right.plus(half_right), forward: at.forward.plus(half_forward) }
	rail_quad(
		[
			raised_point(back, Distance.zero),
			raised_point(front, Distance.zero),
			raised_point(front, GuardRail.bar_top),
			raised_point(back, GuardRail.bar_top),
		],
		GuardRail.rail_post_metal,
	)
}

expect GuardRail.rail_height.to_metres() == 0.5
expect GuardRail.rail_thickness.to_metres() == 0.1
expect GuardRail.rail_post_width.to_metres() == 0.02
expect GuardRail.bar_top.to_metres() == 0.55
expect GuardRail.bar_bot.to_metres() == 0.45
expect GuardRail.half_post.to_metres() == 0.01

expect GuardRail.rail_metal == 0xC2C7CF
expect GuardRail.rail_post_metal == 0x9AA0A8
expect GuardRail.rail_runout == 10
expect GuardRail.max_rail_quads == 3072

first_post : List(Geom.RiderPoint) -> GuardRail.RailQuad
first_post = |route| GuardRail.posts(route).first() ?? crash "a route of two points has posts"

corner_at : GuardRail.RailQuad, U64 -> Geom.RaisedPoint
corner_at = |quad, i| quad.corners.get(i) ?? crash "a quad has four corners"

straight_route : List(Geom.RiderPoint)
straight_route = [
	{ right: Distance.metres(0.0), forward: Distance.metres(10.0) },
	{ right: Distance.metres(0.0), forward: Distance.metres(20.0) },
	{ right: Distance.metres(0.0), forward: Distance.metres(30.0) },
]

straight_rail : List(GuardRail.RailQuad)
straight_rail = GuardRail.quads_along(straight_route)

first_bar : GuardRail.RailQuad
first_bar = straight_rail.first() ?? crash "a straight route has a rail"

expect straight_rail.len() == 5
expect GuardRail.bars(straight_route).len() == 2
expect GuardRail.posts(straight_route).len() == 3
expect straight_rail.all(|quad| quad.corners.len() == 4)

expect
	straight_rail.map(|quad| quad.color)
		== [0xC2C7CF, 0xC2C7CF, 0x9AA0A8, 0x9AA0A8, 0x9AA0A8]
expect straight_rail.map(|quad| quad.forward.to_metres()) == [15.0, 25.0, 10.0, 20.0, 30.0]

# The first bar runs from one post to the next, between the bar's two heights.
expect first_bar.corners.map(|corner| corner.forward.to_metres()) == [10.0, 20.0, 20.0, 10.0]
expect first_bar.corners.map(|corner| corner.height.to_metres()) == [0.45, 0.45, 0.55, 0.55]

# A post is square to the path, and stands from the ground to the bar's top.
expect
	first_post(straight_route).corners.map(|corner| corner.forward.to_metres())
		== [9.99, 10.01, 10.01, 9.99]
expect corner_at(first_post(straight_route), 0).height.to_metres() == 0.0
expect corner_at(first_post(straight_route), 2).height.to_metres() == 0.55
expect corner_at(first_post(straight_route), 0).right.to_metres() == 0.0
expect corner_at(first_post(straight_route), 1).right.to_metres() == 0.0

diagonal_post : GuardRail.RailQuad
diagonal_post = first_post([
	{ right: Distance.metres(0.0), forward: Distance.metres(10.0) },
	{ right: Distance.metres(30.0), forward: Distance.metres(50.0) },
])

expect corner_at(diagonal_post, 0).right.to_metres() == -0.006
expect corner_at(diagonal_post, 1).right.to_metres() == 0.006
expect corner_at(diagonal_post, 0).forward.to_metres() == 9.992
expect corner_at(diagonal_post, 1).forward.to_metres() == 10.008

doubled_route : List(Geom.RiderPoint)
doubled_route = [
	{ right: Distance.metres(0.0), forward: Distance.metres(10.0) },
	{ right: Distance.metres(0.0), forward: Distance.metres(10.0) },
]

doubled_post : GuardRail.RailQuad
doubled_post = first_post(doubled_route)

# A path that goes nowhere keeps its posts, each with no width.
expect GuardRail.quads_along(doubled_route).len() == 3
expect corner_at(doubled_post, 0).right.to_metres() == 0.0
expect corner_at(doubled_post, 1).right.to_metres() == 0.0
expect corner_at(doubled_post, 0).forward.to_metres() == 10.0
expect corner_at(doubled_post, 1).forward.to_metres() == 10.0
expect corner_at(doubled_post, 2).height.to_metres() == 0.55

expect GuardRail.quads_along([]).len() == 0
expect GuardRail.quads_along([
	{ right: Distance.metres(0.0), forward: Distance.metres(10.0) },
]).len() == 0
expect GuardRail.bars([{ right: Distance.metres(0.0), forward: Distance.metres(10.0) }]).len() == 0
