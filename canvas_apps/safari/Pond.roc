## The duck pond past a bend, on the outside of the turn: its water, its bank,
## and the ducks on it. A point on the pond is measured along the road past the
## end of the segment, and out from the middle of the road on the outside of
## the bend, in metres.
import Across
import Along
import BendInView
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
	match (BendInView.outer_side(bend.turn), facing) {
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
## water.
bank_under_water : Distance
bank_under_water = Distance.metres(10.0)

## How far the bank's two inner end corners are pulled in toward the road.
## Left in line with the far shore's ends, each end of the bank would leave the
## water exactly at the water's corner, beside the shore at a narrow angle, and
## the browser's antialiasing would leave a seam of grass between them. Pulled
## in, each end edge crosses the shore beside the corner at an angle.
bank_end_pull_in : Distance
bank_end_pull_in = Distance.metres(2.0)

## The bank's inner edge: the far shore, moved back under the water, with its
## two ends pulled in toward the road.
bank_inner_points : List(PondPoint)
bank_inner_points = {
	under_water = |point| { ..point, past_end: point.past_end.minus(bank_under_water) }
	pulled_in = |point| { ..point, out_from_middle: point.out_from_middle.minus(bank_end_pull_in) }
	match far_shore_points.fold_rev([], |point, out| out.append(under_water(point))) {
		[first, middle, last] => [pulled_in(first), middle, pulled_in(last)]
		_ => crash "Pond.bank_inner_points: the far shore has three points"
	}
}

## The bank: its inner edge under the water, then its outer edge.
bank_points : List(PondPoint)
bank_points = bank_inner_points.concat(bank_outer_points)

bank_color : RgbColor
bank_color = RgbColor.of(0xC2B280)

## Where `point` lies on the road around `bend`, the bend that ends a segment.
## This is the one place a pond point becomes a road point.
segment_point : PondPoint, Geom.Bend -> Geom.RoadPoint
segment_point = |point, bend| {
	along: Along.at(bend.segment_length).plus(point.past_end),
	across: match BendInView.outer_side(bend.turn) {
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

## Whether `point` lies inside the water's outline: a line from it, out along
## the road, crosses the outline an odd number of times.
is_inside_water : PondPoint -> Bool
is_inside_water = |point| {
	x = point.past_end.to_metres()
	y = point.out_from_middle.to_metres()
	corners = water_points.map(
		|corner| { x: corner.past_end.to_metres(), y: corner.out_from_middle.to_metres() },
	)
	next_corners = corners.drop_first(1).concat(corners.take_first(1))
	edges = corners.map2(next_corners, |from, to| { from, to })
	is_crossed = |{ from, to }| {
		is_spanned = (from.y > y) != (to.y > y)
		crossing_x = from.x + (y - from.y) / (to.y - from.y) * (to.x - from.x)
		is_spanned and x < crossing_x
	}
	edges.keep_if(is_crossed).len() % 2 == 1
}

# The bank's inner edge lies under the water, where the water hides it. Moved
# back as far as the near shore, it would show.
expect bank_inner_points.all(is_inside_water)

# A point just inside each edge of the water is in it, and one just past is not.
expect
	[
		({ past_end: Distance.metres(3.1), out_from_middle: Distance.metres(10.0) }, True),
		({ past_end: Distance.metres(2.9), out_from_middle: Distance.metres(10.0) }, False),
		({ past_end: Distance.metres(31.9), out_from_middle: Distance.metres(17.0) }, True),
		({ past_end: Distance.metres(32.1), out_from_middle: Distance.metres(17.0) }, False),
		({ past_end: Distance.metres(10.0), out_from_middle: Distance.metres(3.9) }, True),
		({ past_end: Distance.metres(10.0), out_from_middle: Distance.metres(3.3) }, False),
	].all(|(at, inside)| is_inside_water(at) == inside)

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
