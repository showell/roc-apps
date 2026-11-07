## A conifer: a trunk under eight tiers of foliage. A far tree's tiers are flat
## triangles on the screen. A near one's are cones seen from the camera: the
## hull of a ring of points round each tier's base and its apex, so the
## tiers fatten as the camera passes under them. It works from what it is
## handed: a tree's height and color, where it stands from the camera, how many
## trees are nearer, and the lens.
import Camera
import Detail
import Distance
import Fraction
import Geom
import Picture
import Polygon
import Pixels
import Screen
import lib.Brush
import lib.RgbColor
import lib.Shapes

TreeShapes :: [].{

	## Where a tree's foot stands on the screen, and how tall it looks there.
	TreeOutline : { foot : Screen.Point, height : Pixels }

	## The tree on the screen: its trunk, then its tiers top to bottom. The
	## nearest trees have a shaded trunk. The crown is cones, shaded by how near
	## they are, within Detail.cone_reach, and triangles beyond it.
	tree_picture : Picture.Setting({ nearer_tree_count : U16 }),
	{
		height : Distance,
		foliage_color : RgbColor,
	} -> Picture
	tree_picture = |{ spot, cam_focal, context }, { height, foliage_color }| {
		foot = spot.foot()
		lift = spot.lift()
		tip = foot.at_height(lift.plus(height))
		outline = tree_outline({ tip, lift, cam_focal })
		trunk_finish = if context.nearer_tree_count < Detail.round_trunk_limit {
			Shaded
		} else {
			Flat
		}
		inputs = {
			tip,
			cam_focal,
			outline,
			foliage_color,
			crown: crown_of(foot.forward()),
		}
		trunk = trunk_shape(outline, trunk_finish)
		Picture.from_shapes([trunk].concat(tiers.map(|tier| tier_shape(tier, inputs))))
	}

	## How a crown is drawn: cones, shaded by how near they are, or flat triangles.
	Crown : [Cones({ shade : Fraction }), Triangles]

	## How a tree's crown is drawn at distance `forward`.
	crown_of : Distance -> TreeShapes.Crown
	crown_of = |forward|
		if forward < Detail.cone_reach {
			Cones({ shade: crown_shade(forward) })
		} else {
			Triangles
		}

	## Where a tree is on the screen, given its `tip`, for a tree standing
	## `lift` off the ground, through a lens of focal length `cam_focal`.
	tree_outline : {
		tip : Geom.AheadPoint,
		lift : Distance,
		cam_focal : Pixels,
	} -> TreeShapes.TreeOutline
	tree_outline = |{ tip, lift, cam_focal }| {
		foot = Camera.project(tip.at_height(lift), cam_focal)
		top = Camera.project(tip, cam_focal)
		{ foot, height: foot.y.minus(top.y) }
	}

	## The tree is drawn 136 parts tall, and the shares below are parts of that.
	tree_parts : U64
	tree_parts = 136
}

## How tall a tree's crown looks on the screen.
crown_height : TreeShapes.TreeOutline -> Pixels
crown_height = |outline| outline.height.times(crown_height_share.to_f64())

## Where the top of a tree's crown is on the screen: the trunk's share of the
## height up from the foot, then the crown's share, each taken off in turn.
crown_top_y : TreeShapes.TreeOutline -> Pixels
crown_top_y = |outline| {
	crown_bottom_y = outline.foot.y.minus(outline.height.times(trunk_height_share.to_f64()))
	crown_bottom_y.minus(crown_height(outline))
}

## How far the crown reaches either side of the trunk at its widest, on the
## screen.
crown_half_width : TreeShapes.TreeOutline -> Pixels
crown_half_width = |outline| outline.height.times(crown_half_width_share.to_f64())

## One tier of the crown: where its top and its bottom are, as fractions of
## the crown's height down from its top, and how wide its bottom is, as a
## fraction of the crown's width.
Tier : {
	top : Fraction,
	bottom : Fraction,
	width : Fraction,
}

## What every tier of one tree needs. `tip` is the top of the tree.
TierInputs : {
	tip : Geom.AheadPoint,
	cam_focal : Pixels,
	outline : TreeShapes.TreeOutline,
	foliage_color : RgbColor,
	crown : TreeShapes.Crown,
}

