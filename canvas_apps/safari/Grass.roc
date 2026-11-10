## The grass, from just above the horizon down past the foot of the screen.
## It is one colour, dimmed as the sky darkens, and nothing else in the ride
## draws grass: the grass is whatever the rest of the frame doesn't paint over.
import lib.Fraction
import lib.Pixels
import Screen
import Sky
import lib.Brush
import lib.RgbColor
import lib.Shapes

Grass :: [].{

	## The grass's colour by day, which the rolling land in front of the
	## mountains takes too.
	grass_color : RgbColor
	grass_color = RgbColor.of(0x4A8F43)

	## The grass's colour under a sky `darkness` dark.
	grass_color_at : Fraction -> RgbColor
	grass_color_at = |darkness| Sky.color_at_darkness(Grass.grass_color, darkness)

	## The grass starts a pixel above the horizon, so no seam shows between
	## the two under the roll.
	grass_top_y : Pixels
	grass_top_y = Screen.horizon_y.minus(Pixels.of(1.0))

	## The grass under a sky `darkness` dark: a rectangle from `grass_top_y`
	## down to `roll_margin` below the screen, and `roll_margin` past each side.
	grass_shape : Fraction -> Shapes.Shape
	grass_shape = |darkness|
		Screen.margin_rect(
			{ top: grass_top_y, bottom: Screen.height.plus(Screen.roll_margin) },
			Brush.flat(Grass.grass_color_at(darkness)),
		)
}
