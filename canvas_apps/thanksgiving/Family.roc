## Family is the tiny robot and its mother. The baby rolls in with the pie,
## which slips and is caught, and twirls round with the pie held up over its
## head for joy. The mother walks in behind it to the table, turns, bends and
## takes the pie from it, turns back and sets it on the table as Placing has
## it. Then she turns, walks back past the baby to behind its chair, pulls
## the chair out for it, waits while it climbs up, and pushes it in. Last she
## walks to her own chair and sits as any grown robot does, by Seating.
##
## Baby moves the baby's own arms and its twirl; Stances builds the
## mother's poses between her walks.
##
## Everything here is in ticks of the movie and the backyard's metres. Each
## of the mother's steps is a stretch of ticks, named for what she does in it.
import lib.Eye
import Ease
import Figure
import Placing
import Robot
import RobotBody
import Seating
import SideBody
import Stances
import Table

Family :: [].{

	## When the baby's pie starts to slip.
	slip_tick : I64
	slip_tick = 542

	## When the mother starts setting the pie down.
	pie_place_tick : I64
	pie_place_tick = place_start

	## When the baby's chair is out, and when the mother starts pushing it in.
	baby_pulled_tick : I64
	baby_pulled_tick = pull_start + pull_frames

	baby_pushed_tick : I64
	baby_pushed_tick = 1000

	## The baby's plan: it walks, or rolls, in, and is helped with its chair.
	baby_plan : Seating.Plan
	baby_plan = {
		build: Tiny,
		walk_from: -3.6,
		stop_right: baby_chair.right + 0.03,
		aisle_forward: baby_chair.forward - 0.5,
		chair: baby_chair,
		setback: 0.12,
		step: 0.4,
		enter_tick: 400,
		arrive_tick: 540,
		chair_tick: Family.baby_pulled_tick,
		chair_mover: Helped({
			pulled_tick: Family.baby_pulled_tick,
			pushed_tick: Family.baby_pushed_tick,
		}),
	}

	## The mother's plan for her own chair, from behind the baby's.
	mommy_plan : Seating.Plan
	mommy_plan = {
		build: Mommy,
		walk_from: behind_chair,
		stop_right: table_side,
		aisle_forward: lane,
		chair: mommy_chair,
		setback: 0.22,
		step: 1.0,
		enter_tick: own_walk_start,
		arrive_tick: own_walk_start + 45,
		chair_tick: own_walk_start + 48,
		chair_mover: Itself,
	}

	## How far the baby's chair is pulled out: by the mother, and back in.
	baby_chair_pulled : I64 -> F64
	baby_chair_pulled = |now|
		Seating.pull_metres * (Ease.smooth(Ease.ramp(now - pull_start, pull_frames))
			- Ease.smooth(Ease.ramp(now - Family.baby_pushed_tick, Seating.scoot_frames)))

	## The mother at `now`.
	mommy_at : I64, { look : F64, glow : F64 } -> Seating.Guest
	mommy_at = |now, lit| {
		body = Robot.proportions(Mommy)
		if now < turn_to_take {
			Seating.guest_at(arrival_plan, { now, look: lit.look, glow: lit.glow })
		} else if now >= own_walk_start {
			Seating.guest_at(Family.mommy_plan, { now, look: lit.look, glow: lit.glow })
		} else {
			helping_at(body, { now, look: lit.look, glow: lit.glow })
		}
	}

	## Where the pie is and whose hands it is in, `now`: the baby's until the
	## mother takes it, then hers until she lets it go on the table.
	pie_holder : I64 -> [BabyHolds, Passing(F64), MommyHolds, OnTable]
	pie_holder = |now|
		if now < take_grab {
			BabyHolds
		} else if now < take_grab + 11 {
			Passing(Ease.smooth(Ease.ramp(now - take_grab, 11)))
		} else if now < place_start {
			MommyHolds
		} else {
			reach = placing_reach(Robot.proportions(Mommy), now)
			match reach.dish {
				InHands => MommyHolds
				Down => OnTable
			}
		}

	## When the mother has taken the pie and turns back to the table, and
	## the baby's arms come down.
	arms_down_tick : I64
	arms_down_tick = turn_to_table

	## The slip's three stretches, in ticks.
	slip_frames : I64
	slip_frames = 16

	fall_frames : I64
	fall_frames = 12

	lift_frames : I64
	lift_frames = 40
}

