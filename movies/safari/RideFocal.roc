# RideFocal -- originally emitted from Codex by rocemit; the Roc is the program now
# and this file is edited here (safari/README.md).
import Bike
import Cat
import DeviceMath
import Gaze
import Lens
import Pose
import World

RideFocal :: [].{

	cat_attention : List(World.Segment), Pose.RiderState -> F64
	cat_attention = |w, s| ({
		seg = (List.get(w, I64.to_u64_wrap(s.segment)) ?? crash("list-at out of range"))
		(if seg.has_cat { Cat.cat_focus((seg.cat.along - s.along), s.v) } else { 0.0 })
	})

	ride_focal : List(World.Segment), Pose.RiderState -> F64
	ride_focal = |w, s| ({
		lean_frac = DeviceMath.real_min((DeviceMath.real_abs(s.tilt) / Bike.max_lean), 1.0)
		attention = DeviceMath.real_max(cat_attention(w, s), Gaze.gaze_focus(s.focus))
		Lens.cam_focal(lean_frac, attention)
	})
}
