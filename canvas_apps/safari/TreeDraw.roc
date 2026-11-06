## A conifer: a trunk under eight tiers of foliage. A far tree's tiers are flat
## triangles on the screen. A near one's are cones seen from the camera: the
## outline of a ring of points round each tier's base and its apex, so the
## tiers fatten as the camera passes under them. It draws from what it is
## handed: a tree's kind, where it stands from the camera, how many trees are
## nearer, and the lens.
import Camera
import Conifer
import Detail
import Distance
import Fraction
import Geom
import Polygon
import Pixels
import Screen
import lib.Brush
import lib.Shapes

TreeDraw :: [].{

	## A tree in front of the camera, so of its lengths only `right` can be
	## negative. A record with more in it can be handed to `draw` as it is.
	TreeAhead(others) : {
		right : Distance,
		forward : Distance,
		conifer : Conifer,
		..others,
	}

	## Where a tree stands on the screen, and how big it looks there.
	TreeOnScreen : {
		base_x : Pixels,
		base_y : Pixels,
		height_px : Pixels,
		crown_top_y : Pixels,
		crown_height_px : Pixels,
		crown_half_width : Pixels,
	}

	## One tier of the crown: where its top and its bottom are, as fractions of
	## the crown's height down from its top, and how wide its bottom is, as a
	## fraction of the crown's width.
	Tier : {
		top : Fraction,
		bottom : Fraction,
		width : Fraction,
	}

	## The tree on the screen: its trunk, then its tiers top to bottom. The
	## nearest trees have a shaded trunk. The crown is cones, shaded by how near
	## they are, within Detail.cone_reach, and triangles beyond it.
	draw : { tree : TreeDraw.TreeAhead(others), nearer_trees : U64 }, Pixels -> List(Shapes.Shape)
	draw = |{ tree, nearer_trees }, cam_focal| {
		point = {
			right: tree.right,
			forward: tree.forward,
			height: tree.conifer.height(),
		}
		screen_tree = tree_on_screen(point, cam_focal)
		trunk = if nearer_trees < Detail.round_trunk_limit {
			Shaded
		} else {
			Flat
		}
		look = {
			point,
			cam_focal,
			screen_tree,
			color: conifer_color(tree.conifer),
			crown: crown_of(tree.forward),
		}
		draw_trunk(screen_tree, trunk).concat(tiers.join_map(|tier| draw_tier(tier, look)))
	}

	## How a crown is drawn: cones, shaded by how near they are, or flat triangles.
	Crown : [Cones({ shade : Fraction }), Triangles]

	## How a tree's crown is drawn at distance `forward`.
	crown_of : Distance -> TreeDraw.Crown
	crown_of = |forward|
		if forward < Detail.cone_reach {
			Cones({ shade: crown_shade(forward) })
		} else {
			Triangles
		}

	## Where a tree whose foot is at `point`, and `point.height` tall, is on the
	## screen, through a lens of focal length `cam_focal`.
	tree_on_screen : Geom.RaisedPoint, Pixels -> TreeDraw.TreeOnScreen
	tree_on_screen = |point, cam_focal| {
		base = Camera.project({ ..point, height: Distance.zero }, cam_focal)
		top = Camera.project(point, cam_focal)
		height_px = base.y.minus(top.y)
		crown_height_px = height_px.times(crown_height_share.to_f64())
		crown_bottom_y = base.y.minus(height_px.times(trunk_height_share.to_f64()))
		{
			base_x: base.x,
			base_y: base.y,
			height_px,
			crown_top_y: crown_bottom_y.minus(crown_height_px),
			crown_height_px,
			crown_half_width: height_px.times(crown_half_width_share.to_f64()),
		}
	}
}

