## March says where the robot army is at each tick and how each marcher
## stands. The army steps out from under the guest's eye, so it comes up
## over the bottom of the screen big and shrinks as it marches off toward
## the tables, the way the jets in roc-screensaver's Lanterns come over the
## camera and shrink into the sky: the path is laid out from where the eye
## stands, and the same projection as everything else does the shrinking.
##
## A drum major in front pumps a drumstick on the beat. Behind it come
## three ranks, each carrying more food: tall robots with turkeys, round ones
## with potatoes, tiny ones with pies, the tiny ones rolling at double time
## to keep up. The army marches up between the near floats and halts among
## them; on the halt the drum major tosses the drumstick up and catches it,
## and a last tiny robot, late, races in to its gap in the back rank.
## Marchers says where each marcher goes from there.
import lib.Eye
import Dancer
import Dishes
import Ease
import Robot
import Script

March :: [].{

	## One marcher in the ranks: its build, the dish it carries, where its
	## feet are, how it stands, and how far its dish is tipped.
	Trooper : {
		build : Robot.Build,
		dish : Dishes.Dish,
		feet : Eye.At,
		pose : Robot.Pose,
		dish_tilt : F64,
	}

	## The drum major: where its feet are, how it stands, and the drumstick,
	## gripped `grip` metres across and up from its feet and pointing `angle`
	## radians from straight down, as an arm's bones are.
	DrumMajor : {
		feet : Eye.At,
		pose : Dancer.Pose,
		drumstick : { grip : { across : F64, up : F64 }, angle : F64 },
		drumstick_layer : [OverBody, UnderBody],
	}

	## A place in the army: the build and dish of the marcher in it, how far
	## behind the drum major and how far across, and whether it marches in
	## step or comes in late.
	Slot : {
		build : Robot.Build,
		dish : Dishes.Dish,
		behind : F64,
		right : F64,
		arrives : [InStep, Late],
	}

	## Every place in the army, farthest first, the straggler last.
	slots : List(March.Slot)
	slots =
		[
			(Tall, Turkey, 1.5),
			(Round, Potatoes, 2.6),
			(Tiny, Pie, 3.7),
		]
			.map(
				|(build, dish, behind)| files.map(
					|right| {
						build,
						dish,
						behind,
						right,
						arrives: InStep,
					},
				),
			)
			.join()
			.drop_last(1)
			.append(straggler_slot)

	## The marcher in `slot` at `now`, marching, halted, or rolling in late.
	trooper_at : March.Slot, I64 -> March.Trooper
	trooper_at = |slot, now|
		match slot.arrives {
			InStep => trooper(slot, now)
			Late => straggler(now)
		}

	## Where a marcher stands once the army has halted, or the straggler
	## has caught up.
	halt_spot : March.Slot -> Eye.At
	halt_spot = |slot| {
		right: slot.right,
		forward: halt_lead - slot.behind,
		height: 0.0,
	}

	## Where the drum major stands once the army has halted.
	drum_major_halt_spot : Eye.At
	drum_major_halt_spot = { right: 0.4, forward: halt_lead, height: 0.0 }

	## When the straggler is in its gap.
	straggler_in_tick : I64
	straggler_in_tick = Script.seat_tick + 20

	## A marcher holding its dish up, eyes lit. A tiny robot's wheel turns
	## twice as fast as the others' legs, as it hurries to keep up.
	carrying_pose : {
		build : Robot.Build,
		phase : F64,
		stride : F64,
	} -> Robot.Pose
	carrying_pose = |{ build, phase, stride }| {
		phase: match build {
			Tiny => 2.0 * phase
			Tall | Round | Mommy => phase
		},
		stride,
		reach: 1.0,
		eye_glow: 1.0,
		look: 0.0,
	}

	## The drum major at `tick`, or `NotYet` before the army steps out.
	drum_major_at : I64 -> [Marching(March.DrumMajor), NotYet]
	drum_major_at = |tick| {
		now = Script.held_tick(tick)
		if now < Script.army_tick {
			NotYet
		} else {
			Marching(drum_major(now))
		}
	}
}

# Three ranks of four, tall, round, tiny, either side of an aisle the drum
# major leads down, with the back rank's last place left for the straggler.
files : List(F64)
files = [-1.9, -0.7, 1.5, 2.7]

straggler_slot : March.Slot
straggler_slot = {
	build: Tiny,
	dish: Pie,
	behind: 3.7,
	right: 2.7,
	arrives: Late,
}

# Where the drum major starts, just in front of the eye at the wide shot,
# and where it halts, between the near floats: three and a half metres a
# second, at the double.
lead_start : F64
lead_start = -25.1

halt_lead : F64
halt_lead = -11.0

metres_a_tick : F64
metres_a_tick = (halt_lead - lead_start) / Script.march_frames.to_f64()

