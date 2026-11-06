## The Roc bird's drawings, in the two purples of roc-lang.org's logo. The
## perched bird is the logo itself. All of them are in units of their height, as
## the other stills are (the bottom at y 0, y up, height 1). A flying bird is wider
## than a perched one, so x runs from -1 to 1.
##
## From the side the beak points toward +x, as the perched bird's does. The
## two side views alternate as the wings beat. The bird flying toward us and
## away from us are seen head on and tail on, and the diving bird falls with
## its beak down and its wings swept back.
import BirdFlight
import Stills

BirdStills :: [].{

	## The drawing for a pose.
	pose_polys : BirdFlight.Pose -> List(Stills.StillPoly)
	pose_polys = |pose|
		match pose {
			Perched => perched
			Side(WingsUp) => side_wings_up
			Side(WingsDown) => side_wings_down
			Away(WingsUp) => away_wings_up
			Away(WingsDown) => away_wings_down
			Diving => diving
		}

	## Sitting on a treetop: the logo, beak toward +x.
	perched : List(Stills.StillPoly)
	perched = [
		{ color: logo_dark, grad: [], pts: [{ x: -0.0344, y: 0.5715 }, { x: -0.148, y: 0.0 }, { x: 0.0368, y: 0.1469 }, { x: 0.0183, y: 0.2577 }] },
		{ color: logo_light, grad: [], pts: [{ x: 0.2216, y: 0.6413 }, { x: 0.3497, y: 0.5025 }, { x: 0.3679, y: 0.5849 }, { x: 0.3862, y: 0.6862 }] },
		{ color: logo_light, grad: [], pts: [{ x: -0.0305, y: 0.9394 }, { x: -0.4811, y: 1.0 }, { x: -0.0344, y: 0.5715 }] },
		{ color: logo_light, grad: [], pts: [{ x: 0.3497, y: 0.5025 }, { x: -0.0344, y: 0.5715 }, { x: 0.0183, y: 0.2577 }] },
		{ color: logo_dark, grad: [], pts: [{ x: 0.4717, y: 0.5849 }, { x: 0.3862, y: 0.6862 }, { x: 0.3679, y: 0.5849 }] },
		{ color: logo_dark, grad: [], pts: [{ x: -0.0344, y: 0.5715 }, { x: 0.3497, y: 0.5025 }, { x: 0.2216, y: 0.6413 }, { x: -0.0305, y: 0.9394 }] },
	]

	## Seen from the side, with the wing at the top of its beat.
	side_wings_up : List(Stills.StillPoly)
	side_wings_up = [
		{ color: logo_dark, grad: [], pts: [{ x: -0.45, y: 0.42 }, { x: -0.8, y: 0.5 }, { x: -0.74, y: 0.32 }, { x: -0.1, y: 0.3 }] },
		{ color: logo_light, grad: [], pts: [{ x: -0.45, y: 0.42 }, { x: 0.3, y: 0.52 }, { x: 0.36, y: 0.4 }, { x: -0.1, y: 0.3 }] },
		{ color: logo_dark, grad: [], pts: [{ x: 0.3, y: 0.52 }, { x: 0.52, y: 0.5 }, { x: 0.36, y: 0.4 }] },
		{ color: logo_light, grad: [], pts: [{ x: 0.52, y: 0.5 }, { x: 0.66, y: 0.43 }, { x: 0.44, y: 0.44 }] },
		{ color: logo_dark, grad: [], pts: [{ x: -0.12, y: 0.46 }, { x: 0.18, y: 0.5 }, { x: -0.18, y: 0.98 }, { x: -0.42, y: 0.9 }] },
		{ color: logo_light, grad: [], pts: [{ x: -0.18, y: 0.98 }, { x: -0.42, y: 0.9 }, { x: -0.64, y: 1.0 }] },
	]

	## Seen from the side, with the wing at the bottom of its beat.
	side_wings_down : List(Stills.StillPoly)
	side_wings_down = [
		{ color: logo_dark, grad: [], pts: [{ x: -0.45, y: 0.52 }, { x: -0.8, y: 0.6 }, { x: -0.74, y: 0.42 }, { x: -0.1, y: 0.4 }] },
		{ color: logo_light, grad: [], pts: [{ x: -0.45, y: 0.52 }, { x: 0.3, y: 0.62 }, { x: 0.36, y: 0.5 }, { x: -0.1, y: 0.4 }] },
		{ color: logo_dark, grad: [], pts: [{ x: 0.3, y: 0.62 }, { x: 0.52, y: 0.6 }, { x: 0.36, y: 0.5 }] },
		{ color: logo_light, grad: [], pts: [{ x: 0.52, y: 0.6 }, { x: 0.66, y: 0.53 }, { x: 0.44, y: 0.54 }] },
		{ color: logo_dark, grad: [], pts: [{ x: -0.12, y: 0.52 }, { x: 0.18, y: 0.54 }, { x: -0.02, y: 0.08 }, { x: -0.3, y: 0.14 }] },
		{ color: logo_light, grad: [], pts: [{ x: -0.02, y: 0.08 }, { x: -0.3, y: 0.14 }, { x: -0.3, y: 0.0 }] },
	]

	## Flying toward us: head on, wings spread, beak in the middle. No pose
	## shows it yet.
	toward_us : List(Stills.StillPoly)
	toward_us = [
		{ color: logo_light, grad: [], pts: [{ x: -0.08, y: 0.54 }, { x: -0.86, y: 0.82 }, { x: -0.98, y: 0.62 }, { x: -0.08, y: 0.38 }] },
		{ color: logo_dark, grad: [], pts: [{ x: 0.08, y: 0.54 }, { x: 0.86, y: 0.82 }, { x: 0.98, y: 0.62 }, { x: 0.08, y: 0.38 }] },
		{ color: logo_dark, grad: [], pts: [{ x: -0.1, y: 0.56 }, { x: 0.1, y: 0.56 }, { x: 0.06, y: 0.28 }, { x: -0.06, y: 0.28 }] },
		{ color: logo_light, grad: [], pts: [{ x: -0.06, y: 0.28 }, { x: 0.06, y: 0.28 }, { x: 0.0, y: 0.12 }] },
		{ color: logo_light, grad: [], pts: [{ x: -0.1, y: 0.56 }, { x: 0.1, y: 0.56 }, { x: 0.0, y: 0.74 }] },
		{ color: logo_dark, grad: [], pts: [{ x: -0.04, y: 0.6 }, { x: 0.04, y: 0.6 }, { x: 0.0, y: 0.5 }] },
	]

	## Flying away from us: tail on, wings spread, the tail fanned, no beak.
	away_wings_up : List(Stills.StillPoly)
	away_wings_up = [
		{ color: logo_dark, grad: [], pts: [{ x: -0.06, y: 0.58 }, { x: -0.96, y: 0.86 }, { x: -0.92, y: 0.66 }, { x: -0.06, y: 0.42 }] },
		{ color: logo_light, grad: [], pts: [{ x: 0.06, y: 0.58 }, { x: 0.96, y: 0.86 }, { x: 0.92, y: 0.66 }, { x: 0.06, y: 0.42 }] },
		{ color: logo_light, grad: [], pts: [{ x: -0.1, y: 0.62 }, { x: 0.1, y: 0.62 }, { x: 0.08, y: 0.3 }, { x: -0.08, y: 0.3 }] },
		{ color: logo_dark, grad: [], pts: [{ x: -0.08, y: 0.32 }, { x: 0.08, y: 0.32 }, { x: 0.22, y: 0.08 }, { x: 0.0, y: 0.0 }, { x: -0.22, y: 0.08 }] },
	]

	## Flying away from us with the wings at the bottom of their beat.
	away_wings_down : List(Stills.StillPoly)
	away_wings_down = [
		{ color: logo_dark, grad: [], pts: [{ x: -0.06, y: 0.56 }, { x: -0.94, y: 0.36 }, { x: -0.86, y: 0.2 }, { x: -0.06, y: 0.4 }] },
		{ color: logo_light, grad: [], pts: [{ x: 0.06, y: 0.56 }, { x: 0.94, y: 0.36 }, { x: 0.86, y: 0.2 }, { x: 0.06, y: 0.4 }] },
		{ color: logo_light, grad: [], pts: [{ x: -0.1, y: 0.62 }, { x: 0.1, y: 0.62 }, { x: 0.08, y: 0.3 }, { x: -0.08, y: 0.3 }] },
		{ color: logo_dark, grad: [], pts: [{ x: -0.08, y: 0.32 }, { x: 0.08, y: 0.32 }, { x: 0.22, y: 0.08 }, { x: 0.0, y: 0.0 }, { x: -0.22, y: 0.08 }] },
	]

	## Diving: seen from the side, beak down and wings swept back.
	diving : List(Stills.StillPoly)
	diving = [
		{ color: logo_dark, grad: [], pts: [{ x: -0.2, y: 0.9 }, { x: 0.0, y: 0.96 }, { x: -0.16, y: 1.0 }, { x: -0.3, y: 1.0 }] },
		{ color: logo_dark, grad: [], pts: [{ x: -0.04, y: 0.68 }, { x: 0.08, y: 0.5 }, { x: -0.5, y: 0.94 }, { x: -0.62, y: 0.8 }] },
		{ color: logo_light, grad: [], pts: [{ x: -0.2, y: 0.9 }, { x: 0.0, y: 0.96 }, { x: 0.22, y: 0.3 }, { x: 0.08, y: 0.24 }] },
		{ color: logo_light, grad: [], pts: [{ x: 0.02, y: 0.76 }, { x: 0.12, y: 0.58 }, { x: 0.46, y: 1.0 }, { x: 0.3, y: 1.0 }] },
		{ color: logo_dark, grad: [], pts: [{ x: 0.08, y: 0.24 }, { x: 0.22, y: 0.3 }, { x: 0.2, y: 0.1 }] },
		{ color: logo_light, grad: [], pts: [{ x: 0.12, y: 0.16 }, { x: 0.24, y: 0.18 }, { x: 0.25, y: 0.0 }] },
	]
}

