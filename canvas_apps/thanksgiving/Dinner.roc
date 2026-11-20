## Dinner says where the party at one table is at each tick: where each robot
## is on its way to its chair and how it stands, where each dish is, how
## bright each string light is, how far the banner has dropped and how long
## the leaves have blown, and how the dancer moves. It asks Script when the
## beats are. Every drawing module is handed numbers, so none of them is
## re-timed when the cut changes.
##
## The tall robot brings the turkey first and sits down while the eye
## watches it, then the round one brings the potatoes, then the tiny one the
## pie, which wobbles all the way, slips, and is caught. Each sets its dish
## on the table and sits as Seating has it. Once all three sit, the lights
## blink on down the table, each robot's eyes lighting with the bulb above
## its place. A fourth robot walks in and dances the routine, while the
## others turn their heads to watch.
import lib.Eye
import Dancer
import Dishes
import Ease
import Lights
import Moves
import Robot
import Routine
import Script
import Seating
import SideBody
import Table

Dinner :: [].{

	## The dish each robot brings.
	dish_of : Robot.Build -> Dishes.Dish
	dish_of = |build|
		match build {
			Tall => Turkey
			Round => Potatoes
			Tiny => Pie
		}

	## Where a robot is and how it stands at `tick`: carrying its dish in,
	## setting it down, then pulling its chair out and sitting.
	guest_at : Robot.Build, I64 -> Seating.Guest
	guest_at = |build, tick| {
		now = Script.held_tick(tick)
		chair = Table.chair_of(build)
		Seating.guest_at(
			guest_plan(build),
			{
				now,
				carry: carrying_arm(build, now),
				look: Ease.smooth(Ease.ramp(now - Script.watch_tick, 30)),
				glow: bulb_glow(Lights.nearest_bulb(chair.forward), now),
			},
		)
	}

	## The plan a robot sits down by.
	guest_plan : Robot.Build -> Seating.Plan
	guest_plan = |build| {
		chair = Table.chair_of(build)
		walk = walk_of(build)
		{
			build,
			walk_from: walk.from_right,
			stop_right: chair.right + 0.32,
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
			chair_tick: set_tick(build) + set_frames + 5,
		}
	}

	## Where the dancer's feet are: walking in from the right, then on its spot
	## beside the near end of the table.
	dancer_feet : I64 -> Eye.At
	dancer_feet = |tick| {
		right: dancer_right(Script.held_tick(tick)),
		forward: 1.4,
		height: 0.0,
	}

	## How the dancer stands at `tick`: arms swinging in steps on the walk in,
	## then the routine. Its antenna boings after the wink.
	dancer_pose : I64 -> Dancer.Pose
	dancer_pose = |tick| {
		now = Script.held_tick(tick)
		walked = dancer_from - dancer_right(now)
		phase = walked * F64.tau / 0.55
		pace = ((dancer_right(now - 5) - dancer_right(now)) / 0.09).min(1.0)
		rest = Moves.rest
		move =
			if now < Script.dance_tick {
				clicks = (phase.sin() * 2.0 + 2.5).to_i64_wrap() - 2
				swing = 0.18 * I64.to_f64(clicks) * pace
				{
					..rest,
					left_upper: rest.left_upper - swing,
					right_upper: rest.right_upper - swing,
				}
			} else {
				Routine.move_at(now - Script.dance_tick)
			}
		{
			left_upper: move.left_upper,
			left_fore: move.left_fore,
			right_upper: move.right_upper,
			right_fore: move.right_fore,
			head: move.head,
			pop: move.pop,
			turn: move.turn,
			bounce: move.bounce,
			wink: move.wink,
			antenna_sway: Ease.boing(now - Script.wink_tick - 16),
			phase,
			stride: pace,
		}
	}

	## The tick by which a robot is sat with its hands on the table.
	seated_tick : Robot.Build -> I64
	seated_tick = |build| Seating.seated_tick(guest_plan(build))

	## Where a robot's dish is and how far it is tipped. A carried dish is
	## drawn with its robot; a dish on its way down, or down, is drawn on the
	## table.
	dish_place : Robot.Build,
	I64 -> {
		at : Eye.At,
		tilt : F64,
		layer : [Carried, OnTable],
	}
	dish_place = |build, tick| {
		now = Script.held_tick(tick)
		set_at = set_tick(build)
		if now < set_at {
			held_dish(build, now)
		} else if now >= set_at + set_frames {
			{
				at: Table.dish_spot(build),
				tilt: 0.0,
				layer: OnTable,
			}
		} else {
			lifted = held_dish(build, set_at)
			spot = Table.dish_spot(build)
			set_down = Ease.smooth(Ease.ramp(now - set_at, set_frames))
			# The dish rises a little on its way over, so it is lowered onto the
			# cloth rather than slid.
			arc = 0.08 * (F64.pi * set_down).sin()
			{
				at: {
					right: lifted.at.right + (spot.right - lifted.at.right) * set_down,
					forward: lifted.at.forward + (spot.forward - lifted.at.forward) * set_down,
					height: lifted.at.height + (spot.height - lifted.at.height) * set_down + arc,
				},
				tilt: lifted.tilt * (1.0 - set_down),
				layer: OnTable,
			}
		}
	}

	## How bright each bulb is, nearest the guest first.
	bulb_glows : I64 -> List(F64)
	bulb_glows = |tick| {
		now = Script.held_tick(tick)
		var $out = List.with_capacity(Lights.bulb_count)
		for k in 0..<Lights.bulb_count {
			$out = $out.append(bulb_glow(k, now))
		}
		$out
	}

	## How far the banner has dropped in, from 0 to 1.
	banner_drop : I64 -> F64
	banner_drop = |tick| {
		drop_progress = Ease.ramp(Script.held_tick(tick) - Script.banner_tick, banner_frames)
		1.0 - (1.0 - drop_progress) * (1.0 - drop_progress)
	}

	## When the tiny robot's pie starts to slip.
	slip_tick : I64
	slip_tick = 542

	## How many seconds the leaves have been blowing; negative before.
	gust_seconds : I64 -> F64
	gust_seconds = |tick| (Script.held_tick(tick) - Script.gust_tick).to_f64() / 60.0
}

