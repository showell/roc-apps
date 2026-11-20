## Copies is the robots multiplying: four copies of the whole table, its
## party and its dancer, each springing up out of the lawn at one of the
## dancer's shoulder pops, once the eye has backed far enough away to see
## where they stand. A copy is the first table's scene moved, so every
## dancer dances in step.
import Ease
import Script

Copies :: [].{

	## A table: where it stands, moved from the first table's place, and how
	## far it has sprung up, from 0, not there yet, to 1, full size.
	TablePlace : { offset : { right : F64, forward : F64 }, scale : F64 }

	## Every table at `tick`, farthest first: the first table, always there,
	## then the copies, the far pair before the near pair.
	table_places_at : I64 -> List(Copies.TablePlace)
	table_places_at = |tick| {
		now = Script.held_tick(tick)
		copies = List.map2(copy_offsets, Script.copy_ticks, |offset, pop_tick| { offset, scale: sprung(now - pop_tick) })
		[{ offset: { right: 0.0, forward: 0.0 }, scale: 1.0 }].concat(copies)
	}

	## The spot on the ground a table springs up from, in its own metres:
	## halfway down the table.
	middle : { right : F64, forward : F64 }
	middle = { right: 0.0, forward: 3.3 }
}

# The copies stand in two rows nearer the eye than the first table, popping
# up left, right, left, right. The rows are given far row first, so the list
# is in the order they are painted.
copy_offsets : List({ right : F64, forward : F64 })
copy_offsets = [
	{ right: -2.75, forward: -8.5 },
	{ right: 2.75, forward: -8.5 },
	{ right: -5.5, forward: -17.0 },
	{ right: 5.5, forward: -17.0 },
]

# How far a copy has sprung up `since` ticks after its pop: overshooting a
# little and settling, in `spring_frames` ticks.
sprung : I64 -> F64
sprung = |since| Ease.springy(Ease.ramp(since, spring_frames))

spring_frames : I64
spring_frames = 20

# Before its pop a copy is not there; after it, it stands full size.
expect Copies.table_places_at(0).map(|table| table.scale) == [1.0, 0.0, 0.0, 0.0, 0.0]
expect Copies.table_places_at(Script.end_tick).all(|table| table.scale == 1.0)
