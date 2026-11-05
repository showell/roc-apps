## The camera's lens: a 70° view across the screen at rest. The view
## widens as the rider leans into a turn, and as something catches the
## rider's attention; the camera takes the wider of the two.
import Angle
import Attention
import Fraction
import Screen
import lib.Trig

Lens :: [].{

	field_of_view : Angle.Turn
	field_of_view = Angle.Turn.degrees(70.0)

	## The focal length at rest, in pixels.
	focal : F64
	focal = ((Screen.width / 2.0) / Trig.r_tan(field_of_view.times(0.5).to_radians()))

	min_focal_factor : F64
	min_focal_factor = 0.35

	min_gaze_focal_factor : F64
	min_gaze_focal_factor = 0.61

	## The focal length for a lean, from 0 (upright) to 1 (the deepest lean).
	focal_for_lean : Fraction -> F64
	focal_for_lean = |lean_frac| {
		lean = lean_frac.to_f64()
		(focal * (1.0 - (((1.0 - min_focal_factor) * lean) * lean)))
	}

	## The focal length for the rider's attention.
	focal_for_gaze : Attention -> F64
	focal_for_gaze = |attention|
		(focal * (1.0 - ((1.0 - min_gaze_focal_factor) * attention.to_f64())))

	## The focal length the camera uses: the shorter of the two, which
	## gives the wider view.
	cam_focal : { lean_frac : Fraction, attention : Attention } -> F64
	cam_focal = |{ lean_frac, attention }| {
		for_lean = focal_for_lean(lean_frac)
		for_gaze = focal_for_gaze(attention)
		if (for_lean < for_gaze) for_lean else for_gaze
	}
}
