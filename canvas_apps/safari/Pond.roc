## The duck pond past the corner at a segment's end: its water, its bank, and
## the ducks on it. A point on the pond is measured from that corner, along
## the road and across it, in metres.
import Billboards
import Distance

Pond :: [].{
	PondPt : { along : F64, across : F64 }
	Duck : { at : Pond.PondPt, facing : Billboards.Facing }

	water_outline : List(Pond.PondPt)
	water_outline = [
		{ along: 3.0, across: (-2.0) },
		{ along: 3.0, across: (-28.0) },
		{ along: 14.0, across: (-31.0) },
		{ along: 28.0, across: (-26.0) },
		{ along: 32.0, across: (-15.0) },
		{ along: 29.0, across: (-5.0) },
		{ along: 16.0, across: (-1.0) },
	]

	water_color : I64
	water_color = 3112588

	bank : List(Pond.PondPt)
	bank = [
		{ along: 29.0, across: (-5.0) },
		{ along: 32.0, across: (-15.0) },
		{ along: 28.0, across: (-26.0) },
		{ along: 29.0, across: (-26.0) },
		{ along: 33.0, across: (-15.0) },
		{ along: 30.0, across: (-5.0) },
	]

	bank_color : I64
	bank_color = 12759680

	duck_codepoint : I64
	duck_codepoint = 129414

	duck_height : Distance
	duck_height = Distance.metres(0.9)

	ducks : List(Pond.Duck)
	ducks = [
		{ at: { along: 11.0, across: (-8.0) }, facing: FacesRight },
		{ at: { along: 17.0, across: (-16.0) }, facing: FacesLeft },
		{ at: { along: 21.0, across: (-9.0) }, facing: FacesRight },
		{ at: { along: 6.0, across: (-4.0) }, facing: FacesRight },
		{ at: { along: 7.0, across: (-12.0) }, facing: FacesLeft },
		{ at: { along: 8.0, across: (-20.0) }, facing: FacesRight },
	]
}
