## Dinner says when everything happens in the Thanksgiving movie, and where
## things are at each tick: where each robot has walked to and how it stands,
## where each dish is, how bright each string light is, where the guest's eye
## has moved to, how far the banner has dropped and how long the leaves have
## blown. It is the only module that knows what time it is. Every drawing
## module is handed numbers, so none of them is re-timed when the cut changes.
##
## Sixty ticks a second. The tall robot brings the turkey first, then the
## round one the potatoes, then the tiny one the pie, which wobbles all the
## way, slips, and is caught. Once all three sit, the lights blink on down the
## table, each robot's eyes lighting with the bulb above its place, and the
## eye eases back to take in the whole table. The banner drops, the leaves
## blow across, and a fourth robot walks in and does the robot dance, while
## the others turn their eyes to watch. Mid-dance the eye backs away to show
## five identical tables dancing in step, and the last frame holds the final
## pose.
import lib.Eye
import Dancer
import Dishes
import Lights
import Robot
import Table

Dinner :: [].{

	## The last tick that moves. Every tick after it shows the same frame.
	end_tick : I64
	end_tick = 1796

	## When the first bulb blinks on.
	lights_tick : I64
	lights_tick = 800

	## The tick the movie shows at `tick`, which holds at the end.
	held_tick : I64 -> I64
	held_tick = |tick|
		if tick < 0 {
			0
		} else if tick > end_tick {
			end_tick
		} else {
			tick
		}

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
			right: walked_right(build, held_tick(tick)),
			forward: chair.forward,
			height: 0.0,
		}
	}

	## How a robot stands at `tick`.
	robot_pose : Robot.Build, I64 -> Robot.Pose
	robot_pose = |build, tick| {
		now = held_tick(tick)
		plan = timing(build)
		walked = walked_right(build, now) - plan.from_right
		{
			phase: walked * F64.tau / plan.step,
			stride: stride(build, now),
			sit: smooth(ramp(now - plan.sit_tick, sit_frames)),
			seat_height: Table.chair_of(build).seat_height,
			reach: reach(build, now),
			eye_glow: bulb_glow(Lights.nearest_bulb(Table.chair_of(build).forward), now),
			look: smooth(ramp(now - watch_tick, 30)),
		}
	}

	## Where the dancer's feet are: walking in from the right, then on its spot
	## beside the near end of the table.
	dancer_feet : I64 -> Eye.At
	dancer_feet = |tick| { right: dancer_right(held_tick(tick)), forward: 1.4, height: 0.0 }

	## How the dancer stands at `tick`: arms swinging in steps on the walk in,
	## then the routine, each move snapping into place and holding.
	dancer_pose : I64 -> Dancer.Pose
	dancer_pose = |tick| {
		now = held_tick(tick)
		walked = dancer_from - dancer_right(now)
		phase = walked * F64.tau / 0.55
		pace = ((dancer_right(now - 5) - dancer_right(now)) / 0.09).min(1.0)
		move =
			if now < dance_tick {
				clicks = (phase.sin() * 2.0 + 2.5).to_i64_wrap() - 2
				swing = 0.18 * I64.to_f64(clicks) * pace
				{ ..rest, left_upper: rest.left_upper - swing, right_upper: rest.right_upper - swing }
			} else {
				dance_move(now - dance_tick)
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
		now = held_tick(tick)
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
			u = smooth(ramp(now - plan.set_tick, set_frames))
			# The dish rises a little on its way over, so it is lowered onto the
			# cloth rather than slid.
			arc = 0.08 * (F64.pi * u).sin()
			{
				at: {
					right: lifted.at.right + (spot.right - lifted.at.right) * u,
					forward: lifted.at.forward + (spot.forward - lifted.at.forward) * u,
					height: lifted.at.height + (spot.height - lifted.at.height) * u + arc,
				},
				tilt: lifted.tilt * (1.0 - u),
				layer: OnTable,
			}
		}
	}

	## How bright each bulb is, nearest the guest first.
	bulb_glows : I64 -> List(F64)
	bulb_glows = |tick| {
		now = held_tick(tick)
		var $out = List.with_capacity(Lights.bulb_count)
		for k in 0..<Lights.bulb_count {
			$out = $out.append(bulb_glow(k, now))
		}
		$out
	}

	## Where the guest's eye is: at the near end of the table, then eased
	## back and up until the whole table is in view.
	eye_spot : I64 -> {
		right : F64,
		forward : F64,
		height : F64,
	}
	eye_spot = |tick| {
		back = smooth(ramp(held_tick(tick) - pull_tick, pull_frames))
		# The reveal: mid-routine, the eye backs away past the other four
		# tables, which stood behind it until then.
		reveal = smooth(ramp(held_tick(tick) - reveal_tick, reveal_frames))
		table_right = -0.4 + 0.4 * back
		table_forward = 0.0 - 1.8 * back
		table_height = 1.15 + 0.4 * back
		{
			right: table_right + (0.4 - table_right) * reveal,
			forward: table_forward + (-25.5 - table_forward) * reveal,
			height: table_height + (3.4 - table_height) * reveal,
		}
	}

	## How far the banner has dropped in, from 0 to 1.
	banner_drop : I64 -> F64
	banner_drop = |tick| {
		u = ramp(held_tick(tick) - banner_tick, banner_frames)
		1.0 - (1.0 - u) * (1.0 - u)
	}

	## How many seconds the leaves have been blowing; negative before.
	gust_seconds : I64 -> F64
	gust_seconds = |tick| (held_tick(tick) - gust_tick).to_f64() / 60.0
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

