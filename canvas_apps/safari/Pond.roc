## The duck pond past the corner at a segment's end: its water, its bank, and
## the ducks on it. A point on the pond is measured from that corner, along
## the road and across it, in metres.
import Across
import Along
import Billboards
import Distance

Pond :: [].{
	PondPt : { along : Along, across : Across }
	Duck : { at : Pond.PondPt, facing : Billboards.Facing }

	water_outline : List(Pond.PondPt)
	water_outline = [
		{ along: Along.metres(3.0), across: Across.metres(-2.0) },
		{ along: Along.metres(3.0), across: Across.metres(-28.0) },
		{ along: Along.metres(14.0), across: Across.metres(-31.0) },
		{ along: Along.metres(28.0), across: Across.metres(-26.0) },
		{ along: Along.metres(32.0), across: Across.metres(-15.0) },
		{ along: Along.metres(29.0), across: Across.metres(-5.0) },
		{ along: Along.metres(16.0), across: Across.metres(-1.0) },
	]

	water_color : I64
	water_color = 3112588

	bank : List(Pond.PondPt)
	bank = [
		{ along: Along.metres(29.0), across: Across.metres(-5.0) },
		{ along: Along.metres(32.0), across: Across.metres(-15.0) },
		{ along: Along.metres(28.0), across: Across.metres(-26.0) },
		{ along: Along.metres(29.0), across: Across.metres(-26.0) },
		{ along: Along.metres(33.0), across: Across.metres(-15.0) },
		{ along: Along.metres(30.0), across: Across.metres(-5.0) },
	]

	bank_color : I64
	bank_color = 12759680

	duck_codepoint : I64
	duck_codepoint = 129414

	duck_height : Distance
	duck_height = Distance.metres(0.9)

	ducks : List(Pond.Duck)
	ducks = [
		{ at: { along: Along.metres(11.0), across: Across.metres(-8.0) }, facing: FacesRight },
		{ at: { along: Along.metres(17.0), across: Across.metres(-16.0) }, facing: FacesLeft },
		{ at: { along: Along.metres(21.0), across: Across.metres(-9.0) }, facing: FacesRight },
		{ at: { along: Along.metres(6.0), across: Across.metres(-4.0) }, facing: FacesRight },
		{ at: { along: Along.metres(7.0), across: Across.metres(-12.0) }, facing: FacesLeft },
		{ at: { along: Along.metres(8.0), across: Across.metres(-20.0) }, facing: FacesRight },
	]
}
