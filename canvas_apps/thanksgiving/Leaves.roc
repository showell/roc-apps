## Leaves draws a few autumn leaves blowing across the screen, given how many
## seconds the gust has been blowing. Each leaf starts off the left edge at its
## own height, drifts right and a little down, rocks up and down and turns
## over, so the same number places every leaf.
import lib.Brush
import lib.Pixels
import lib.Point
import lib.RgbColor
import lib.Shapes

Leaves :: [].{

	## The leaves `seconds` into the gust. Before it starts there are none, and
	## a leaf past the right edge is not drawn.
	leaf_shapes : F64, { width : F64 } -> List(Shapes.Shape)
	leaf_shapes = |seconds, { width }|
		if seconds <= 0.0 {
			[]
		} else {
			gusts.map(|leaf| one_leaf_shapes(leaf, { seconds, width })).join()
		}
}

Leaf : {
	delay : F64,
	height : F64,
	speed : F64,
	spin : F64,
	size : F64,
	color : I64,
}

gusts : List(Leaf)
gusts = [
	{
		delay: 0.0,
		height: 210.0,
		speed: 320.0,
		spin: 3.1,
		size: 17.0,
		color: 0xD9622B,
	},
	{
		delay: 0.3,
		height: 150.0,
		speed: 360.0,
		spin: -2.4,
		size: 14.0,
		color: 0xE8A33D,
	},
	{
		delay: 0.6,
		height: 300.0,
		speed: 300.0,
		spin: 2.2,
		size: 20.0,
		color: 0xB8432A,
	},
	{
		delay: 0.9,
		height: 185.0,
		speed: 340.0,
		spin: -3.4,
		size: 15.0,
		color: 0xC9822E,
	},
	{
		delay: 1.2,
		height: 260.0,
		speed: 310.0,
		spin: 2.7,
		size: 18.0,
		color: 0xE0742F,
	},
]

one_leaf_shapes : Leaf, { seconds : F64, width : F64 } -> List(Shapes.Shape)
one_leaf_shapes = |leaf, { seconds, width }| {
	blown = seconds - leaf.delay
	x = -30.0 + leaf.speed * blown
	if blown <= 0.0 or x > width + 30.0 {
		[]
	} else {
		y = leaf.height + 22.0 * (blown * 2.3 + leaf.delay * 5.0).sin() + 18.0 * blown
		angle = leaf.spin * blown
		# Turning over end on end makes a leaf look thinner, then whole again.
		flip = (blown * 4.0 + leaf.delay).cos()
		cosine = angle.cos()
		sine = angle.sin()
		at = |along, across| {
			scaled_along = along * leaf.size
			scaled_across = across * leaf.size * flip
			Point.at(
				x + scaled_along * cosine - scaled_across * sine,
				y + scaled_along * sine + scaled_across * cosine,
			)
		}
		outline = [
			at(-1.0, 0.0),
			at(-0.45, 0.4),
			at(0.25, 0.42),
			at(1.0, 0.0),
			at(0.25, -0.42),
			at(-0.45, -0.4),
		]
		[
			Shapes.region_from_corners(outline, Brush.flat(RgbColor.of(leaf.color))),
			Shapes.line(
				{
					from: at(-1.45, 0.08),
					to: at(0.85, 0.0),
					width: Pixels.of(1.6),
				},
				Brush.flat(RgbColor.of(0x6B3518)),
			),
		]
	}
}

expect Leaves.leaf_shapes(0.0, { width: 640.0 }) == []
expect Leaves.leaf_shapes(30.0, { width: 640.0 }) == []
expect Leaves.leaf_shapes(1.0, { width: 640.0 }).len() > 0
