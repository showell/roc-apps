## The camera's lens: a 70° view across the screen at rest. The view
## widens as the rider leans into a turn, and as something catches the
## rider's attention; the camera takes the wider of the two.
import Screen
import lib.Trig

Lens :: [].{

	fov_deg : F64
	fov_deg = 70.0

	## The focal length at rest, in pixels.
	focal : F64
	focal = ((Screen.width / 2.0) / Trig.r_tan(((fov_deg / 2.0) * Trig.deg)))

	min_focal_factor : F64
	min_focal_factor = 0.35

	min_gaze_focal_factor : F64
	min_gaze_focal_factor = 0.61

	## The focal length for a lean, from 0 (upright) to 1 (the deepest lean).
	focal_for_lean : F64 -> F64
	focal_for_lean = |lean_frac| (focal * (1.0 - (((1.0 - min_focal_factor) * lean_frac) * lean_frac)))

	## The focal length for the rider's attention, from 0 upward.
	focal_for_gaze : F64 -> F64
	focal_for_gaze = |attention| (focal * (1.0 - ((1.0 - min_gaze_focal_factor) * attention)))

	## The focal length the camera uses: the shorter of the two, which
	## gives the wider view.
	cam_focal : { lean_frac : F64, attention : F64 } -> F64
	cam_focal = |{ lean_frac, attention }| {
		for_lean = focal_for_lean(lean_frac)
		for_gaze = focal_for_gaze(attention)
		if (for_lean < for_gaze) for_lean else for_gaze
	}
}
