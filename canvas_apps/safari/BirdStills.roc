## The Roc bird in flight, as stills: five drawings in the logo's two purples,
## in the same unit frame as the other stills (the bottom at y 0, y up, height
## 1). A flying bird is wider than a perched one, so x runs from -1 to 1.
##
## From the side the beak points toward +x, as the perched bird's does. The
## two side views alternate as the wings beat. The bird flying toward us and
## away from us are seen head on and tail on, and the diving bird falls with
## its beak down and its wings swept back.
import Stills

BirdStills :: [].{

	## Seen from the side, with the wing at the top of its beat.
	wings_up : List(Stills.StillPoly)
	wings_up = [
		{ color: dark, grad: [], pts: [{ x: -0.45, y: 0.42 }, { x: -0.8, y: 0.5 }, { x: -0.74, y: 0.32 }, { x: -0.1, y: 0.3 }] },
		{ color: light, grad: [], pts: [{ x: -0.45, y: 0.42 }, { x: 0.3, y: 0.52 }, { x: 0.36, y: 0.4 }, { x: -0.1, y: 0.3 }] },
		{ color: dark, grad: [], pts: [{ x: 0.3, y: 0.52 }, { x: 0.52, y: 0.5 }, { x: 0.36, y: 0.4 }] },
		{ color: light, grad: [], pts: [{ x: 0.52, y: 0.5 }, { x: 0.66, y: 0.43 }, { x: 0.44, y: 0.44 }] },
		{ color: dark, grad: [], pts: [{ x: -0.12, y: 0.46 }, { x: 0.18, y: 0.5 }, { x: -0.18, y: 0.98 }, { x: -0.42, y: 0.9 }] },
		{ color: light, grad: [], pts: [{ x: -0.18, y: 0.98 }, { x: -0.42, y: 0.9 }, { x: -0.64, y: 1.0 }] },
	]

	## Seen from the side, with the wing at the bottom of its beat.
	wings_down : List(Stills.StillPoly)
	wings_down = [
		{ color: dark, grad: [], pts: [{ x: -0.45, y: 0.52 }, { x: -0.8, y: 0.6 }, { x: -0.74, y: 0.42 }, { x: -0.1, y: 0.4 }] },
		{ color: light, grad: [], pts: [{ x: -0.45, y: 0.52 }, { x: 0.3, y: 0.62 }, { x: 0.36, y: 0.5 }, { x: -0.1, y: 0.4 }] },
		{ color: dark, grad: [], pts: [{ x: 0.3, y: 0.62 }, { x: 0.52, y: 0.6 }, { x: 0.36, y: 0.5 }] },
		{ color: light, grad: [], pts: [{ x: 0.52, y: 0.6 }, { x: 0.66, y: 0.53 }, { x: 0.44, y: 0.54 }] },
		{ color: dark, grad: [], pts: [{ x: -0.12, y: 0.52 }, { x: 0.18, y: 0.54 }, { x: -0.02, y: 0.08 }, { x: -0.3, y: 0.14 }] },
		{ color: light, grad: [], pts: [{ x: -0.02, y: 0.08 }, { x: -0.3, y: 0.14 }, { x: -0.3, y: 0.0 }] },
	]

	## Flying toward us: head on, wings spread, beak in the middle.
	toward_us : List(Stills.StillPoly)
	toward_us = [
		{ color: light, grad: [], pts: [{ x: -0.08, y: 0.54 }, { x: -0.86, y: 0.82 }, { x: -0.98, y: 0.62 }, { x: -0.08, y: 0.38 }] },
		{ color: dark, grad: [], pts: [{ x: 0.08, y: 0.54 }, { x: 0.86, y: 0.82 }, { x: 0.98, y: 0.62 }, { x: 0.08, y: 0.38 }] },
		{ color: dark, grad: [], pts: [{ x: -0.1, y: 0.56 }, { x: 0.1, y: 0.56 }, { x: 0.06, y: 0.28 }, { x: -0.06, y: 0.28 }] },
		{ color: light, grad: [], pts: [{ x: -0.06, y: 0.28 }, { x: 0.06, y: 0.28 }, { x: 0.0, y: 0.12 }] },
		{ color: light, grad: [], pts: [{ x: -0.1, y: 0.56 }, { x: 0.1, y: 0.56 }, { x: 0.0, y: 0.74 }] },
		{ color: dark, grad: [], pts: [{ x: -0.04, y: 0.6 }, { x: 0.04, y: 0.6 }, { x: 0.0, y: 0.5 }] },
	]

	## Flying away from us: tail on, wings spread, the tail fanned, no beak.
	away_from_us : List(Stills.StillPoly)
	away_from_us = [
		{ color: dark, grad: [], pts: [{ x: -0.06, y: 0.58 }, { x: -0.96, y: 0.86 }, { x: -0.92, y: 0.66 }, { x: -0.06, y: 0.42 }] },
		{ color: light, grad: [], pts: [{ x: 0.06, y: 0.58 }, { x: 0.96, y: 0.86 }, { x: 0.92, y: 0.66 }, { x: 0.06, y: 0.42 }] },
		{ color: light, grad: [], pts: [{ x: -0.1, y: 0.62 }, { x: 0.1, y: 0.62 }, { x: 0.08, y: 0.3 }, { x: -0.08, y: 0.3 }] },
		{ color: dark, grad: [], pts: [{ x: -0.08, y: 0.32 }, { x: 0.08, y: 0.32 }, { x: 0.22, y: 0.08 }, { x: 0.0, y: 0.0 }, { x: -0.22, y: 0.08 }] },
	]

	## Diving: seen from the side, beak down and wings swept back.
	diving : List(Stills.StillPoly)
	diving = [
		{ color: dark, grad: [], pts: [{ x: -0.2, y: 0.9 }, { x: 0.0, y: 0.96 }, { x: -0.16, y: 1.0 }, { x: -0.3, y: 1.0 }] },
		{ color: dark, grad: [], pts: [{ x: -0.04, y: 0.68 }, { x: 0.08, y: 0.5 }, { x: -0.5, y: 0.94 }, { x: -0.62, y: 0.8 }] },
		{ color: light, grad: [], pts: [{ x: -0.2, y: 0.9 }, { x: 0.0, y: 0.96 }, { x: 0.22, y: 0.3 }, { x: 0.08, y: 0.24 }] },
		{ color: light, grad: [], pts: [{ x: 0.02, y: 0.76 }, { x: 0.12, y: 0.58 }, { x: 0.46, y: 1.0 }, { x: 0.3, y: 1.0 }] },
		{ color: dark, grad: [], pts: [{ x: 0.08, y: 0.24 }, { x: 0.22, y: 0.3 }, { x: 0.2, y: 0.1 }] },
		{ color: light, grad: [], pts: [{ x: 0.12, y: 0.16 }, { x: 0.24, y: 0.18 }, { x: 0.25, y: 0.0 }] },
	]
}

## The logo's two purples, as RocBird's perched still has them.
dark : I64
dark = 6368222

light : I64
light = 8542181
