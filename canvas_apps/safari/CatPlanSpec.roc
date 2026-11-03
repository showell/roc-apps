# CatPlanSpec -- originally emitted from Codex by rocemit; the Roc is the program now
# and this file is edited here (safari/README.md).
app [main!] {
	lib: "../lib/main.roc",
}

import CatPlan
import Frame
import Grade
import World

segs : List(World.Segment)
segs = [World.segment_at(0), World.segment_at(1), World.segment_at(2)]

chain : List(I64)
chain = [0, 1, 2]

origin : Frame.Pose
origin = { along: 0.0, across: 0.0, yaw: 0.0, hw: 2.0 }

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
gap_got = [CatPlan.chain_gap(segs, chain, 0.0, 0), CatPlan.chain_gap(segs, chain, 0.0, 1), CatPlan.chain_gap(segs, chain, 0.0, 2), CatPlan.chain_gap(segs, chain, 120.0, 0), CatPlan.chain_gap(segs, chain, 120.0, 1), CatPlan.chain_gap(segs, chain, 120.0, 2)]

gap_want : List(F64)
gap_want = [0.0, 500.0, 820.0, (-120.0), 380.0, 700.0]

riding : F64 -> List(CatPlan.CatItem)
riding = |a| CatPlan.walk_cats(segs, chain, { along: a, across: 0.0, yaw: 0.0, hw: 2.0 }, 500.0, a, 1.0, 0)

seen : List(CatPlan.CatItem)
seen = riding(300.0)

count_got : List(I64)
count_got = [seen.len().to_i64_wrap(), CatPlan.seg_cat(segs, chain, origin, 0, 500.0, 0.0, 1.0).len().to_i64_wrap(), CatPlan.seg_cat(segs, chain, origin, 2, 500.0, 0.0, 1.0).len().to_i64_wrap(), CatPlan.max_vis_cats]

count_want : List(I64)
count_want = [1, 0, 0, 8]

place_got : List(F64)
place_got = [(List.get(seen, I64.to_u64_wrap(0)) ?? crash ("list-at out of range")).height, (List.get(seen, I64.to_u64_wrap(0)) ?? crash ("list-at out of range")).lift]

place_want : List(F64)
place_want = [1.7, 0.0]

pose_got : List(I64)
pose_got = [(List.get(seen, I64.to_u64_wrap(0)) ?? crash ("list-at out of range")).pose_idx]

pose_want : List(I64)
pose_want = [0]

closing_got : List(F64)
closing_got = (
	{
		a = (List.get(riding(200.0), I64.to_u64_wrap(0)) ?? crash ("list-at out of range")).fwd
		b = (List.get(riding(300.0), I64.to_u64_wrap(0)) ?? crash ("list-at out of range")).fwd
		c = (List.get(riding(400.0), I64.to_u64_wrap(0)) ?? crash ("list-at out of range")).fwd
		[(b - a), (c - b), ((List.get(riding(300.0), I64.to_u64_wrap(0)) ?? crash ("list-at out of range")).right - (List.get(riding(200.0), I64.to_u64_wrap(0)) ?? crash ("list-at out of range")).right)]
	}
)

closing_want : List(F64)
closing_want = [(-100.0), (-100.0), 0.0]

cull_got : List(I64)
cull_got = [riding(0.0).len().to_i64_wrap(), riding(200.0).len().to_i64_wrap(), riding(500.0).len().to_i64_wrap(), riding(600.0).len().to_i64_wrap(), CatPlan.walk_cats(segs, [], origin, 500.0, 0.0, 1.0, 0).len().to_i64_wrap(), CatPlan.walk_cats(segs, [0], origin, 500.0, 0.0, 1.0, 0).len().to_i64_wrap()]

cull_want : List(I64)
cull_want = [0, 1, 1, 0, 0, 0]

items_got : List(I64)
items_got = [CatPlan.cat_items(seen).len().to_i64_wrap(), CatPlan.cat_items([]).len().to_i64_wrap(), (List.get(CatPlan.cat_items(seen), I64.to_u64_wrap(0)) ?? crash ("list-at out of range")).i]

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