## The tiers, top to bottom. Each overlaps the next.
tiers : List(Tier)
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

trunk_color : RgbColor
trunk_color = RgbColor.of(0x5A3E22)

## Of the tree's parts, 55 are trunk below the crown.
trunk_height_share : Fraction
trunk_height_share = Fraction.of(55.0 / TreeShapes.tree_parts.to_f64())

## The crown is the rest of the tree, so its tip is the tree's height.
crown_height_share : Fraction
crown_height_share = trunk_height_share.complement()

## The crown's widest half-width, as a fraction of the tree's height.
crown_half_width_share : Fraction
crown_half_width_share = Fraction.of(36.0 / TreeShapes.tree_parts.to_f64())

## The trunk's width, as a fraction of the tree's height.
trunk_width_share : Fraction
trunk_width_share = Fraction.of(10.0 / TreeShapes.tree_parts.to_f64())

## However far off a tree is, its trunk is this wide.
min_trunk_width : Pixels
min_trunk_width = Pixels.of(1.0)

## How far the trunk runs up inside the crown, as a fraction of the tree's
## height, so that no sky shows between them.
trunk_overlap_share : Fraction
trunk_overlap_share = Fraction.of(6.25 / TreeShapes.tree_parts.to_f64())

## A cone's base is a ring of this many points.
ring_point_count : U64
ring_point_count = 16

## How much a crown is shaded at distance `forward`: fully at the camera,
## falling evenly to none at Detail.crown_shade_reach.
crown_shade : Distance -> Fraction
crown_shade = |forward| Fraction.clamp(1.0 - forward.portion(Detail.crown_shade_reach))

trunk_shape : TreeShapes.TreeOutline, [Shaded, Flat] -> Shapes.Shape
trunk_shape = |outline, finish| {
	width = outline.height.times(trunk_width_share.to_f64()).max(min_trunk_width)
	below_crown = outline.height.times(trunk_height_share.to_f64())
	height = below_crown.plus(outline.height.times(trunk_overlap_share.to_f64()))
	left = outline.foot.x.minus(width.divided_by(2.0))
	top = outline.foot.y.minus(height)
	trunk_box = {
		top_left: { x: left, y: top },
		bottom_right: { x: left.plus(width), y: outline.foot.y },
	}
	match finish {
		Shaded => Polygon.shaded_polygon(
			Polygon.rectangle_corners(trunk_box),
			{ fill_color: trunk_color, strength: Fraction.whole },
		)
		Flat => Polygon.rectangle(trunk_color, trunk_box)
	}
}

## A tier as a flat triangle: its apex at the tier's top, its base across its
## bottom.
tier_triangle : TreeShapes.TreeOutline, { tier : Tier, foliage_color : RgbColor } -> Shapes.Shape
tier_triangle = |outline, { tier, foliage_color }| {
	crown_top = crown_top_y(outline)
	bottom_y = crown_top.plus(crown_height(outline).times(tier.bottom.to_f64()))
	top_y = crown_top.plus(crown_height(outline).times(tier.top.to_f64()))
	half_base = crown_half_width(outline).times(tier.width.to_f64())
	Polygon.triangle(
		foliage_color,
		{
			first_corner: { x: outline.foot.x, y: top_y },
			second_corner: { x: outline.foot.x.plus(half_base), y: bottom_y },
			third_corner: { x: outline.foot.x.minus(half_base), y: bottom_y },
		},
	)
}

## The convex hull of `points`, clockwise on the screen from the leftmost:
## Andrew's monotone chain, along the hull's top and back along its bottom.
## Fewer than three points are their own hull.
convex_hull_points : List(Screen.Point) -> List(Screen.Point)
convex_hull_points = |points|
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

## The angles of a cone's ring, from 0 round a whole turn. Each is the one
## before plus a step, not a multiple of the step: the two round differently.
ring_angles : List(F64)
ring_angles = {
	step = F64.tau / ring_point_count.to_f64()
	var $angle = 0.0
	var $angles = []
	for _ in 0..<ring_point_count {
		$angles = $angles.append($angle)
		$angle = $angle + step
	}
	$angles
}

