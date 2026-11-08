## The Roc bird's drawings, in the two purples of roc-lang.org's logo. The
## perched bird is the logo itself. Each is in the still's own frame, which
## Still.roc describes. A flying bird is wider than a perched one, so x runs from
## -1 to 1.
##
## From the side the beak points toward +x, as the perched bird's does. The
## two side views alternate as the wings beat. The bird flying away from us is
## seen tail on, and the diving bird falls with its beak down and its wings swept
## back.
import Still
import lib.RgbColor

BirdStills :: [].{

	## Sitting on a treetop: the logo, beak toward +x.
	perched_still : Still
	perched_still = Still.of([
		{ fill: Flat(logo_dark), points: [{ x: -0.0344, y: 0.5715 }, { x: -0.148, y: 0.0 }, { x: 0.0368, y: 0.1469 }, { x: 0.0183, y: 0.2577 }] },
		{ fill: Flat(logo_light), points: [{ x: 0.2216, y: 0.6413 }, { x: 0.3497, y: 0.5025 }, { x: 0.3679, y: 0.5849 }, { x: 0.3862, y: 0.6862 }] },
		{ fill: Flat(logo_light), points: [{ x: -0.0305, y: 0.9394 }, { x: -0.4811, y: 1.0 }, { x: -0.0344, y: 0.5715 }] },
		{ fill: Flat(logo_light), points: [{ x: 0.3497, y: 0.5025 }, { x: -0.0344, y: 0.5715 }, { x: 0.0183, y: 0.2577 }] },
		{ fill: Flat(logo_dark), points: [{ x: 0.4717, y: 0.5849 }, { x: 0.3862, y: 0.6862 }, { x: 0.3679, y: 0.5849 }] },
		{ fill: Flat(logo_dark), points: [{ x: -0.0344, y: 0.5715 }, { x: 0.3497, y: 0.5025 }, { x: 0.2216, y: 0.6413 }, { x: -0.0305, y: 0.9394 }] },
	])

	## Seen from the side, with the wing at the top of its beat.
	side_wings_up_still : Still
	side_wings_up_still = Still.of([
		{ fill: Flat(logo_dark), points: [{ x: -0.45, y: 0.42 }, { x: -0.8, y: 0.5 }, { x: -0.74, y: 0.32 }, { x: -0.1, y: 0.3 }] },
		{ fill: Flat(logo_light), points: [{ x: -0.45, y: 0.42 }, { x: 0.3, y: 0.52 }, { x: 0.36, y: 0.4 }, { x: -0.1, y: 0.3 }] },
		{ fill: Flat(logo_dark), points: [{ x: 0.3, y: 0.52 }, { x: 0.52, y: 0.5 }, { x: 0.36, y: 0.4 }] },
		{ fill: Flat(logo_light), points: [{ x: 0.52, y: 0.5 }, { x: 0.66, y: 0.43 }, { x: 0.44, y: 0.44 }] },
		{ fill: Flat(logo_dark), points: [{ x: -0.12, y: 0.46 }, { x: 0.18, y: 0.5 }, { x: -0.18, y: 0.98 }, { x: -0.42, y: 0.9 }] },
		{ fill: Flat(logo_light), points: [{ x: -0.18, y: 0.98 }, { x: -0.42, y: 0.9 }, { x: -0.64, y: 1.0 }] },
	])

	## Seen from the side, with the wing at the bottom of its beat.
	side_wings_down_still : Still
	side_wings_down_still = Still.of([
		{ fill: Flat(logo_dark), points: [{ x: -0.45, y: 0.52 }, { x: -0.8, y: 0.6 }, { x: -0.74, y: 0.42 }, { x: -0.1, y: 0.4 }] },
		{ fill: Flat(logo_light), points: [{ x: -0.45, y: 0.52 }, { x: 0.3, y: 0.62 }, { x: 0.36, y: 0.5 }, { x: -0.1, y: 0.4 }] },
		{ fill: Flat(logo_dark), points: [{ x: 0.3, y: 0.62 }, { x: 0.52, y: 0.6 }, { x: 0.36, y: 0.5 }] },
		{ fill: Flat(logo_light), points: [{ x: 0.52, y: 0.6 }, { x: 0.66, y: 0.53 }, { x: 0.44, y: 0.54 }] },
		{ fill: Flat(logo_dark), points: [{ x: -0.12, y: 0.52 }, { x: 0.18, y: 0.54 }, { x: -0.02, y: 0.08 }, { x: -0.3, y: 0.14 }] },
		{ fill: Flat(logo_light), points: [{ x: -0.02, y: 0.08 }, { x: -0.3, y: 0.14 }, { x: -0.3, y: 0.0 }] },
	])

	## Flying away from us: tail on, wings spread, the tail fanned, no beak.
	away_wings_up_still : Still
	away_wings_up_still = Still.of([
		{ fill: Flat(logo_dark), points: [{ x: -0.06, y: 0.58 }, { x: -0.96, y: 0.86 }, { x: -0.92, y: 0.66 }, { x: -0.06, y: 0.42 }] },
		{ fill: Flat(logo_light), points: [{ x: 0.06, y: 0.58 }, { x: 0.96, y: 0.86 }, { x: 0.92, y: 0.66 }, { x: 0.06, y: 0.42 }] },
		{ fill: Flat(logo_light), points: [{ x: -0.1, y: 0.62 }, { x: 0.1, y: 0.62 }, { x: 0.08, y: 0.3 }, { x: -0.08, y: 0.3 }] },
		{ fill: Flat(logo_dark), points: [{ x: -0.08, y: 0.32 }, { x: 0.08, y: 0.32 }, { x: 0.22, y: 0.08 }, { x: 0.0, y: 0.0 }, { x: -0.22, y: 0.08 }] },
	])

	## Flying away from us with the wings at the bottom of their beat.
	away_wings_down_still : Still
	away_wings_down_still = Still.of([
		{ fill: Flat(logo_dark), points: [{ x: -0.06, y: 0.56 }, { x: -0.94, y: 0.36 }, { x: -0.86, y: 0.2 }, { x: -0.06, y: 0.4 }] },
		{ fill: Flat(logo_light), points: [{ x: 0.06, y: 0.56 }, { x: 0.94, y: 0.36 }, { x: 0.86, y: 0.2 }, { x: 0.06, y: 0.4 }] },
		{ fill: Flat(logo_light), points: [{ x: -0.1, y: 0.62 }, { x: 0.1, y: 0.62 }, { x: 0.08, y: 0.3 }, { x: -0.08, y: 0.3 }] },
		{ fill: Flat(logo_dark), points: [{ x: -0.08, y: 0.32 }, { x: 0.08, y: 0.32 }, { x: 0.22, y: 0.08 }, { x: 0.0, y: 0.0 }, { x: -0.22, y: 0.08 }] },
	])

	## Diving: seen from the side, beak down and wings swept back.
	diving_still : Still
	diving_still = Still.of([
		{ fill: Flat(logo_dark), points: [{ x: -0.2, y: 0.9 }, { x: 0.0, y: 0.96 }, { x: -0.16, y: 1.0 }, { x: -0.3, y: 1.0 }] },
		{ fill: Flat(logo_dark), points: [{ x: -0.04, y: 0.68 }, { x: 0.08, y: 0.5 }, { x: -0.5, y: 0.94 }, { x: -0.62, y: 0.8 }] },
		{ fill: Flat(logo_light), points: [{ x: -0.2, y: 0.9 }, { x: 0.0, y: 0.96 }, { x: 0.22, y: 0.3 }, { x: 0.08, y: 0.24 }] },
		{ fill: Flat(logo_light), points: [{ x: 0.02, y: 0.76 }, { x: 0.12, y: 0.58 }, { x: 0.46, y: 1.0 }, { x: 0.3, y: 1.0 }] },
		{ fill: Flat(logo_dark), points: [{ x: 0.08, y: 0.24 }, { x: 0.22, y: 0.3 }, { x: 0.2, y: 0.1 }] },
		{ fill: Flat(logo_light), points: [{ x: 0.12, y: 0.16 }, { x: 0.24, y: 0.18 }, { x: 0.25, y: 0.0 }] },
	])
}

