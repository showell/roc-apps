## Seating is a robot walking up to its chair and sitting down in it the way
## a body does, as SideBody draws it, side on. It walks in along the aisle
## beside the chairs, the feet planted in turn and the hips riding over them,
## and stops beside its chair. Then it reaches back and pulls the chair out,
## shuffles back in front of the seat, and sits: it leans forward over its
## feet, lowers its hips back and down onto the seat as the knees bend,
## brings the torso upright as it lands, and scoots the chair in with the
## seat under it. Last, its hands go to the edge of the table. A robot on a
## wheel has no knees to bend, so instead it puts its hands back on the seat
## and hoists itself up onto it.
##
## A plan says where the chair is and when the robot sets off, arrives and
## starts on its chair; each step after that takes its own fixed time.
## Before the chair the arms are the caller's, so a robot can carry a dish
## in and set it down.
import lib.Eye
import Ease
import Figure
import Robot
import SideBody

Seating :: [].{

	## Where a robot walks in from and to, its chair, and when it does what.
	## `walk_from` is how far right it sets off along the aisle, `stop_right`
	## where it stops beside its chair, and `setback` how far in front of the
	## seat's middle it stands to sit. `step` is the length of a whole stride,
	## both feet, in metres.
	Plan : {
		build : Robot.Build,
		walk_from : F64,
		stop_right : F64,
		aisle_forward : F64,
		chair : {
			right : F64,
			forward : F64,
			seat_height : F64,
		},
		setback : F64,
		step : F64,
		enter_tick : I64,
		arrive_tick : I64,
		chair_tick : I64,
	}

	## A robot at one tick: the ground spot its pose is measured from, the
	## pose, how far its chair is pulled out from its place, and how far the
	## walk has gone round, in radians.
	Guest : {
		at : Eye.At,
		pose : SideBody.Pose,
		chair_pulled : F64,
		walk_phase : F64,
	}

	## The robot at `now`, its arms carrying as `carry` says until it starts
	## on its chair, and looking and lit as the caller says throughout.
	guest_at : Seating.Plan,
	{
		now : I64,
		carry : SideBody.Arm,
		look : F64,
		glow : F64,
	} -> Seating.Guest
	guest_at = |plan, { now, carry, look, glow }| {
		stage = stage_at(plan, now)
		{
			at: stage.at,
			pose: {
				hip: stage.hip,
				near_foot: stage.near_foot,
				far_foot: stage.far_foot,
				lean: stage.lean,
				head_tilt: 0.0 - 0.6 * stage.lean,
				near_arm: if now < plan.chair_tick {
					carry
				} else {
					stage.near_arm
				},
				far_arm: stage.far_arm,
				wheel_turn: stage.walked / 0.09,
				look,
				glow,
			},
			chair_pulled: stage.chair_pulled,
			walk_phase: stage.walked * F64.tau / plan.step,
		}
	}

	## The tick by which a robot is sat with its chair in and its hands on the
	## table.
	seated_tick : Seating.Plan -> I64
	seated_tick = |plan| Seating.sit_tick(plan) + sit_frames + scoot_frames + rest_frames

	## The tick its hips start down onto the seat.
	sit_tick : Seating.Plan -> I64
	sit_tick = |plan| plan.chair_tick + pull_frames + shuffle_frames

	## How far a robot pulls its chair out, in metres.
	pull_metres : F64
	pull_metres = 0.25
}

pull_frames : I64
pull_frames = 26

shuffle_frames : I64
shuffle_frames = 34

sit_frames : I64
sit_frames = 66

scoot_frames : I64
scoot_frames = 26

rest_frames : I64
rest_frames = 22

# Everything about a stage of the sit that changes over it.
Stage : {
	at : Eye.At,
	hip : Figure.Spot,
	near_foot : Figure.Spot,
	far_foot : Figure.Spot,
	lean : F64,
	near_arm : SideBody.Arm,
	far_arm : SideBody.Arm,
	chair_pulled : F64,
	walked : F64,
}

hanging : SideBody.Arm
hanging = { upper: 0.05, fore: 0.1 }

stage_at : Seating.Plan, I64 -> Stage
stage_at = |plan, now| {
	pulled_at = plan.chair_tick + pull_frames
	shuffled_at = pulled_at + shuffle_frames
	sat_at = shuffled_at + sit_frames
	scooted_at = sat_at + scoot_frames
	if now < plan.chair_tick {
		walking_stage(plan, now)
	} else if now < pulled_at {
		pulling_stage(plan, Ease.ramp(now - plan.chair_tick, pull_frames))
	} else if now < shuffled_at {
		shuffling_stage(plan, Ease.ramp(now - pulled_at, shuffle_frames))
	} else if now < sat_at {
		lowered_stage(plan, Ease.ramp(now - shuffled_at, sit_frames))
	} else {
		scooting_stage(
			plan,
			{
				scooted: Ease.ramp(now - sat_at, scoot_frames),
				rested: Ease.ramp(now - scooted_at, rest_frames),
			},
		)
	}
}

