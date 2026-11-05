## A guard rail: a metal bar half a metre up, on thin posts, along a path
## on the ground. Each stretch of bar between two points of the path, and
## each post, is a flat quad, which the depth sort places among the frame's
## other things.
import Camera
import lib.DeviceMath
import Geom
import Paint
import lib.Shapes

GuardRail :: [].{

	## A quad of the rail: its corners, its colour, and how far ahead it
	## is, the mean of its corners' distances, for the depth sort.
	RailPoly : {
		corners : List(Geom.SpacePoint),
		color : I64,
		forward : F64,
	}

	rail_height : F64
	rail_height = 0.5

	rail_thickness : F64
	rail_thickness = 0.1

	rail_post_width : F64
	rail_post_width = 0.02

	rail_metal : I64
	rail_metal = 0xC2C7CF

	rail_post_metal : I64
	rail_post_metal = 0x9AA0A8

	## How many metres the rail runs on, a post a metre, past each end of
	## a bend.
	rail_runout : U32
	rail_runout = 10

	## The most quads one rail draws.
	max_rail_polys : U64
	max_rail_polys = 3072

	bar_top : F64
	bar_top = (rail_height + (rail_thickness / 2.0))

	bar_bot : F64
	bar_bot = (rail_height - (rail_thickness / 2.0))

	half_post : F64
	half_post = (rail_post_width / 2.0)

	## The rail along `path`: the bars, then the posts, at most
	## `max_rail_polys` quads in all. A path of fewer than two points has
	## no rail.
	quads_along : List(Geom.RiderPoint) -> List(GuardRail.RailPoly)
	quads_along = |path|
		if path.len() < 2 {
			[]
		} else {
			GuardRail.bars(path).concat(GuardRail.posts(path)).take_first(max_rail_polys)
		}

	## A stretch of bar between each two neighbouring points of `path`.
	bars : List(Geom.RiderPoint) -> List(GuardRail.RailPoly)
	bars = |path| path.map2(path.drop_first(1), |from, to| bar({ from, to }))

	## A post at each point of `path`, turned to face along the path from
	## the point before it to the point after it. A post at an end of the
	## path takes its own point in place of the one it lacks.
	posts : List(Geom.RiderPoint) -> List(GuardRail.RailPoly)
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
	draw : GuardRail.RailPoly, F64 -> List(Shapes.Shape)
	draw = |quad, cam_focal| {
		in_front = Geom.clip_near(quad.corners)
		if in_front.len() < 3 {
			[]
		} else {
			Paint.push_poly(quad.color, Camera.project_all(in_front, cam_focal))
		}
	}
}

## A quad with these corners, in `color`.
rail_quad : List(Geom.SpacePoint), I64 -> GuardRail.RailPoly
rail_quad = |corners, color| {
	corners,
	color,
	forward: mean_forward(corners),
}

## The mean of the corners' distances ahead, summed from the first corner
## to the last; a float sum's rounding depends on its order.
mean_forward : List(Geom.SpacePoint) -> F64
mean_forward = |corners| {
	first = corners.first() ?? crash "GuardRail: a quad has corners"
	sum = corners.drop_first(1).fold(first.forward, |total, corner| total + corner.forward)
	sum / corners.len().to_f64()
}

## A point of the path, at `height` above the ground.
at_height : Geom.RiderPoint, F64 -> Geom.SpacePoint
at_height = |point, height| {
	right: point.right,
	forward: point.forward,
	height,
}

## The bar from `from` to `to`, bottom edge first.
bar : { from : Geom.RiderPoint, to : Geom.RiderPoint } -> GuardRail.RailPoly
bar = |{ from, to }|
	rail_quad(
		[
			at_height(from, GuardRail.bar_bot),
			at_height(to, GuardRail.bar_bot),
			at_height(to, GuardRail.bar_top),
			at_height(from, GuardRail.bar_top),
		],
		GuardRail.rail_metal,
	)

