# TruckPlanSpec -- originally emitted from Codex by rocemit; the Roc is the program now
# and this file is edited here (safari/README.md).
import Frame
import Grade
import TruckPlan
import World

segs : List(World.Segment)
segs = [World.segment_at(0), World.segment_at(1), World.segment_at(2)]

chain : List(I64)
chain = [0, 1, 2]

here : Frame.Pose
here = { along: 0.0, across: 0.0, yaw: 0.0, hw: 2.0 }

lengths_got : List(F64)
lengths_got = [(List.get(segs, I64.to_u64_wrap(0)) ?? crash("list-at out of range")).length, (List.get(segs, I64.to_u64_wrap(1)) ?? crash("list-at out of range")).length, (List.get(segs, I64.to_u64_wrap(2)) ?? crash("list-at out of range")).length]

lengths_want : List(F64)
lengths_want = [500.0, 320.0, 400.0]

lead_of : F64 -> TruckPlan.TruckAt
lead_of = |lead| TruckPlan.truck_at(segs, chain, here, 0.0, lead)

present_got : List(Bool)
present_got = [lead_of(100.0).present, lead_of(499.0).present, lead_of(600.0).present, lead_of(900.0).present, lead_of(2000.0).present, lead_of(0.0).present, lead_of((0.0 - 50.0)).present]

present_want : List(Bool)
present_want = [True, True, True, True, False, False, False]

landed_got : List(I64)
landed_got = [lead_of(100.0).d, lead_of(499.0).d, lead_of(600.0).d, lead_of(900.0).d]

landed_want : List(I64)
landed_want = [0, 0, 1, 2]

along_got : List(F64)
along_got = [lead_of(100.0).along, lead_of(499.0).along, lead_of(600.0).along, lead_of(900.0).along]

along_want : List(F64)
along_want = [100.0, 499.0, 100.0, 80.0]

fwd_got : List(F64)
fwd_got = [lead_of(100.0).fwd, lead_of(499.0).fwd]

fwd_want : List(F64)
fwd_want = [100.0, 499.0]

none_got : List(F64)
none_got = ({
	n = lead_of(2000.0)
	[n.along, n.fwd, I64.to_f64(n.d), TruckPlan.no_truck.along, TruckPlan.no_truck.fwd, I64.to_f64(TruckPlan.no_truck.d)]
})

none_want : List(F64)
none_want = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0]

none_flag_got : List(Bool)
none_flag_got = [TruckPlan.no_truck.present, lead_of(2000.0).present]

none_flag_want : List(Bool)
none_flag_want = [False, False]

behind : TruckPlan.TruckAt
behind = TruckPlan.truck_at(segs, chain, { along: 100.0, across: 0.0, yaw: 0.0, hw: 2.0 }, 0.0, 100.0)

behind_got : List(Bool)
behind_got = [behind.present, TruckPlan.truck_at(segs, chain, { along: 99.0, across: 0.0, yaw: 0.0, hw: 2.0 }, 0.0, 100.0).present]

behind_want : List(Bool)
behind_want = [False, True]

items_got : List(I64)
items_got = [TruckPlan.truck_items(lead_of(100.0)).len().to_i64_wrap(), TruckPlan.truck_items(lead_of(2000.0)).len().to_i64_wrap(), TruckPlan.truck_items(TruckPlan.no_truck).len().to_i64_wrap(), (List.get(TruckPlan.truck_items(lead_of(100.0)), I64.to_u64_wrap(0)) ?? crash("list-at out of range")).i]

items_want : List(I64)
items_want = [1, 0, 0, 0]

item_fwd_got : List(F64)
item_fwd_got = [(List.get(TruckPlan.truck_items(lead_of(499.0)), I64.to_u64_wrap(0)) ?? crash("list-at out of range")).fwd]

item_fwd_want : List(F64)
item_fwd_want = [499.0]

# --- Entry ---

main! = |_args| {
	verdicts = [
		Grade.reals({
			name: "tp-length",
			got: lengths_got,
			want: lengths_want,
			tol: 0.0,
		}),
		Grade.bools({
			name: "tp-presnt",
			got: present_got,
			want: present_want,
		}),
		Grade.ints({
			name: "tp-landed",
			got: landed_got,
			want: landed_want,
		}),
		Grade.reals({
			name: "tp-along ",
			got: along_got,
			want: along_want,
			tol: 0.0,
		}),
		Grade.reals({
			name: "tp-fwd   ",
			got: fwd_got,
			want: fwd_want,
			tol: 0.0001,
		}),
		Grade.reals({
			name: "tp-none  ",
			got: none_got,
			want: none_want,
			tol: 0.0,
		}),
		Grade.bools({
			name: "tp-nflag ",
			got: none_flag_got,
			want: none_flag_want,
		}),
		Grade.bools({
			name: "tp-behind",
			got: behind_got,
			want: behind_want,
		}),
		Grade.ints({
			name: "tp-items ",
			got: items_got,
			want: items_want,
		}),
		Grade.reals({
			name: "tp-ifwd  ",
			got: item_fwd_got,
			want: item_fwd_want,
			tol: 0.0001,
		}),
	]
	for verdict in verdicts {
		echo!(verdict)
	}
	Ok({})
}
