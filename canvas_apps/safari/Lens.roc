## The camera's lens: a 70° view across the screen at rest. The view
## widens as the rider leans into a turn, and as something catches the
## rider's attention; the camera takes the wider of the two.
import Pixels
import Angle
import Attention
import Fraction
import Screen
import lib.Trig

Lens :: [].{

	field_of_view : Angle.Turn
	field_of_view = Angle.Turn.degrees(70.0)

	## The focal length at rest, in pixels.
	focal : Pixels
	focal = {
		half_view = field_of_view.times(0.5)
		Screen.width.divided_by(2.0).divided_by(half_view.to_radians().tan())
	}

	min_focal_factor : Fraction
	min_focal_factor = Fraction.of(0.35)

	## How much of the resting focal length is left at an attention of 1. It is
	## no minimum, because a cat in the lane holds the eye harder than that.
	focal_factor_at_full_attention : Fraction
	focal_factor_at_full_attention = Fraction.of(0.61)

	## The focal length for a lean, from 0 (upright) to 1 (the deepest lean).
	focal_for_lean : Fraction -> Pixels
	focal_for_lean = |lean_fraction| {
		lean = lean_fraction.to_f64()
		focal.times(1.0 - (1.0 - min_focal_factor.to_f64()) * lean * lean)
	}

	## The focal length for the rider's attention.
	focal_for_attention : Attention -> Pixels
	focal_for_attention = |attention|
		focal.times(1.0 - (1.0 - focal_factor_at_full_attention.to_f64()) * attention.to_f64())

	## The focal length the camera uses: the shorter of the two, which
	## gives the wider view.
	cam_focal : { lean_fraction : Fraction, attention : Attention } -> Pixels
	cam_focal = |{ lean_fraction, attention }| {
		for_lean = focal_for_lean(lean_fraction)
		for_attention = focal_for_attention(attention)
		if for_lean < for_attention {
			for_lean
		} else {
			for_attention
		}
	}
}

## Whether `got` is within 1e-9 of `want`, scaled up by a want past 1.
is_close : F64, F64 -> Bool
is_close = |got, want| (got - want).abs() <= 0.000000001 * want.abs().max(1.0)

expect
	[
		(Screen.width.to_f64(), 960.0),
		(Lens.field_of_view.to_radians() / Trig.deg, 70.0),
		(Lens.focal.to_f64(), 685.5110432362151),
	].all(|(got, want)| is_close(got, want))

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
				lean_fraction: Fraction.of(lean),
				attention: Attention.of(strength),
			})
			is_close(got.to_f64(), want)
		},
	)
