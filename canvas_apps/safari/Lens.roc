## The camera's lens: a 70° view across the screen at rest. The view
## widens as the rider leans into a turn, and as something catches the
## rider's attention; the camera takes the wider of the two.
import Pixels
import Angle
import Attention
import Fraction
import Screen

Lens :: [].{

	## Which way the camera faces in a frame, and its focal length.
	CameraAim : { heading : Angle.Bearing, cam_focal : Pixels }

	field_of_view : Angle.Turn
	field_of_view = Angle.Turn.degrees(70.0)

	## The focal length at rest, in pixels.
	resting_focal : Pixels
	resting_focal = {
		half_view = field_of_view.times(0.5)
		Screen.width.divided_by(2.0).divided_by(half_view.to_radians().tan())
	}

	## The lean that widens the view all it can. Nothing holds the bike to it:
	## a deeper lean just widens the view no further.
	full_lean : Angle.Lean
	full_lean = Angle.Lean.degrees(20.0)

	## How much of the resting focal length is left at `full_lean`.
	focal_factor_at_full_lean : Fraction
	focal_factor_at_full_lean = Fraction.of(0.35)

	## How much of the resting focal length is left at an attention of 1. It is
	## no minimum, because a cat in the road holds the eye harder than that.
	focal_factor_at_full_attention : Fraction
	focal_factor_at_full_attention = Fraction.of(0.61)

	## The focal length for a lean, from 0 (upright) to 1 (`full_lean`).
	focal_for_lean : Fraction -> Pixels
	focal_for_lean = |lean_fraction| {
		lean = lean_fraction.to_f64()
		resting_focal.times(1.0 - focal_factor_at_full_lean.less().to_f64() * lean * lean)
	}

	## The focal length for the rider's attention.
	focal_for_attention : Attention -> Pixels
	focal_for_attention = |attention| {
		lost_at_full_attention = focal_factor_at_full_attention.less().to_f64()
		resting_focal.times(1.0 - lost_at_full_attention * attention.to_f64())
	}

	## The focal length the camera uses: the shorter of the two, which
	## gives the wider view. A lean to either side widens it alike.
	cam_focal : { lean : Angle.Lean, attention : Attention } -> Pixels
	cam_focal = |{ lean, attention }| {
		lean_fraction = Fraction.clamp(lean.abs().portion(full_lean))
		for_lean = focal_for_lean(lean_fraction)
		for_attention = focal_for_attention(attention)
		if for_lean < for_attention {
			for_lean
		} else {
			for_attention
		}
	}

	## The screen's y for something `height` above the horizon, seen far
	## away through a lens of `cam_focal`. A height below the horizon is
	## negative, and lands below it.
	y_for_height : { height : Pixels, cam_focal : Pixels } -> Pixels
	y_for_height = |{ height, cam_focal: focal }|
		Screen.horizon_y.minus(height.times(scale_for(focal).to_f64()))

	## How large a lens of focal length `focal` draws things beside the lens at
	## rest. The lens only ever widens, so that is never larger.
	scale_for : Pixels -> Fraction
	scale_for = |focal| Fraction.of(focal.portion(resting_focal))

	## The screen's x for something `turn` to the right of where the camera
	## faces, through a lens of `cam_focal`. The turn stays under a quarter
	## turn either way, in front of the camera.
	x_for_turn : { turn : Angle.Turn, cam_focal : Pixels } -> Pixels
	x_for_turn = |{ turn, cam_focal: focal }|
		Screen.center_x.plus(focal.times(turn.to_radians().tan()))

	## How far to the right of where the camera faces the screen's `x` looks,
	## through a lens of `cam_focal`: the way back from `x_for_turn`.
	turn_at_x : { x : Pixels, cam_focal : Pixels } -> Angle.Turn
	turn_at_x = |{ x, cam_focal: focal }| {
		slope = x.minus(Screen.center_x).portion(focal)
		Angle.Turn.radians(slope.atan())
	}
}

## Whether `got` is within 1e-9 of `want`, scaled up by a want past 1.
is_close : F64, F64 -> Bool
is_close = |got, want| (got - want).abs() <= 0.000000001 * want.abs().max(1.0)

expect
	[
		(0.0, 685.5110432362151),
		(0.25, 657.6621571047439),
		(0.5, 574.1154987103301),
		(0.75, 434.8710680529739),
		(1.0, 239.92886513267527),
	].all(|(lean, want)| is_close(Lens.focal_for_lean(Fraction.of(lean)).to_f64(), want))

expect
	[
		(0.0, 685.5110432362151),
		(0.5, 551.8363898051531),
		(1.0, 418.16173637409116),
		(1.5, 284.4870829430293),
	].all(
		|(strength, want)| is_close(
			Lens.focal_for_attention(Attention.of(strength)).to_f64(),
			want,
		),
	)

expect
	[
		((0.0, 0.0), 685.5110432362151),
		((1.0, 0.0), 239.92886513267527),
		((0.0, 1.0), 418.16173637409116),
		((0.5, 0.3), 574.1154987103301),
		((0.9, 1.4), 311.2220136292417),
		((0.6, 0.5), 525.1014591189407),
	].all(
		|((lean, strength), want)| {
			got = Lens.cam_focal({
				lean: Angle.Lean.degrees(lean * 20.0),
				attention: Attention.of(strength),
			})
			is_close(got.to_f64(), want)
		},
	)

# A height lands above the horizon, on it, or below it, and a wider lens draws
# it nearer the horizon.
expect
	[
		((100.0, Lens.resting_focal), 200.0),
		((0.0, Lens.resting_focal), 300.0),
		((-40.0, Lens.resting_focal), 340.0),
		((100.0, Lens.resting_focal.times(0.5)), 250.0),
	].all(
		|((height, cam_focal), y)| {
			got = Lens.y_for_height({ height: Pixels.of(height), cam_focal })
			got == Pixels.of(y)
		},
	)

## The screen's x at a turn of `radians`, through the lens at rest.
x_at_rest : F64 -> Pixels
x_at_rest = |radians| {
	turn = Angle.Turn.radians(radians)
	Lens.x_for_turn({ turn, cam_focal: Lens.resting_focal })
}

# Straight ahead is the middle of the screen, a turn to the right lands right of
# it, and a turn to the left left of it.
expect x_at_rest(0.0) == Screen.center_x
expect x_at_rest(0.3) > Screen.center_x
expect x_at_rest(-0.3) < Screen.center_x
expect Lens.turn_at_x({ x: Screen.center_x, cam_focal: Lens.resting_focal }).to_radians() == 0.0

# The turn at an x is the way back from the x at a turn.
expect
	[-1.2, -0.3, 0.0, 0.4, 1.3].all(
		|radians| {
			x = x_at_rest(radians)
			back = Lens.turn_at_x({ x, cam_focal: Lens.resting_focal })
			is_close(back.to_radians(), radians)
		},
	)
