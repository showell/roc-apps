## The grass, from just above the horizon down past the foot of the screen.
## It is one colour, and nothing else in the ride draws grass: the grass is
## whatever the rest of the frame doesn't paint over.
import Screen
import lib.Brush
import lib.RgbColor
import lib.Shapes

Grass :: [].{

	## The grass's colour, which the rolling land in front of the mountains
	## takes too.
	grass_color : RgbColor
	grass_color = RgbColor.of(0x4A8F43)

	## The grass, over the rectangle below the grass's top.
	grass_shape : Shapes.Shape
	grass_shape = Screen.below_grass_top_rect(Brush.flat(grass_color))
}
