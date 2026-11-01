# RenderSpec -- originally emitted from Codex by rocemit; the Roc is the program now
# and this file is edited here (safari/README.md).
app [main!] {
	lib: "../lib/main.roc",
}

import CatPlan
import CritterPlan
import DepthSort
import Frame
import Grade
import Pose
import RailPlan
import Render
import TowerPlan
import TreePlan
import TruckPlan
import World

segs : List(World.Segment)
segs = seg_list(0)

# seg_list builds its list by appending a recursive call; emitted as an accumulator loop, which is linear where the direct shape is quadratic.
seg_list : I64 -> List(World.Segment)
seg_list = |i| seg_list_acc(i, [])

seg_list_acc : I64, List(World.Segment) -> List(World.Segment)
seg_list_acc = |i, acc| (
	if (i >= World.route.len().to_i64_wrap()) {
		acc
	} else {
		seg_list_acc((i + 1), List.append(acc, World.segment_at(i)))
	}
)

origin : Frame.Pose
origin = { along: 0.0, across: 0.0, yaw: 0.0, hw: 2.0 }

frame : Render.Collected
frame = Render.collect(segs, 0, origin, 500.0, 0.0, Pose.v_base, 500.0)

prev_got : List(I64)
prev_got = [Render.prev_index(0), Render.prev_index(1), Render.prev_index(5)]

prev_want : List(I64)
prev_want = [0, 0, 4]

merge_got : List(I64)
merge_got = (
	{
		n = frame.order.len().to_i64_wrap()
		parts = (TreePlan.tree_items(frame.trees).len().to_i64_wrap() + TowerPlan.tower_items(frame.towers).len().to_i64_wrap())
		more = (CritterPlan.cow_items(frame.cows).len().to_i64_wrap() + CatPlan.cat_items(frame.cats).len().to_i64_wrap())
		rest = (TruckPlan.truck_items(frame.truck).len().to_i64_wrap() + RailPlan.rail_items(frame.rails).len().to_i64_wrap())
		[(n - ((parts + more) + rest))]
	}
)

merge_want : List(I64)
merge_want = [0]

present_got : List(Bool)
present_got = [(frame.trees.len().to_i64_wrap() > 0), (frame.towers.len().to_i64_wrap() > 0), (frame.cows.len().to_i64_wrap() > 0), (frame.rails.len().to_i64_wrap() > 0), (frame.order.len().to_i64_wrap() > 0)]

present_want : List(Bool)
present_want = [True, True, True, True, True]

cap_got : List(Bool)
cap_got = [(frame.trees.len().to_i64_wrap() <= TreePlan.max_vis_trees), (frame.towers.len().to_i64_wrap() <= TowerPlan.max_vis_towers), (frame.cows.len().to_i64_wrap() <= CritterPlan.max_vis_critters), (frame.cats.len().to_i64_wrap() <= CatPlan.max_vis_cats)]

cap_want : List(Bool)
cap_want = [True, True, True, True]

cap_values_got : List(I64)
cap_values_got = [TreePlan.max_vis_trees, TowerPlan.max_vis_towers, CatPlan.max_vis_cats]

cap_values_want : List(I64)
cap_values_want = [640, 16, 8]

descending : List(DepthSort.DepthKey), I64 -> Bool
descending = |xs, i| (
	if ((i + 1) >= xs.len().to_i64_wrap()) {
		True
	} else {
		(
			if DepthSort.deeper_than((List.get(xs, I64.to_u64_wrap((i + 1))) ?? crash ("list-at out of range")).fwd, (List.get(xs, I64.to_u64_wrap(i)) ?? crash ("list-at out of range")).fwd) {
				False
			} else {
				descending(xs, (i + 1))
			}
		)
	}
)

sorted_got : List(Bool)
sorted_got = [descending(frame.order, 0), descending([], 0)]

sorted_want : List(Bool)
sorted_want = [True, True]

cull_got : List(Bool)
cull_got = [(frame.cull_seg >= 0), (frame.cull_size >= 0), (frame.cull_seg > 0)]

cull_want : List(Bool)
cull_want = [True, True, True]

seg_cull_got : List(I64)
seg_cull_got = (
	{
		a = Render.seg_cull_count(segs, [0, 1, 2, 3, 4, 5], 3)
		b = ((List.get(segs, I64.to_u64_wrap(3)) ?? crash ("list-at out of range")).cows.len().to_i64_wrap() + (List.get(segs, I64.to_u64_wrap(3)) ?? crash ("list-at out of range")).pigs.len().to_i64_wrap())
		[(a - b), Render.seg_cull_count(segs, [0, 1, 2, 3, 4, 5], 0), Render.seg_cull_count(segs, [0, 1, 2, 3, 4, 5], 2), Render.walk_seg_cull(segs, [], 0)]
	}
)

seg_cull_want : List(I64)
seg_cull_want = [0, 0, 0, 0]

shrink_got : List(Bool)
shrink_got = (
	{
		long = Render.walk_seg_cull(segs, [0, 1, 2, 3, 4, 5], 0)
		short = Render.walk_seg_cull(segs, [0, 1, 2], 0)
		[(long > short), (short == 0)]
	}
)

shrink_want : List(Bool)
shrink_want = [True, True]

# --- Entry ---

main! = |_args| {
	verdicts = [
		Grade.ints({
			name: "rn-prev  ",
			got: prev_got,
			want: prev_want,
		}),
		Grade.ints({
			name: "rn-merge ",
			got: merge_got,
			want: merge_want,
		}),
		Grade.bools({
			name: "rn-presnt",
			got: present_got,
			want: present_want,
		}),
		Grade.bools({
			name: "rn-cap   ",
			got: cap_got,
			want: cap_want,
		}),
		Grade.ints({
			name: "rn-caps  ",
			got: cap_values_got,
			want: cap_values_want,
		}),
		Grade.bools({
			name: "rn-sorted",
			got: sorted_got,
			want: sorted_want,
		}),
		Grade.bools({
			name: "rn-cull  ",
			got: cull_got,
			want: cull_want,
		}),
		Grade.ints({
			name: "rn-segcul",
			got: seg_cull_got,
			want: seg_cull_want,
		}),
		Grade.bools({
			name: "rn-shrink",
			got: shrink_got,
			want: shrink_want,
		}),
	]
	for verdict in verdicts {
		echo!(verdict)
	}
	Ok({})
}