# Each robot's walk in: when it sets off and arrives, how far left it sets
# off from, the length of its stride, and how far in front of its seat it
# stands to sit.
Walk : {
	enter_tick : I64,
	arrive_tick : I64,
	from_right : F64,
	step : F64,
	setback : F64,
}

walk_of : Robot.Build -> Walk
walk_of = |build|
	match build {
		Tall => {
			enter_tick: 10,
			arrive_tick: 150,
			from_right: -5.0,
			step: 1.1,
			setback: 0.25,
		}
		Round => {
			enter_tick: 300,
			arrive_tick: 420,
			from_right: -4.4,
			step: 0.5,
			setback: 0.15,
		}
		Tiny => {
			enter_tick: 400,
			arrive_tick: 540,
			from_right: -3.6,
			step: 0.4,
			setback: 0.12,
		}
	}

# When a robot starts to set its dish down: as soon as it stops, unless it
# is the tiny one, which waits until its pie is caught.
set_tick : Robot.Build -> I64
set_tick = |build|
	match build {
		Tall | Round => walk_of(build).arrive_tick + 5
		Tiny => Dinner.slip_tick + slip_frames + fall_frames + lift_frames + 8
	}

set_frames : I64
set_frames = 40

banner_frames : I64
banner_frames = 60

bulb_gap : I64
bulb_gap = 7

# The tiny robot's slip: the pie rocks harder for `slip_frames`, falls for
# `fall_frames` while the hand dives to meet it, and is lifted back up over
# `lift_frames`.
slip_frames : I64
slip_frames = 16

fall_frames : I64
fall_frames = 12

lift_frames : I64
lift_frames = 40

catch_reach : F64
catch_reach = 0.5

# The carrying arm: hanging at 0, holding a dish up in front at 1, and
# pushed out toward the table as the dish is set down.
carrying_arm : Robot.Build, I64 -> SideBody.Arm
carrying_arm = |build, now| {
	held = reach(build, now)
	setting = Ease.ramp(now - set_tick(build), set_frames)
	out = (F64.pi * setting).sin()
	{ upper: 0.05 + 0.55 * held + 0.6 * out, fore: 0.1 + 1.45 * held + 0.2 * out }
}

reach : Robot.Build, I64 -> F64
reach = |build, tick| {
	set_down = 1.0 - Ease.smooth(Ease.ramp(tick - set_tick(build), set_frames))
	match build {
		Tall | Round => set_down
		Tiny =>
			if tick < Dinner.slip_tick + slip_frames {
				1.0
			} else if tick < Dinner.slip_tick + slip_frames + fall_frames {
				dive = Ease.ramp(tick - Dinner.slip_tick - slip_frames, fall_frames)
				1.0 - (1.0 - catch_reach) * (1.0 - (1.0 - dive) * (1.0 - dive))
			} else if tick < set_tick(build) {
				catch_reach + (1.0 - catch_reach) * Ease.smooth(
					Ease.ramp(tick - Dinner.slip_tick - slip_frames - fall_frames, lift_frames),
				)
			} else {
				set_down
			}
	}
}

# Where the near hand is in the backyard: the robot's spot and the hand's
# place on the robot, a little nearer the eye than its body.
hand_in_yard : Robot.Build, I64 -> Eye.At
hand_in_yard = |build, tick| {
	guest = Dinner.guest_at(build, tick)
	hand = SideBody.near_hand_at(Robot.proportions(build), guest.pose)
	{
		right: guest.at.right + hand.across,
		forward: guest.at.forward - 0.12,
		height: hand.up + 0.02,
	}
}

