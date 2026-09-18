# Lens -- originally emitted from Codex by rocemit; the Roc is the program now
# and this file is edited here (safari/README.md).
import Trig

Lens :: [].{

	camera_w : F64
	camera_w = 960.0

	fov_deg : F64
	fov_deg = 70.0

	focal : F64
	focal = ((camera_w / 2.0) / Trig.r_tan(((fov_deg / 2.0) * Trig.deg)))

	min_focal_factor : F64
	min_focal_factor = 0.35

	min_gaze_focal_factor : F64
	min_gaze_focal_factor = 0.61

	focal_for_lean : F64 -> F64
	focal_for_lean = |lean_frac| (focal * (1.0 - (((1.0 - min_focal_factor) * lean_frac) * lean_frac)))

	focal_for_gaze : F64 -> F64
	focal_for_gaze = |attention| (focal * (1.0 - ((1.0 - min_gaze_focal_factor) * attention)))

	cam_focal : F64, F64 -> F64
	cam_focal = |lean_frac, attention| ({
		a = focal_for_lean(lean_frac)
		b = focal_for_gaze(attention)
		(if (a < b) { a } else { b })
	})
}