## The post at `at`, half its width to each side of it along the path from
## `previous` to `next`, from the ground to the top of the bar. Two points
## at one place give no direction, and the post then has no width.
post : Geom.RiderPoint, { previous : Geom.RiderPoint, next : Geom.RiderPoint } -> GuardRail.RailPoly
post = |at, { previous, next }| {
	dr = (next.right - previous.right)
	df = (next.forward - previous.forward)
	length = DeviceMath.real_sqrt(((dr * dr) + (df * df)))
	run = if (length.to_bits() == 0) 1.0 else length
	half_right = ((dr / run) * GuardRail.half_post)
	half_forward = ((df / run) * GuardRail.half_post)
	back = { right: (at.right - half_right), forward: (at.forward - half_forward) }
	front = { right: (at.right + half_right), forward: (at.forward + half_forward) }
	rail_quad(
		[
			at_height(back, 0.0),
			at_height(front, 0.0),
			at_height(front, GuardRail.bar_top),
			at_height(back, GuardRail.bar_top),
		],
		GuardRail.rail_post_metal,
	)
}

expect GuardRail.rail_height == 0.5
expect GuardRail.rail_thickness == 0.1
expect GuardRail.rail_post_width == 0.02
expect GuardRail.bar_top == 0.55
expect GuardRail.bar_bot == 0.45
expect GuardRail.half_post == 0.01

expect GuardRail.rail_metal == 12765135
expect GuardRail.rail_post_metal == 10133672
expect GuardRail.rail_runout == 10
expect GuardRail.max_rail_polys == 3072

first_post : List(Geom.RiderPoint) -> GuardRail.RailPoly
first_post = |route| GuardRail.posts(route).first() ?? crash "a route of two points has posts"

corner_at : GuardRail.RailPoly, U64 -> Geom.SpacePoint
corner_at = |quad, i| quad.corners.get(i) ?? crash "a quad has four corners"

straight_route : List(Geom.RiderPoint)
straight_route = [
	{ right: 0.0, forward: 10.0 },
	{ right: 0.0, forward: 20.0 },
	{ right: 0.0, forward: 30.0 },
]

straight_rail : List(GuardRail.RailPoly)
straight_rail = GuardRail.quads_along(straight_route)

first_bar : GuardRail.RailPoly
first_bar = straight_rail.first() ?? crash "a straight route has a rail"

expect straight_rail.len() == 5
expect GuardRail.bars(straight_route).len() == 2
expect GuardRail.posts(straight_route).len() == 3
expect straight_rail.all(|quad| quad.corners.len() == 4)

expect
	straight_rail.map(|quad| quad.color)
		== [12765135, 12765135, 10133672, 10133672, 10133672]
expect straight_rail.map(|quad| quad.forward) == [15.0, 25.0, 10.0, 20.0, 30.0]

# The first bar runs from one post to the next, between the bar's two heights.
expect first_bar.corners.map(|corner| corner.forward) == [10.0, 20.0, 20.0, 10.0]
expect first_bar.corners.map(|corner| corner.height) == [0.45, 0.45, 0.55, 0.55]

# A post is square to the path, and stands from the ground to the bar's top.
expect first_post(straight_route).corners.map(|corner| corner.forward) == [9.99, 10.01, 10.01, 9.99]
expect corner_at(first_post(straight_route), 0).height == 0.0
expect corner_at(first_post(straight_route), 2).height == 0.55
expect corner_at(first_post(straight_route), 0).right == 0.0
expect corner_at(first_post(straight_route), 1).right == 0.0

diagonal_post : GuardRail.RailPoly
diagonal_post = first_post([{ right: 0.0, forward: 10.0 }, { right: 30.0, forward: 50.0 }])

expect corner_at(diagonal_post, 0).right == -0.006
expect corner_at(diagonal_post, 1).right == 0.006
expect corner_at(diagonal_post, 0).forward == 9.992
expect corner_at(diagonal_post, 1).forward == 10.008

doubled_route : List(Geom.RiderPoint)
doubled_route = [{ right: 0.0, forward: 10.0 }, { right: 0.0, forward: 10.0 }]

doubled_post : GuardRail.RailPoly
doubled_post = first_post(doubled_route)

# A path that goes nowhere keeps its posts, each with no width.
expect GuardRail.quads_along(doubled_route).len() == 3
expect corner_at(doubled_post, 0).right == 0.0
expect corner_at(doubled_post, 1).right == 0.0
expect corner_at(doubled_post, 0).forward == 10.0
expect corner_at(doubled_post, 1).forward == 10.0
expect corner_at(doubled_post, 2).height == 0.55

expect GuardRail.quads_along([]).len() == 0
expect GuardRail.quads_along([{ right: 0.0, forward: 10.0 }]).len() == 0
expect GuardRail.bars([{ right: 0.0, forward: 10.0 }]).len() == 0
