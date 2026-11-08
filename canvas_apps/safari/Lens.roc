## The camera's lens: a 70° view across the screen at rest, the far height an
## elevation stands at, and where something infinitely far away lands on the
## screen through a lens of any focal length. How far the view widens from rest
## is the rider camera's to say.
##
## The two axes of a far direction use different models. Across the screen, a
## turn lands the focal length times its tangent beside the middle, as a pinhole
## puts it. Up the screen, a far height is only scaled with the focal length:
## it isn't stretched toward the screen's sides, as a pinhole would stretch it,
## so a far height stays level across the view as the rider turns.
import Pixels
import Angle
import FarHeight
import Fraction
import Screen

Lens :: [].{

	## The focal length at rest, in pixels.
	resting_focal_length : Pixels
	resting_focal_length = {
		half_view = field_of_view.times(0.5)
		Screen.width.divided_by(2.0).divided_by(half_view.to_radians().tan())
	}

	## The far height of a direction `elevation` above the horizon: the
	## tangent of the elevation times the resting focal length, which is where
	## the lens at rest draws it above the horizon. The sun's elevation becomes
	## a far height here, once, so it is measured as the skyline is.
	height_at_elevation : Angle.Turn -> FarHeight
	height_at_elevation = |elevation|
		FarHeight.of(resting_focal_length.times(elevation.to_radians().tan()).to_f64())

	## Where something infinitely far away lands on the screen, through a lens
	## of `focal_length`: `turn` to the right of where the camera faces, and
	## `height` above the horizon. This is the one projection for far
	## directions, the sun's and the skyline's. A far height is an elevation as
	## the resting lens holds it, its tangent times the resting focal length
	## (`height_at_elevation`), so straight ahead both axes follow one rule: the
	## focal length times the tangent of the angle off the middle of the view.
	## The turn stays under a quarter turn either way, in front of the camera.
	far_point : {
		turn : Angle.Turn,
		height : FarHeight,
		focal_length : Pixels,
	} -> Screen.Point
	far_point = |{ turn, height, focal_length }| {
		x: x_for_slope({ slope: turn.to_radians().tan(), focal_length }),
		y: y_for_height({ height, focal_length }),
	}

	## The pinhole's rule across the screen: the x for a line of sight that goes
	## `slope` to the right for every unit forward, through a lens of
	## `focal_length`. A near point's slope (`Camera.project`) and a far
	## direction's (`far_point`) both land here.
	x_for_slope : { slope : F64, focal_length : Pixels } -> Pixels
	x_for_slope = |{ slope, focal_length }| Screen.center_x.plus(focal_length.times(slope))

	## How far to the right of where the camera faces the screen's `x` looks,
	## through a lens of `focal_length`: the way back from `far_point`'s x.
	turn_at_x : { x : Pixels, focal_length : Pixels } -> Angle.Turn
	turn_at_x = |{ x, focal_length }| {
		slope = x.minus(Screen.center_x).ratio_to(focal_length)
		Angle.Turn.radians(slope.atan())
	}

	## The screen's y for something infinitely far away, `height` above the
	## horizon, through a lens of `focal_length`. A height below the horizon is
	## negative, and lands below it. This is the one place a far height
	## becomes pixels, and the y of `far_point`; the skyline asks for it alone,
	## since it walks the screen's columns and already has each x.
	y_for_height : { height : FarHeight, focal_length : Pixels } -> Pixels
	y_for_height = |{ height, focal_length }|
		Screen.horizon_y.minus(size_on_screen({ size: height, focal_length }))

	## How long something infinitely far away is drawn through a lens of
	## `focal_length`, when the lens at rest draws it `size` pixels long. It takes
	## any such length as a far height: a height above the horizon, or a size
	## kept in pixels at rest, such as the sun's radii. The lens only ever
	## widens, so it is never drawn longer than at rest.
	size_on_screen : { size : FarHeight, focal_length : Pixels } -> Pixels
	size_on_screen = |{ size, focal_length }|
		Pixels.of(size.to_f64() * lens_scale(focal_length).to_f64())
}

## How large a lens of `focal_length` draws things beside the lens at rest.
## The lens only ever widens, so that is never larger.
lens_scale : Pixels -> Fraction
lens_scale = |focal_length| Fraction.of(focal_length.ratio_to(Lens.resting_focal_length))

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
		((100.0, Lens.resting_focal_length), 200.0),
		((0.0, Lens.resting_focal_length), 300.0),
		((-40.0, Lens.resting_focal_length), 340.0),
		((100.0, Lens.resting_focal_length.times(0.5)), 250.0),
	].all(
		|((height, focal_length), y)| {
			got = Lens.y_for_height({ height: FarHeight.of(height), focal_length })
			got == Pixels.of(y)
		},
	)

## The screen's x at a turn of `radians`, through the lens at rest.
x_at_turn : F64 -> Pixels
x_at_turn = |radians| {
	turn = Angle.Turn.radians(radians)
	Lens.far_point({ turn, height: FarHeight.zero, focal_length: Lens.resting_focal_length }).x
}

# A far direction at an elevation lands the focal length times the elevation's
# tangent above the horizon through any lens, as a turn lands the focal length
# times its tangent beside the middle: the sun's elevation and the skyline's far
# heights are one measure on the screen.
expect
	[
		(10.0, 600.0),
		(-4.0, 600.0),
		(25.0, 300.0),
	].all(
		|(degrees, focal_length)| {
			elevation = Angle.Turn.degrees(degrees)
			height = Lens.height_at_elevation(elevation)
			got = Lens.far_point({
				turn: Angle.straight_ahead,
				height,
				focal_length: Pixels.of(focal_length),
			})
			want = Screen.horizon_y.minus(Pixels.of(focal_length * elevation.to_radians().tan()))
			got.y.minus(want).abs() <= Pixels.of(0.000000001) and got.x == Screen.center_x
		},
	)

# Straight ahead is the middle of the screen, a turn to the right lands right of
# it, and a turn to the left left of it.
expect x_at_turn(0.0) == Screen.center_x
expect x_at_turn(0.3) > Screen.center_x
expect x_at_turn(-0.3) < Screen.center_x
expect Lens.turn_at_x({ x: Screen.center_x, focal_length: Pixels.of(800.0) }).to_radians() == 0.0

# The turn at an x is the way back from the x at a turn.
expect
	[-1.2, -0.3, 0.0, 0.4, 1.3].all(
		|radians| {
			back = Lens.turn_at_x({
				x: x_at_turn(radians),
				focal_length: Lens.resting_focal_length,
			})
			(back.to_radians() - radians).abs() <= 0.000000001
		},
	)
