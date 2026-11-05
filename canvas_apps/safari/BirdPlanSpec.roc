## These are BirdPlan's checks, on a straight segment with its fifth left tree
## 100 m along: a bird sits, flies and lands as the rider comes, stays where no
## tree is far enough to fly to, and is left out with no tree for it, behind
## the near plane or too small to draw. The depth keys name each bird by its
## place.
app [main!] {
	lib: "../lib/main.roc",
}

import Angle
import BirdPlan
import DepthSort
import Frame
import Grade
import RocBird
import Scenery
import World

tree_at : F64, F64 -> Scenery.Tree
tree_at = |along, across| {
	along,
	across,
	color: 0,
	height: 10.0,
}

left_trees : List(Scenery.Tree)
left_trees = [20.0, 40.0, 60.0, 80.0, 100.0].map(|along| tree_at(along, -6.0))

far_tree : Scenery.Tree
far_tree = { ..tree_at(130.0, 6.0), height: 14.0 }

## A straight segment 200 m long holding only `trees`.
segment_of : List(Scenery.Tree) -> World.Segment
segment_of = |trees| {
	..World.route_segment(0),
	length: 200.0,
	trees,
	exit_angle: Angle.straight_ahead,
}

## The birds on one segment of `trees`, for a rider `rider_along` metres into
## it, seen through a focal length of `cam_focal`.
birds_on : List(Scenery.Tree), { rider_along : F64, cam_focal : F64 } -> List(RocBird.PlacedBird)
birds_on = |trees, { rider_along, cam_focal }|
	BirdPlan.in_view({
		world: [segment_of(trees)],
		chain: [World.SegmentIndex.first],
		pose: {
			along: rider_along,
			across: 0.0,
			yaw: Angle.straight_ahead,
			half_width: 2.0,
		},
		cam_focal,
		rider_along,
	})

## The one bird that a rider `rider_along` metres in sees on the segment with
## a far tree.
bird_at : F64 -> RocBird.PlacedBird
bird_at = |rider_along|
	birds_on(left_trees.append(far_tree), { rider_along, cam_focal: 500.0 }).first()
		?? crash "BirdPlanSpec: this rider sees a bird"

## How far off a bird is, across the road and up.
place_of : RocBird.PlacedBird -> List(F64)
place_of = |bird| [
	bird.right,
	bird.forward,
	bird.lift,
]

sitting_got : List(F64)
sitting_got = List.concat(place_of(bird_at(0.0)), place_of(bird_at(40.0)))

sitting_want : List(F64)
sitting_want = [
	-6.0,
	100.0,
	10.0,
	-6.0,
	60.0,
	10.0,
]

## Halfway through its flight, with the rider 37.5 m from the tree it left.
flying_got : List(F64)
flying_got = place_of(bird_at(62.5))

flying_want : List(F64)
flying_want = [0.0, 52.5, 17.0]

landed_got : List(F64)
landed_got = place_of(bird_at(85.0))

landed_want : List(F64)
landed_want = [6.0, 45.0, 14.0]

pose_got : List(Bool)
pose_got = [
	bird_at(40.0).pose == Perched,
	bird_at(62.5).pose != Perched,
	bird_at(85.0).pose == Perched,
]

pose_want : List(Bool)
pose_want = [True, True, True]

## With no tree far enough to fly to, the bird stays on its own however near
## the rider is.
stays_got : List(F64)
stays_got = birds_on(left_trees, { rider_along: 62.5, cam_focal: 500.0 }).join_map(place_of)

stays_want : List(F64)
stays_want = [-6.0, 37.5, 10.0]

## How many birds there are on `trees` for each rider and focal length.
count_on : List(Scenery.Tree), { rider_along : F64, cam_focal : F64 } -> I64
count_on = |trees, seen_from| birds_on(trees, seen_from).len().to_i64_wrap()

count_got : List(I64)
count_got = [
	count_on(left_trees, { rider_along: 0.0, cam_focal: 500.0 }),
	count_on(left_trees.drop_last(1), { rider_along: 0.0, cam_focal: 500.0 }),
	count_on(left_trees, { rider_along: 99.5, cam_focal: 500.0 }),
	count_on(left_trees, { rider_along: 99.7, cam_focal: 500.0 }),
	count_on(left_trees, { rider_along: 120.0, cam_focal: 500.0 }),
	count_on(left_trees, { rider_along: 0.0, cam_focal: 91.0 }),
	count_on(left_trees, { rider_along: 0.0, cam_focal: 90.0 }),
]

count_want : List(I64)
count_want = [
	1,
	0,
	1,
	0,
	0,
	1,
	0,
]

## Two segments in the chain, the rider at the start of the first.
two_segments : List(RocBird.PlacedBird)
two_segments = BirdPlan.in_view({
	world: [segment_of(left_trees), segment_of(left_trees)],
	chain: [0, 1].map(World.SegmentIndex.number),
	pose: {
		along: 0.0,
		across: 0.0,
		yaw: Angle.straight_ahead,
		half_width: 2.0,
	},
	cam_focal: 500.0,
	rider_along: 0.0,
})

## A key's place in the birds' list.
bird_place : DepthSort.DepthKey -> I64
bird_place = |key|
	match key.subject {
		Bird(place) => place.to_i64()
		Tree(_) | Tower(_) | Critter(_) | Cat(_) | Truck | Rail(_) =>
			crash "BirdPlanSpec: a bird's key names a bird"
	}

keys_got : List(I64)
keys_got = BirdPlan.depth_keys(two_segments).map(bird_place)

keys_want : List(I64)
keys_want = [0, 1]

nearest_first_got : List(Bool)
nearest_first_got =
	match BirdPlan.depth_keys(two_segments).map(|key| key.forward) {
		[near, far] => [near == 100.0, near < far]
		_ => crash "BirdPlanSpec: each of two segments has a bird in view"
	}

nearest_first_want : List(Bool)
nearest_first_want = [True, True]

main! = |_args| {
	verdicts = [
		Grade.reals({
			name: "bp-sitting",
			got: sitting_got,
			want: sitting_want,
			tol: 0.0,
		}),
		Grade.reals({
			name: "bp-flying ",
			got: flying_got,
			want: flying_want,
			tol: 0.000000001,
		}),
		Grade.reals({
			name: "bp-landed ",
			got: landed_got,
			want: landed_want,
			tol: 0.0,
		}),
		Grade.bools({
			name: "bp-pose   ",
			got: pose_got,
			want: pose_want,
		}),
		Grade.reals({
			name: "bp-stays  ",
			got: stays_got,
			want: stays_want,
			tol: 0.0,
		}),
		Grade.ints({
			name: "bp-count  ",
			got: count_got,
			want: count_want,
		}),
		Grade.ints({
			name: "bp-keys   ",
			got: keys_got,
			want: keys_want,
		}),
		Grade.bools({
			name: "bp-order  ",
			got: nearest_first_got,
			want: nearest_first_want,
		}),
	]
	for verdict in verdicts {
		echo!(verdict)
	}
	Ok({})
}
