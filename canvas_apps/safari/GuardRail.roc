## A guard rail: a metal bar half a metre up, on thin posts, along a path
## on the ground. Each stretch of bar between two points of the path, and
## each post, is a flat quad, which the depth sort places among the frame's
## other things.
import Camera
import lib.DeviceMath
import Geom
import Paint

GuardRail :: [].{

	## A quad of the rail: its corners, its colour, and how far ahead it
	## is, the mean of its corners' distances, for the depth sort.
	RailPoly : { corners : List(Geom.Vec3), color : I64, forward : F64 }

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
	rail_runout : I64
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
	quads_along : List(Geom.RiderPt) -> List(GuardRail.RailPoly)
	quads_along = |path|
		if path.len() < 2 {
			[]
		} else {
			GuardRail.bars(path).concat(GuardRail.posts(path)).take_first(max_rail_polys)
		}

	## A stretch of bar between each two neighbouring points of `path`.
	bars : List(Geom.RiderPt) -> List(GuardRail.RailPoly)
	bars = |path| List.map2(path, path.drop_first(1), |from, to| bar({ from, to }))

	## A post at each point of `path`, turned to face along the path from
	## the point before it to the point after it. A post at an end of the
	## path takes its own point in place of the one it lacks.
	posts : List(Geom.RiderPt) -> List(GuardRail.RailPoly)
	posts = |path| {
		before = path.take_first(1).concat(path.drop_last(1))
		after = path.drop_first(1).concat(path.take_last(1))
		List.map3(before, path, after, |previous, at, next| post(at, { previous, next }))
	}

	## A quad on screen, cut at the camera's near plane; a quad with fewer
	## than three corners left in front of the camera draws nothing.
	draw : GuardRail.RailPoly, { cam_focal : F64, view_w : F64 } -> List(Paint.DrawCmd)
	draw = |quad, { cam_focal, view_w }| {
		in_front = Geom.clip_near(quad.corners)
		if in_front.len() < 3 {
			[]
		} else {
			Paint.push_poly(quad.color, Camera.project_all(in_front, { cam_focal, view_w }))
		}
	}
}

## A quad with these corners, in `color`.
rail_quad : List(Geom.Vec3), I64 -> GuardRail.RailPoly
rail_quad = |corners, color| { corners, color, forward: mean_forward(corners) }

## The mean of the corners' distances ahead, summed from the first corner
## to the last; a float sum's rounding depends on its order.
mean_forward : List(Geom.Vec3) -> F64
mean_forward = |corners| {
	first = corners.first() ?? crash "GuardRail: a quad has corners"
	sum = corners.drop_first(1).fold(first.forward, |total, corner| total + corner.forward)
	sum / corners.len().to_f64()
}

## A point of the path, at `height` above the ground.
at_height : Geom.RiderPt, F64 -> Geom.Vec3
at_height = |point, height| { right: point.right, forward: point.forward, height }

## The bar from `from` to `to`, bottom edge first.
bar : { from : Geom.RiderPt, to : Geom.RiderPt } -> GuardRail.RailPoly
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
post : Geom.RiderPt, { previous : Geom.RiderPt, next : Geom.RiderPt } -> GuardRail.RailPoly
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