baby_chair : {
	right : F64,
	forward : F64,
	seat_height : F64,
}
baby_chair = {
	right: Table.chair_of(Tiny).right,
	forward: Table.chair_of(Tiny).forward,
	seat_height: Table.chair_of(Tiny).seat_height,
}

mommy_chair : {
	right : F64,
	forward : F64,
	seat_height : F64,
}
mommy_chair = {
	right: Table.chair_of(Mommy).right,
	forward: Table.chair_of(Mommy).forward,
	seat_height: Table.chair_of(Mommy).seat_height,
}

# The mother's lane, just nearer the eye than the baby's, so she passes in
# front of it; where she stands at the table; and where she stands behind
# the baby's chair, pushed in and pulled out.
lane : F64
lane = baby_chair.forward - 0.6

table_side : F64
table_side = -0.7

behind_chair : F64
behind_chair = baby_chair.right - 0.21 - 0.36

# The mother's ticks, in order.
turn_to_take : I64
turn_to_take = 645

take_grab : I64
take_grab = 670

turn_to_table : I64
turn_to_table = 681

place_start : I64
place_start = 695

turn_away : I64
turn_away = 768

walk_back : I64
walk_back = 780

turn_to_chair : I64
turn_to_chair = 830

step_behind : I64
step_behind = 842

pull_start : I64
pull_start = 870

pull_frames : I64
pull_frames = 26

step_out : I64
step_out = 1030

own_walk_start : I64
own_walk_start = 1060

turn_frames : I64
turn_frames = 12

# The mother's walk in to the table, by Seating's walk.
arrival_plan : Seating.Plan
arrival_plan = {
	..Family.mommy_plan,
	walk_from: -5.0,
	stop_right: table_side,
	aisle_forward: lane,
	enter_tick: 520,
	arrive_tick: 640,
	chair_tick: own_walk_start,
}

mix : Figure.Spot, Figure.Spot, F64 -> Figure.Spot
mix = |from, to, fraction| {
	across: from.across + (to.across - from.across) * fraction,
	up: from.up + (to.up - from.up) * fraction,
}

