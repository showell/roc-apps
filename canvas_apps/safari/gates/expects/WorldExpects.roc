## WorldExpects holds the rules the real route keeps that World can't check
## beside its data, because the rule's home is a module World doesn't import.

import game.Speed
import game.VehicleLimits
import game.World

WorldExpects :: [].{}

# Every bend's turn rounds to a whole degree in VehicleLimits' turn_speeds. Throttle and
# TruckJourney ask turn_speed for each bend, and it crashes on a turn that isn't there.
expect World.bending_plans.all(|{ turn, .. }| VehicleLimits.turn_speed(turn) > Speed.at_rest)

# The world chapter's table of the route's first six segments, as World.bending_plans
# declares them. A turn to the right is positive.
expect
	book_route_plans.map(|plan| plan.length.to_metres())
		== [500.0, 320.0, 400.0, 300.0, 300.0, 300.0]
expect
	book_route_plans.map(|plan| plan.scheme)
		== [AllGreen, AllGreen, AllGreen, GoldGreen, AllGreen, AllGreen]
expect
	book_route_plans.map(|plan| plan.encounter)
		== [BirdHere, QuietRoad, BirdHere, CatCrosses, QuietRoad, BirdHere]
expect
	book_route_plans.map(|plan| plan.pigs)
		== [NoPigs, NoPigs, WithPigs, NoPigs, NoPigs, NoPigs]
expect
	book_route_plans.map(|plan| plan.bull)
		== [NoBull, NoBull, NoBull, NoBull, WithBull, WithBull]
expect {
	turns = World.bending_plans.take_first(6).map(|{ turn, .. }| turn.to_degrees())
	want_turns = [50.0, -70.0, 20.0, 20.0, -70.0, -70.0]
	turns.len() == want_turns.len()
		and want_turns
			.map_with_index(
				|want, at|
					match turns.get(at) {
						Ok(got) => (got - want).abs() < 0.000001
						Err(_) => False
					},
			)
			.all(|is_same| is_same)
}

## The plans of the route's first six segments, the rows of the book's table.
book_route_plans : List(World.SegmentPlan)
book_route_plans = World.bending_plans.take_first(6).map(|{ segment_plan, .. }| segment_plan)