# How far along the aisle the robot has walked at `now`.
walked_right : Seating.Plan, I64 -> F64
walked_right = |plan, now| {
	progress = Ease.smooth(Ease.ramp(now - plan.enter_tick, plan.arrive_tick - plan.enter_tick))
	plan.walk_from + (plan.stop_right - plan.walk_from) * progress
}

# How much walking is going on, from the ground covered over the last five
# ticks against a brisk pace for the walk, so the stride dies away as it
# stops.
stride_at : Seating.Plan, I64 -> F64
stride_at = |plan, now| {
	covered = (walked_right(plan, now) - walked_right(plan, now - 5)).abs()
	walk_frames = (plan.arrive_tick - plan.enter_tick).to_f64()
	brisk = 0.6 * 5.0 * walk_length(plan).abs() / walk_frames
	(covered / brisk).min(1.0)
}

walking_stage : Seating.Plan, I64 -> Stage
walking_stage = |plan, now| {
	right = walked_right(plan, now)
	walked = right - plan.walk_from
	stride = stride_at(plan, now)
	gait = gait_at(plan, { phase: walked * F64.tau / plan.step, stride })
	{
		at: { right, forward: plan.aisle_forward, height: 0.0 },
		hip: gait.hip,
		near_foot: gait.near_foot,
		far_foot: gait.far_foot,
		lean: 0.05 * stride,
		near_arm: hanging,
		far_arm: { upper: 0.05 - 0.3 * stride * (walked * F64.tau / plan.step).sin(), fore: 0.15 },
		chair_pulled: 0.0,
		walked,
	}
}

# Where the hips and the ankles are `phase` radians through a walk, taking
# strides `stride` of a full one: each foot is planted for half the stride
# and slides back under the hips as they pass over it, then lifts and
# swings forward. The hips dip a little as the feet pass.
gait_at : Seating.Plan,
{ phase : F64, stride : F64 } -> {
	hip : Figure.Spot,
	near_foot : Figure.Spot,
	far_foot : Figure.Spot,
}
gait_at = |plan, { phase, stride }| {
	body = Robot.proportions(plan.build)
	half = plan.step / 2.0 * stride
	lift = 0.2 * SideBody.bone_length(body) * stride
	foot = |turned| {
		cycle = turned / F64.tau
		whole = cycle - cycle.to_i64_wrap().to_f64()
		part = if whole < 0.0 {
			whole + 1.0
		} else {
			whole
		}
		if part < 0.5 {
			{ across: half / 2.0 - half * (part / 0.5), up: SideBody.ankle_height }
		} else {
			swing = (part - 0.5) / 0.5
			{
				across: 0.0 - half / 2.0 + half * Ease.smooth(swing),
				up: SideBody.ankle_height + lift * (F64.pi * swing).sin(),
			}
		}
	}
	dip = 0.02 * stride * (1.0 - (2.0 * phase).cos()) / 2.0
	{
		hip: { across: 0.0, up: SideBody.standing_hip(body) - dip },
		near_foot: foot(phase),
		far_foot: foot(phase + F64.pi),
	}
}

# How far the whole walk in goes, which a wheel keeps turned once it stops.
walk_length : Seating.Plan -> F64
walk_length = |plan| plan.stop_right - plan.walk_from

standing_hip_spot : Seating.Plan -> Figure.Spot
standing_hip_spot = |plan| { across: 0.0, up: SideBody.standing_hip(Robot.proportions(plan.build)) }

planted : Figure.Spot
planted = { across: 0.05, up: SideBody.ankle_height }

# Reaching back for the chair and drawing it out: the near arm goes back
# over the first half, and the chair comes with it over the second.
pulling_stage : Seating.Plan, F64 -> Stage
pulling_stage = |plan, progress| {
	reach = Ease.smooth(fraction_between(progress, 0.0, 0.5))
	draw = Ease.smooth(fraction_between(progress, 0.4, 1.0))
	{
		at: {
			right: plan.stop_right,
			forward: plan.aisle_forward,
			height: 0.0,
		},
		hip: standing_hip_spot(plan),
		near_foot: planted,
		far_foot: { ..planted, across: -0.05 },
		lean: 0.08 * reach,
		near_arm: {
			upper: 0.05 - 0.75 * reach + 0.25 * draw,
			fore: 0.1 - 0.9 * reach + 0.3 * draw,
		},
		far_arm: hanging,
		chair_pulled: Seating.pull_metres * draw,
		walked: walk_length(plan),
	}
}

# Small steps back and in, from the aisle to just in front of the seat.
shuffling_stage : Seating.Plan, F64 -> Stage
shuffling_stage = |plan, progress| {
	moved = Ease.smooth(progress)
	to_right = plan.chair.right - Seating.pull_metres + plan.setback
	gait = gait_at(
		plan,
		{ phase: 2.0 * F64.tau * progress, stride: 0.35 * (F64.pi * progress).sin() },
	)
	{
		at: {
			right: plan.stop_right + (to_right - plan.stop_right) * moved,
			forward: plan.aisle_forward + (plan.chair.forward - plan.aisle_forward) * moved,
			height: 0.0,
		},
		hip: gait.hip,
		near_foot: { ..gait.near_foot, across: gait.near_foot.across + planted.across * moved },
		far_foot: { ..gait.far_foot, across: gait.far_foot.across + planted.across * moved },
		lean: 0.0,
		near_arm: hanging,
		far_arm: hanging,
		chair_pulled: Seating.pull_metres,
		walked: walk_length(plan),
	}
}

