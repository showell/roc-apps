## The duck pond past a bend, on the outside of the turn: its water, its bank,
## and the ducks on it. A point on the pond is measured along the road past the
## end of the segment, and out from the middle of the road on the outside of
## the bend, in metres.
import Across
import Along
import BendView
import Billboard
import Distance
import EmojiStills
import Geom
import lib.RgbColor

Pond :: [].{

	## The pond's outlines on the road around `bend`, the bend that ends a
	## segment, in the order they are painted: its bank, then its water over
	## the bank's inner edge.
	pond_outlines : Geom.Bend -> List({ corners : List(Geom.RoadPoint), color : RgbColor })
	pond_outlines = |bend| {
		on_road = |outline| outline.map(|point| segment_point(point, bend))
		[
			{ corners: on_road(bank_points), color: bank_color },
			{ corners: on_road(water_points), color: water_color },
		]
	}

	## The ducks, placed at `bend`, the bend that ends a segment.
	placed_ducks : Geom.Bend -> List(Geom.Placed(Billboard))
	placed_ducks = |bend|
		ducks.map(
			|pond_duck| {
				road_point: segment_point(pond_duck.at, bend),
				lift: Distance.zero,
				kind: Billboard.adult_billboard(duck, facing_at(pond_duck.facing, bend)),
			},
		)
}

## Which way a duck laid out as facing `facing` faces at `bend`. The ducks are
## laid out for a pond on the road's left, at a right turn; at a left turn the
## pond is mirrored to the right, and so is every duck.
facing_at : Billboard.Facing, Geom.Bend -> Billboard.Facing
facing_at = |facing, bend|
	match (BendView.outer_side(bend.turn), facing) {
		(LeftSide, _) => facing
		(RightSide, FacesLeft) => FacesRight
		(RightSide, FacesRight) => FacesLeft
	}

## A point on the pond, `past_end` along the road past the segment's end and
## `out_from_middle` from the middle of the road, on the outside of the bend.
PondPoint : { past_end : Distance, out_from_middle : Distance }

## The water's shore on the bend's side, from where it comes nearest the road
## round to the far shore.
near_shore_points : List(PondPoint)
near_shore_points = [
	{ past_end: Distance.metres(16.0), out_from_middle: Distance.metres(3.0) },
	{ past_end: Distance.metres(3.0), out_from_middle: Distance.metres(4.0) },
	{ past_end: Distance.metres(3.0), out_from_middle: Distance.metres(30.0) },
	{ past_end: Distance.metres(14.0), out_from_middle: Distance.metres(33.0) },
]

## The water's shore farthest along the road, where the bank meets it.
far_shore_points : List(PondPoint)
far_shore_points = [
	{ past_end: Distance.metres(28.0), out_from_middle: Distance.metres(28.0) },
	{ past_end: Distance.metres(32.0), out_from_middle: Distance.metres(17.0) },
	{ past_end: Distance.metres(29.0), out_from_middle: Distance.metres(7.0) },
]

water_points : List(PondPoint)
water_points = near_shore_points.concat(far_shore_points)

water_color : RgbColor
water_color = RgbColor.of(0x2F7E8C)

## The bank's edge away from the water, running the way the far shore runs.
bank_outer_points : List(PondPoint)
bank_outer_points = [
	{ past_end: Distance.metres(29.0), out_from_middle: Distance.metres(28.0) },
	{ past_end: Distance.metres(33.0), out_from_middle: Distance.metres(17.0) },
	{ past_end: Distance.metres(30.0), out_from_middle: Distance.metres(7.0) },
]

## How far back from the far shore the bank's inner edge runs, under the
## water. Two polygons that share an edge show a seam where the browser
## antialiases both, so the bank lies under the water's edge instead, and the
## water hides the overlap. A distance along the road shrinks fast on screen,
## so the overlap is generous; it only has to keep the inner edge inside the
## water. The bank's ends still meet the far shore's ends, because each end of
## the bank lies straight along the road from its inner corner.
bank_under_water : Distance
bank_under_water = Distance.metres(10.0)

## The bank: the far shore, moved back under the water, then its outer edge.
bank_points : List(PondPoint)
bank_points = {
	under_water = |point| { ..point, past_end: point.past_end.minus(bank_under_water) }
	inner_points = far_shore_points.fold_rev([], |point, out| out.append(under_water(point)))
	inner_points.concat(bank_outer_points)
}

bank_color : RgbColor
bank_color = RgbColor.of(0xC2B280)

## Where `point` lies on the road around `bend`, the bend that ends a segment.
## This is the one place a pond point becomes a road point.
segment_point : PondPoint, Geom.Bend -> Geom.RoadPoint
segment_point = |point, bend| {
	along: Along.at(bend.segment_length).plus(point.past_end),
	across: match BendView.outer_side(bend.turn) {
		LeftSide => Across.left_of_middle(point.out_from_middle)
		RightSide => Across.right_of_middle(point.out_from_middle)
	},
}

## The duck's still, and how tall a duck stands.
duck : Billboard.Species
duck = { still: EmojiStills.duck, adult_height: Distance.metres(0.9) }

## A duck on the pond, where it floats and which way it faces.
Duck : { at : PondPoint, facing : Billboard.Facing }

ducks : List(Duck)
ducks = [
	{
		at: { past_end: Distance.metres(11.0), out_from_middle: Distance.metres(10.0) },
		facing: FacesRight,
	},
	{
		at: { past_end: Distance.metres(17.0), out_from_middle: Distance.metres(18.0) },
		facing: FacesLeft,
	},
	{
		at: { past_end: Distance.metres(21.0), out_from_middle: Distance.metres(11.0) },
		facing: FacesRight,
	},
	{
		at: { past_end: Distance.metres(6.0), out_from_middle: Distance.metres(6.0) },
		facing: FacesRight,
	},
	{
		at: { past_end: Distance.metres(7.0), out_from_middle: Distance.metres(14.0) },
		facing: FacesLeft,
	},
	{
		at: { past_end: Distance.metres(8.0), out_from_middle: Distance.metres(22.0) },
		facing: FacesRight,
	},
]

## Whether a duck floats within the water's reach, along the road and out from
## its middle.
is_on_water : Duck -> Bool
is_on_water = |pond_duck| {
	is_within = |value, bounds|
		bounds.any(|bound| bound <= value) and bounds.any(|bound| bound >= value)
	outs = water_points.map(|point| point.out_from_middle.to_metres())
	past_ends = water_points.map(|point| point.past_end.to_metres())
	is_within(pond_duck.at.out_from_middle.to_metres(), outs)
		and is_within(pond_duck.at.past_end.to_metres(), past_ends)
}

expect ducks.all(is_on_water)

# A duck just past each edge of the water is off it.
expect
	[
		{ past_end: Distance.metres(2.9), out_from_middle: Distance.metres(10.0) },
		{ past_end: Distance.metres(32.1), out_from_middle: Distance.metres(10.0) },
		{ past_end: Distance.metres(10.0), out_from_middle: Distance.metres(2.9) },
		{ past_end: Distance.metres(10.0), out_from_middle: Distance.metres(33.1) },
	].all(|at| !is_on_water({ at, facing: FacesRight }))

expect
	ducks.map(|pond_duck| pond_duck.facing == FacesRight)
		== [True, False, True, True, False, True]