logo_dark : RgbColor
logo_dark = RgbColor.of(0x612BDE)

logo_light : RgbColor
logo_light = RgbColor.of(0x8257E5)

all_stills : List(Still)
all_stills = [
	BirdStills.perched_still,
	BirdStills.side_wings_up_still,
	BirdStills.side_wings_down_still,
	BirdStills.away_wings_up_still,
	BirdStills.away_wings_down_still,
	BirdStills.diving_still,
]

# Whether every corner of a still has x from -1 to 1 and y from 0 to 1.
is_within_bounds : Still -> Bool
is_within_bounds = |still|
	still.polygons().all(
		|poly| poly.points.all(|pt| pt.x >= -1.0 and pt.x <= 1.0 and pt.y >= 0.0 and pt.y <= 1.0),
	)

# Whether every polygon of a still is one of the logo's two purples.
is_logo_coloured : Still -> Bool
is_logo_coloured = |still| still.polygons().all(|poly| poly.fill == Flat(logo_dark) or poly.fill == Flat(logo_light))

expect all_stills.all(is_within_bounds)
expect
	!is_within_bounds(
		Still.of([
			{
				fill: Flat(logo_dark),
				points: [{ x: 1.1, y: 0.5 }],
			},
		]),
	)

expect all_stills.all(is_logo_coloured)
expect
	!is_logo_coloured(
		Still.of([
			{
				fill: Flat(RgbColor.of(0)),
				points: [],
			},
		]),
	)