# Down onto the seat, by the knees or, on a wheel, by the arms.
lowered_stage : Seating.Plan, F64 -> Stage
lowered_stage = |plan, progress|
	match Robot.proportions(plan.build).moves_on {
		Legs => sitting_stage(plan, progress)
		Wheel => hoisting_stage(plan, progress)
	}

# Down onto the seat: lean forward over the feet first, then the hips go
# back and down while the knees bend, the torso comes upright as they land,
# and they settle a centimetre. The hands go forward to balance.
sitting_stage : Seating.Plan, F64 -> Stage
sitting_stage = |plan, progress| {
	stand = SideBody.standing_hip(Robot.proportions(plan.build))
	seat = plan.chair.seat_height + 0.025
	back = Ease.smooth(fraction_between(progress, 0.1, 0.85))
	down = Ease.smooth(fraction_between(progress, 0.2, 0.88))
	settle = 0.012 * (F64.pi * fraction_between(progress, 0.85, 1.0)).sin()
	lean_in = Ease.smooth(fraction_between(progress, 0.0, 0.4))
	lean_out = Ease.smooth(fraction_between(progress, 0.65, 1.0))
	brace = lean_in * (1.0 - lean_out)
	{
		at: {
			right: plan.chair.right - Seating.pull_metres + plan.setback,
			forward: plan.chair.forward,
			height: 0.0,
		},
		hip: { across: 0.0 - plan.setback * back, up: stand + (seat - stand) * down - settle },
		near_foot: planted,
		far_foot: { ..planted, across: planted.across - 0.06 },
		lean: 0.04 + 0.5 * brace,
		near_arm: { upper: 0.05 + 0.6 * brace, fore: 0.1 + 0.9 * brace },
		far_arm: { upper: 0.05 + 0.5 * brace, fore: 0.1 + 0.8 * brace },
		chair_pulled: Seating.pull_metres,
		walked: walk_length(plan),
	}
}

# The chair scooted in under the seated robot, a little lift as it goes, and
# then the hands to the table's edge.
scooting_stage : Seating.Plan, { scooted : F64, rested : F64 } -> Stage
scooting_stage = |plan, { scooted, rested }| {
	moved = Ease.smooth(scooted)
	lifted = 0.015 * (F64.pi * scooted).sin()
	settled = lowered_stage(plan, 1.0)
	table = Ease.smooth(rested)
	{
		..settled,
		at: { ..settled.at, right: settled.at.right + Seating.pull_metres * moved },
		hip: { ..settled.hip, up: settled.hip.up + lifted },
		near_arm: { upper: 0.05 + 0.6 * table, fore: 0.1 + 1.45 * table },
		far_arm: { upper: 0.05 + 0.5 * table, fore: 0.1 + 1.35 * table },
		chair_pulled: Seating.pull_metres * (1.0 - moved),
	}
}

# Up onto a seat higher than the hips, on a wheel: the hands go back onto
# the seat's edge, the arms push the body up, and it shifts back over the
# seat and sits, the wheel left hanging.
hoisting_stage : Seating.Plan, F64 -> Stage
hoisting_stage = |plan, progress| {
	stand = SideBody.standing_hip(Robot.proportions(plan.build))
	seat = plan.chair.seat_height + 0.025
	hands = Ease.smooth(fraction_between(progress, 0.0, 0.2))
	up = Ease.smooth(fraction_between(progress, 0.15, 0.65))
	back = Ease.smooth(fraction_between(progress, 0.45, 0.9))
	let_go = Ease.smooth(fraction_between(progress, 0.8, 1.0))
	push = hands * (1.0 - let_go)
	{
		at: {
			right: plan.chair.right - Seating.pull_metres + plan.setback,
			forward: plan.chair.forward,
			height: 0.0,
		},
		hip: { across: 0.0 - plan.setback * back, up: stand + (seat - stand) * up },
		near_foot: planted,
		far_foot: planted,
		lean: 0.15 * push,
		near_arm: { upper: 0.05 - 0.55 * push, fore: 0.1 - 0.2 * push },
		far_arm: { upper: 0.05 - 0.5 * push, fore: 0.1 - 0.2 * push },
		chair_pulled: Seating.pull_metres,
		walked: walk_length(plan),
	}
}

# How far `progress` is through the part of a motion from `from` to `to`,
# both fractions of the whole, held at 0 before and 1 after.
fraction_between : F64, F64, F64 -> F64
fraction_between = |progress, from, to|
	if progress <= from {
		0.0
	} else if progress >= to {
		1.0
	} else {
		(progress - from) / (to - from)
	}