## What every tier of one tree is drawn from.
TreeLook : {
	point : Geom.RaisedPoint,
	cam_focal : Pixels,
	screen_tree : TreeDraw.TreeOnScreen,
	color : I64,
	crown : [Cones({ shade : Fraction }), Triangles],
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

green_color : I64
green_color = 0x1C5A22

gold_color : I64
gold_color = 0xCF9A18

red_color : I64
red_color = 0xB23A2A

## A conifer's foliage colour.
conifer_color : Conifer -> I64
conifer_color = |conifer|
	match conifer {
		BigGreen | SmallGreen => green_color
		Gold => gold_color
		Red => red_color
	}

## A tree is 136 parts tall, and the shares below are parts of that. Of those
## parts, 55 are trunk below the crown.
trunk_height_share : Fraction
trunk_height_share = Fraction.of(55.0 / 136.0)

## The crown is the rest of the tree, so its tip is the tree's height.
crown_height_share : Fraction
crown_height_share = trunk_height_share.complement()

## The crown's widest half-width, as a fraction of the tree's height.
crown_half_width_share : Fraction
crown_half_width_share = Fraction.of(36.0 / 136.0)

## The trunk's width, as a fraction of the tree's height.
trunk_width_share : Fraction
trunk_width_share = Fraction.of(10.0 / 136.0)

## However far off a tree is, its trunk is this wide.
min_trunk_width : Pixels
min_trunk_width = Pixels.of(1.0)

## How far the trunk runs up inside the crown, as a fraction of the tree's
## height, so that no sky shows between them.
trunk_overlap_share : Fraction
trunk_overlap_share = Fraction.of(6.25 / 136.0)

## A cone's base is a ring of this many points.
ring_points : U64
ring_points = 16

## How much a crown is shaded at distance `forward`: fully at the camera,
## falling evenly to none at Detail.crown_shade_reach.
crown_shade : Distance -> Fraction
crown_shade = |forward| Fraction.clamp(1.0 - forward.ratio_to(Detail.crown_shade_reach))

draw_trunk : TreeDraw.TreeOnScreen, [Shaded, Flat] -> List(Shapes.Shape)
draw_trunk = |screen_tree, finish| {
	width = screen_tree.height_px.times(trunk_width_share.to_f64()).max(min_trunk_width)
	below_crown = screen_tree.height_px.times(trunk_height_share.to_f64())
	height = below_crown.plus(screen_tree.height_px.times(trunk_overlap_share.to_f64()))
	left = screen_tree.base_x.minus(width.divided_by(2.0))
	top = screen_tree.base_y.minus(height)
	points = [
		{ x: left, y: top },
		{ x: left.plus(width), y: top },
		{ x: left.plus(width), y: screen_tree.base_y },
		{ x: left, y: screen_tree.base_y },
	]
	match finish {
		Shaded => Polygon.shaded_polygon(
			points,
			{ fill_color: trunk_color, strength: Fraction.whole },
		)
		Flat => Polygon.flat_polygon(trunk_color, points)
	}
}

## A tier as a flat triangle: its apex at the tier's top, its base across its
## bottom.
tier_triangle : TreeDraw.TreeOnScreen, { tier : TreeDraw.Tier, color : I64 } -> List(Shapes.Shape)
tier_triangle = |screen_tree, { tier, color }| {
	bottom_y = screen_tree.crown_top_y.plus(screen_tree.crown_height_px.times(tier.bottom.to_f64()))
	top_y = screen_tree.crown_top_y.plus(screen_tree.crown_height_px.times(tier.top.to_f64()))
	half_base = screen_tree.crown_half_width.times(tier.width.to_f64())
	Polygon.flat_polygon(
		color,
		[
			{ x: screen_tree.base_x, y: top_y },
			{ x: screen_tree.base_x.plus(half_base), y: bottom_y },
			{ x: screen_tree.base_x.minus(half_base), y: bottom_y },
		],
	)
}

## The convex hull of `points`, clockwise on the screen from the leftmost:
## Andrew's monotone chain, along the hull's top and back along its bottom.
## Fewer than three points are their own hull.
convex_hull : List(Screen.Point) -> List(Screen.Point)
convex_hull = |points|
	if points.len() < 3 {
		points
	} else {
		sorted = points.sort_with(left_to_right)
		top_chain = sorted.fold([], |hull, point| trim_hull(hull, point).append(point))
		bottom_chain = sorted.fold_rev([], |point, hull| trim_hull(hull, point).append(point))
		top_chain.drop_last(1).concat(bottom_chain.drop_last(1))
	}

## The order the hull walks points in: left to right, and top to bottom where
## they share an x.
left_to_right : Screen.Point, Screen.Point -> [Before, Same, After]
left_to_right = |a, b|
	if is_before(a, b) {
		Before
	} else if is_before(b, a) {
		After
	} else {
		Same
	}

## Whether `a` comes before `b`: left of it, or above it at the same x.
is_before : Screen.Point, Screen.Point -> Bool
is_before = |a, b| a.x < b.x or (a.x == b.x and a.y < b.y)

## The hull with its last points taken off while they don't turn clockwise on
## the way to `point`. The screen's y grows downward, so a positive `turn` is
## clockwise as the eye sees it.
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
	step = F64.tau / ring_points.to_f64()
	var $angle = 0.0
	var $angles = []
	for _ in 0..<ring_points {
		$angles = $angles.append($angle)
		$angle = $angle + step
	}
	$angles
}