## A tier, as a cone when the tree is near and the ring round the cone's base
## is at or past the near plane, else as a triangle.
tier_shape : Tier, TierInputs -> Shapes.Shape
tier_shape = |tier, inputs| {
	colored_tier = { tier, foliage_color: inputs.foliage_color }
	match inputs.crown {
		Cones({ shade }) => {
			radius_share = crown_half_width_share.to_f64() * tier.width.to_f64()
			cone_radius = inputs.tip.height().times(radius_share)
			match cone_ring_points(tier, { tip: inputs.tip, cone_radius }) {
				Ok(ring_points) => tier_cone(tier, { inputs, ring_points, shade })
				Err(BehindCamera) => tier_triangle(inputs.outline, colored_tier)
			}
		}
		Triangles => tier_triangle(inputs.outline, colored_tier)
	}
}

## The ring of points round a tier's base, `cone_radius` out from the tree's
## middle, if every one of them is at or past the near plane.
cone_ring_points : Tier,
{
	tip : Geom.AheadPoint,
	cone_radius : Distance,
} -> Try(List(Geom.AheadPoint), [BehindCamera])
cone_ring_points = |tier, { tip, cone_radius }| {
	trunk_part = trunk_height_share.to_f64()
	crown_part = crown_height_share.to_f64()
	bottom = tier.bottom.to_f64()
	base_height = tip.height().times(trunk_part + crown_part * (1.0 - bottom))
	Geom.ahead_points(
		ring_angles.map(
			|angle| {
				right: tip.right().plus(cone_radius.times(angle.cos())),
				forward: tip.forward().plus(cone_radius.times(angle.sin())),
				height: base_height,
			},
		),
	)
}

