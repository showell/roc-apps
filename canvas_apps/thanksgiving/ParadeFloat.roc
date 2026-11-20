## ParadeFloat draws the float a copied table rides in on, and the tiny robot
## pushing it: a low deck on wheels, skirted in red with bunting along its
## front, its wheels turning as far as it has rolled. Everything is drawn
## through the view moved to that table, in the table's own metres, so the
## deck lies under the party wherever the float has got to.
import lib.Brush
import lib.Eye
import lib.Pixels
import lib.RgbColor
import lib.Shapes
import Copies
import Robot
import View

ParadeFloat :: [].{

	## The deck, its skirt, bunting and wheels, which go under the party.
	deck_shapes : View, Copies.FloatRide -> List(Shapes.Shape)
	deck_shapes = |view, ride| {
		top = ride.deck_height
		[
			side_shapes(view, top),
			view.region_shapes({
				corners: upright_corners({
					top,
					right_from: deck_left,
					right_to: deck_right,
					forward: deck_near,
				}),
				fill: skirt_red,
			}),
			view.region_shapes({
				corners: [
					{
						right: deck_left,
						forward: deck_near,
						height: top,
					},
					{
						right: deck_right,
						forward: deck_near,
						height: top,
					},
					{
						right: deck_right,
						forward: deck_far,
						height: top,
					},
					{
						right: deck_left,
						forward: deck_far,
						height: top,
					},
				],
				fill: deck_green,
			}),
			bunting_shapes(view, top),
			[-1.8, 0.0, 1.8].map(|right| wheel_shapes(view, { right, rolled: ride.rolled, top })).join(),
		].join()
	}

	## Whether the pusher is on the eye's side of the float, and so is
	## painted over the party rather than under the deck.
	is_pusher_near : View, Copies.FloatRide -> Bool
	is_pusher_near = |view, ride| view.eye_ground().right * ride.from_side > 0.0

	## The tiny robot behind the float, arms up against it, its wheel
	## spinning, until the float stops and its arms drop.
	pusher_shapes : View, Copies.FloatRide -> List(Shapes.Shape)
	pusher_shapes = |view, ride|
		match view.sighting({
			right: ride.from_side * 3.0,
			forward: 3.3,
			height: 0.0,
		}) {
			Ok({ point, pixels_per_metre }) =>
				Robot.figure_shapes({
					build: Tiny,
					pose: {
						phase: ride.rolled / 0.09,
						stride: ride.speed.min(0.6) * 2.0,
						reach: (ride.speed * 6.0).min(1.0),
						eye_glow: 1.0,
						look: 0.5 - 0.5 * ride.from_side,
					},
					feet: point,
					pixels_per_metre,
				})
			Err(BehindEye) => []
		}
}

deck_left : F64
deck_left = -2.4

deck_right : F64
deck_right = 2.4

deck_near : F64
deck_near = -0.3

deck_far : F64
deck_far = 7.0

# How far the skirt hangs from the deck: three quarters of the way to the
# lawn.
skirt_depth : F64 -> F64
skirt_depth = |top| 0.75 * top

# The skirt on the deck's end facing the eye, if the eye is off to one side.
side_shapes : View, F64 -> List(Shapes.Shape)
side_shapes = |view, top| {
	eye = view.eye_ground()
	side =
		if eye.right < deck_left {
			Shown(deck_left)
		} else if eye.right > deck_right {
			Shown(deck_right)
		} else {
			Hidden
		}
	match side {
		Shown(right) =>
			view.region_shapes({
				corners: [
					{
						right,
						forward: deck_near,
						height: top - skirt_depth(top),
					},
					{
						right,
						forward: deck_far,
						height: top - skirt_depth(top),
					},
					{ right, forward: deck_far, height: top },
					{ right, forward: deck_near, height: top },
				],
				fill: skirt_shade,
			})
		Hidden => []
	}
}

# A face of the skirt across the float at `forward`, from the bottom of the
# skirt to the deck.
upright_corners : {
	top : F64,
	right_from : F64,
	right_to : F64,
	forward : F64,
} -> List(Eye.At)
upright_corners = |{ top, right_from, right_to, forward }| [
	{ right: right_from, forward, height: top },
	{ right: right_to, forward, height: top },
	{
		right: right_to,
		forward,
		height: top - skirt_depth(top),
	},
	{
		right: right_from,
		forward,
		height: top - skirt_depth(top),
	},
]

# Pennants hanging from the deck's front edge, three colors in turn.
bunting_shapes : View, F64 -> List(Shapes.Shape)
bunting_shapes = |view, deck_top| {
	pennant_count : U64
	pennant_count = 12
	wide = (deck_right - deck_left) / pennant_count.to_f64()
	top = deck_top - 0.01
	drop = (0.5 * deck_top).min(0.2)
	var $out = List.with_capacity(pennant_count)
	for k in 0..<pennant_count {
		left = deck_left + wide * k.to_f64()
		fill = pennant_colors.get(k % 3) ?? crash "ParadeFloat.bunting_shapes: three pennant colors"
		$out = List.concat(
			$out,
			view.region_shapes({
				corners: [
					{
						right: left,
						forward: deck_near - 0.01,
						height: top,
					},
					{
						right: left + wide,
						forward: deck_near - 0.01,
						height: top,
					},
					{
						right: left + wide / 2.0,
						forward: deck_near - 0.01,
						height: top - drop,
					},
				],
				fill,
			}),
		)
	}
	$out
}

# A wheel on the front of the float: a tyre, a hub and a spoke turned as far
# as the float has rolled. It draws up into the float as the deck kneels.
wheel_shapes : View,
{
	right : F64,
	rolled : F64,
	top : F64,
} -> List(Shapes.Shape)
wheel_shapes = |view, { right, rolled, top }| {
	radius = 0.17 * top / Copies.deck_height
	middle = {
		right,
		forward: deck_near - 0.05,
		height: radius,
	}
	turned = rolled / radius
	spoke_end = {
		..middle,
		right: right + 0.8 * radius * turned.sin(),
		height: radius + 0.8 * radius * turned.cos(),
	}
	match view.sighting(middle) {
		Ok(_) if radius < 0.02 => []
		Ok({ point, pixels_per_metre }) =>
			[
				Disc({
					center: point,
					radius: Pixels.of(radius * pixels_per_metre),
					fill: tyre,
				}),
				Disc({
					center: point,
					radius: Pixels.of(0.45 * radius * pixels_per_metre),
					fill: hub,
				}),
			].concat(
				view.line_shapes({
					from: middle,
					to: spoke_end,
					width: 0.04,
					fill: hub,
				}),
			)
		Err(BehindEye) => []
	}
}

pennant_colors : List(Brush.Fill)
pennant_colors = [
	Brush.flat(RgbColor.of(0xF2C14E)),
	Brush.flat(RgbColor.of(0xE0702E)),
	Brush.flat(RgbColor.of(0xF7F1E1)),
]

skirt_red : Brush.Fill
skirt_red = Brush.flat(RgbColor.of(0xA8322A))

skirt_shade : Brush.Fill
skirt_shade = Brush.flat(RgbColor.of(0x7E241E))

deck_green : Brush.Fill
deck_green = Brush.flat(RgbColor.of(0x3F6B3A))

tyre : Brush.Fill
tyre = Brush.flat(RgbColor.of(0x1E1B1A))

hub : Brush.Fill
hub = Brush.flat(RgbColor.of(0xC9B27A))
