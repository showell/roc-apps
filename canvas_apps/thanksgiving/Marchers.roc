## Marchers is the army breaking ranks for the empty chairs. Once the drum
## major has caught the drumstick, each marcher runs, face on, from its place
## in the ranks to the end of an aisle beside a float: the near left float,
## close by; the far left, up the gap between the floats; or the far right,
## up the gap and across. There it turns side on and does what the opening
## guests do, by Seating and Placing: walks up the aisle to the table, sets
## its dish down, pulls its chair out and sits, the chairs on the right side
## of the floats, so it faces left. A tiny one sets its pie down once it is
## up on its chair, since it cannot reach over the table standing. The
## straggler, last in, takes the last chair.
##
## On the lawn a marcher is in the backyard's metres; at its table it is in
## that table's own metres, and the table's party draws it.
import lib.Eye
import Dishes
import Ease
import Copies
import Figure
import March
import Placing
import Robot
import RobotBody
import Script
import Seating
import SideBody
import Table

Marchers :: [].{

	## A marcher at its table: its build, how it stands, its chair and
	## where its dish is, all in the table's own metres.
	Visitor : {
		build : Robot.Build,
		guest : Seating.Guest,
		chair : Table.Chair,
		dish : Dishes.Dish,
		dish_place : {
			at : Eye.At,
			tilt : F64,
			layer : [Carried, OnTable],
		},
	}

	## The marchers still on the lawn at `tick`, face on: marching, halted,
	## or running for their tables.
	running_at : I64 -> List(March.Trooper)
	running_at = |tick| {
		now = Script.held_tick(tick)
		if now < Script.army_tick {
			[]
		} else {
			seats.keep_if(|seat| now < reach_tick(seat)).map(|seat| runner(seat, now))
		}
	}

	## The marchers that have reached table `index` by `tick`.
	visitors_at : U64, I64 -> List(Marchers.Visitor)
	visitors_at = |index, tick| {
		now = Script.held_tick(tick)
		seats.keep_if(|seat| seat.table == index and now >= reach_tick(seat)).map(
			|seat| visitor(seat, now),
		)
	}

	## The chairs along table `index`'s right side, each as high as its
	## marcher wants it.
	right_chairs : U64 -> List(Table.Chair)
	right_chairs = |index| seats.keep_if(|seat| seat.table == index).map(chair_of)
}

# Which table a marcher runs for, and which place along its right side,
# counted from the far end.
Seat : {
	slot : March.Slot,
	table : U64,
	place : U64,
}

# The first file of each rank takes the near left float, the second the far
# left and the third the far right; the fourth file and the straggler fill
# the last place at each.
seats : List(Seat)
seats =
	List.map2(
		March.slots,
		[
			(3, 0),
			(1, 0),
			(2, 0),
			(3, 3),
			(3, 1),
			(1, 1),
			(2, 1),
			(1, 3),
			(3, 2),
			(1, 2),
			(2, 2),
			(2, 3),
		],
		|slot, (table, place)| { slot, table, place },
	)

place_forwards : List(F64)
place_forwards = [5.2, 4.1, 3.0, 1.9]

place_forward : Seat -> F64
place_forward = |seat| place_forwards.get(seat.place) ?? crash "Marchers.place_forward: four places a side"

chair_of : Seat -> Table.Chair
chair_of = |seat| {
	right: 0.0 - Table.chair_of(seat.slot.build).right,
	forward: place_forward(seat),
	seat_height: Table.chair_of(seat.slot.build).seat_height,
}

# Where a marcher's aisle starts, off the table's right side, in the
# table's own metres and in the backyard's.
aisle_start : Seat -> { right : F64, forward : F64 }
aisle_start = |seat| { right: 2.6, forward: place_forward(seat) - 0.5 }

in_yard : Seat, { right : F64, forward : F64 } -> { right : F64, forward : F64 }
in_yard = |seat, spot| {
	offset = Copies.table_offset(seat.table)
	{ right: offset.right + spot.right, forward: offset.forward + spot.forward }
}

# The way from a marcher's place in the ranks to its aisle: straight to the
# near float's; across then up the gap to the far left's; up the gap, across
# between the rows of floats, and up beside the far right's.
route : Seat -> List({ right : F64, forward : F64 })
route = |seat| {
	start = March.halt_spot(seat.slot)
	to = in_yard(seat, aisle_start(seat))
	between_rows = -9.4
	match seat.table {
		1 => [
			{ right: start.right, forward: start.forward },
			{ right: to.right, forward: start.forward },
			to,
		]
		2 => [
			{ right: start.right, forward: start.forward },
			{ right: start.right, forward: between_rows },
			{ right: to.right, forward: between_rows },
			to,
		]
		_ => [{ right: start.right, forward: start.forward }, to]
	}
}