# The mother between her walk in and her walk to her own chair, stretch by
# stretch.
helping_at : RobotBody.Proportions,
{
	now : I64,
	look : F64,
	glow : F64,
} -> Seating.Guest
helping_at = |body, { now, look, glow }| {
	hip = { across: 0.0, up: SideBody.standing_hip(body) }
	carry = Placing.carrying_hand(body, hip)
	down = {
		across: 0.06,
		up: SideBody.shoulder(body, { hip, lean: 0.0 }).up - 0.95 * (body.upper_arm + body.forearm),
	}
	at_table = {
		right: table_side,
		forward: lane,
		height: 0.0,
	}
	pose = { build: Mommy, look, glow }
	if now < turn_to_take + turn_frames {
		Stances.standing(
			pose,
			{
				at: at_table,
				facing: Stances.turned(
					now,
					{
						from: 1.0,
						start: turn_to_take,
						frames: turn_frames,
					},
				),
				hand: Free,
				lean: 0.0,
			},
		)
	} else if now < turn_to_table {
		taking(pose, { at: at_table, hip, carry, now })
	} else if now < place_start {
		Stances.standing(
			pose,
			{
				at: at_table,
				facing: Stances.turned(
					now,
					{
						from: -1.0,
						start: turn_to_table,
						frames: turn_frames,
					},
				),
				hand: Holding(carry),
				lean: 0.0,
			},
		)
	} else if now < turn_away {
		reach = placing_reach(body, now)
		Stances.standing(
			pose,
			{
				at: at_table,
				facing: 1.0,
				hand: Holding(reach.hand),
				lean: reach.lean,
			},
		)
	} else if now < walk_back {
		Stances.standing(
			pose,
			{
				at: at_table,
				facing: Stances.turned(
					now,
					{
						from: 1.0,
						start: turn_away,
						frames: turn_frames,
					},
				),
				hand: Holding(down),
				lean: 0.0,
			},
		)
	} else if now < turn_to_chair {
		Stances.strolling(
			pose,
			{
				from: table_side,
				to: behind_chair,
				forward: lane,
				start: walk_back,
				frames: turn_to_chair - walk_back,
				now,
			},
		)
	} else if now < step_behind {
		Stances.standing(
			pose,
			{
				at: {
					right: behind_chair,
					forward: lane,
					height: 0.0,
				},
				facing: Stances.turned(
					now,
					{
						from: -1.0,
						start: turn_to_chair,
						frames: turn_frames,
					},
				),
				hand: Holding(down),
				lean: 0.0,
			},
		)
	} else if now < pull_start {
		Stances.sidestepping(
			pose,
			{
				right: behind_chair,
				from: lane,
				to: baby_chair.forward,
				start: step_behind,
				frames: pull_start - step_behind,
				now,
			},
		)
	} else if now < Family.baby_pushed_tick + Seating.scoot_frames {
		pulled = Family.baby_chair_pulled(now)
		at = {
			right: behind_chair - pulled,
			forward: baby_chair.forward,
			height: 0.0,
		}
		back_top = {
			across: baby_chair.right - pulled - 0.21 - at.right,
			up: baby_chair.seat_height + 0.58,
		}
		Stances.standing(
			pose,
			{
				at,
				facing: 1.0,
				hand: Holding(back_top),
				lean: 0.12,
			},
		)
	} else if now < step_out {
		Stances.standing(
			pose,
			{
				at: {
					right: behind_chair,
					forward: baby_chair.forward,
					height: 0.0,
				},
				facing: 1.0,
				hand: Holding(down),
				lean: 0.0,
			},
		)
	} else {
		Stances.sidestepping(
			pose,
			{
				right: behind_chair,
				from: baby_chair.forward,
				to: lane,
				start: step_out,
				frames: own_walk_start - step_out,
				now,
			},
		)
	}
}

# Bending to the baby, taking the pie from its raised hands, and coming up
# with it.
taking : Stances.Who,
{
	at : Eye.At,
	hip : Figure.Spot,
	carry : Figure.Spot,
	now : I64,
} -> Seating.Guest
taking = |pose, { at, hip, carry, now }| {
	pie = baby_raised_hand_in_yard
	target = { across: at.right - pie.right, up: pie.height - 0.02 }
	bow = Placing.lean_to_reach(Robot.proportions(pose.build), { hip, target })
	reach_start = turn_to_take + turn_frames
	reaching = Ease.smooth(Ease.ramp(now - reach_start, take_grab - reach_start))
	rising = Ease.smooth(Ease.ramp(now - take_grab, turn_to_table - take_grab))
	hand =
		if now < take_grab {
			mix(carry, target, reaching)
		} else {
			mix(target, carry, rising)
		}
	Stances.standing(
		pose,
		{
			at,
			facing: -1.0,
			hand: Holding(hand),
			lean: bow * reaching * (1.0 - rising),
		},
	)
}

# Where the baby's raised hands are, holding the pie up: it is standing
# where it stopped, facing the table.
baby_raised_hand_in_yard : Eye.At
baby_raised_hand_in_yard = {
	body = Robot.proportions(Tiny)
	hip = { across: 0.0, up: SideBody.standing_hip(body) }
	shoulder = SideBody.shoulder(body, { hip, lean: 0.0 })
	{
		right: Family.baby_plan.stop_right + 0.04,
		forward: Family.baby_plan.aisle_forward - 0.12,
		height: shoulder.up + 0.22 + 0.02,
	}
}

# The mother setting the pie down, from her spot at the table.
placing_reach : RobotBody.Proportions, I64 -> Placing.Reach
placing_reach = |body, now| {
	hip = { across: 0.0, up: SideBody.standing_hip(body) }
	spot = Table.dish_spot(Pie)
	Placing.setting_down(
		body,
		{
			hip,
			carry: Placing.carrying_hand(body, hip),
			spot: { across: spot.right - table_side, up: spot.height - 0.02 },
			progress: Ease.ramp(now - place_start, Placing.placing_frames),
		},
	)
}
