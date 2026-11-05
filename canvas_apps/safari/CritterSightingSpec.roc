## These are CritterSighting's checks: how far along the chain each kind of
## critter is sighted, the road's last segment, ponds, and the critters
## of the whole chain and of the segment behind the rider.
app [main!] {
	lib: "../lib/main.roc",
}

import Angle
import CritterSighting
import Frame
import Across
import Along
import Distance
import Grade
import World

reach_got : List(I64)
reach_got = [CritterSighting.farm_reach.to_i64(), CritterSighting.safari_reach.to_i64()]

reach_want : List(I64)
reach_want = [3, 5]

origin : Frame.Pose
origin = {
	along: Along.metres(0.0),
	across: Across.metres(0.0),
	yaw: Angle.straight_ahead,
	half_width: Distance.metres(2.0),
}

## The first six segments, chained in order.
road : Frame.RoadView
road = {
	world: [0, 1, 2, 3, 4, 5].map(World.route_segment),
	chain: [0, 1, 2, 3, 4, 5].map(World.SegmentIndex.number),
	pose: origin,
}

## The world's segment `index` alone.
lone : U32 -> Frame.RoadView
lone = |index| {
	world: [World.route_segment(index)],
	chain: [0].map(World.SegmentIndex.number),
	pose: origin,
}

farm_at : U32 -> I64
farm_at = |number| CritterSighting.farm_sightings(
	road,
	Frame.ChainPosition.number(number),
).len().to_i64_wrap()

safari_at : U32 -> I64
safari_at = |number|
	CritterSighting.safari_sightings(road, Frame.ChainPosition.number(number)).len().to_i64_wrap()

cutoff_got : List(Bool)
cutoff_got = [
	(farm_at(0) > 0),
	(farm_at(2) > 0),
	(farm_at(3) == 0),
	(farm_at(4) == 0),
	(farm_at(5) == 0),
	(safari_at(3) > 0),
	(safari_at(4) > 0),
	(safari_at(5) == 0),
]

cutoff_want : List(Bool)
cutoff_want = [True, True, True, True, True, True, True, True]

term_got : List(I64)
term_got = [
	CritterSighting.safari_sightings(lone(18), Frame.ChainPosition.first).len().to_i64_wrap(),
]

term_want : List(I64)
term_want = [0]

term_flag_got : List(Bool)
term_flag_got = [(CritterSighting.safari_sightings(lone(0), Frame.ChainPosition.first).len() > 0)]

term_flag_want : List(Bool)
term_flag_want = [True]

duck_count : U32 -> I64
duck_count = |index|
	CritterSighting.duck_sightings(lone(index), Frame.ChainPosition.first).len().to_i64_wrap()

duck_got : List(Bool)
duck_got = [
	(duck_count(12) > 0),
	(duck_count(0) == 0),
	(duck_count(4) == 0),
	(duck_count(18) == 0),
]

duck_want : List(Bool)
duck_want = [True, True, True, True]

duck_reach_got : List(I64)
duck_reach_got = [
	CritterSighting.duck_sightings(road, Frame.ChainPosition.number(5)).len().to_i64_wrap(),
	duck_count(12),
]

duck_reach_want : List(I64)
duck_reach_want = [0, 6]

order_got : List(I64)
order_got = {
	whole = CritterSighting.sightings_at(road, Frame.ChainPosition.first).len().to_i64_wrap()
	ducks = CritterSighting.duck_sightings(road, Frame.ChainPosition.first).len().to_i64_wrap()
	[(whole - ((farm_at(0) + safari_at(0)) + ducks))]
}

order_want : List(I64)
order_want = [0]

## How many critters the segments from `position` to the chain's end hold.
count_from : U32 -> I64
count_from = |position|
	List.from_iter(U32.until(position, 6))
		.map(
			|number| CritterSighting.sightings_at(road, Frame.ChainPosition.number(number))
				.len()
				.to_i64_wrap(),
		)
		.sum()

walk_got : List(I64)
walk_got = [
	CritterSighting.sightings_ahead({ ..road, chain: [] }).len().to_i64_wrap(),
	(
		CritterSighting.sightings_ahead(lone(0)).len().to_i64_wrap() - CritterSighting.sightings_at(
			lone(0),
			Frame.ChainPosition.first,
		).len().to_i64_wrap()
	),
	(CritterSighting.sightings_ahead(road).len().to_i64_wrap() - count_from(0)),
]

walk_want : List(I64)
walk_want = [0, 0, 0]

grow_got : List(Bool)
grow_got = [(count_from(0) >= count_from(1)), (count_from(1) >= count_from(2))]

grow_want : List(Bool)
grow_want = [True, True]

behind_got : List(Bool)
behind_got = [
	(CritterSighting.sightings_behind(road, World.SegmentIndex.number(4)).len() > 0),
	(CritterSighting.ducks_behind(road, World.route_segment(12)).len() > 0),
	(CritterSighting.ducks_behind(road, World.route_segment(0)).len() == 0),
]

behind_want : List(Bool)
behind_want = [True, True, True]

# --- Entry ---

main! = |_args| {
	verdicts = [
		Grade.ints({
			name: "cn-reach ",
			got: reach_got,
			want: reach_want,
		}),
		Grade.bools({
			name: "cn-cutoff",
			got: cutoff_got,
			want: cutoff_want,
		}),
		Grade.ints({
			name: "cn-term  ",
			got: term_got,
			want: term_want,
		}),
		Grade.bools({
			name: "cn-tflag ",
			got: term_flag_got,
			want: term_flag_want,
		}),
		Grade.bools({
			name: "cn-duck  ",
			got: duck_got,
			want: duck_want,
		}),
		Grade.ints({
			name: "cn-dreach",
			got: duck_reach_got,
			want: duck_reach_want,
		}),
		Grade.ints({
			name: "cn-order ",
			got: order_got,
			want: order_want,
		}),
		Grade.ints({
			name: "cn-walk  ",
			got: walk_got,
			want: walk_want,
		}),
		Grade.bools({
			name: "cn-grow  ",
			got: grow_got,
			want: grow_want,
		}),
		Grade.bools({
			name: "cn-behind",
			got: behind_got,
			want: behind_want,
		}),
	]
	for verdict in verdicts {
		echo!(verdict)
	}
	Ok({})
}