# How many ticks the army has marched, which stop at the halt.
ticks_marched : I64 -> I64
ticks_marched = |now| (now - Script.army_tick).min(Script.march_frames)

# The step's own clock: one stride, left foot and right, a second. The
# march lasts a whole number of half strides, so both feet are down at the
# halt.
step_phase : I64 -> F64
step_phase = |now| ticks_marched(now).to_f64() * F64.tau / 60.0

# How much the army is marching, 1 on the way and settling to 0 over a few
# ticks after the halt. The knees come up high while it does, a proud
# `high_step` times a guest's stride.
marching : I64 -> F64
marching = |now| 1.0 - Ease.ramp(now - Script.halt_tick, 8)

high_step : F64
high_step = 2.4

lead_forward : I64 -> F64
lead_forward = |now| lead_start + metres_a_tick * ticks_marched(now).to_f64()

trooper : March.Slot, I64 -> March.Trooper
trooper = |slot, now| {
	phase = step_phase(now)
	{
		build: slot.build,
		dish: slot.dish,
		feet: {
			right: slot.right,
			forward: lead_forward(now) - slot.behind,
			height: 0.0,
		},
		pose: March.carrying_pose({
			build: slot.build,
			phase,
			stride: high_step * marching(now),
		}),
		dish_tilt: 0.07 * (phase + slot.right).sin() * marching(now),
	}
}

# The straggler sets off from under the eye as the others near the halt,
# rolls fast, and brakes into its gap just after the others break ranks,
# its pie rocking all the way.
straggler_start : I64
straggler_start = Script.halt_tick - 60

straggler_frames : I64
straggler_frames = March.straggler_in_tick - straggler_start

straggler : I64 -> March.Trooper
straggler = |now| {
	spot = halt_lead - straggler_slot.behind
	from = spot - 8.0
	progress = Ease.ramp(now - straggler_start, straggler_frames)
	braking = 1.0 - (1.0 - progress) * (1.0 - progress)
	rolled = (spot - from) * braking
	{
		build: Tiny,
		dish: Pie,
		feet: {
			right: straggler_slot.right,
			forward: from + rolled,
			height: 0.0,
		},
		pose: March.carrying_pose({
			build: Tiny,
			phase: rolled / wheel_radius,
			stride: 2.0 * (1.0 - progress),
		}),
		dish_tilt: 0.35 * (now.to_f64() * 0.5).sin() * (1.0 - progress),
	}
}

# A tiny robot's wheel, so the straggler's spokes turn as far as it rolls.
wheel_radius : F64
wheel_radius = 0.09

drum_major : I64 -> March.DrumMajor
drum_major = |now| {
	phase = step_phase(now)
	pump = 0.35 * (2.0 * phase).sin() * marching(now)
	# The left hand on the hip, the right holding the drumstick high.
	pose = {
		left_upper: -0.75,
		left_fore: 0.75,
		right_upper: 2.5,
		right_fore: F64.pi + pump,
		head: 0.0,
		pop: 0.0,
		turn: 1.0,
		bounce: 0.0,
		wink: 0.0,
		antenna_sway: Ease.boing(now - Script.halt_tick),
		phase,
		stride: high_step * marching(now),
	}
	{
		feet: { ..March.drum_major_halt_spot, forward: lead_forward(now) },
		pose,
		drumstick: tossed_drumstick({
			hand: Dancer.right_hand_at(pose),
			angle: pose.right_fore,
			since: now - Script.halt_tick,
		}),
		drumstick_layer: OverBody,
	}
}

# On the halt the drumstick goes up out of the hand, `toss_height` metres
# at the top, turning over three times, and comes down into it again
# `toss_frames` later.
toss_frames : I64
toss_frames = 56

toss_height : F64
toss_height = 1.4

tossed_drumstick : {
	hand : { across : F64, up : F64 },
	angle : F64,
	since : I64,
} -> { grip : { across : F64, up : F64 }, angle : F64 }
tossed_drumstick = |{ hand, angle, since }| {
	flight = Ease.ramp(since, toss_frames)
	{
		grip: { across: hand.across, up: hand.up + 4.0 * toss_height * flight * (1.0 - flight) },
		angle: angle + 3.0 * F64.tau * flight,
	}
}

# Twelve march, the straggler among them, and the drum major is not out
# before the army steps out.
expect March.slots.len() == 12
expect March.drum_major_at(Script.army_tick - 1) == NotYet

# Every marcher stands at its halt spot once the army halts, the straggler
# once it is in.
expect
	March.slots.all(
		|slot| {
			halted = March.trooper_at(slot, March.straggler_in_tick + 1)
			(halted.feet.forward - March.halt_spot(slot).forward).abs() < 0.0001
		},
	)