logo_dark : I64
logo_dark = 6368222

logo_light : I64
logo_light = 8542181

# A still's polygon count, corner count and gradient count.
still_counts : List(Stills.StillPoly) -> List(I64)
still_counts = |polys| [
	polys.len().to_i64_wrap(),
	polys.fold(0, |sum, poly| sum + poly.pts.len().to_i64_wrap()),
	polys.fold(0, |sum, poly| sum + poly.grad.len().to_i64_wrap()),
]

expect
	[
		(BirdStills.pose_polys(Perched), [6, 21, 0]),
		(BirdStills.pose_polys(Side(WingsUp)), [6, 21, 0]),
		(BirdStills.pose_polys(Side(WingsDown)), [6, 21, 0]),
		(BirdStills.pose_polys(Away(WingsUp)), [4, 17, 0]),
		(BirdStills.pose_polys(Away(WingsDown)), [4, 17, 0]),
		(BirdStills.pose_polys(Diving), [6, 22, 0]),
		(BirdStills.toward_us, [6, 21, 0]),
	].all(|(polys, want)| still_counts(polys) == want)

# The first corner of a still's first polygon, which tells the drawings apart.
first_corner : List(Stills.StillPoly) -> List(F64)
first_corner = |polys| {
	first_poly = polys.first() ?? crash "every still has polygons"
	first_pt = first_poly.pts.first() ?? crash "every polygon has corners"
	[first_pt.x, first_pt.y]
}

