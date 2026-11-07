## The duck pond past the bend at a segment's end: its water, its bank, and
## the ducks on it. A point on the pond is measured along the road past the
## end of the segment, and across it from the middle of the road, in metres.
import Across
import Along
import Billboard
import Distance
import EmojiStills
import Geom
import lib.RgbColor

Pond :: [].{

	## A point on the pond, `past_end` along the road past the segment's end
	## and `across` from the middle of the road.
	PondPoint : { past_end : Distance, across : Across }

	water_points : List(Pond.PondPoint)
	water_points = [
		{ past_end: Distance.metres(3.0), across: Across.metres(-4.0) },
		{ past_end: Distance.metres(3.0), across: Across.metres(-30.0) },
		{ past_end: Distance.metres(14.0), across: Across.metres(-33.0) },
		{ past_end: Distance.metres(28.0), across: Across.metres(-28.0) },
		{ past_end: Distance.metres(32.0), across: Across.metres(-17.0) },
		{ past_end: Distance.metres(29.0), across: Across.metres(-7.0) },
		{ past_end: Distance.metres(16.0), across: Across.metres(-3.0) },
	]

	water_color : RgbColor
	water_color = RgbColor.of(0x2F7E8C)

	bank_points : List(Pond.PondPoint)
	bank_points = [
		{ past_end: Distance.metres(29.0), across: Across.metres(-7.0) },
		{ past_end: Distance.metres(32.0), across: Across.metres(-17.0) },
		{ past_end: Distance.metres(28.0), across: Across.metres(-28.0) },
		{ past_end: Distance.metres(29.0), across: Across.metres(-28.0) },
		{ past_end: Distance.metres(33.0), across: Across.metres(-17.0) },
		{ past_end: Distance.metres(30.0), across: Across.metres(-7.0) },
	]

	bank_color : RgbColor
	bank_color = RgbColor.of(0xC2B280)

	## Where `point` lies on a segment `length` long, whose end it is measured
	## from. This is the one place a pond point becomes an `Along`.
	segment_point : Pond.PondPoint, Distance -> Geom.RoadPoint
	segment_point = |point, length| {
		along: Along.at(length).plus(point.past_end),
		across: point.across,
	}

	## The ducks, placed on a segment `length` long.
	placed_ducks : Distance -> List(Geom.Placed(Billboard))
	placed_ducks = |length|
		ducks.map(
			|pond_duck| {
				on_segment = Pond.segment_point(pond_duck.at, length)
				{
					road_point: { along: on_segment.along, across: on_segment.across },
					lift: Distance.zero,
					kind: Billboard.adult_billboard(duck, pond_duck.facing),
				}
			},
		)
}

## The duck's still, and how tall a duck stands.
duck : Billboard.Species
duck = { still: EmojiStills.duck, adult_height: Distance.metres(0.9) }

## A duck on the pond, where it floats and which way it faces.
Duck : { at : Pond.PondPoint, facing : Billboard.Facing }

ducks : List(Duck)
ducks = [
	{ at: { past_end: Distance.metres(11.0), across: Across.metres(-10.0) }, facing: FacesRight },
	{ at: { past_end: Distance.metres(17.0), across: Across.metres(-18.0) }, facing: FacesLeft },
	{ at: { past_end: Distance.metres(21.0), across: Across.metres(-11.0) }, facing: FacesRight },
	{ at: { past_end: Distance.metres(6.0), across: Across.metres(-6.0) }, facing: FacesRight },
	{ at: { past_end: Distance.metres(7.0), across: Across.metres(-14.0) }, facing: FacesLeft },
	{ at: { past_end: Distance.metres(8.0), across: Across.metres(-22.0) }, facing: FacesRight },
]

expect
	Pond.segment_point(
		{ past_end: Distance.metres(6.0), across: Across.metres(-22.0) },
		Distance.metres(100.0),
	)
		== { along: Along.metres(106.0), across: Across.metres(-22.0) }
expect
	Pond.placed_ducks(Distance.metres(100.0)).map(|placed| placed.road_point.along.to_metres())
		== [111.0, 117.0, 121.0, 106.0, 107.0, 108.0]
expect Pond.placed_ducks(Distance.metres(100.0)).all(|placed| placed.kind.height.to_metres() == 0.9)

## Whether a duck floats within the water's reach, along the road and across it.
is_on_water : Duck -> Bool
is_on_water = |pond_duck| {
	is_within = |value, bounds|
		bounds.any(|bound| bound <= value) and bounds.any(|bound| bound >= value)
	acrosses = Pond.water_points.map(|point| point.across.to_metres())
	past_ends = Pond.water_points.map(|point| point.past_end.to_metres())
	is_within(pond_duck.at.across.to_metres(), acrosses)
		and is_within(pond_duck.at.past_end.to_metres(), past_ends)
}

expect ducks.all(is_on_water)

# A duck just past each edge of the water is off it.
expect
	[
		{ past_end: Distance.metres(2.9), across: Across.metres(-10.0) },
		{ past_end: Distance.metres(32.1), across: Across.metres(-10.0) },
		{ past_end: Distance.metres(10.0), across: Across.metres(-2.9) },
		{ past_end: Distance.metres(10.0), across: Across.metres(-33.1) },
	].all(|at| !is_on_water({ at, facing: FacesRight }))

expect
	ducks.map(|pond_duck| pond_duck.facing == FacesRight)
		== [True, False, True, True, False, True]