## A tier, as a cone when the tree is near and the whole cone is past the near
## plane, else as a triangle: the camera can't see a cone from inside.
draw_tier : TreeDraw.Tier, TreeLook -> List(Shapes.Shape)
draw_tier = |tier, look| {
	cone_radius = look.point.height.times(crown_half_width_share.to_f64() * tier.width.to_f64())
	match look.crown {
		Cones(_) if look.point.forward.minus(cone_radius) < Geom.near_plane =>
			tier_triangle(look.screen_tree, { tier, color: look.color })
		Cones({ shade }) => tier_cone(tier, { look, cone_radius, shade })
		Triangles => tier_triangle(look.screen_tree, { tier, color: look.color })
	}
}

## A tier as a cone: the outline of the ring round its base and its apex.
tier_cone : TreeDraw.Tier,
{
	look : TreeLook,
	cone_radius : Distance,
	shade : Fraction,
} -> List(Shapes.Shape)
tier_cone = |tier, { look, cone_radius, shade }| {
	point = look.point
	trunk_part = trunk_height_share.to_f64()
	crown_part = crown_height_share.to_f64()
	bottom = tier.bottom.to_f64()
	top = tier.top.to_f64()
	base_height = point.height.times(trunk_part + crown_part * (1.0 - bottom))
	apex_height = point.height.times(trunk_part + crown_part * (1.0 - top))
	apex = Camera.project({ ..point, height: apex_height }, look.cam_focal)
	ring = ring_angles.map(
		|angle| {
			on_ring = {
				right: point.right.plus(cone_radius.times(angle.cos())),
				forward: point.forward.plus(cone_radius.times(angle.sin())),
				height: base_height,
			}
			Camera.project(on_ring, look.cam_focal)
		},
	)
	Polygon.shaded_polygon(
		convex_hull(ring.append(apex)),
		{ fill_color: look.color, strength: shade },
	)
}

expect tiers.map(|tier| tier.top.to_f64()) == [0.0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7]
expect tiers.map(|tier| tier.bottom.to_f64()) == [0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1.0]
expect tiers.map(|tier| tier.width.to_f64()) == [
	0.35,
	0.44,
	0.53,
	0.63,
	0.72,
	0.81,
	0.91,
	1.0,
]

expect tiers.len() == 8
expect ring_points == 16
expect trunk_color == 0x5A3E22
expect conifer_color(Conifer.BigGreen) == 0x1C5A22
expect conifer_color(Conifer.SmallGreen) == 0x1C5A22
expect conifer_color(Conifer.Gold) == 0xCF9A18
expect conifer_color(Conifer.Red) == 0xB23A2A

expect trunk_height_share.to_f64() + crown_height_share.to_f64() == 1.0

expect crown_shade(Distance.metres(0.0)).to_f64() == 1.0
expect crown_shade(Distance.metres(20.0)).to_f64() == 0.75
expect crown_shade(Distance.metres(40.0)).to_f64() == 0.5
expect crown_shade(Distance.metres(80.0)).to_f64() == 0.0
expect crown_shade(Distance.metres(200.0)).to_f64() == 0.0
expect crown_shade(Distance.metres(-50.0)).to_f64() == 1.0

expect TreeDraw.crown_of(Distance.metres(40.0)) == Cones({ shade: Fraction.of(0.5) })
expect TreeDraw.crown_of(Distance.metres(199.0)) == Cones({ shade: Fraction.zero })
expect TreeDraw.crown_of(Distance.metres(200.0)) == Triangles

