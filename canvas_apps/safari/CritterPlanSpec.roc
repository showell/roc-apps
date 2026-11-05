## These are CritterPlan's checks: how far along the chain each kind of
## critter is sighted, the road's last segment, ponds, and the critters
## of the whole chain and of the segment behind the rider.
app [main!] {
	lib: "../lib/main.roc",
}

import CritterPlan
import Frame
import Grade
import World

reach_got : List(I64)
reach_got = [CritterPlan.farm_reach, CritterPlan.safari_reach]

reach_want : List(I64)
reach_want = [3, 5]

origin : Frame.Pose
origin = {
	along: 0.0,
	across: 0.0,
	yaw: 0.0,
	half_width: 2.0,
}

## The first six segments, chained in order.
scene : CritterPlan.Scene
scene = {
	world: [0, 1, 2, 3, 4, 5].map(World.segment_at),
	chain: [0, 1, 2, 3, 4, 5],
	pose: origin,
}

## The world's segment `index` alone.
lone : I64 -> CritterPlan.Scene
lone = |index| {
	world: [World.segment_at(index)],
	chain: [0],
	pose: origin,
}

farm_at : I64 -> I64
farm_at = |position| CritterPlan.farm_sightings(scene, position).len().to_i64_wrap()

safari_at : I64 -> I64
safari_at = |position| CritterPlan.safari_sightings(scene, position).len().to_i64_wrap()

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
term_got = [CritterPlan.safari_sightings(lone(18), 0).len().to_i64_wrap()]

term_want : List(I64)
term_want = [0]

term_flag_got : List(Bool)
term_flag_got = [(CritterPlan.safari_sightings(lone(0), 0).len() > 0)]

term_flag_want : List(Bool)
term_flag_want = [True]

duck_count : I64 -> I64
duck_count = |index| CritterPlan.duck_sightings(lone(index), 0).len().to_i64_wrap()

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
duck_reach_got = [CritterPlan.duck_sightings(scene, 5).len().to_i64_wrap(), duck_count(12)]

duck_reach_want : List(I64)
duck_reach_want = [0, 6]

order_got : List(I64)
order_got = {
	whole = CritterPlan.sightings_at(scene, 0).len().to_i64_wrap()
	ducks = CritterPlan.duck_sightings(scene, 0).len().to_i64_wrap()
	[(whole - ((farm_at(0) + safari_at(0)) + ducks))]
}

order_want : List(I64)
order_want = [0]

## How many critters the segments from `position` to the chain's end hold.
count_from : I64 -> I64
count_from = |position|
	List.from_iter(I64.until(position, 6))
		.map(|at| CritterPlan.sightings_at(scene, at).len().to_i64_wrap())
		.sum()

walk_got : List(I64)
walk_got = [
	CritterPlan.sightings_ahead({ ..scene, chain: [] }).len().to_i64_wrap(),
	(
		CritterPlan.sightings_ahead(lone(0)).len().to_i64_wrap() - CritterPlan.sightings_at(
			lone(0),
			0,
		).len().to_i64_wrap()
	),
	(CritterPlan.sightings_ahead(scene).len().to_i64_wrap() - count_from(0)),
]

walk_want : List(I64)
walk_want = [0, 0, 0]

grow_got : List(Bool)
grow_got = [(count_from(0) >= count_from(1)), (count_from(1) >= count_from(2))]

grow_want : List(Bool)
grow_want = [True, True]

behind_got : List(Bool)
behind_got = [
	(CritterPlan.sightings_behind(scene, 4).len() > 0),
	(CritterPlan.ducks_behind(scene, World.segment_at(12)).len() > 0),
	(CritterPlan.ducks_behind(scene, World.segment_at(0)).len() == 0),
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
