## The camera's lens: a 70° view across the screen at rest, the far height an
## elevation stands at, and where a far height lands on the screen through a
## lens of any focal length. How far the view widens from rest is the rider
## camera's to say.
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

	## The far height of a direction `elevation` above the horizon: the
	## tangent of the elevation times the resting focal length, which is where
	## the lens at rest draws it above the horizon. The sun's elevation becomes
	## a far height here, once, so it is measured as the skyline is.
	height_at_elevation : Angle.Turn -> FarHeight
	height_at_elevation = |elevation|
		FarHeight.of(resting_focal.times(elevation.to_radians().tan()).to_f64())

	## The screen's y for something infinitely far away, `height` above the
	## horizon, through a lens of `cam_focal`. A height below the horizon is
	## negative, and lands below it. This is the one place a far height
	## becomes pixels, and the y of `Camera.far_point`; the skyline asks for
	## it alone, since it walks the screen's columns and already has each x.
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
scale_for = |focal| Fraction.of(focal.ratio_to(Lens.resting_focal))

field_of_view : Angle.Turn
field_of_view = Angle.Turn.degrees(70.0)

# Level with the horizon is no height. An elevation of half the view stands as
# high as the screen is half wide, as a turn that far lands at its edge. Below
# the horizon is negative.
expect Lens.height_at_elevation(Angle.straight_ahead) == FarHeight.zero
expect {
	half_width = Screen.width.divided_by(2.0).to_f64()
	edge = Lens.height_at_elevation(field_of_view.times(0.5)).to_f64()
	(edge - half_width).abs() <= 0.000000001
}
expect Lens.height_at_elevation(Angle.Turn.degrees(-5.0)) < FarHeight.zero

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