# A dish in its robot's hand. The pie wobbles with the walk, rocks, falls
# and is caught; the others ride steady.
held_dish : Robot.Build,
I64 -> {
	at : Eye.At,
	tilt : F64,
	layer : [Carried, OnTable],
}
held_dish = |build, tick| {
	hand = hand_in_yard(build, tick)
	match build {
		Tall | Round => {
			at: hand,
			tilt: 0.0,
			layer: Carried,
		}
		Tiny => {
			walking_wobble = 0.13 * (Dinner.guest_at(Tiny, tick).walk_phase * 0.5).sin()
			slip_start = Dinner.slip_tick
			fall_start = Dinner.slip_tick + slip_frames
			lift_start = fall_start + fall_frames
			rock = tick.to_f64() * 0.45
			if tick < slip_start {
				{
					at: hand,
					tilt: walking_wobble,
					layer: Carried,
				}
			} else if tick < fall_start {
				slip_progress = Ease.ramp(tick - slip_start, slip_frames)
				{
					at: { ..hand, right: hand.right + 0.05 * slip_progress },
					tilt: (0.13 + 0.45 * slip_progress) * rock.sin(),
					layer: Carried,
				}
			} else if tick < lift_start {
				fall_progress = Ease.ramp(tick - fall_start, fall_frames)
				# Let go at the top of its slip, the pie falls faster and faster
				# until the diving hand meets it.
				top = hand_in_yard(Tiny, fall_start)
				caught = hand_in_yard(Tiny, lift_start)
				fall = fall_progress * fall_progress
				{
					at: {
						right: top.right + 0.05 + (caught.right - top.right - 0.05) * fall_progress,
						forward: top.forward,
						height: top.height + (caught.height - top.height) * fall,
					},
					tilt: (0.58 + 0.4 * fall_progress) * rock.sin(),
					layer: Carried,
				}
			} else {
				lift_progress = Ease.ramp(tick - lift_start, lift_frames)
				{
					at: hand,
					tilt: 0.98 * (1.0 - lift_progress) * (1.0 - lift_progress) * rock.sin(),
					layer: Carried,
				}
			}
		}
	}
}

# A bulb's brightness: off until its turn, then a blink, on, dim, on.
bulb_glow : U64, I64 -> F64
bulb_glow = |index, tick| {
	since = tick - (Script.lights_tick + bulb_gap * index.to_i64_wrap())
	if since < 0 {
		0.0
	} else if since < 3 {
		1.0
	} else if since < 6 {
		0.25
	} else {
		1.0
	}
}

# The dancer walks in from the right, after the banner is up, to a spot
# beside the near end of the table where the pulled-back eye sees it whole.
dancer_from : F64
dancer_from = 4.5

dancer_right : I64 -> F64
dancer_right = |tick| {
	walk_progress = Ease.smooth(
		Ease.ramp(tick - Script.walk_in_tick, Script.dance_tick - 6 - Script.walk_in_tick),
	)
	dancer_from + (1.25 - dancer_from) * walk_progress
}

# Every robot is sat with its hands on the table before the first bulb
# blinks, its hips on its seat.
expect [Tall, Round, Tiny].all(|build| Dinner.seated_tick(build) < Script.lights_tick)
expect
	[Tall, Round, Tiny].all(
		|build| {
			hip = Dinner.guest_at(build, Script.lights_tick).pose.hip
			(hip.up - Table.chair_of(build).seat_height - 0.025).abs() < 0.001
		},
	)

# The tall robot starts down onto its seat when Script says the first sit
# is, so the eye is there to watch it.
expect Seating.sit_tick(Dinner.guest_plan(Tall)) == Script.first_sit_tick

# The hips are still well off the seat as a robot starts down onto it.
expect
	[Tall, Round].all(
		|build| {
			hip = Dinner.guest_at(build, Seating.sit_tick(Dinner.guest_plan(build))).pose.hip
			hip.up > Table.chair_of(build).seat_height + 0.05
		},
	)

# Every dish is on its spot on the table before its robot starts on its
# chair.
expect
	[Tall, Round, Tiny].all(
		|build| {
			place = Dinner.dish_place(build, Dinner.guest_plan(build).chair_tick)
			place.at == Table.dish_spot(build) and place.layer == OnTable
		},
	)

# No bulb is lit before the lights start, and every bulb is lit at the end.
expect Dinner.bulb_glows(Script.lights_tick - 1).all(|glow| glow == 0.0)
expect Dinner.bulb_glows(Script.end_tick).all(|glow| glow == 1.0)

# The tiny robot's eyes light after the lights start, and are dark before.
expect Dinner.guest_at(Tiny, Script.lights_tick - 1).pose.glow == 0.0
expect Dinner.guest_at(Tiny, Script.end_tick).pose.glow == 1.0

# The pie falls below the hand's carrying height and is caught again.
expect {
	carried = Dinner.dish_place(Tiny, Dinner.slip_tick).at.height
	falling = Dinner.dish_place(Tiny, Dinner.slip_tick + slip_frames + fall_frames - 1).at.height
	lifted = Dinner.dish_place(Tiny, set_tick(Tiny) - 1).at.height
	falling < carried - 0.05 and (lifted - carried).abs() < 0.03
}
