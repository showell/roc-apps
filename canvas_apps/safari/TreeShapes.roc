## A conifer: a trunk under eight tiers of foliage. A far tree's tiers are flat
## triangles on the screen. A near one's are cones seen from the camera: the
## hull of a ring of points round each tier's base and its apex, so the
## tiers fatten as the camera passes under them. It works from what it is
## handed: a tree's height and color, where it stands from the camera, how many
## trees are nearer, and the lens.
import Camera
import ConvexHull
import Distance
import Fraction
import RiderView
import Picture
import Polygon
import Pixels
import Spot
import lib.RgbColor
import lib.Shapes

TreeShapes :: [].{

	## What a tree's detail depends on beyond itself: how many trees are nearer.
	Detail : { nearer_tree_count : U64 }

	## The tree on the screen: its trunk, then its tiers top to bottom. The
	## nearest trees have a shaded trunk. The crown is cones, shaded by how near
	## they are, within cone_reach, and triangles beyond it.
	tree_picture : Picture.Setting(TreeShapes.Detail),
	{
		height : Distance,
		foliage_color : RgbColor,
	} -> Picture
	tree_picture = |{ spot, focal_length, context }, { height, foliage_color }| {
		inputs = tier_inputs_of(spot.base(), { height, focal_length, foliage_color })
		trunk = trunk_shape(inputs.outline, trunk_finish_of(context.nearer_tree_count))
		Picture.from_shapes([trunk].concat(tiers.map(|tier| tier_shape(tier, inputs))))
	}

	## How a crown is drawn: cones, shaded by how near they are, or flat triangles.
	Crown : [Cones({ shade : Fraction }), Triangles]

	## How a tree's crown is drawn at distance `forward`.
	crown_of : Distance -> TreeShapes.Crown
	crown_of = |forward|
		if forward < cone_reach {
			Cones({ shade: crown_shade(forward) })
		} else {
			Triangles
		}

	## Where the tree at `spot` is on the screen, `height` tall, through a lens
	## of `focal_length`.
	tree_outline : Spot, { height : Distance, focal_length : Pixels } -> Camera.Upright
	tree_outline = |spot, { height, focal_length }|
		Camera.upright_on_screen(spot.base(), { height, focal_length })
}

## The tree is drawn 136 parts tall, and the shares below are parts of that.
tree_parts : U64
tree_parts = 136

## A tree nearer than this has cones for a crown.
cone_reach : Distance
cone_reach = Distance.metres(200.0)

## A tree's crown is shaded fully at the camera, less the farther off it
## is, and not at all from this far on.
crown_shade_reach : Distance
crown_shade_reach = Distance.metres(80.0)

## A tree with fewer than this many trees nearer than it gets a shaded
## trunk, which looks round.
round_trunk_limit : U64
round_trunk_limit = 4

## How a tree's trunk is drawn: shaded, which looks round, or flat.
TrunkFinish : [Shaded, Flat]

## How a tree's trunk is drawn, with `nearer_tree_count` trees nearer than it.
trunk_finish_of : U64 -> TrunkFinish
trunk_finish_of = |nearer_tree_count|
	if nearer_tree_count < round_trunk_limit {
		Shaded
	} else {
		Flat
	}

## How tall a tree's crown looks on the screen.
crown_height : Camera.Upright -> Pixels
crown_height = |outline| outline.height_on_screen.scaled_by(crown_height_share)

## Where the top of a tree's crown is on the screen: the tree's tip.
crown_top_y : Camera.Upright -> Pixels
crown_top_y = |outline| outline.foot.y.minus(outline.height_on_screen)

## How far the crown reaches either side of the trunk at its widest, on the
## screen.
crown_half_width : Camera.Upright -> Pixels
crown_half_width = |outline| outline.height_on_screen.scaled_by(crown_half_width_share)

## One tier of the crown: where its top and its bottom are, as fractions of
## the crown's height down from its top, and how wide its bottom is, as a
## fraction of the crown's width.
Tier : {
	top : Fraction,
	bottom : Fraction,
	width : Fraction,
}

## What every tier of one tree needs. `base` is the middle of the tree's foot,
## and `height` how far its tip stands above that.
TierInputs : {
	base : RiderView.RaisedPointAhead,
	height : Distance,
	focal_length : Pixels,
	outline : Camera.Upright,
	foliage_color : RgbColor,
	crown : TreeShapes.Crown,
}