expect
	[
		(BirdStills.pose_polys(Perched), [-0.0344, 0.5715]),
		(BirdStills.pose_polys(Side(WingsUp)), [-0.45, 0.42]),
		(BirdStills.pose_polys(Side(WingsDown)), [-0.45, 0.52]),
		(BirdStills.pose_polys(Away(WingsUp)), [-0.06, 0.58]),
		(BirdStills.pose_polys(Away(WingsDown)), [-0.06, 0.56]),
		(BirdStills.pose_polys(Diving), [-0.2, 0.9]),
		(BirdStills.toward_us, [-0.08, 0.54]),
	].all(|(polys, want)| first_corner(polys) == want)

every_still : List(List(Stills.StillPoly))
every_still = [
	BirdStills.pose_polys(Perched),
	BirdStills.pose_polys(Side(WingsUp)),
	BirdStills.pose_polys(Side(WingsDown)),
	BirdStills.pose_polys(Away(WingsUp)),
	BirdStills.pose_polys(Away(WingsDown)),
	BirdStills.pose_polys(Diving),
	BirdStills.toward_us,
]

# Whether every corner of a still has x from -1 to 1 and y from 0 to 1.
is_within_bounds : List(Stills.StillPoly) -> Bool
is_within_bounds = |polys|
	polys.all(
		|poly| poly.pts.all(|pt| pt.x >= -1.0 and pt.x <= 1.0 and pt.y >= 0.0 and pt.y <= 1.0),
	)

# Whether every polygon of a still is one of the logo's two purples.
is_logo_coloured : List(Stills.StillPoly) -> Bool
is_logo_coloured = |polys| polys.all(|poly| poly.color == 6368222 or poly.color == 8542181)

expect every_still.all(is_within_bounds)
expect
	!is_within_bounds([
		{
			color: 6368222,
			grad: [],
			pts: [{ x: 1.1, y: 0.5 }],
		},
	])

expect every_still.all(is_logo_coloured)
expect
	!is_logo_coloured([
		{
			color: 0,
			grad: [],
			pts: [],
		},
	])