## A tier as a cone: the hull of the ring round its base and its apex.
tier_cone : Tier,
{
	inputs : TierInputs,
	ring_points : List(Geom.AheadPoint),
	shade : Fraction,
} -> Shapes.Shape
tier_cone = |tier, { inputs, ring_points, shade }| {
	tip = inputs.tip
	trunk_part = trunk_height_share.to_f64()
	crown_part = crown_height_share.to_f64()
	top = tier.top.to_f64()
	apex_height = tip.height().times(trunk_part + crown_part * (1.0 - top))
	apex = Camera.project(tip.at_height(apex_height), inputs.cam_focal)
	ring_on_screen = Camera.projected_points(ring_points, inputs.cam_focal)
	Polygon.shaded_polygon(
		convex_hull_points(ring_on_screen.append(apex)),
		{ fill_color: inputs.foliage_color, strength: shade },
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
expect ring_point_count == 16
expect trunk_color == RgbColor.of(0x5A3E22)

expect trunk_height_share.to_f64() + crown_height_share.to_f64() == 1.0

expect crown_shade(Distance.metres(0.0)).to_f64() == 1.0
expect crown_shade(Distance.metres(20.0)).to_f64() == 0.75
expect crown_shade(Distance.metres(40.0)).to_f64() == 0.5
expect crown_shade(Distance.metres(80.0)).to_f64() == 0.0
expect crown_shade(Distance.metres(200.0)).to_f64() == 0.0
expect crown_shade(Distance.metres(-50.0)).to_f64() == 1.0

expect TreeShapes.crown_of(Distance.metres(40.0)) == Cones({ shade: Fraction.of(0.5) })
expect TreeShapes.crown_of(Distance.metres(199.0)) == Cones({ shade: Fraction.zero })
expect TreeShapes.crown_of(Distance.metres(200.0)) == Triangles

sample_outline : TreeShapes.TreeOutline
sample_outline = TreeShapes.tree_outline({
	tip: Geom.ahead_point({
		right: Distance.metres(0.0),
		forward: Distance.metres(2.0),
		height: Distance.metres(4.352),
	})
		?? crash "the sample tree is past the near plane",
	lift: Distance.zero,
	cam_focal: Pixels.of(500.0),
})

## Whether two lists of coordinates agree, past rounding.
is_near : List(F64), List(F64) -> Bool
is_near = |got, expected|
	got.len() == expected.len() and got.map2(
		expected,
		|x, y| (x - y).abs(),
	).all(|miss| miss <= 0.000000001)

expect
	is_near(
		[
			sample_outline.foot.x.to_f64(),
			sample_outline.foot.y.to_f64(),
			sample_outline.height.to_f64(),
			crown_height(sample_outline).to_f64(),
			crown_half_width(sample_outline).to_f64(),
		],
		[480.0, 600.0, 1088.0, 648.0, 288.0],
	)

# The crown's tip is the tree's height.
expect
	is_near(
		[crown_top_y(sample_outline).to_f64()],
		[sample_outline.foot.y.minus(sample_outline.height).to_f64()],
	)

expect
	match trunk_shape(sample_outline, Flat) {
		Poly(polygon) =>
			polygon.fill == Flat(Brush.opaque(RgbColor.of(0x5A3E22)))
				and is_near(
					polygon.coordinates,
					[
						440.0,
						110.0,
						520.0,
						110.0,
						520.0,
						600.0,
						440.0,
						600.0,
					],
				)
		_ => False
	}

# A shaded trunk is the same colour, lighter in the middle of its width.
expect
	match trunk_shape(sample_outline, Shaded) {
		Poly({ coordinates, fill: Span({ edge_color, middle_color, left_x, right_x }) }) =>
			edge_color == Brush.opaque(RgbColor.of(0x362514))
				and middle_color == Brush.opaque(RgbColor.of(0x714E2B))
				and is_near([left_x, right_x], [440.0, 520.0])
				and is_near(coordinates, [440.0, 110.0, 520.0, 110.0, 520.0, 600.0, 440.0, 600.0])
		_ => False
	}

expect {
	corners_of = |tier|
		match tier_triangle(sample_outline, { tier, foliage_color: RgbColor.of(7) }) {
			Poly(polygon) => polygon.coordinates
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
hull_points = |points| Polygon.flat_coordinates(convex_hull_points(points))

square_and_inside_points : List(Screen.Point)
square_and_inside_points = [
	Screen.point(0.0, 0.0),
	Screen.point(4.0, 0.0),
	Screen.point(4.0, 4.0),
	Screen.point(0.0, 4.0),
	Screen.point(2.0, 2.0),
	Screen.point(2.0, 0.0),
]

triangle_points : List(Screen.Point)
triangle_points = [
	Screen.point(0.0, 0.0),
	Screen.point(4.0, 0.0),
	Screen.point(2.0, 3.0),
]

line_points : List(Screen.Point)
line_points = [
	Screen.point(0.0, 0.0),
	Screen.point(1.0, 1.0),
	Screen.point(2.0, 2.0),
	Screen.point(3.0, 3.0),
]

pair_points : List(Screen.Point)
pair_points = [Screen.point(1.0, 2.0), Screen.point(0.0, 0.0)]

repeated_points : List(Screen.Point)
repeated_points = [
	Screen.point(0.0, 0.0),
	Screen.point(0.0, 0.0),
	Screen.point(4.0, 0.0),
	Screen.point(4.0, 4.0),
]

expect hull_points(square_and_inside_points) == [0.0, 0.0, 4.0, 0.0, 4.0, 4.0, 0.0, 4.0]
expect hull_points(triangle_points) == [0.0, 0.0, 4.0, 0.0, 2.0, 3.0]
expect hull_points(line_points) == [0.0, 0.0, 3.0, 3.0]
expect hull_points(pair_points) == [1.0, 2.0, 0.0, 0.0]
expect hull_points([Screen.point(9.0, 9.0)]) == [9.0, 9.0]
expect hull_points([]) == []
expect hull_points(repeated_points) == [0.0, 0.0, 4.0, 0.0, 4.0, 4.0]

expect convex_hull_points(square_and_inside_points).len() == 4
expect convex_hull_points(triangle_points).len() == 3
expect convex_hull_points(line_points).len() == 2
expect convex_hull_points(pair_points).len() == 2
expect convex_hull_points(repeated_points).len() == 3

expect
	Polygon.flat_coordinates(square_and_inside_points.sort_with(left_to_right))
		== [0.0, 0.0, 0.0, 4.0, 2.0, 0.0, 2.0, 2.0, 4.0, 0.0, 4.0, 4.0]

expect left_to_right(Screen.point(1.0, 9.0), Screen.point(2.0, 0.0)) == Before
expect left_to_right(Screen.point(2.0, 0.0), Screen.point(1.0, 9.0)) == After
expect left_to_right(Screen.point(1.0, 2.0), Screen.point(1.0, 2.0)) == Same
