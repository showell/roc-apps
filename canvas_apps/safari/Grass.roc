## The grass, from just above the horizon down past the foot of the screen.
## It is one colour, and nothing else in the ride draws grass: the grass is
## whatever the rest of the frame doesn't paint over.
import Pixels
import Screen
import lib.Brush
import lib.RgbColor
import lib.Shapes

Grass :: [].{

	## The grass's colour, which the rolling land in front of the mountains
	## takes too.
	grass_color : RgbColor
	grass_color = RgbColor.of(0x4A8F43)

	## The grass starts a pixel above the horizon, so no seam shows between
	## the two under the roll.
	grass_top_y : Pixels
	grass_top_y = Screen.horizon_y.minus(Pixels.of(1.0))

	## The grass: a rectangle from `grass_top_y` down to `roll_margin` below
	## the screen, and `roll_margin` past each side.
	grass_shape : Shapes.Shape
	grass_shape = Rect({
		x: Screen.roll_margin.opposite().to_f64(),
		y: grass_top_y.to_f64(),
		width: Screen.width_with_margins.to_f64(),
		height: Screen.height.minus(grass_top_y).plus(Screen.roll_margin).to_f64(),
		fill: Brush.flat(grass_color),
	})
}
