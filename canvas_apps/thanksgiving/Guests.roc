## Guests says where each robot at the table is and how it stands at a tick.
## The tall robot brings the turkey and the round one the potatoes: each
## walks up the aisle to the table's edge carrying its dish in both hands,
## sets it down there as Placing has it, and sits as Seating has it. The
## tiny robot and its mother are Family's. Each robot's eyes light with the
## bulb over its place, and its head turns to watch the dancer.
import Baby
import Dinner
import Ease
import Family
import Lights
import Placing
import Robot
import Script
import Seating
import SideBody
import Table

Guests :: [].{

	## Everyone at the table, farthest from the eye first.
	everyone : List(Robot.Build)
	everyone = [Tall, Round, Tiny, Mommy]

	## Where a robot is and how it stands at `tick`.
	guest_at : Robot.Build, I64 -> Seating.Guest
	guest_at = |build, tick| {
		now = Script.held_tick(tick)
		lit = {
			look: Ease.smooth(Ease.ramp(now - Script.watch_tick, 30)),
			glow: Dinner.bulb_glow(Lights.nearest_bulb(Table.chair_of(build).forward), now),
		}
		match build {
			Tall => serving_at(Tall, { now, look: lit.look, glow: lit.glow })
			Round => serving_at(Round, { now, look: lit.look, glow: lit.glow })
			Tiny => Baby.baby_at(now, lit)
			Mommy => Family.mommy_at(now, lit)
		}
	}

	## How far a robot's chair is pulled out from its place at `tick`.
	chair_pulled : Robot.Build, I64 -> F64
	chair_pulled = |build, tick|
		match build {
			Tiny => Family.baby_chair_pulled(Script.held_tick(tick))
			Tall | Round | Mommy => Guests.guest_at(build, tick).chair_pulled
		}

	## The plan a robot that serves itself sits down by.
	guest_plan : [Tall, Round] -> Seating.Plan
	guest_plan = |server| {
		build = Guests.build_of(server)
		chair = Table.chair_of(build)
		walk = walk_of(server)
		{
			build,
			walk_from: walk.from_right,
			stop_right: walk.stop_right,
			aisle_forward: chair.forward - 0.5,
			chair: {
				right: chair.right,
				forward: chair.forward,
				seat_height: chair.seat_height,
			},
			setback: walk.setback,
			step: walk.step,
			enter_tick: walk.enter_tick,
			arrive_tick: walk.arrive_tick,
			chair_tick: walk.set_tick + walk.set_frames + 2,
			chair_mover: Itself,
		}
	}

	## How far through setting its dish down a robot is at `now`: where its
	## hands are and how far it leans, from its spot.
	placing_reach : [Tall, Round], I64 -> Placing.Reach
	placing_reach = |server, now| {
		walk = walk_of(server)
		body = Robot.proportions(Guests.build_of(server))
		hip = { across: 0.0, up: SideBody.standing_hip(body) }
		spot = Table.dish_spot(
			match server {
				Tall => Turkey
				Round => Potatoes
			},
		)
		Placing.setting_down(
			body,
			{
				hip,
				carry: Placing.carrying_hand(body, hip),
				spot: { across: spot.right - walk.stop_right, up: spot.height - 0.02 },
				progress: Ease.ramp(now - walk.set_tick, walk.set_frames),
			},
		)
	}

	## A robot that serves itself, as any robot.
	build_of : [Tall, Round] -> Robot.Build
	build_of = |server|
		match server {
			Tall => Tall
			Round => Round
		}

	## When a robot starts setting its dish down.
	set_tick : [Tall, Round] -> I64
	set_tick = |build| walk_of(build).set_tick
}

# Each serving robot's walk in: when it sets off and arrives, how far left it
# sets off from and where it stops, at the table's edge; the length of its
# stride; how far in front of its seat it stands to sit; and when and for how
# long it sets its dish down. The round robot stops with its barrel against
# the table's edge, which its arms are too short to reach past otherwise.
Walk : {
	enter_tick : I64,
	arrive_tick : I64,
	from_right : F64,
	stop_right : F64,
	step : F64,
	setback : F64,
	set_tick : I64,
	set_frames : I64,
}

walk_of : [Tall, Round] -> Walk
walk_of = |build|
	match build {
		Tall => {
			enter_tick: 10,
			arrive_tick: 150,
			from_right: -5.0,
			stop_right: Table.chair_of(Tall).right + 0.32,
			step: 1.1,
			setback: 0.25,
			set_tick: 152,
			set_frames: 46,
		}
		Round => {
			enter_tick: 300,
			arrive_tick: 420,
			from_right: -4.4,
			stop_right: 0.0 - Table.half_width - 0.02 - Robot.proportions(Round).body_width / 2.0,
			step: 0.5,
			setback: 0.15,
			set_tick: 423,
			set_frames: Placing.placing_frames,
		}
	}

# A serving robot by Seating, its hands and lean Placing's from the moment it
# stops until it starts on its chair.
serving_at : [Tall, Round],
{
	now : I64,
	look : F64,
	glow : F64,
} -> Seating.Guest
serving_at = |server, { now, look, glow }| {
	plan = Guests.guest_plan(server)
	seated = Seating.guest_at(plan, { now, look, glow })
	if now >= plan.chair_tick {
		seated
	} else {
		body = Robot.proportions(Guests.build_of(server))
		reach = Guests.placing_reach(server, now)
		leaning = { ..seated.pose, lean: seated.pose.lean + reach.lean }
		{
			..seated,
			pose: {
				..leaning,
				near_arm: SideBody.arm_toward(body, { pose: leaning, hand: reach.hand }),
				far_arm: SideBody.arm_toward(
					body,
					{ pose: leaning, hand: { ..reach.hand, across: reach.hand.across - 0.04 } },
				),
			},
		}
	}
}

# Every robot is sat before the first bulb blinks, its hips on its seat.
expect
	Guests.everyone.all(
		|build| {
			hip = Guests.guest_at(build, Script.lights_tick).pose.hip
			(hip.up - Table.chair_of(build).seat_height - 0.025).abs() < 0.001
		},
	)

# The tall robot starts down onto its seat when Script says the first sit
# is, so the eye is there to watch it.
expect Seating.sit_tick(Guests.guest_plan(Tall)) == Script.first_sit_tick

# Everyone's chair is back in its place once they are all sat.
expect Guests.everyone.all(|build| Guests.chair_pulled(build, Script.lights_tick) == 0.0)

# The tiny robot's eyes light after the lights start, and are dark before.
expect Guests.guest_at(Tiny, Script.lights_tick - 1).pose.glow == 0.0
expect Guests.guest_at(Tiny, Script.end_tick).pose.glow == 1.0
