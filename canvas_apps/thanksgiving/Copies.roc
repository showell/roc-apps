## Copies is the robots multiplying: four copies of the whole table, its
## party and its dancer, each riding in on a parade float. A float rolls in
## from far off to one side, pushed by a tiny robot puffing along behind
## it, and brakes to a stop on one of the dancer's shoulder pops. Each float
## comes in faster than the one before. A copy is
## the first table's scene moved and raised onto its float, so every dancer
## dances in step, even while it rides.
import Ease
import Script

Copies :: [].{

	## A table: where it stands, moved from the first table's place, and how
	## it got there. The first table stands on the lawn; a copy rides a
	## float.
	TablePlace : {
		index : U64,
		offset : { right : F64, forward : F64 },
		ride : [OnLawn, OnFloat(Copies.FloatRide)],
	}

	## A float on its way: how far it has rolled, in metres, how fast it is
	## going, from 1, full speed, to 0, stopped, and which way it came from,
	## -1 from the left and 1 from the right. Its pusher is on that side.
	FloatRide : {
		rolled : F64,
		speed : F64,
		from_side : F64,
		deck_height : F64,
	}

	## Every table at `tick`, farthest first: the first table, always there,
	## then the copies that have set off, the far pair before the near pair.
	table_places_at : I64 -> List(Copies.TablePlace)
	table_places_at = |tick| {
		now = Script.held_tick(tick)
		floats =
			List.map3(
				float_routes,
				Script.float_stop_ticks,
				[1, 2, 3, 4],
				|route, stop_tick, index| {
					route,
					index,
					since: now - stop_tick + route.roll_frames,
				},
			)
				.keep_if(|float| float.since > 0)
				.map(|float| float_place(float, Copies.deck_height_at(now)))
		[
			{
				index: 0,
				offset: { right: 0.0, forward: 0.0 },
				ride: OnLawn,
			},
		].concat(floats)
	}

	## How high a float's deck stands off the lawn, in metres, until the
	## floats kneel.
	deck_height : F64
	deck_height = 0.4

	## Where table `index` stops: the first table, 0, where it always is,
	## then the copies in the order they are painted.
	table_offset : U64 -> { right : F64, forward : F64 }
	table_offset = |index|
		if index == 0 {
			{ right: 0.0, forward: 0.0 }
		} else {
			route = float_routes.get(index - 1) ?? crash "Copies.table_offset: four floats"
			route.stop
		}

	## How high every deck stands at `tick`: up while the floats roll, then,
	## as the army halts among them, down onto the lawn with a hiss and a
	## bounce, like a bus kneeling, so the marchers can walk aboard.
	deck_height_at : I64 -> F64
	deck_height_at = |tick| {
		down = Ease.ramp(Script.held_tick(tick) - Script.kneel_tick, kneel_frames)
		bounce = 0.03 * (F64.pi * 3.0 * down).sin() * (1.0 - down)
		(Copies.deck_height * (1.0 - Ease.smooth(down)) + bounce).max(0.0)
	}
}

# Where a float stops, which side it comes in from, and how many ticks it
# takes to roll in.
FloatRoute : {
	stop : { right : F64, forward : F64 },
	from_side : F64,
	roll_frames : I64,
}

# The floats stand in two rows nearer the eye than the first table, an aisle
# down the middle, each coming in from its own side. The far row is given
# first, so the list is in the order they are painted.
float_routes : List(FloatRoute)
float_routes = [
	{
		stop: { right: -2.75, forward: -8.5 },
		from_side: -1.0,
		roll_frames: 200,
	},
	{
		stop: { right: 2.75, forward: -8.5 },
		from_side: 1.0,
		roll_frames: 130,
	},
	{
		stop: { right: -5.5, forward: -17.0 },
		from_side: -1.0,
		roll_frames: 90,
	},
	{
		stop: { right: 5.5, forward: -17.0 },
		from_side: 1.0,
		roll_frames: 60,
	},
]

# How far out a float starts. It brakes all the way, so it comes in fast and
# eases to its stop.
roll_metres : F64
roll_metres = 34.0

kneel_frames : I64
kneel_frames = 40

float_place : {
	route : FloatRoute,
	index : U64,
	since : I64,
},
F64 -> Copies.TablePlace
float_place = |{ route, index, since }, deck_height| {
	progress = Ease.ramp(since, route.roll_frames)
	left_to_go = (1.0 - progress) * (1.0 - progress)
	{
		index,
		offset: {
			right: route.stop.right + route.from_side * roll_metres * left_to_go,
			forward: route.stop.forward,
		},
		ride: OnFloat({
			rolled: roll_metres * (1.0 - left_to_go),
			speed: 1.0 - progress,
			from_side: route.from_side,
			deck_height,
		}),
	}
}

# No float is out before the parade; one just set off is far out to its
# side; at the end every float is at its stop, stopped.
expect Copies.table_places_at(Script.parade_tick).len() == 1
expect {
	first_off = (Script.float_stop_ticks.first() ?? 0) - 200 + 1
	match Copies.table_places_at(first_off) {
		[_, just_off] => just_off.offset.right.abs() > 30.0
		_ => False
	}
}
expect
	Copies.table_places_at(Script.end_tick)
		.drop_first(1)
		.all(
			|table|
				match table.ride {
					OnFloat(ride) => ride.speed == 0.0 and table.offset.right.abs() < 6.0
					OnLawn => False
				},
		)
