## A conifer by the road: a trunk under eight tiers of foliage. A far tree's
## tiers are flat triangles on the screen. A near one's are cones seen from
## the rider: the outline of a ring of points round each tier's base and its
## apex, so the tiers fatten as the rider passes under them.
import Pixels
import Camera
import Distance
import Fraction
import Paint
import lib.Trig
import lib.Brush
import Screen
import lib.Shapes

TreeDraw :: [].{

	## A tree to draw, where it stands in the rider's view and how. Of the
	## nearest trees, the trunk's corners are rounded; the crown is cones
	## within the detail distance, and triangles beyond it. A tree in view is
	## ahead of the rider, so of its lengths only `right` can be negative.
	TreeInView : {
		right : Distance,
		forward : Distance,
		height : Distance,
		color : I64,
		cam_focal : Pixels,
		trunk : [RoundCorners, SharpCorners],
		crown : [Cones, Triangles],
		shade : Fraction,
	}

	## Where a tree stands on the screen, and how big it looks there.
	TreeOnScreen : {
		base_x : Pixels,
		base_y : Pixels,
		height_px : Pixels,
		crown_top_y : Pixels,
		foliage_px : Pixels,
		crown_half_width : Pixels,
	}

	## One tier of the crown: where its top and its bottom are, as fractions of
	## the foliage down from the crown's top, and how wide its bottom is, as a
	## fraction of the crown's width.
	Tier : {
		top : Fraction,
		bottom : Fraction,
		width : Fraction,
	}

	## The tiers, top to bottom. Each overlaps the next.
	tiers : List(TreeDraw.Tier)
	tiers = [
		{
			top: Fraction.of(0.0),
			bottom: Fraction.of(0.3),
			width: Fraction.of(0.35),
		},
		{
			top: Fraction.of(0.1),
			bottom: Fraction.of(0.4),
			width: Fraction.of(0.44),
		},
		{
			top: Fraction.of(0.2),
			bottom: Fraction.of(0.5),
			width: Fraction.of(0.53),
		},
		{
			top: Fraction.of(0.3),
			bottom: Fraction.of(0.6),
			width: Fraction.of(0.63),
		},
		{
			top: Fraction.of(0.4),
			bottom: Fraction.of(0.7),
			width: Fraction.of(0.72),
		},
		{
			top: Fraction.of(0.5),
			bottom: Fraction.of(0.8),
			width: Fraction.of(0.81),
		},
		{
			top: Fraction.of(0.6),
			bottom: Fraction.of(0.9),
			width: Fraction.of(0.91),
		},
		{
			top: Fraction.of(0.7),
			bottom: Fraction.of(1.0),
			width: Fraction.of(1.0),
		},
	]

	trunk_color : I64
	trunk_color = 0x5A3E22

	## How much of the tree's height is trunk below the crown.
	visible_trunk : Fraction
	visible_trunk = Fraction.of(0.44)

	## The crown's height, and its widest half-width, as fractions of the
	## tree's height.
	crown_height : Fraction
	crown_height = Fraction.of(0.648)

	crown_width : Fraction
	crown_width = Fraction.of(0.288)

	## A cone whose near edge is closer than this is drawn as a triangle: the
	## camera would see it from inside.
	min_cone_forward : Distance
	min_cone_forward = Distance.metres(0.4)

	## A cone's base is a ring of this many points.
	ring_n : I64
	ring_n = 16

	## The tree on the screen: its trunk, then its tiers top to bottom. A tree
	## less than a pixel tall isn't drawn.
	draw : TreeDraw.TreeInView -> List(Shapes.Shape)
	draw = |tree| {
		seen = on_screen({
			right: tree.right,
			forward: tree.forward,
			height: tree.height,
			cam_focal: tree.cam_focal,
		})
		if seen.height_px < Pixels.of(1.0) {
			[]
		} else {
			draw_trunk(seen, tree.trunk).concat(
				tiers.join_map(|tier| draw_tier(tree, { seen, tier })),
			)
		}
	}

	## Where a tree `height` tall, standing `right` and `forward` of the
	## rider, is on the screen.
	on_screen : {
		right : Distance,
		forward : Distance,
		height : Distance,
		cam_focal : Pixels,
	} -> TreeDraw.TreeOnScreen
	on_screen = |{ right, forward, height, cam_focal }| {
		base = Camera.project({ right, forward, height: Distance.zero }, cam_focal)
		top = Camera.project({ right, forward, height }, cam_focal)
		height_px = base.y.minus(top.y)
		foliage_px = height_px.times(crown_height.to_f64())
		crown_bottom_y = base.y.minus(height_px.times(visible_trunk.to_f64()))
		{
			base_x: base.x,
			base_y: base.y,
			height_px,
			crown_top_y: crown_bottom_y.minus(foliage_px),
			foliage_px,
			crown_half_width: height_px.times(crown_width.to_f64()),
		}
	}

	draw_trunk : TreeDraw.TreeOnScreen, [RoundCorners, SharpCorners] -> List(Shapes.Shape)
	draw_trunk = |seen, corners| {
		width = if seen.height_px.times(0.08) > Pixels.of(1.0) {
			seen.height_px.times(0.08)
		} else {
			Pixels.of(1.0)
		}
		below_crown = seen.height_px.times(visible_trunk.to_f64())
		height = below_crown.plus(seen.height_px.times(0.05))
		left = seen.base_x.minus(width.divided_by(2.0))
		top = seen.base_y.minus(height)
		points = [
			{ x: left, y: top },
			{ x: left.plus(width), y: top },
			{ x: left.plus(width), y: seen.base_y },
			{ x: left, y: seen.base_y },
		]
		match corners {
			RoundCorners => Paint.round_polygon(
				points,
				{ fill_color: trunk_color, round_strength: Fraction.whole },
			)
			SharpCorners => Paint.polygon(trunk_color, points)
		}
	}

	## A tier as a flat triangle: its apex at the tier's top, its base across
	## its bottom.
	tier_triangle : TreeDraw.TreeOnScreen,
	{
		tier : TreeDraw.Tier,
		color : I64,
	} -> List(Shapes.Shape)
	tier_triangle = |seen, { tier, color }| {
		bottom_y = seen.crown_top_y.plus(seen.foliage_px.times(tier.bottom.to_f64()))
		top_y = seen.crown_top_y.plus(seen.foliage_px.times(tier.top.to_f64()))
		half_base = seen.crown_half_width.times(tier.width.to_f64())
		Paint.polygon(
			color,
			[
				{ x: seen.base_x, y: top_y },
				{ x: seen.base_x.plus(half_base), y: bottom_y },
				{ x: seen.base_x.minus(half_base), y: bottom_y },
			],
		)
	}

	## The convex hull of `points`, going round from the leftmost: Andrew's
	## monotone chain, its lower chain and then its upper. Fewer than three
	## points are their own hull.
	convex_hull : List(Screen.Point) -> List(Screen.Point)
	convex_hull = |points|
		if points.len() < 3 {
			points
		} else {
			sorted = sorted_points(points)
			lower = sorted.fold([], |hull, point| trim_hull(hull, point).append(point))
			upper = sorted.fold_rev([], |point, hull| trim_hull(hull, point).append(point))
			lower.drop_last(1).concat(upper.drop_last(1))
		}

	## The points left to right, and top to bottom where they share an x. Each
	## goes in after the ones it doesn't come before, so points that tie keep
	## their order.
	sorted_points : List(Screen.Point) -> List(Screen.Point)
	sorted_points = |points|
		points.fold(
			[],
			|sorted, point|
				match sorted.find_first_index(|placed| is_before(point, placed)) {
					Ok(at) => [sorted.take_first(at), [point], sorted.drop_first(at)].join()
					Err(NotFound) => sorted.append(point)
				},
		)
}