route_length : List({ right : F64, forward : F64 }) -> F64
route_length = |points|
	List.map2(
		points.drop_last(1),
		points.drop_first(1),
		|a, b| distance(a, b),
	).fold(0.0, |total, length| total + length)

distance : { right : F64, forward : F64 }, { right : F64, forward : F64 } -> F64
distance = |a, b| {
	across = b.right - a.right
	along = b.forward - a.forward
	(across * across + along * along).sqrt()
}

# Where along a route a marcher is, `run` metres in.
along_route : List({ right : F64, forward : F64 }), F64 -> { right : F64, forward : F64 }
along_route = |points, run| {
	var $left = run
	var $at = points.first() ?? crash "Marchers.along_route: a route has a start"
	for (a, b) in List.map2(
		points.drop_last(1),
		points.drop_first(1),
		|a, b| (a, b),
	) {
		length = distance(a, b)
		if $left > 0.0 {
			part = ($left / length).min(1.0)
			$at = {
				right: a.right + (b.right - a.right) * part,
				forward: a.forward + (b.forward - a.forward) * part,
			}
			$left = $left - length
		}
	}
	$at
}

# A run, at a sprint.
run_metres_a_tick : F64
run_metres_a_tick = 0.07

# When a marcher sets off: the ranks go in turn, tall, round, tiny, and the
# straggler as soon as it is in.
break_tick : Seat -> I64
break_tick = |seat|
	match seat.slot.arrives {
		Late => March.straggler_in_tick + 5
		InStep =>
			Script.seat_tick
				+ (
					match seat.slot.build {
						Tall | Mommy => 0
						Round => 10
						Tiny => 20
					}
				)
	}

# When a marcher reaches its aisle and turns side on.
reach_tick : Seat -> I64
reach_tick = |seat| {
	run_ticks = route_length(route(seat)) / run_metres_a_tick
	break_tick(seat) + 1 + run_ticks.to_i64_wrap()
}

runner : Seat, I64 -> March.Trooper
runner = |seat, now|
	if now < break_tick(seat) {
		March.trooper_at(seat.slot, now)
	} else {
		run = run_metres_a_tick * (now - break_tick(seat)).to_f64()
		spot = along_route(route(seat), run)
		{
			build: seat.slot.build,
			dish: seat.slot.dish,
			feet: {
				right: spot.right,
				forward: spot.forward,
				height: 0.0,
			},
			pose: March.carrying_pose({
				build: seat.slot.build,
				phase: run * F64.tau / 0.9,
				stride: 1.4,
			}),
			dish_tilt: 0.1 * (run * 7.0).sin(),
		}
	}

turn_frames : I64
turn_frames = 10

# A marcher's sit, by Seating, in its table's metres, facing left.
plan_of : Seat -> Seating.Plan
plan_of = |seat| {
	build = seat.slot.build
	chair = chair_of(seat)
	walk_in = reach_tick(seat) + turn_frames
	arrive = walk_in + 40
	{
		build,
		walk_from: aisle_start(seat).right,
		stop_right: stop_right_of(build, chair),
		aisle_forward: aisle_start(seat).forward,
		chair,
		setback: setback_of(build),
		step: step_of(build),
		enter_tick: walk_in,
		arrive_tick: arrive,
		chair_tick: match build {
			Tiny => arrive + 2
			Tall | Round | Mommy => arrive + 2 + set_frames + 2
		},
		facing: -1.0,
		chair_mover: Itself,
	}
}

# Where a marcher stops in its aisle: beside its chair, the round one with
# its barrel against the table's edge.
stop_right_of : Robot.Build, Table.Chair -> F64
stop_right_of = |build, chair|
	match build {
		Round => Table.half_width + 0.02 + Robot.proportions(Round).body_width / 2.0
		Tiny => chair.right - 0.03
		Tall | Mommy => chair.right - 0.32
	}

setback_of : Robot.Build -> F64
setback_of = |build|
	match build {
		Tall | Mommy => 0.25
		Round => 0.15
		Tiny => 0.12
	}

step_of : Robot.Build -> F64
step_of = |build|
	match build {
		Tall | Mommy => 1.1
		Round => 0.5
		Tiny => 0.4
	}

