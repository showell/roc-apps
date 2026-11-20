## Army draws the robot army March places: the drum major and its drumstick,
## then the marchers back to front, each with the dish it carries. Every
## marcher is sighted through the guest's eye, so one that is still under
## the eye is below the screen, and comes up over its bottom edge as it
## marches out.
import lib.Brush
import lib.RgbColor
import lib.Shapes
import Dancer
import Figure
import Dinner
import Dishes
import March
import Robot
import View

Army :: [].{

	## The whole army at `tick`, farthest first.
	army_shapes : View, I64 -> List(Shapes.Shape)
	army_shapes = |view, tick| {
		leader =
			match March.drum_major_at(tick) {
				Marching(drum_major) => drum_major_shapes(view, drum_major)
				NotYet => []
			}
		List.concat(
			leader,
			March.troopers_at(tick).map(|trooper| trooper_shapes(view, trooper)).join(),
		)
	}
}

# A marcher, then its dish held up in its right hand.
trooper_shapes : View, March.Trooper -> List(Shapes.Shape)
trooper_shapes = |view, { build, feet, pose, dish_tilt }|
	match view.sighting(feet) {
		Ok({ point, pixels_per_metre }) => {
			figure = Robot.figure_shapes({ build, pose, feet: point, pixels_per_metre })
			hand = Robot.hand_at(build, pose)
			dish_at = {
				right: feet.right + hand.across,
				forward: feet.forward - 0.1,
				height: hand.up + 0.02,
			}
			dish =
				match view.sighting(dish_at) {
					Ok(held) => Dishes.dish_shapes(
						Dinner.dish_of(build),
						{
							base: held.point,
							pixels_per_metre: held.pixels_per_metre,
							tilt: dish_tilt,
						},
					)
					Err(BehindEye) => []
				}
			List.concat(figure, dish)
		}
		Err(BehindEye) => []
	}

drum_major_shapes : View, March.DrumMajor -> List(Shapes.Shape)
drum_major_shapes = |view, { feet, pose, drumstick }|
	match view.sighting(feet) {
		Ok({ point, pixels_per_metre }) => {
			place = {
				x: point.x.to_f64(),
				y: point.y.to_f64(),
				scale: pixels_per_metre,
			}
			Dancer.figure_shapes({ pose, feet: point, pixels_per_metre })
				.concat(drumstick_shapes(place, drumstick))
		}
		Err(BehindEye) => []
	}

# A drumstick from the turkey: a bone with a knuckle at the gripped end and
# the roasted meat at the far end, pointing `angle` from straight down.
drumstick_shapes : Figure.Place, { grip : Figure.Spot, angle : F64 } -> List(Shapes.Shape)
drumstick_shapes = |place, { grip, angle }| {
	along = |metres| {
		across: grip.across + angle.sin() * metres,
		up: grip.up - angle.cos() * metres,
	}
	knuckle = along(-0.07)
	[
		Figure.bar(
			place,
			{
				from: knuckle,
				to: along(0.3),
				width: 0.035,
				fill: bone,
			},
		),
		Figure.dot(
			place,
			{
				at: {
					across: knuckle.across + 0.02 * angle.cos(),
					up: knuckle.up + 0.02 * angle.sin(),
				},
				radius: 0.028,
				fill: bone,
			},
		),
		Figure.dot(
			place,
			{
				at: {
					across: knuckle.across - 0.02 * angle.cos(),
					up: knuckle.up - 0.02 * angle.sin(),
				},
				radius: 0.028,
				fill: bone,
			},
		),
		Figure.dot(
			place,
			{
				at: along(0.27),
				radius: 0.07,
				fill: roast,
			},
		),
		Figure.dot(
			place,
			{
				at: along(0.36),
				radius: 0.095,
				fill: roast,
			},
		),
		Figure.dot(
			place,
			{
				at: along(0.38),
				radius: 0.05,
				fill: crisp,
			},
		),
	]
}

bone : Brush.Fill
bone = Brush.flat(RgbColor.of(0xF3E9D2))

roast : Brush.Fill
roast = Brush.flat(RgbColor.of(0x9A4E24))

crisp : Brush.Fill
crisp = Brush.flat(RgbColor.of(0xC8763D))
