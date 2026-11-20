## Dinner says where the party at one table is at each tick: where each robot
## has walked to and how it stands, where each dish is, how bright each
## string light is, how far the banner has dropped and how long the leaves
## have blown, and how the dancer moves. It asks Script when the beats are.
## Every drawing module is handed numbers, so none of them is re-timed when
## the cut changes.
##
## The tall robot brings the turkey first, then the round one the potatoes,
## then the tiny one the pie, which wobbles all the way, slips, and is
## caught. Once all three sit, the lights blink on down the table, each
## robot's eyes lighting with the bulb above its place. A fourth robot walks
## in and dances the routine, while the others turn their eyes to watch.
import lib.Eye
import Dancer
import Dishes
import Ease
import Lights
import Robot
import Routine
import Script
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

	## Where a robot's feet are: walking in from the left along its chair's
	## line, then standing at its chair.
	robot_feet : Robot.Build, I64 -> Eye.At
	robot_feet = |build, tick| {
		chair = Table.chair_of(build)
		{
			right: walked_right(build, Script.held_tick(tick)),
			forward: chair.forward,
			height: 0.0,
		}
	}

	## How a robot stands at `tick`.
	robot_pose : Robot.Build, I64 -> Robot.Pose
	robot_pose = |build, tick| {
		now = Script.held_tick(tick)
		plan = timing(build)
		walked = walked_right(build, now) - plan.from_right
		{
			phase: walked * F64.tau / plan.step,
			stride: stride(build, now),
			sit: Ease.smooth(Ease.ramp(now - plan.sit_tick, sit_frames)),
			seat_height: Table.chair_of(build).seat_height,
			reach: reach(build, now),
			eye_glow: bulb_glow(Lights.nearest_bulb(Table.chair_of(build).forward), now),
			look: Ease.smooth(Ease.ramp(now - Script.watch_tick, 30)),
		}
	}

	## Where the dancer's feet are: walking in from the right, then on its spot
	## beside the near end of the table.
	dancer_feet : I64 -> Eye.At
	dancer_feet = |tick| { right: dancer_right(Script.held_tick(tick)), forward: 1.4, height: 0.0 }

	## How the dancer stands at `tick`: arms swinging in steps on the walk in,
	## then the routine. Its antenna boings after the wink.
	dancer_pose : I64 -> Dancer.Pose
	dancer_pose = |tick| {
		now = Script.held_tick(tick)
		walked = dancer_from - dancer_right(now)
		phase = walked * F64.tau / 0.55
		pace = ((dancer_right(now - 5) - dancer_right(now)) / 0.09).min(1.0)
		rest = Routine.rest
		move =
			if now < Script.dance_tick {
				clicks = (phase.sin() * 2.0 + 2.5).to_i64_wrap() - 2
				swing = 0.18 * I64.to_f64(clicks) * pace
				{ ..rest, left_upper: rest.left_upper - swing, right_upper: rest.right_upper - swing }
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

	## The tick by which a robot is sat down.
	seated_tick : Robot.Build -> I64
	seated_tick = |build| timing(build).sit_tick + sit_frames

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
		plan = timing(build)
		if now < plan.set_tick {
			held_dish(build, now)
		} else if now >= plan.set_tick + set_frames {
			{
				at: Table.dish_spot(build),
				tilt: 0.0,
				layer: OnTable,
			}
		} else {
			lifted = held_dish(build, plan.set_tick)
			spot = Table.dish_spot(build)
			set_down = Ease.smooth(Ease.ramp(now - plan.set_tick, set_frames))
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

	## How many seconds the leaves have been blowing; negative before.
	gust_seconds : I64 -> F64
	gust_seconds = |tick| (Script.held_tick(tick) - Script.gust_tick).to_f64() / 60.0
}

# Each robot's walk, set-down and sit, in ticks, with where it walks in from
# and the length of its step. The tiny robot's set-down waits for its catch.
Timing : {
	enter_tick : I64,
	arrive_tick : I64,
	from_right : F64,
	step : F64,
	set_tick : I64,
	sit_tick : I64,
}

timing : Robot.Build -> Timing
timing = |build|
	match build {
		Tall => {
			enter_tick: 30,
			arrive_tick: 210,
			from_right: -6.0,
			step: 0.6,
			set_tick: 215,
			sit_tick: 258,
		}
		Round => {
			enter_tick: 230,
			arrive_tick: 390,
			from_right: -4.6,
			step: 0.3,
			set_tick: 395,
			sit_tick: 438,
		}
		Tiny => {
			enter_tick: 450,
			arrive_tick: 620,
			from_right: -3.6,
			step: 0.22,
			set_tick: 700,
			sit_tick: 745,
		}
	}

set_frames : I64
set_frames = 40

sit_frames : I64
sit_frames = 35

banner_frames : I64
banner_frames = 60

bulb_gap : I64
bulb_gap = 7

# The tiny robot's slip: the pie rocks harder for `slip_frames`, falls for
# `fall_frames` while the hand dives to meet it, and is lifted back up over
# `lift_frames`.
slip_tick : I64
slip_tick = 622

slip_frames : I64
slip_frames = 16

fall_frames : I64
fall_frames = 12

lift_frames : I64
lift_frames = 40

catch_reach : F64
catch_reach = 0.5

walked_right : Robot.Build, I64 -> F64
walked_right = |build, tick| {
	plan = timing(build)
	to = Table.chair_of(build).right
	walk_progress = Ease.smooth(Ease.ramp(tick - plan.enter_tick, plan.arrive_tick - plan.enter_tick))
	plan.from_right + (to - plan.from_right) * walk_progress
}

# How much walking is going on, from the walking itself: the ground covered
# over the last five ticks, against a brisk pace for that build.
stride : Robot.Build, I64 -> F64
stride = |build, tick| {
	plan = timing(build)
	covered = (walked_right(build, tick) - walked_right(build, tick - 5)).abs()
	walk_frames = (plan.arrive_tick - plan.enter_tick).to_f64()
	brisk = 0.6 * 5.0 * (Table.chair_of(build).right - plan.from_right) / walk_frames
	(covered / brisk).min(1.0)
}

reach : Robot.Build, I64 -> F64
reach = |build, tick| {
	plan = timing(build)
	set_down = 1.0 - Ease.smooth(Ease.ramp(tick - plan.set_tick, set_frames))
	match build {
		Tall | Round => set_down
		Tiny =>
			if tick < slip_tick + slip_frames {
				1.0
			} else if tick < slip_tick + slip_frames + fall_frames {
				dive = Ease.ramp(tick - slip_tick - slip_frames, fall_frames)
				1.0 - (1.0 - catch_reach) * (1.0 - (1.0 - dive) * (1.0 - dive))
			} else if tick < plan.set_tick {
				catch_reach + (1.0 - catch_reach) * Ease.smooth(
					Ease.ramp(tick - slip_tick - slip_frames - fall_frames, lift_frames),
				)
			} else {
				set_down
			}
	}
}

# Where the right hand is in the backyard: the robot's feet and the hand's
# place on the robot, a little in front of its body.
hand_in_yard : Robot.Build, I64 -> Eye.At
hand_in_yard = |build, tick| {
	feet = Dinner.robot_feet(build, tick)
	hand = Robot.hand_at(build, Dinner.robot_pose(build, tick))
	{
		right: feet.right + hand.across,
		forward: feet.forward - 0.1,
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
			pose = Dinner.robot_pose(Tiny, tick)
			walking_wobble = 0.13 * (pose.phase * 0.5).sin()
			slip_start = slip_tick
			fall_start = slip_tick + slip_frames
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
	walk_progress = Ease.smooth(Ease.ramp(tick - Script.walk_in_tick, Script.dance_tick - 6 - Script.walk_in_tick))
	dancer_from + (1.25 - dancer_from) * walk_progress
}

# Every robot is sat down before the first bulb blinks, and is still sitting
# down one tick before it is seated.
expect [Tall, Round, Tiny].all(|build| Dinner.seated_tick(build) < Script.lights_tick)
expect [Tall, Round, Tiny].all(|build| Dinner.robot_pose(build, Script.lights_tick).sit == 1.0)
expect [Tall, Round, Tiny].all(
	|build| Dinner.robot_pose(build, Dinner.seated_tick(build) - 1).sit < 1.0,
)

# Each robot sets its dish down after it arrives and sits after setting it.
expect
	[Tall, Round, Tiny].all(
		|build| {
			plan = timing(build)
			plan.arrive_tick <= plan.set_tick and plan.set_tick + set_frames <= plan.sit_tick
		},
	)

# Every dish is on its spot on the table once its robot sits.
expect
	[Tall, Round, Tiny].all(
		|build| {
			place = Dinner.dish_place(build, timing(build).sit_tick)
			place.at == Table.dish_spot(build) and place.layer == OnTable
		},
	)

# No bulb is lit before the lights start, and every bulb is lit at the end.
expect Dinner.bulb_glows(Script.lights_tick - 1).all(|glow| glow == 0.0)
expect Dinner.bulb_glows(Script.end_tick).all(|glow| glow == 1.0)

# The tiny robot's eyes light after the lights start, and are dark before.
expect Dinner.robot_pose(Tiny, Script.lights_tick - 1).eye_glow == 0.0
expect Dinner.robot_pose(Tiny, Script.end_tick).eye_glow == 1.0

# The pie falls below the hand's carrying height and is caught again.
expect {
	carried = Dinner.dish_place(Tiny, slip_tick).at.height
	falling = Dinner.dish_place(Tiny, slip_tick + slip_frames + fall_frames - 1).at.height
	lifted = Dinner.dish_place(Tiny, timing(Tiny).set_tick - 1).at.height
	falling < carried - 0.05 and (lifted - carried).abs() < 0.03
}
