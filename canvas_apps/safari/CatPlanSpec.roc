## These are CatPlan's checks: how far ahead each segment starts, which
## cats are in view as the rider comes on them, and the keys the depth sort
## reads.
app [main!] {
	lib: "../lib/main.roc",
}

import Cat
import CatPlan
import Frame
import Grade
import World

segs : List(World.Segment)
segs = [World.segment_at(0), World.segment_at(1), World.segment_at(2)]

origin : Frame.Pose
origin = { along: 0.0, across: 0.0, yaw: 0.0, hw: 2.0 }

## The first three segments seen from the origin, at 1 m a step.
from_origin : CatPlan.View
from_origin = { world: segs, chain: [0, 1, 2], pose: origin, cam_focal: 500.0, rider_along: 0.0, speed: 1.0 }

has_got : List(Bool)
has_got = segs.map(has_cat)

## Whether a segment has a cat waiting by the road.
has_cat : World.Segment -> Bool
has_cat = |seg|
	match seg.cat {
		Waits(_) => True
		NoCat => False
	}

has_want : List(Bool)
has_want = [False, True, False]

gap_got : List(F64)
gap_got = [0.0, 120.0].join_map(|rider_along| [0, 1, 2].map(|place| CatPlan.gap_to_segment({ ..from_origin, rider_along }, place)))

gap_want : List(F64)
gap_want = [0.0, 500.0, 820.0, (-120.0), 380.0, 700.0]

## The cats in view for a rider `along` metres into the first segment.
riding : F64 -> List(CatPlan.CatItem)
riding = |along| CatPlan.in_view({ ..from_origin, pose: { along, across: 0.0, yaw: 0.0, hw: 2.0 }, rider_along: along })

seen : List(CatPlan.CatItem)
seen = riding(300.0)

## The first cat in view for a rider `along` metres in.
first_cat : F64 -> CatPlan.CatItem
first_cat = |along| riding(along).first() ?? crash "CatPlanSpec: the second segment's cat is in view"

count_got : List(I64)
count_got = [
	seen.len().to_i64_wrap(),
	CatPlan.segment_cat(from_origin, 0).len().to_i64_wrap(),
	CatPlan.segment_cat(from_origin, 2).len().to_i64_wrap(),
	CatPlan.max_vis_cats,
]

count_want : List(I64)
count_want = [1, 0, 0, 8]

place_got : List(F64)
place_got = [first_cat(300.0).height, first_cat(300.0).lift]

place_want : List(F64)
place_want = [1.7, 0.0]

pose_got : List(I64)
pose_got = [Cat.pose_index(first_cat(300.0).pose)]

pose_want : List(I64)
pose_want = [0]

closing_got : List(F64)
closing_got = [
	(first_cat(300.0).fwd - first_cat(200.0).fwd),
	(first_cat(400.0).fwd - first_cat(300.0).fwd),
	(first_cat(300.0).right - first_cat(200.0).right),
]

closing_want : List(F64)
closing_want = [(-100.0), (-100.0), 0.0]

cull_got : List(I64)
cull_got = [
	riding(0.0).len().to_i64_wrap(),
	riding(200.0).len().to_i64_wrap(),
	riding(500.0).len().to_i64_wrap(),
	riding(600.0).len().to_i64_wrap(),
	CatPlan.in_view({ ..from_origin, chain: [] }).len().to_i64_wrap(),
	CatPlan.in_view({ ..from_origin, chain: [0] }).len().to_i64_wrap(),
]

cull_want : List(I64)
cull_want = [0, 1, 1, 0, 0, 0]

items_got : List(I64)
items_got = {
	key = CatPlan.depth_keys(seen).first() ?? crash "CatPlanSpec: one cat is in view"
	place =
		match key.subject {
			Cat(at) => at.to_i64_wrap()
			Tree(_) | Tower(_) | Critter(_) | Truck | Rail(_) | Bird(_) => crash "CatPlanSpec: a cat's key names a cat"
		}
	[CatPlan.depth_keys(seen).len().to_i64_wrap(), CatPlan.depth_keys([]).len().to_i64_wrap(), place]
}

items_want : List(I64)
items_want = [1, 0, 0]

# --- Entry ---

main! = |_args| {
	verdicts = [
		Grade.bools({
			name: "cp-has   ",
			got: has_got,
			want: has_want,
		}),
		Grade.reals({
			name: "cp-gap   ",
			got: gap_got,
			want: gap_want,
			tol: 0.0,
		}),
		Grade.ints({
			name: "cp-count ",
			got: count_got,
			want: count_want,
		}),
		Grade.reals({
			name: "cp-place ",
			got: place_got,
			want: place_want,
			tol: 0.0,
		}),
		Grade.ints({
			name: "cp-pose  ",
			got: pose_got,
			want: pose_want,
		}),
		Grade.reals({
			name: "cp-close ",
			got: closing_got,
			want: closing_want,
			tol: 0.0001,
		}),
		Grade.ints({
			name: "cp-cull  ",
			got: cull_got,
			want: cull_want,
		}),
		Grade.ints({
			name: "cp-items ",
			got: items_got,
			want: items_want,
		}),
	]
	for verdict in verdicts {
		echo!(verdict)
	}
	Ok({})
}