set_frames : I64
set_frames = 50

# When a marcher starts setting its dish down: as it stops, or, a tiny one,
# once it is up on its chair.
set_tick : Seat -> I64
set_tick = |seat| {
	plan = plan_of(seat)
	match seat.slot.build {
		Tiny => Seating.seated_tick(plan)
		Tall | Round | Mommy => plan.arrive_tick + 2
	}
}

# Where a dish goes down: in front of the hands that set it.
dish_spot : Seat -> Eye.At
dish_spot = |seat| {
	forward =
		match seat.slot.build {
			Tiny => place_forward(seat) - 0.12
			Tall | Round | Mommy => aisle_start(seat).forward - 0.12
		}
	across =
		match seat.slot.build {
			Round => 0.42
			Tall | Tiny | Mommy => 0.3
		}
	{ right: across, forward, height: Table.top_height }
}

visitor : Seat, I64 -> Marchers.Visitor
visitor = |seat, now| {
	build = seat.slot.build
	body = Robot.proportions(build)
	plan = plan_of(seat)
	seated = Seating.guest_at(plan, { now, look: 0.0, glow: 1.0 })
	turning = Ease.smooth(Ease.ramp(now - reach_tick(seat), turn_frames))
	facing_now = { ..seated, pose: { ..seated.pose, facing: 0.0 - turning } }
	reach = placing_at(seat, { guest: facing_now, now })
	guest =
		match reach {
			Holding(held) => with_hands(
				body,
				{
					guest: facing_now,
					hand: held.hand,
					lean: held.lean,
				},
			)
			Free => facing_now
		}
	hand = Seating.hand_in_yard(body, guest)
	down = {
		at: dish_spot(seat),
		tilt: 0.0,
		layer: OnTable,
	}
	dish_place =
		match reach {
			Holding(held) =>
				match held.dish {
					Down => down
					InHands =>
						if now >= set_tick(seat) {
							{
								at: hand,
								tilt: 0.0,
								layer: OnTable,
							}
						} else {
							{
								at: hand,
								tilt: 0.0,
								layer: Carried,
							}
						}
				}
			Free =>
				if now >= set_tick(seat) + set_frames {
					down
				} else {
					{
						at: hand,
						tilt: 0.0,
						layer: Carried,
					}
				}
		}
	{
		build,
		guest,
		chair: chair_of(seat),
		dish: seat.slot.dish,
		dish_place,
	}
}

# Where the hands are, if they are the dish's: carried in, then set down.
# A tiny marcher's hands are Seating's while it gets onto its chair, the pie
# in them.
placing_at : Seat, { guest : Seating.Guest, now : I64 } -> [Holding(Placing.Reach), Free]
placing_at = |seat, { guest, now }| {
	body = Robot.proportions(seat.slot.build)
	plan = plan_of(seat)
	set_at = set_tick(seat)
	spot = dish_spot(seat)
	hip = guest.pose.hip
	setting = Placing.setting_down(
		body,
		{
			hip,
			carry: Placing.carrying_hand(body, hip),
			spot: { across: plan.facing * (spot.right - guest.at.right), up: spot.height - 0.02 },
			progress: Ease.ramp(now - set_at, set_frames),
		},
	)
	on_chair = now >= plan.chair_tick and now < set_at
	if on_chair or now >= set_at + set_frames {
		Free
	} else {
		Holding(setting)
	}
}

with_hands : RobotBody.Proportions,
{
	guest : Seating.Guest,
	hand : Figure.Spot,
	lean : F64,
} -> Seating.Guest
with_hands = |body, { guest, hand, lean }| {
	leaning = { ..guest.pose, lean: guest.pose.lean + lean }
	{
		..guest,
		pose: {
			..leaning,
			near_arm: SideBody.arm_toward(body, { pose: leaning, hand }),
			far_arm: SideBody.arm_toward(
				body,
				{ pose: leaning, hand: { ..hand, across: hand.across - 0.04 } },
			),
		},
	}
}

# Every marcher has a chair of its own, and twelve sit at the three floats.
expect seats.len() == 12
expect
	[1, 2, 3].all(|index| Marchers.right_chairs(index).len() == 4)

# Every marcher is at its table, sat, its dish down, by the time the crowd
# floods in.
expect
	[1, 2, 3].all(
		|index| {
			visitors = Marchers.visitors_at(index, Script.flood_tick)
			visitors.len() == 4 and visitors.all(|visit| visit.dish_place.layer == OnTable)
		},
	)