pull_tick : I64
pull_tick = 880

pull_frames : I64
pull_frames = 180

reveal_tick : I64
reveal_tick = 1330

reveal_frames : I64
reveal_frames = 260

banner_tick : I64
banner_tick = 1020

banner_frames : I64
banner_frames = 60

gust_tick : I64
gust_tick = 1060

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
	u = smooth(ramp(tick - plan.enter_tick, plan.arrive_tick - plan.enter_tick))
	plan.from_right + (to - plan.from_right) * u
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
	set_down = 1.0 - smooth(ramp(tick - plan.set_tick, set_frames))
	match build {
		Tall | Round => set_down
		Tiny =>
			if tick < slip_tick + slip_frames {
				1.0
			} else if tick < slip_tick + slip_frames + fall_frames {
				dive = ramp(tick - slip_tick - slip_frames, fall_frames)
				1.0 - (1.0 - catch_reach) * (1.0 - (1.0 - dive) * (1.0 - dive))
			} else if tick < plan.set_tick {
				catch_reach + (1.0 - catch_reach) * smooth(
					ramp(tick - slip_tick - slip_frames - fall_frames, lift_frames),
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
				u = ramp(tick - slip_start, slip_frames)
				{
					at: { ..hand, right: hand.right + 0.05 * u },
					tilt: (0.13 + 0.45 * u) * rock.sin(),
					layer: Carried,
				}
			} else if tick < lift_start {
				v = ramp(tick - fall_start, fall_frames)
				# Let go at the top of its slip, the pie falls faster and faster
				# until the diving hand meets it.
				top = hand_in_yard(Tiny, fall_start)
				caught = hand_in_yard(Tiny, lift_start)
				fall = v * v
				{
					at: {
						right: top.right + 0.05 + (caught.right - top.right - 0.05) * v,
						forward: top.forward,
						height: top.height + (caught.height - top.height) * fall,
					},
					tilt: (0.58 + 0.4 * v) * rock.sin(),
					layer: Carried,
				}
			} else {
				w = ramp(tick - lift_start, lift_frames)
				{
					at: hand,
					tilt: 0.98 * (1.0 - w) * (1.0 - w) * rock.sin(),
					layer: Carried,
				}
			}
		}
	}
}

