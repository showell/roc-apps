## The duck pond past the bend at a segment's end: its water, its bank, and
## the ducks on it. A point on the pond is measured along the road past the
## end of the segment, and across it from the middle of the road, in metres.
import Across
import Along
import Billboard
import Distance
import Geom
import lib.RgbColor

Pond :: [].{

	## A point on the pond, `past_end` along the road past the segment's end
	## and `across` from the middle of the road.
	PondPt : { past_end : Distance, across : Across }
	Duck : { at : Pond.PondPt, facing : Billboard.Facing }

	water_outline_points : List(Pond.PondPt)
	water_outline_points = [
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

	bank_points : List(Pond.PondPt)
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

	duck_codepoint : U32
	duck_codepoint = 129414

	duck_height : Distance
	duck_height = Distance.metres(0.9)

	ducks : List(Pond.Duck)
	ducks = [
		{
			at: { past_end: Distance.metres(11.0), across: Across.metres(-10.0) },
			facing: FacesRight,
		},
		{
			at: { past_end: Distance.metres(17.0), across: Across.metres(-18.0) },
			facing: FacesLeft,
		},
		{
			at: { past_end: Distance.metres(21.0), across: Across.metres(-11.0) },
			facing: FacesRight,
		},
		{ at: { past_end: Distance.metres(6.0), across: Across.metres(-6.0) }, facing: FacesRight },
		{ at: { past_end: Distance.metres(7.0), across: Across.metres(-14.0) }, facing: FacesLeft },
		{
			at: { past_end: Distance.metres(8.0), across: Across.metres(-22.0) },
			facing: FacesRight,
		},
	]

	## Where `point` lies on a segment `length` long, whose end it is measured
	## from. This is the one place a pond point becomes an `Along`.
	segment_point : Pond.PondPt, Distance -> Geom.RoadPoint
	segment_point = |point, length| {
		along: Along.at(length).plus(point.past_end),
		across: point.across,
	}

	## The ducks, placed on a segment `length` long.
	placed_ducks : Distance -> List(Geom.Placed(Billboard))
	placed_ducks = |length|
		ducks.map(
			|duck| {
				on_segment = Pond.segment_point(duck.at, length)
				{
					along: on_segment.along,
					across: on_segment.across,
					kind: {
						codepoint: duck_codepoint,
						height: duck_height,
						facing: duck.facing,
					},
				}
			},
		)
}

expect Pond.water_outline_points.len() == 7
expect Pond.bank_points.len() == 6
expect Pond.ducks.len() == 6
expect
	Pond.segment_point(
		{ past_end: Distance.metres(6.0), across: Across.metres(-22.0) },
		Distance.metres(100.0),
	)
		== { along: Along.metres(106.0), across: Across.metres(-22.0) }
expect
	Pond.placed_ducks(Distance.metres(100.0)).map(|duck| duck.along.to_metres())
		== [111.0, 117.0, 121.0, 106.0, 107.0, 108.0]
expect Pond.placed_ducks(Distance.metres(100.0)).all(|duck| duck.kind.height == Pond.duck_height)
expect Pond.water_color == RgbColor.of(0x2F7E8C)
expect Pond.bank_color == RgbColor.of(0xC2B280)
expect Pond.duck_codepoint == 129414
expect Pond.duck_height.to_metres() == 0.9

expect Pond.water_outline_points.get(0) == Ok({
	past_end: Distance.metres(3.0),
	across: Across.metres(-4.0),
})
expect Pond.water_outline_points.get(4) == Ok({
	past_end: Distance.metres(32.0),
	across: Across.metres(-17.0),
})
expect Pond.bank_points.get(0) == Ok({
	past_end: Distance.metres(29.0),
	across: Across.metres(-7.0),
})

is_on_water : Pond.Duck -> Bool
is_on_water = |duck|
	duck.at.across <= Across.metres(-3.0)
		and duck.at.across >= Across.metres(-33.0)
		and duck.at.past_end >= Distance.metres(3.0)
		and duck.at.past_end <= Distance.metres(32.0)

expect Pond.ducks.all(is_on_water)

expect
	Pond.ducks.map(|duck| duck.facing == FacesRight)
		== [True, False, True, True, False, True]