## Whether `a` comes before `b`: left of it, or above it at the same x.
is_before : Screen.Point, Screen.Point -> Bool
is_before = |a, b| a.x < b.x or (a.x == b.x and a.y < b.y)

## The hull with its last points taken off while they don't turn left on the
## way to `point`.
trim_hull : List(Screen.Point), Screen.Point -> List(Screen.Point)
trim_hull = |hull, point|
	match hull {
		[.., a, b] => {
			edge_x = b.x.minus(a.x).to_f64()
			edge_y = b.y.minus(a.y).to_f64()
			reach_x = point.x.minus(a.x).to_f64()
			reach_y = point.y.minus(a.y).to_f64()
			turn = edge_x * reach_y - edge_y * reach_x
			if turn <= 0.0 {
				trim_hull(hull.drop_last(1), point)
			} else {
				hull
			}
		}
		_ => hull
	}

## The angles of a cone's ring, from 0 round a whole turn. Each is the one
## before plus a step, not a multiple of the step: the two round differently.
ring_angles : List(F64)
ring_angles = {
	step = Trig.two_pi / TreeDraw.ring_n.to_f64()
	walked = List.repeat(step, (TreeDraw.ring_n - 1).to_u64_wrap()).fold(
		{ angle: 0.0, angles: [0.0] },
		|so_far, turn| {
			angle = so_far.angle + turn
			{ angle, angles: so_far.angles.append(angle) }
		},
	)
	walked.angles
}

