## Placing is a robot setting a dish down on the table the way a body does:
## it carries the dish in front of it in both hands, and when it is standing
## at the table it reaches up and over the edge, leaning from the hips as far
## as it must for its arms to get there, lowers the dish level onto the
## cloth, lets go, and draws its hands back as it straightens up. Every hand
## position here is in the robot's own metres, from the spot its pose is
## measured from, as SideBody's are, and the arms are aimed at it, so a
## short-armed robot leans further than a long-armed one.
import Ease
import Figure
import RobotBody
import SideBody

Placing :: [].{

	## The hands and the lean at one moment of a placing, and whether the
	## dish is still in the hands or down on the table.
	Reach : {
		hand : Figure.Spot,
		lean : F64,
		dish : [InHands, Down],
	}

	## How many ticks a placing takes.
	placing_frames : I64
	placing_frames = 70

	## Where the hands hold a carried dish: in front of the chest, clear of
	## the body.
	carrying_hand : RobotBody.Proportions, Figure.Spot -> Figure.Spot
	carrying_hand = |body, hip| {
		shoulder = SideBody.shoulder(body, { hip, lean: 0.0 })
		arm = body.upper_arm + body.forearm
		{ across: (0.55 * arm).max(front_of(body) + 0.06), up: shoulder.up - 0.3 * body.upper_arm }
	}

	## The hands and lean `progress` through setting a dish down, the hands
	## starting at `carry` and the dish's base ending at `spot`, both from the
	## robot's spot.
	setting_down : RobotBody.Proportions,
	{
		hip : Figure.Spot,
		carry : Figure.Spot,
		spot : Figure.Spot,
		progress : F64,
	} -> Placing.Reach
	setting_down = |body, { hip, carry, spot, progress }| {
		bow = Placing.lean_to_reach(body, { hip, target: spot })
		above = { ..spot, up: spot.up + 0.12 }
		out = Ease.smooth(fraction_between(progress, 0.0, 0.35))
		down = Ease.smooth(fraction_between(progress, 0.35, 0.58))
		back = Ease.smooth(fraction_between(progress, 0.68, 1.0))
		lean_in = Ease.smooth(fraction_between(progress, 0.0, 0.4))
		lean_out = Ease.smooth(fraction_between(progress, 0.62, 1.0))
		shoulder = SideBody.shoulder(body, { hip, lean: 0.0 })
		hanging = { across: 0.06, up: shoulder.up - 0.95 * (body.upper_arm + body.forearm) }
		hand =
			if progress < 0.35 {
				arc = 0.05 * (F64.pi * out).sin()
				lifted = mix(carry, above, out)
				{ ..lifted, up: lifted.up + arc }
			} else if progress < 0.68 {
				mix(above, spot, down)
			} else {
				mix(spot, hanging, back)
			}
		{
			hand,
			lean: bow * lean_in * (1.0 - lean_out),
			dish: if progress < 0.62 {
				InHands
			} else {
				Down
			},
		}
	}

	## The least lean from the hips, in steps of a tenth of a radian, that brings
	## `target` within the arms' reach; the deepest bow if none does.
	lean_to_reach : RobotBody.Proportions, { hip : Figure.Spot, target : Figure.Spot } -> F64
	lean_to_reach = |body, { hip, target }| {
		reach = 0.93 * (body.upper_arm + body.forearm)
		leans = [0.0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9]
		found = leans.fold(
			Searching,
			|search, lean|
				match search {
					Found(_) => search
					Searching => {
						shoulder = SideBody.shoulder(body, { hip, lean })
						if distance(shoulder, target) <= reach {
							Found(lean)
						} else {
							Searching
						}
					}
				},
		)
		match found {
			Found(lean) => lean
			Searching => 0.9
		}
	}
}

# How far in front of the hips the body's front is.
front_of : RobotBody.Proportions -> F64
front_of = |body|
	match body.torso {
		Boxy => body.body_width * 0.375
		Barrel => body.body_width / 2.0
	}

distance : Figure.Spot, Figure.Spot -> F64
distance = |a, b| {
	across = b.across - a.across
	up = b.up - a.up
	(across * across + up * up).sqrt()
}

mix : Figure.Spot, Figure.Spot, F64 -> Figure.Spot
mix = |from, to, fraction| {
	across: from.across + (to.across - from.across) * fraction,
	up: from.up + (to.up - from.up) * fraction,
}

fraction_between : F64, F64, F64 -> F64
fraction_between = |progress, from, to|
	if progress <= from {
		0.0
	} else if progress >= to {
		1.0
	} else {
		(progress - from) / (to - from)
	}

# The dish ends exactly on its spot, and a long reach makes a robot lean.
expect {
	body = {
		hip: 0.86,
		body_width: 0.3,
		body_height: 0.6,
		torso: Boxy,
		neck: 0.07,
		head_width: 0.24,
		head_height: 0.21,
		upper_arm: 0.3,
		forearm: 0.28,
		limb_width: 0.055,
		moves_on: Legs,
		antenna: 0.12,
		paint: {
			r: 1.0,
			g: 1.0,
			b: 1.0,
			a: 1.0,
		},
		trim: {
			r: 0.0,
			g: 0.0,
			b: 0.0,
			a: 1.0,
		},
	}
	hip = { across: 0.0, up: 0.85 }
	spot = { across: 0.4, up: 0.74 }
	reaching = Placing.setting_down(
		body,
		{
			hip,
			carry: Placing.carrying_hand(body, hip),
			spot,
			progress: 0.6,
		},
	)
	reaching.hand == spot and Placing.lean_to_reach(body, { hip, target: spot }) > 0.2
}