## What every tier of the tree at `base` needs, its outline and its crown
## worked out from the rest.
tier_inputs_of : RiderView.RaisedPointAhead,
{
	height : Distance,
	focal_length : Pixels,
	foliage_color : RgbColor,
} -> TierInputs
tier_inputs_of = |base, { height, focal_length, foliage_color }| {
	base,
	height,
	focal_length,
	outline: Camera.upright_on_screen(base, { height, focal_length }),
	foliage_color,
	crown: TreeShapes.crown_of(base.forward()),
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
trunk_height_share = Fraction.of(55.0 / tree_parts.to_f64())

## The crown is the rest of the tree, so its tip is the tree's height.
crown_height_share : Fraction
crown_height_share = trunk_height_share.complement()

## The crown's widest half-width, as a fraction of the tree's height.
crown_half_width_share : Fraction
crown_half_width_share = Fraction.of(36.0 / tree_parts.to_f64())

## The trunk's width, as a fraction of the tree's height.
trunk_width_share : Fraction
trunk_width_share = Fraction.of(10.0 / tree_parts.to_f64())

## However far off a tree is, its trunk is this wide.
min_trunk_width : Pixels
min_trunk_width = Pixels.of(1.0)

## How far the trunk runs up inside the crown, as a fraction of the tree's
## height, so that no sky shows between them.
trunk_overlap_share : Fraction
trunk_overlap_share = Fraction.of(6.25 / tree_parts.to_f64())

## A cone's base is a ring of this many points.
ring_point_count : U64
ring_point_count = 16

## How much a crown is shaded at distance `forward`: fully at the camera,
## falling evenly to none at crown_shade_reach.
crown_shade : Distance -> Fraction
crown_shade = |forward| Fraction.clamp(forward.ratio_to(crown_shade_reach)).complement()

trunk_shape : Camera.Upright, TrunkFinish -> Shapes.Shape
trunk_shape = |outline, finish| {
	width = outline.height_on_screen.scaled_by(trunk_width_share).max(min_trunk_width)
	below_crown = outline.height_on_screen.scaled_by(trunk_height_share)
	height = below_crown.plus(outline.height_on_screen.scaled_by(trunk_overlap_share))
	left = outline.foot.x.minus(width.divided_by(2.0))
	top = outline.foot.y.minus(height)
	trunk_box = {
		top_left: { x: left, y: top },
		bottom_right: { x: left.plus(width), y: outline.foot.y },
	}
	match finish {
		Shaded => Polygon.shaded_polygon(
			Polygon.rectangle_corners(trunk_box),
			{ color: trunk_color, strength: Fraction.whole },
		)
		Flat => Polygon.rectangle(trunk_box, trunk_color)
	}
}

## A tier as a flat triangle: its apex at the tier's top, its base across its
## bottom.
tier_triangle : Camera.Upright, { tier : Tier, foliage_color : RgbColor } -> Shapes.Shape
tier_triangle = |outline, { tier, foliage_color }| {
	crown_top = crown_top_y(outline)
	bottom_y = crown_top.plus(crown_height(outline).scaled_by(tier.bottom))
	top_y = crown_top.plus(crown_height(outline).scaled_by(tier.top))
	half_base = crown_half_width(outline).scaled_by(tier.width)
	Polygon.triangle(
		{
			first_corner: { x: outline.foot.x, y: top_y },
			second_corner: { x: outline.foot.x.plus(half_base), y: bottom_y },
			third_corner: { x: outline.foot.x.minus(half_base), y: bottom_y },
		},
		foliage_color,
	)
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

## The cosine and sine of each of the ring's angles, worked out once rather
## than for every tier of every tree.
ring_units : List({ cos : F64, sin : F64 })
ring_units = ring_angles.map(|angle| { cos: angle.cos(), sin: angle.sin() })

## A tier, as a cone when the tree is near and the ring round the cone's base
## is at or past the near plane, else as a triangle.
tier_shape : Tier, TierInputs -> Shapes.Shape
tier_shape = |tier, inputs| {
	colored_tier = { tier, foliage_color: inputs.foliage_color }
	match inputs.crown {
		Cones({ shade }) => {
			radius_share = crown_half_width_share.to_f64() * tier.width.to_f64()
			cone_radius = inputs.height.times(radius_share)
			match cone_ring_points(tier, { inputs, cone_radius }) {
				Ok(ring_points) => tier_cone(tier, { inputs, ring_points, shade })
				Err(BehindCamera) => tier_triangle(inputs.outline, colored_tier)
			}
		}
		Triangles => tier_triangle(inputs.outline, colored_tier)
	}
}

## How high above the ground a point `down` the crown is, as a fraction of the
## crown's height down from its tip: the tree's base, then the trunk's share of
## its height, then the crown's share less the part above the point.
height_down_crown : TierInputs, Fraction -> Distance
height_down_crown = |inputs, down| {
	trunk_part = trunk_height_share.to_f64()
	crown_part = crown_height_share.to_f64()
	inputs.base.height().plus(inputs.height.times(trunk_part + crown_part * (1.0 - down.to_f64())))
}

## The ring of points round a tier's base, `cone_radius` out from the tree's
## middle, if every one of them is at or past the near plane.
cone_ring_points : Tier,
{
	inputs : TierInputs,
	cone_radius : Distance,
} -> Try(List(RiderView.RaisedPointAhead), [BehindCamera])
cone_ring_points = |tier, { inputs, cone_radius }| {
	base = inputs.base
	ring_height = height_down_crown(inputs, tier.bottom)
	RiderView.raised_points_ahead(
		ring_units.map(
			|unit| {
				right: base.right().plus(cone_radius.times(unit.cos)),
				forward: base.forward().plus(cone_radius.times(unit.sin)),
				height: ring_height,
			},
		),
	)
}

## A tier as a cone: the hull of the ring round its base and its apex.
tier_cone : Tier,
{
	inputs : TierInputs,
	ring_points : List(RiderView.RaisedPointAhead),
	shade : Fraction,
} -> Shapes.Shape
tier_cone = |tier, { inputs, ring_points, shade }| {
	apex_height = height_down_crown(inputs, tier.top)
	apex = Camera.project(inputs.base.at_height(apex_height), inputs.focal_length)
	ring_on_screen = Camera.projected_points(ring_points, inputs.focal_length)
	Polygon.shaded_polygon(
		ConvexHull.cone_hull_points(ring_on_screen, apex),
		{ color: inputs.foliage_color, strength: shade },
	)
}

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

# The four nearest trees have a shaded trunk, and the fifth has a flat one.
expect [0, 3].all(|count| trunk_finish_of(count) == Shaded)
expect [4, 9].all(|count| trunk_finish_of(count) == Flat)

## The sample tree's base, the middle of its foot, at `lift` off the ground.
sample_base : Distance -> RiderView.RaisedPointAhead
sample_base = |lift|
	RiderView.raised_point_ahead({
		right: Distance.metres(0.0),
		forward: Distance.metres(2.0),
		height: lift,
	})
		?? crash "the sample tree is past the near plane"

sample_height : Distance
sample_height = Distance.metres(4.352)

sample_outline : Camera.Upright
sample_outline = Camera.upright_on_screen(
	sample_base(Distance.zero),
	{ height: sample_height, focal_length: Pixels.of(500.0) },
)

# A lifted tree's cones measure from its foot: the ring under the bottom tier
# sits the trunk's share of the height above the foot, which here is 2 m up.
expect {
	inputs = tier_inputs_of(
		sample_base(Distance.metres(2.0)),
		{
			height: sample_height,
			focal_length: Pixels.of(500.0),
			foliage_color: RgbColor.of(7),
		},
	)
	bottom_tier = tiers.last() ?? crash "a tree has tiers"
	want = 2.0 + 4.352 * 55.0 / 136.0
	is_at_want = |point| (point.height().to_metres() - want).abs() <= 0.000000001
	match cone_ring_points(bottom_tier, { inputs, cone_radius: Distance.metres(1.0) }) {
		Ok(ring_points) => ring_points.len() == ring_point_count and ring_points.all(is_at_want)
		Err(BehindCamera) => False
	}
}

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
			sample_outline.height_on_screen.to_f64(),
			crown_height(sample_outline).to_f64(),
			crown_half_width(sample_outline).to_f64(),
		],
		[480.0, 600.0, 1088.0, 648.0, 288.0],
	)

expect {
	trunk_brown = {
		r: 0x5A,
		g: 0x3E,
		b: 0x22,
		a: 1.0,
	}
	match trunk_shape(sample_outline, Flat) {
		Poly(polygon) =>
			polygon.fill == Flat(trunk_brown)
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
}

# A shaded trunk is the same colour, lighter in the middle of its width.
expect {
	edge_brown = {
		r: 0x36,
		g: 0x25,
		b: 0x14,
		a: 1.0,
	}
	middle_brown = {
		r: 0x71,
		g: 0x4E,
		b: 0x2B,
		a: 1.0,
	}
	match trunk_shape(sample_outline, Shaded) {
		Poly({ coordinates, fill: Span({ edge_color, middle_color, left_x, right_x }) }) =>
			edge_color == edge_brown
				and middle_color == middle_brown
				and is_near([left_x, right_x], [440.0, 520.0])
				and is_near(coordinates, [440.0, 110.0, 520.0, 110.0, 520.0, 600.0, 440.0, 600.0])
		_ => False
	}
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