## A tier, as a cone when the tree is near and the cone is in front of the
## camera, else as a triangle.
draw_tier : TreeDraw.TreeInView,
{
	seen : TreeDraw.TreeOnScreen,
	tier : TreeDraw.Tier,
} -> List(Shapes.Shape)
draw_tier = |tree, { seen, tier }| {
	cone_radius = tree.height.times(TreeDraw.crown_width.to_f64() * tier.width.to_f64())
	match tree.crown {
		Cones if tree.forward.minus(cone_radius) < TreeDraw.min_cone_forward =>
			TreeDraw.tier_triangle(seen, { tier, color: tree.color })
		Cones => tier_cone(tree, { tier, cone_radius })
		Triangles => TreeDraw.tier_triangle(seen, { tier, color: tree.color })
	}
}

## A tier as a cone: the outline of the ring round its base and its apex.
tier_cone : TreeDraw.TreeInView,
{
	tier : TreeDraw.Tier,
	cone_radius : Distance,
} -> List(Shapes.Shape)
tier_cone = |tree, { tier, cone_radius }| {
	trunk = TreeDraw.visible_trunk.to_f64()
	crown = TreeDraw.crown_height.to_f64()
	bottom = tier.bottom.to_f64()
	top = tier.top.to_f64()
	base_height = tree.height.times(trunk + crown * (1.0 - bottom))
	apex_height = tree.height.times(trunk + crown * (1.0 - top))
	apex = Camera.project(
		{
			right: tree.right,
			forward: tree.forward,
			height: apex_height,
		},
		tree.cam_focal,
	)
	ring = ring_angles.map(
		|angle| {
			on_ring = {
				right: tree.right.plus(cone_radius.times(Trig.r_cos(angle))),
				forward: tree.forward.plus(cone_radius.times(Trig.r_sin(angle))),
				height: base_height,
			}
			Camera.project(on_ring, tree.cam_focal)
		},
	)
	hull = TreeDraw.convex_hull(ring.append(apex))
	if hull.len() < 3 {
		[]
	} else {
		Paint.round_polygon(hull, { fill_color: tree.color, round_strength: tree.shade })
	}
}

expect TreeDraw.tiers.map(|tier| tier.top.to_f64()) == [0.0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7]
expect TreeDraw.tiers.map(|tier| tier.bottom.to_f64()) == [0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1.0]
expect TreeDraw.tiers.map(|tier| tier.width.to_f64()) == [
	0.35,
	0.44,
	0.53,
	0.63,
	0.72,
	0.81,
	0.91,
	1.0,
]

expect TreeDraw.tiers.len() == 8
expect TreeDraw.ring_n == 16
expect TreeDraw.trunk_color == 0x5A3E22

expect TreeDraw.visible_trunk.to_f64() == 0.44
expect TreeDraw.crown_height.to_f64() == 0.648
expect TreeDraw.crown_width.to_f64() == 0.288
expect TreeDraw.min_cone_forward.to_metres() == 0.4

sample_on_screen : TreeDraw.TreeOnScreen
sample_on_screen = TreeDraw.on_screen({
	right: Distance.metres(0.0),
	forward: Distance.metres(2.0),
	height: Distance.metres(4.0),
	cam_focal: Pixels.of(500.0),
})

expect sample_on_screen.base_x.to_f64() == 480.0
expect sample_on_screen.base_y.to_f64() == 600.0
expect sample_on_screen.height_px.to_f64() == 1000.0
expect sample_on_screen.foliage_px.to_f64() == 648.0
expect sample_on_screen.crown_top_y.to_f64() == -488.0
expect sample_on_screen.crown_half_width.to_f64() == 288.0

expect
	TreeDraw.draw_trunk(sample_on_screen, SharpCorners)
		== [
			Poly({
				pts: [440.0, 110.0, 520.0, 110.0, 520.0, 600.0, 440.0, 600.0],
				fill: Flat(Brush.opaque(0x5A3E22)),
			}),
		]

