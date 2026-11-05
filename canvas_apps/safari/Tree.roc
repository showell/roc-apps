## A conifer by the road: a trunk under eight tiers of foliage. A far tree's
## tiers are flat triangles on the screen. A near one's are cones seen from
## the rider: the outline of a ring of points round each tier's base and its
## apex, so the tiers fatten as the rider passes under them.
import Camera
import Paint
import lib.Trig
import Screen

Tree :: [].{

	## A tree to draw, where it stands in the rider's view and how. Of the
	## nearest trees, the trunk's corners are rounded; the crown is cones
	## within the detail distance, and triangles beyond it.
	TreeInView : {
		right : F64,
		forward : F64,
		height : F64,
		color : I64,
		cam_focal : F64,
		view_w : F64,
		trunk : [RoundCorners, SharpCorners],
		crown : [Cones, Triangles],
		shade : F64,
	}

	## Where a tree stands on the screen, and how big it looks there.
	Outline : {
		base_x : F64,
		base_y : F64,
		height_px : F64,
		crown_top_y : F64,
		foliage_px : F64,
		crown_half_width : F64,
	}

	## One tier of the crown: where its top and its bottom are, as fractions of
	## the foliage down from the crown's top, and how wide its bottom is, as a
	## fraction of the crown's width.
	Tier : {
		top : F64,
		bottom : F64,
		width : F64,
	}

	## The tiers, top to bottom. Each overlaps the next.
	tiers : List(Tree.Tier)
	tiers = [
		{
			top: 0.0,
			bottom: 0.3,
			width: 0.35,
		},
		{
			top: 0.1,
			bottom: 0.4,
			width: 0.44,
		},
		{
			top: 0.2,
			bottom: 0.5,
			width: 0.53,
		},
		{
			top: 0.3,
			bottom: 0.6,
			width: 0.63,
		},
		{
			top: 0.4,
			bottom: 0.7,
			width: 0.72,
		},
		{
			top: 0.5,
			bottom: 0.8,
			width: 0.81,
		},
		{
			top: 0.6,
			bottom: 0.9,
			width: 0.91,
		},
		{
			top: 0.7,
			bottom: 1.0,
			width: 1.0,
		},
	]

	trunk_color : I64
	trunk_color = 0x5A3E22

	## How much of the tree's height is trunk below the crown.
	visible_trunk : F64
	visible_trunk = 0.44

	## The crown's height, and its widest half-width, as fractions of the
	## tree's height.
	crown_height : F64
	crown_height = 0.648

	crown_width : F64
	crown_width = 0.288

	## A cone whose near edge is closer than this, in metres, is drawn as a
	## triangle: the camera would see it from inside.
	min_cone_forward : F64
	min_cone_forward = 0.4

	## A cone's base is a ring of this many points.
	ring_n : I64
	ring_n = 16

	## The tree on the screen: its trunk, then its tiers top to bottom. A tree
	## less than a pixel tall isn't drawn.
	draw : Tree.TreeInView -> List(Paint.DrawCmd)
	draw = |tree| {
		seen = outline({
			right: tree.right,
			forward: tree.forward,
			height: tree.height,
			cam_focal: tree.cam_focal,
			view_w: tree.view_w,
		})
		if seen.height_px < 1.0 {
			[]
		} else {
			List.concat(
				draw_trunk(seen, tree.trunk),
				tiers.join_map(|tier| draw_tier(tree, { seen, tier })),
			)
		}
	}

	## Where a tree of `height` metres, standing `right` and `forward` of the
	## rider, is on the screen.
	outline : {
		right : F64,
		forward : F64,
		height : F64,
		cam_focal : F64,
		view_w : F64,
	} -> Tree.Outline
	outline = |
		{
			right,
			forward,
			height,
			cam_focal,
			view_w,
		},
	| {
		base = Camera.project(
			{
				right,
				forward,
				height: 0.0,
			},
			{ cam_focal, view_w },
		)
		top = Camera.project(
			{
				right,
				forward,
				height,
			},
			{ cam_focal, view_w },
		)
		height_px = (base.y - top.y)
		foliage_px = (height_px * crown_height)
		crown_bottom_y = (base.y - (height_px * visible_trunk))
		{
			base_x: base.x,
			base_y: base.y,
			height_px,
			crown_top_y: (crown_bottom_y - foliage_px),
			foliage_px,
			crown_half_width: (height_px * crown_width),
		}
	}

	draw_trunk : Tree.Outline, [RoundCorners, SharpCorners] -> List(Paint.DrawCmd)
	draw_trunk = |seen, corners| {
		width = if ((seen.height_px * 0.08) > 1.0) (seen.height_px * 0.08) else 1.0
		height = ((seen.height_px * visible_trunk) + (seen.height_px * 0.05))
		left = (seen.base_x - (width / 2.0))
		top = (seen.base_y - height)
		points = [
			{ x: left, y: top },
			{ x: (left + width), y: top },
			{ x: (left + width), y: seen.base_y },
			{ x: left, y: seen.base_y },
		]
		match corners {
			RoundCorners => Paint.push_round_poly(
				points,
				{ fill_color: trunk_color, round_strength: 1.0 },
			)
			SharpCorners => Paint.push_poly(trunk_color, points)
		}
	}

	## A tier as a flat triangle: its apex at the tier's top, its base across
	## its bottom.
	tier_triangle : Tree.Outline, { tier : Tree.Tier, color : I64 } -> List(Paint.DrawCmd)
	tier_triangle = |seen, { tier, color }| {
		bottom_y = (seen.crown_top_y + (seen.foliage_px * tier.bottom))
		Paint.push_poly(
			color,
			[
				{ x: seen.base_x, y: (seen.crown_top_y + (seen.foliage_px * tier.top)) },
				{ x: (seen.base_x + (seen.crown_half_width * tier.width)), y: bottom_y },
				{ x: (seen.base_x - (seen.crown_half_width * tier.width)), y: bottom_y },
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

	## The points left to right, and bottom to top where they share an x. Each
	## goes in after the ones it doesn't come before, so points that tie keep
	## their order.
	sorted_points : List(Screen.Point) -> List(Screen.Point)
	sorted_points = |points|
		points.fold(
			[],
			|sorted, point|
				match sorted.find_first_index(|placed| is_before(point, placed)) {
					Ok(at) => List.join([
						sorted.take_first(at),
						[point],
						sorted.drop_first(at),
					])
					Err(NotFound) => sorted.append(point)
				},
		)
}

## Whether `a` comes before `b`: left of it, or above it at the same x.
is_before : Screen.Point, Screen.Point -> Bool
is_before = |a, b| a.x < b.x or (F64.to_bits(a.x) == F64.to_bits(b.x) and a.y < b.y)

## The hull with its last points taken off while they don't turn left on the
## way to `point`.
trim_hull : List(Screen.Point), Screen.Point -> List(Screen.Point)
trim_hull = |hull, point|
	match hull {
		[
			..,
			a,
			b,
		] => {
			turn = (((b.x - a.x) * (point.y - a.y)) - ((b.y - a.y) * (point.x - a.x)))
			if (turn <= 0.0) trim_hull(hull.drop_last(1), point) else hull
		}
		_ => hull
	}

## The angles of a cone's ring, from 0 round a whole turn. Each is the one
## before plus a step, not a multiple of the step: the two round differently.
ring_angles : List(F64)
ring_angles = {
	step = (Trig.two_pi / I64.to_f64(Tree.ring_n))
	walked = List.repeat(step, I64.to_u64_wrap((Tree.ring_n - 1))).fold(
		{ angle: 0.0, angles: [0.0] },
		|so_far, turn| {
			angle = (so_far.angle + turn)
			{ angle, angles: so_far.angles.append(angle) }
		},
	)
	walked.angles
}

## A tier, as a cone when the tree is near and the cone is in front of the
## camera, else as a triangle.
draw_tier : Tree.TreeInView, { seen : Tree.Outline, tier : Tree.Tier } -> List(Paint.DrawCmd)
draw_tier = |tree, { seen, tier }| {
	radius = ((Tree.crown_width * tier.width) * tree.height)
	match tree.crown {
		Cones if (tree.forward - radius) < Tree.min_cone_forward => Tree.tier_triangle(
			seen,
			{ tier, color: tree.color },
		)
		Cones => tier_cone(tree, { tier, radius })
		Triangles => Tree.tier_triangle(seen, { tier, color: tree.color })
	}
}

## A tier as a cone: the outline of the ring round its base and its apex.
tier_cone : Tree.TreeInView, { tier : Tree.Tier, radius : F64 } -> List(Paint.DrawCmd)
tier_cone = |tree, { tier, radius }| {
	base_height = ((Tree.visible_trunk + (Tree.crown_height * (1.0 - tier.bottom))) * tree.height)
	apex_height = ((Tree.visible_trunk + (Tree.crown_height * (1.0 - tier.top))) * tree.height)
	apex = Camera.project(
		{
			right: tree.right,
			forward: tree.forward,
			height: apex_height,
		},
		{ cam_focal: tree.cam_focal, view_w: tree.view_w },
	)
	ring = ring_angles.map(
		|angle| {
			on_ring = {
				right: (tree.right + (radius * Trig.r_cos(angle))),
				forward: (tree.forward + (radius * Trig.r_sin(angle))),
				height: base_height,
			}
			Camera.project(on_ring, { cam_focal: tree.cam_focal, view_w: tree.view_w })
		},
	)
	hull = Tree.convex_hull(ring.append(apex))
	if (hull.len() < 3) [] else Paint.push_round_poly(
		hull,
		{ fill_color: tree.color, round_strength: tree.shade },
	)
}
