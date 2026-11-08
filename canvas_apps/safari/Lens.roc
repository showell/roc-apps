## The camera's lens: a 70° view across the screen at rest, and where a far
## height lands on the screen through a lens of any focal length. How far the
## view widens from rest is the rider camera's to say.
import Pixels
import Angle
import FarHeight
import Fraction
import Screen

Lens :: [].{

	## The focal length at rest, in pixels.
	resting_focal : Pixels
	resting_focal = {
		half_view = field_of_view.times(0.5)
		Screen.width.divided_by(2.0).divided_by(half_view.to_radians().tan())
	}

	## The screen's y for something infinitely far away, `height` above the
	## horizon, through a lens of `cam_focal`. A height below the horizon is
	## negative, and lands below it. This is the one place a far height
	## becomes pixels.
	y_for_height : { height : FarHeight, cam_focal : Pixels } -> Pixels
	y_for_height = |{ height, cam_focal }|
		Screen.horizon_y.minus(size_on_screen({ size: height, cam_focal }))

	## How long something infinitely far away is drawn through a lens of
	## `cam_focal`, when the lens at rest draws it `size` pixels long. It takes
	## any such length as a far height: a height above the horizon, or a size
	## kept in pixels at rest, such as the sun's radii. The lens only ever
	## widens, so it is never drawn longer than at rest.
	size_on_screen : { size : FarHeight, cam_focal : Pixels } -> Pixels
	size_on_screen = |{ size, cam_focal }|
		Pixels.of(size.to_f64() * scale_for(cam_focal).to_f64())
}

## How large a lens of focal length `focal` draws things beside the lens at
## rest. The lens only ever widens, so that is never larger.
scale_for : Pixels -> Fraction
scale_for = |focal| Fraction.of(focal.portion(Lens.resting_focal))

field_of_view : Angle.Turn
field_of_view = Angle.Turn.degrees(70.0)

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
			got = Lens.y_for_height({ height: FarHeight.of(height), cam_focal })
			got == Pixels.of(y)
		},
	)