# A round trunk is the same colour, shaded across its width.
expect
	TreeDraw.draw_trunk(sample_on_screen, RoundCorners)
		== [
			Poly({
				pts: [440.0, 110.0, 520.0, 110.0, 520.0, 600.0, 440.0, 600.0],
				fill: Span({
					edge: Brush.opaque(0x362514),
					middle: Brush.opaque(0x714E2B),
					x0: 440.0,
					x1: 520.0,
				}),
			}),
		]

expect {
	corners_of = |tier|
		match TreeDraw.tier_triangle(sample_on_screen, { tier, color: 7 }) {
			[Poly(polygon)] => polygon.pts
			_ => crash "a tier is one polygon"
		}
	top_tier = TreeDraw.tiers.first() ?? crash "a tree has tiers"
	bottom_tier = TreeDraw.tiers.last() ?? crash "a tree has tiers"
	[
		(top_tier, [480.0, -488.0, 580.8, -293.6, 379.2, -293.6]),
		(bottom_tier, [480.0, -34.4, 768.0, 160.0, 192.0, 160.0]),
	].all(
		|(tier, want)| {
			got = corners_of(tier)
			got.len() == want.len() and got.map2(
				want,
				|x, y| (x - y).abs(),
			).all(|miss| miss <= 0.000000001)
		},
	)
}

# Of two points at one x the higher comes first, and of two equal points neither does.
expect is_before(Screen.point(1.0, 9.0), Screen.point(2.0, 0.0))
expect !is_before(Screen.point(2.0, 0.0), Screen.point(1.0, 9.0))
expect is_before(Screen.point(1.0, 2.0), Screen.point(1.0, 3.0))
expect !is_before(Screen.point(1.0, 3.0), Screen.point(1.0, 2.0))
expect !is_before(Screen.point(1.0, 2.0), Screen.point(1.0, 2.0))

hull_points : List(Screen.Point) -> List(F64)
hull_points = |points| Paint.flatten_screen(TreeDraw.convex_hull(points))

square_with_inside_points : List(Screen.Point)
square_with_inside_points = [
	Screen.point(0.0, 0.0),
	Screen.point(4.0, 0.0),
	Screen.point(4.0, 4.0),
	Screen.point(0.0, 4.0),
	Screen.point(2.0, 2.0),
	Screen.point(2.0, 0.0),
]

hull_triangle : List(Screen.Point)
hull_triangle = [
	Screen.point(0.0, 0.0),
	Screen.point(4.0, 0.0),
	Screen.point(2.0, 3.0),
]

hull_line : List(Screen.Point)
hull_line = [
	Screen.point(0.0, 0.0),
	Screen.point(1.0, 1.0),
	Screen.point(2.0, 2.0),
	Screen.point(3.0, 3.0),
]

hull_pair : List(Screen.Point)
hull_pair = [Screen.point(1.0, 2.0), Screen.point(0.0, 0.0)]

hull_with_a_repeat : List(Screen.Point)
hull_with_a_repeat = [
	Screen.point(0.0, 0.0),
	Screen.point(0.0, 0.0),
	Screen.point(4.0, 0.0),
	Screen.point(4.0, 4.0),
]

expect hull_points(square_with_inside_points) == [0.0, 0.0, 4.0, 0.0, 4.0, 4.0, 0.0, 4.0]
expect hull_points(hull_triangle) == [0.0, 0.0, 4.0, 0.0, 2.0, 3.0]
expect hull_points(hull_line) == [0.0, 0.0, 3.0, 3.0]
expect hull_points(hull_pair) == [1.0, 2.0, 0.0, 0.0]
expect hull_points([Screen.point(9.0, 9.0)]) == [9.0, 9.0]
expect hull_points([]) == []
expect hull_points(hull_with_a_repeat) == [0.0, 0.0, 4.0, 0.0, 4.0, 4.0]

expect TreeDraw.convex_hull(square_with_inside_points).len() == 4
expect TreeDraw.convex_hull(hull_triangle).len() == 3
expect TreeDraw.convex_hull(hull_line).len() == 2
expect TreeDraw.convex_hull(hull_pair).len() == 2
expect TreeDraw.convex_hull(hull_with_a_repeat).len() == 3

expect
	Paint.flatten_screen(TreeDraw.sorted_points(square_with_inside_points))
		== [0.0, 0.0, 0.0, 4.0, 2.0, 0.0, 2.0, 2.0, 4.0, 0.0, 4.0, 4.0]