sample_on_screen : TreeDraw.TreeOnScreen
sample_on_screen = TreeDraw.tree_on_screen(
	{
		right: Distance.metres(0.0),
		forward: Distance.metres(2.0),
		height: Distance.metres(4.352),
	},
	Pixels.of(500.0),
)

## Whether two lists of coordinates agree, past rounding.
is_near : List(F64), List(F64) -> Bool
is_near = |got, want|
	got.len() == want.len() and got.map2(want, |x, y| (x - y).abs()).all(|miss| miss <= 0.000000001)

expect
	is_near(
		[
			sample_on_screen.base_x.to_f64(),
			sample_on_screen.base_y.to_f64(),
			sample_on_screen.height_px.to_f64(),
			sample_on_screen.crown_height_px.to_f64(),
			sample_on_screen.crown_half_width.to_f64(),
		],
		[480.0, 600.0, 1088.0, 648.0, 288.0],
	)

# The crown's tip is the tree's height.
expect
	is_near(
		[sample_on_screen.crown_top_y.to_f64()],
		[sample_on_screen.base_y.minus(sample_on_screen.height_px).to_f64()],
	)

expect
	match draw_trunk(sample_on_screen, Flat) {
		[Poly(polygon)] =>
			polygon.fill == Flat(Brush.opaque(0x5A3E22))
				and is_near(polygon.pts, [440.0, 110.0, 520.0, 110.0, 520.0, 600.0, 440.0, 600.0])
		_ => False
	}

# A shaded trunk is the same colour, lighter in the middle of its width.
expect
	match draw_trunk(sample_on_screen, Shaded) {
		[Poly({ pts, fill: Span({ edge, middle, x0, x1 }) })] =>
			edge == Brush.opaque(0x362514)
				and middle == Brush.opaque(0x714E2B)
				and is_near([x0, x1], [440.0, 520.0])
				and is_near(pts, [440.0, 110.0, 520.0, 110.0, 520.0, 600.0, 440.0, 600.0])
		_ => False
	}

expect {
	corners_of = |tier|
		match tier_triangle(sample_on_screen, { tier, color: 7 }) {
			[Poly(polygon)] => polygon.pts
			_ => crash "a tier is one polygon"
		}
	top_tier = tiers.first() ?? crash "a tree has tiers"
	bottom_tier = tiers.last() ?? crash "a tree has tiers"
	[
		(top_tier, [480.0, -488.0, 580.8, -293.6, 379.2, -293.6]),
		(bottom_tier, [480.0, -34.4, 768.0, 160.0, 192.0, 160.0]),
	].all(|(tier, want)| is_near(corners_of(tier), want))
}

# Of two points at one x the higher comes first, and of two equal points neither does.
expect is_before(Screen.point(1.0, 9.0), Screen.point(2.0, 0.0))
expect !is_before(Screen.point(2.0, 0.0), Screen.point(1.0, 9.0))
expect is_before(Screen.point(1.0, 2.0), Screen.point(1.0, 3.0))
expect !is_before(Screen.point(1.0, 3.0), Screen.point(1.0, 2.0))
expect !is_before(Screen.point(1.0, 2.0), Screen.point(1.0, 2.0))

hull_points : List(Screen.Point) -> List(F64)
hull_points = |points| Polygon.flatten_screen(convex_hull(points))

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

expect convex_hull(square_with_inside_points).len() == 4
expect convex_hull(hull_triangle).len() == 3
expect convex_hull(hull_line).len() == 2
expect convex_hull(hull_pair).len() == 2
expect convex_hull(hull_with_a_repeat).len() == 3

expect
	Polygon.flatten_screen(square_with_inside_points.sort_with(left_to_right))
		== [0.0, 0.0, 0.0, 4.0, 2.0, 0.0, 2.0, 2.0, 4.0, 0.0, 4.0, 4.0]

expect left_to_right(Screen.point(1.0, 9.0), Screen.point(2.0, 0.0)) == Before
expect left_to_right(Screen.point(2.0, 0.0), Screen.point(1.0, 9.0)) == After
expect left_to_right(Screen.point(1.0, 2.0), Screen.point(1.0, 2.0)) == Same
