# CritterPlanSpec -- originally emitted from Codex by rocemit; the Roc is the program now
# and this file is edited here (safari/README.md).
import CritterPlan
import Frame
import Grade
import World

reach_got : List(I64)
reach_got = [CritterPlan.farm_seg_reach, CritterPlan.safari_seg_reach]

reach_want : List(I64)
reach_want = [3, 5]

segs : List(World.Segment)
segs = [World.segment_at(0), World.segment_at(1), World.segment_at(2), World.segment_at(3), World.segment_at(4), World.segment_at(5)]

chain : List(I64)
chain = [0, 1, 2, 3, 4, 5]

origin : Frame.Pose
origin = { along: 0.0, across: 0.0, yaw: 0.0, hw: 2.0 }

farm_at : I64 -> I64
farm_at = |d| U64.to_i64_wrap(List.len(CritterPlan.seg_farm(segs, chain, origin, d, 2.0)))

safari_at : I64 -> I64
safari_at = |d| U64.to_i64_wrap(List.len(CritterPlan.seg_safari(segs, chain, origin, d, 2.0)))

cutoff_got : List(Bool)
cutoff_got = [(farm_at(0) > 0), (farm_at(2) > 0), (farm_at(3) == 0), (farm_at(4) == 0), (farm_at(5) == 0), (safari_at(3) > 0), (safari_at(4) > 0), (safari_at(5) == 0)]

cutoff_want : List(Bool)
cutoff_want = [True, True, True, True, True, True, True, True]

term_got : List(I64)
term_got = [U64.to_i64_wrap(List.len(CritterPlan.seg_safari([World.segment_at(18)], [0], origin, 0, 2.0)))]

term_want : List(I64)
term_want = [0]

term_flag_got : List(Bool)
term_flag_got = [(U64.to_i64_wrap(List.len(CritterPlan.seg_safari([World.segment_at(0)], [0], origin, 0, 2.0))) > 0)]

term_flag_want : List(Bool)
term_flag_want = [True]

duck_count : I64 -> I64
duck_count = |i| U64.to_i64_wrap(List.len(CritterPlan.seg_ducks([World.segment_at(i)], [0], origin, 0)))

duck_got : List(Bool)
duck_got = [(duck_count(12) > 0), (duck_count(0) == 0), (duck_count(4) == 0), (duck_count(18) == 0)]

duck_want : List(Bool)
duck_want = [True, True, True, True]

duck_reach_got : List(I64)
duck_reach_got = [U64.to_i64_wrap(List.len(CritterPlan.seg_ducks(segs, chain, origin, 5))), U64.to_i64_wrap(List.len(CritterPlan.seg_ducks([World.segment_at(12)], [0], origin, 0)))]

duck_reach_want : List(I64)
duck_reach_want = [0, 6]

order_got : List(I64)
order_got = ({
	d0 = U64.to_i64_wrap(List.len(CritterPlan.seg_billboards(segs, chain, origin, 0)))
	f0 = farm_at(0)
	s0 = safari_at(0)
	k0 = U64.to_i64_wrap(List.len(CritterPlan.seg_ducks(segs, chain, origin, 0)))
	[(d0 - ((f0 + s0) + k0))]
})

order_want : List(I64)
order_want = [0]

one_seg : List(World.Segment)
one_seg = [World.segment_at(0)]

walk_got : List(I64)
walk_got = [U64.to_i64_wrap(List.len(CritterPlan.walk_billboards(segs, [], origin))), (U64.to_i64_wrap(List.len(CritterPlan.walk_billboards(one_seg, [0], origin))) - U64.to_i64_wrap(List.len(CritterPlan.seg_billboards(one_seg, [0], origin, 0)))), U64.to_i64_wrap(List.len(CritterPlan.walk_billboards_acc(segs, chain, origin, 6, [])))]

walk_want : List(I64)
walk_want = [0, 0, 0]

grow_got : List(Bool)
grow_got = ({
	a = U64.to_i64_wrap(List.len(CritterPlan.walk_billboards(segs, chain, origin)))
	b = U64.to_i64_wrap(List.len(CritterPlan.walk_billboards_acc(segs, chain, origin, 1, [])))
	c = U64.to_i64_wrap(List.len(CritterPlan.walk_billboards_acc(segs, chain, origin, 2, [])))
	[(a >= b), (b >= c)]
})

grow_want : List(Bool)
grow_want = [True, True]

behind_got : List(Bool)
behind_got = [(U64.to_i64_wrap(List.len(CritterPlan.behind_billboards(segs, chain, origin, 0))) >= 0), (U64.to_i64_wrap(List.len(CritterPlan.behind_ducks(segs, chain, origin, World.segment_at(12)))) > 0), (U64.to_i64_wrap(List.len(CritterPlan.behind_ducks(segs, chain, origin, World.segment_at(0)))) == 0)]

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
