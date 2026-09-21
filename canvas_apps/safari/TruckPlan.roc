# TruckPlan -- originally emitted from Codex by rocemit; the Roc is the program now
# and this file is edited here (safari/README.md).
import DepthSort
import Frame
import Geom
import World

TruckPlan :: [].{
	TruckAt : { present : Bool, d : I64, along : F64, fwd : F64 }

	no_truck : TruckPlan.TruckAt
	no_truck = { present: False, d: 0, along: 0.0, fwd: 0.0 }

	truck_step : List(World.Segment), List(I64), Frame.Pose, F64, I64 -> TruckPlan.TruckAt
	truck_step = |segs, ch, pose, remaining, d| (if (d >= U64.to_i64_wrap(List.len(ch))) { no_truck } else { (if (remaining > (List.get(segs, I64.to_u64_wrap((List.get(ch, I64.to_u64_wrap(d)) ?? crash("list-at out of range")))) ?? crash("list-at out of range")).length) { truck_step(segs, ch, pose, (remaining - (List.get(segs, I64.to_u64_wrap((List.get(ch, I64.to_u64_wrap(d)) ?? crash("list-at out of range")))) ?? crash("list-at out of range")).length), (d + 1)) } else { truck_here(segs, ch, pose, remaining, d) }) })

	truck_here : List(World.Segment), List(I64), Frame.Pose, F64, I64 -> TruckPlan.TruckAt
	truck_here = |segs, ch, pose, remaining, d| ({
		c = Frame.at(segs, ch, pose, d, remaining, ((List.get(segs, I64.to_u64_wrap((List.get(ch, I64.to_u64_wrap(d)) ?? crash("list-at out of range")))) ?? crash("list-at out of range")).width / 2.0))
		(if (c.forward > Geom.near) { { present: True, d: d, along: remaining, fwd: c.forward } } else { no_truck })
	})

	truck_at : List(World.Segment), List(I64), Frame.Pose, F64, F64 -> TruckPlan.TruckAt
	truck_at = |segs, ch, pose, along, lead| (if (lead > 0.0) { truck_step(segs, ch, pose, (along + lead), 0) } else { no_truck })

	truck_items : TruckPlan.TruckAt -> List(DepthSort.Item)
	truck_items = |t| (if t.present { [{ fwd: t.fwd, kind: KTruck, i: 0 }] } else { [] })
}