# A bulb's brightness: off until its turn, then a blink, on, dim, on.
bulb_glow : U64, I64 -> F64
bulb_glow = |index, tick| {
	since = tick - (Dinner.lights_tick + bulb_gap * index.to_i64_wrap())
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

# How much of the way through something that starts at 0 and takes `len`,
# held at each end.
ramp : I64, I64 -> F64
ramp = |since, len|
	if since <= 0 {
		0.0
	} else if since >= len {
		1.0
	} else {
		since.to_f64() / len.to_f64()
	}

smooth : F64 -> F64
smooth = |u| u * u * (3.0 - 2.0 * u)

# The seated robots turn their eyes to the dancer as it walks in.
watch_tick : I64
watch_tick = 1110

# The dancer walks in from the right, after the banner is up, to a spot
# beside the near end of the table where the pulled-back eye sees it whole.
walk_in_tick : I64
walk_in_tick = 1090

dance_tick : I64
dance_tick = 1236

dancer_from : F64
dancer_from = 4.5

dancer_right : I64 -> F64
dancer_right = |tick| {
	u = smooth(ramp(tick - walk_in_tick, dance_tick - 6 - walk_in_tick))
	dancer_from + (1.25 - dancer_from) * u
}

# One pose of the dance: the joints and the rest of what Dancer is told,
# without the walk.
Move : { left_upper : F64, left_fore : F64, right_upper : F64, right_fore : F64, head : F64, pop : F64, turn : F64, bounce : F64 }

rest : Move
rest = { left_upper: -0.12, left_fore: -0.12, right_upper: 0.12, right_fore: 0.12, head: 0.0, pop: 0.0, turn: 1.0, bounce: 0.0 }

quarter : F64
quarter = F64.pi / 2.0

# Both arms out and bent up at the elbow, a right angle each.
goalpost : Move
goalpost = { ..rest, left_upper: -quarter, left_fore: -F64.pi, right_upper: quarter, right_fore: F64.pi }

# Both arms straight out to the sides.
arms_out : Move
arms_out = { ..rest, left_upper: -quarter, left_fore: -quarter, right_upper: quarter, right_fore: quarter }

# The routine, a move and how many ticks it lasts. A move snaps into place
# over its first `snap_frames` ticks and holds for the rest, so the dance
# goes in clicks rather than easing.
routine : List({ move : Move, frames : I64 })
routine = [
	{ move: { ..rest, right_upper: quarter, right_fore: quarter }, frames: 14 },
	{ move: { ..rest, right_upper: quarter, right_fore: F64.pi }, frames: 18 },
	{ move: { ..rest, right_upper: quarter, right_fore: 2.62 }, frames: 9 },
	{ move: { ..rest, right_upper: quarter, right_fore: 2.09 }, frames: 9 },
	{ move: { ..rest, right_upper: quarter, right_fore: 1.57 }, frames: 9 },
	{ move: { ..rest, right_upper: quarter, right_fore: 1.05 }, frames: 9 },
	{ move: { ..rest, right_upper: quarter, right_fore: 0.52 }, frames: 12 },
	{ move: goalpost, frames: 16 },
	{ move: { ..goalpost, head: 0.5 }, frames: 8 },
	{ move: { ..goalpost, head: 1.0 }, frames: 14 },
	{ move: { ..goalpost, head: 0.5 }, frames: 8 },
	{ move: goalpost, frames: 8 },
	{ move: { ..goalpost, head: -0.5 }, frames: 8 },
	{ move: { ..goalpost, head: -1.0 }, frames: 14 },
	{ move: goalpost, frames: 12 },
	{ move: { ..goalpost, pop: 0.07 }, frames: 8 },
	{ move: goalpost, frames: 6 },
	{ move: { ..goalpost, pop: -0.07 }, frames: 8 },
	{ move: goalpost, frames: 6 },
	{ move: { ..goalpost, pop: 0.07 }, frames: 8 },
	{ move: goalpost, frames: 10 },
	{ move: { ..arms_out, bounce: 0.05 }, frames: 7 },
	{ move: arms_out, frames: 7 },
	{ move: { ..arms_out, bounce: 0.05 }, frames: 7 },
	{ move: arms_out, frames: 7 },
	{ move: { ..arms_out, bounce: 0.05 }, frames: 7 },
	{ move: arms_out, frames: 9 },
	{ move: { ..rest, turn: 0.88 }, frames: 10 },
	{ move: { ..rest, turn: 0.75 }, frames: 10 },
	{ move: { ..rest, turn: 0.62 }, frames: 10 },
	{ move: { ..rest, turn: 0.5 }, frames: 16 },
	{ move: { ..rest, turn: 0.62 }, frames: 10 },
	{ move: { ..rest, turn: 0.75 }, frames: 10 },
	{ move: { ..rest, turn: 0.88 }, frames: 10 },
	{ move: rest, frames: 12 },
	{ move: { ..goalpost, left_fore: -2.09, right_fore: 2.09 }, frames: 9 },
	{ move: { ..goalpost, left_fore: -1.57, right_fore: 1.57 }, frames: 9 },
	{ move: { ..goalpost, left_fore: -1.05, right_fore: 1.05 }, frames: 9 },
	{ move: { ..goalpost, left_fore: -1.05, right_fore: 1.05, head: 1.0 }, frames: 10 },
	{ move: { ..goalpost, left_fore: -1.05, right_fore: 1.05, head: -1.0 }, frames: 10 },
	{ move: { ..goalpost, left_fore: -1.05, right_fore: 1.05 }, frames: 8 },
	{ move: { ..goalpost, left_fore: -1.05, right_fore: 1.05, pop: 0.07 }, frames: 6 },
	{ move: { ..goalpost, left_fore: -1.05, right_fore: 1.05 }, frames: 6 },
	{ move: { ..arms_out, bounce: 0.05 }, frames: 7 },
	{ move: arms_out, frames: 7 },
	{ move: { ..arms_out, bounce: 0.05 }, frames: 7 },
	{ move: arms_out, frames: 9 },
	{ move: { ..arms_out, head: 1.0 }, frames: 12 },
	{ move: { ..arms_out, head: -1.0 }, frames: 12 },
	{ move: arms_out, frames: 8 },
	{ move: { ..rest, right_upper: quarter, right_fore: F64.pi }, frames: 12 },
	{ move: { ..rest, right_upper: quarter, right_fore: 2.09 }, frames: 9 },
	{ move: { ..rest, right_upper: quarter, right_fore: 1.05 }, frames: 9 },
	{ move: { ..goalpost, pop: 0.07 }, frames: 10 },
	{ move: goalpost, frames: 14 },
	# The final pose: one forearm up, one down, head to the camera, knees
	# dropped a little. The movie holds on it.
	{ move: { ..rest, right_upper: quarter, right_fore: F64.pi, left_upper: -quarter, left_fore: 0.0, bounce: 0.03 }, frames: 50 },
]

snap_frames : I64
snap_frames = 3

# The move `since` ticks into the routine, and the last move after it ends.
dance_move : I64 -> Move
dance_move = |since| {
	var $before = rest
	var $start = 0
	var $found = False
	var $move = rest
	for step in routine {
		if !$found and since < $start + step.frames {
			$move = snapped({ from: $before, to: step.move, fraction: ramp(since - $start + 1, snap_frames) })
			$found = True
		}
		$before = step.move
		$start = $start + step.frames
	}
	if !$found {
		$before
	} else {
		$move
	}
}

snapped : { from : Move, to : Move, fraction : F64 } -> Move
snapped = |{ from, to, fraction }| {
	mix = |a, b| a + (b - a) * fraction
	{
		left_upper: mix(from.left_upper, to.left_upper),
		left_fore: mix(from.left_fore, to.left_fore),
		right_upper: mix(from.right_upper, to.right_upper),
		right_fore: mix(from.right_fore, to.right_fore),
		head: mix(from.head, to.head),
		pop: mix(from.pop, to.pop),
		turn: mix(from.turn, to.turn),
		bounce: mix(from.bounce, to.bounce),
	}
}

# Every robot is sat down before the first bulb blinks, and is still sitting
# down one tick before it is seated.
expect [Tall, Round, Tiny].all(|build| Dinner.seated_tick(build) < Dinner.lights_tick)
expect [Tall, Round, Tiny].all(|build| Dinner.robot_pose(build, Dinner.lights_tick).sit == 1.0)
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

# The movie holds after its end, and not before it.
expect Dinner.held_tick(Dinner.end_tick + 600) == Dinner.end_tick
expect Dinner.held_tick(Dinner.end_tick - 1) == Dinner.end_tick - 1
expect Dinner.held_tick(-5) == 0

# No bulb is lit before the lights start, and every bulb is lit at the end.
expect Dinner.bulb_glows(Dinner.lights_tick - 1).all(|glow| glow == 0.0)
expect Dinner.bulb_glows(Dinner.end_tick).all(|glow| glow == 1.0)

# The tiny robot's eyes light after the lights start, and are dark before.
expect Dinner.robot_pose(Tiny, Dinner.lights_tick - 1).eye_glow == 0.0
expect Dinner.robot_pose(Tiny, Dinner.end_tick).eye_glow == 1.0

# The pie falls below the hand's carrying height and is caught again.
expect {
	carried = Dinner.dish_place(Tiny, slip_tick).at.height
	falling = Dinner.dish_place(Tiny, slip_tick + slip_frames + fall_frames - 1).at.height
	lifted = Dinner.dish_place(Tiny, timing(Tiny).set_tick - 1).at.height
	falling < carried - 0.05 and (lifted - carried).abs() < 0.03
}
