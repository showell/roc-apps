## Serving says where each dish is at a tick: in the hands that carry it, or
## down on its spot on the table. A dish rides in its carrier's near hand,
## level, and goes wherever the hand goes as it is set down; from the moment
## the hands start out over the table it is painted over the cloth, and once
## Placing says it is let go it sits on its spot. The pie has more of a
## journey: it wobbles as the baby rolls in, rocks, slips, falls into the
## baby's diving hands, rides over the baby's head while it twirls, passes to
## its mother's hands, and she sets it down.
import lib.Eye
import Dishes
import Ease
import Family
import Guests
import Robot
import Script
import Seating
import Table

Serving :: [].{

	## Every dish on the table.
	dishes : List(Dishes.Dish)
	dishes = [Turkey, Potatoes, Pie]

	## Where a dish is and how far it is tipped. A carried dish is painted
	## with the robots; one over the table, or on it, is painted on the cloth.
	dish_place : Dishes.Dish,
	I64 -> {
		at : Eye.At,
		tilt : F64,
		layer : [Carried, OnTable],
	}
	dish_place = |dish, tick| {
		now = Script.held_tick(tick)
		match dish {
			Turkey => served_place(Tall, { dish, now })
			Potatoes => served_place(Round, { dish, now })
			Pie => pie_place(now)
		}
	}
}

# A dish its own robot carries in and sets down.
served_place : [Tall, Round],
{ dish : Dishes.Dish, now : I64 } -> {
	at : Eye.At,
	tilt : F64,
	layer : [Carried, OnTable],
}
served_place = |server, { dish, now }| {
	reach = Guests.placing_reach(server, now)
	build = Guests.build_of(server)
	hand = Seating.hand_in_yard(Robot.proportions(build), Guests.guest_at(build, now))
	match reach.dish {
		Down => {
			at: Table.dish_spot(dish),
			tilt: 0.0,
			layer: OnTable,
		}
		InHands =>
			if now < Guests.set_tick(server) {
				{
					at: hand,
					tilt: 0.0,
					layer: Carried,
				}
			} else {
				{
					at: hand,
					tilt: 0.0,
					layer: OnTable,
				}
			}
	}
}

pie_place : I64 -> {
	at : Eye.At,
	tilt : F64,
	layer : [Carried, OnTable],
}
pie_place = |now|
	match Family.pie_holder(now) {
		BabyHolds => babys_pie(now)
		Passing(fraction) => {
			from = baby_hand(now)
			to = mommy_hand(now)
			{
				at: {
					right: from.right + (to.right - from.right) * fraction,
					forward: from.forward + (to.forward - from.forward) * fraction,
					height: from.height + (to.height - from.height) * fraction,
				},
				tilt: 0.0,
				layer: Carried,
			}
		}
		MommyHolds => {
			at: mommy_hand(now),
			tilt: 0.0,
			layer: if now < Family.pie_place_tick {
				Carried
			} else {
				OnTable
			},
		}
		OnTable => {
			at: Table.dish_spot(Pie),
			tilt: 0.0,
			layer: OnTable,
		}
	}

baby_hand : I64 -> Eye.At
baby_hand = |now| Seating.hand_in_yard(Robot.proportions(Tiny), Guests.guest_at(Tiny, now))

mommy_hand : I64 -> Eye.At
mommy_hand = |now| Seating.hand_in_yard(Robot.proportions(Mommy), Guests.guest_at(Mommy, now))

# The pie in the baby's hands: it wobbles with the rolling, rocks harder as
# it slips, falls faster and faster from the top of its slip until the
# diving hands meet it, and rocks less and less as it is lifted back up.
babys_pie : I64 -> {
	at : Eye.At,
	tilt : F64,
	layer : [Carried, OnTable],
}
babys_pie = |now| {
	hand = baby_hand(now)
	slip_start = Family.slip_tick
	fall_start = slip_start + Family.slip_frames
	lift_start = fall_start + Family.fall_frames
	rock = now.to_f64() * 0.45
	if now < slip_start {
		walking_wobble = 0.13 * (Guests.guest_at(Tiny, now).walk_phase * 0.5).sin()
		{
			at: hand,
			tilt: walking_wobble,
			layer: Carried,
		}
	} else if now < fall_start {
		slip_progress = Ease.ramp(now - slip_start, Family.slip_frames)
		{
			at: { ..hand, right: hand.right + 0.05 * slip_progress },
			tilt: (0.13 + 0.45 * slip_progress) * rock.sin(),
			layer: Carried,
		}
	} else if now < lift_start {
		fall_progress = Ease.ramp(now - fall_start, Family.fall_frames)
		top = baby_hand(fall_start)
		caught = baby_hand(lift_start)
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
		lift_progress = Ease.ramp(now - lift_start, Family.lift_frames)
		{
			at: hand,
			tilt: 0.98 * (1.0 - lift_progress) * (1.0 - lift_progress) * rock.sin(),
			layer: Carried,
		}
	}
}

# Every dish is down on its spot once everyone is sat.
expect
	Serving.dishes.all(
		|dish| {
			place = Serving.dish_place(dish, Script.walk_in_tick)
			place.at == Table.dish_spot(dish) and place.layer == OnTable
		},
	)

# The pie falls below the hands' carrying height and is caught again.
expect {
	carried = Serving.dish_place(Pie, Family.slip_tick).at.height
	falling = Serving.dish_place(
		Pie,
		Family.slip_tick + Family.slip_frames + Family.fall_frames - 1,
	).at.height
	falling < carried - 0.05
}

# A dish is set down where its carrier's hand meets it: as far down the table
# as the hand, so it is never slid in depth.
expect {
	set_down = Serving.dish_place(Turkey, Guests.set_tick(Tall) + 25)
	(set_down.at.forward - Table.dish_spot(Turkey).forward).abs() < 0.001
}
