## Army draws the robot army on the lawn, face on, as March and Marchers
## place it: the drum major and its drumstick, and each marcher with the
## dish it carries, until it reaches its table and turns side on. Every
## marcher is sighted through the guest's eye, so one that is still under
## the eye is below the screen, and comes up over its bottom edge as it
## marches out.
import lib.Brush
import lib.RgbColor
import lib.Shapes
import Dancer
import Figure
import Dishes
import March
import Marchers
import Seatless
import Robot
import View

Army :: [].{

	## Everyone in the army still on the lawn at `tick`, each with the spot
	## it stands on, so the yard can paint it among the tables.
	army_layers : View, I64 -> List({ spot : { right : F64, forward : F64 }, shapes : List(Shapes.Shape) })
	army_layers = |view, tick| {
		leader =
			match Seatless.drum_major_at(tick) {
				Marching(drum_major) => [
					{ spot: ground_spot(drum_major.feet), shapes: drum_major_shapes(view, drum_major) },
				]
				NotYet => []
			}
		runners = Marchers.running_at(tick).map(
			|trooper| { spot: ground_spot(trooper.feet), shapes: trooper_shapes(view, trooper) },
		)
		List.concat(leader, runners)
	}
}

ground_spot : { right : F64, forward : F64, .. } -> { right : F64, forward : F64 }
ground_spot = |{ right, forward, .. }| { right, forward }

# A marcher, then its dish held up in its right hand.
trooper_shapes : View, March.Trooper -> List(Shapes.Shape)
trooper_shapes = |view, { build, dish, feet, pose, dish_tilt }|
	match view.sighting(feet) {
		Ok({ point, pixels_per_metre }) => {
			figure = Robot.figure_shapes({ build, pose, feet: point, pixels_per_metre })
			hand = Robot.hand_at(build, pose)
			dish_at = {
				right: feet.right + hand.across,
				forward: feet.forward - 0.1,
				height: hand.up + 0.02,
			}
			plated =
				match view.sighting(dish_at) {
					Ok(held) => Dishes.dish_shapes(
						dish,
						{
							base: held.point,
							pixels_per_metre: held.pixels_per_metre,
							tilt: dish_tilt,
						},
					)
					Err(BehindEye) => []
				}
			List.concat(figure, plated)
		}
		Err(BehindEye) => []
	}

drum_major_shapes : View, March.DrumMajor -> List(Shapes.Shape)
drum_major_shapes = |view, { feet, pose, drumstick, drumstick_layer }|
	match view.sighting(feet) {
		Ok({ point, pixels_per_metre }) => {
			place = {
				x: point.x.to_f64(),
				y: point.y.to_f64(),
				scale: pixels_per_metre,
			}
			body = Dancer.figure_shapes({ pose, feet: point, pixels_per_metre })
			stick = drumstick_shapes(place, drumstick)
			match drumstick_layer {
				OverBody => List.concat(body, stick)
				UnderBody => List.concat(stick, body)
			}
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
