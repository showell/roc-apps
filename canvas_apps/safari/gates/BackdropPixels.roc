## BackdropPixels paints the sky and the grass, the first layer of a frame's
## pixels for SafariFrame (see SafariFrame for more context). The mountains
## are not part of it: they are shapes, which the game and SafariFrame both
## paint on top.
import lib.Brush
import PixelColor
import PixelGrid
import game.Backdrop
import game.Screen
import ScreenRoll

BackdropPixels :: [].{

	## The sky and the grass, given the sky's colour at the top of the screen
	## and at the horizon, as 0xRRGGBB.
	##
	## The sky holds its top colour to Backdrop's stop on the way down to
	## the horizon, then fades to the horizon colour; the grass is below it.
	## The fade divides by the horizon rather than shading a Linear brush,
	## whose arithmetic rounds differently.
	paint : ScreenRoll, { sky_top_color : I64, sky_horizon_color : I64 } -> List(U32)
	paint = |roll, { sky_top_color, sky_horizon_color }| {
		top_color = Brush.opaque(sky_top_color)
		horizon_color = Brush.opaque(sky_horizon_color)
		width = roll.width_px()
		height = roll.height_px()
		var $px = List.with_capacity(width.to_u64() * height.to_u64())
		for row in PixelGrid.Coordinate.first.until(height) {
			for column in PixelGrid.Coordinate.first.until(width) {
				y = roll.to_scene(ScreenRoll.pixel_point({ row, column })).y
				pixel = if y >= Screen.grass_top_y {
					grass_pixel
				} else {
					t = Brush.clamp01(y / Screen.horizon_y)
					stop = Backdrop.sky_top_stop
					color = if t <= stop {
						top_color
					} else {
						Brush.mix(
							top_color,
							horizon_color,
							(t - stop) / (1.0 - stop),
						)
					}
					PixelColor.pack({
						r: color.r,
						g: color.g,
						b: color.b,
					})
				}
				$px = $px.append(pixel)
			}
		}
		$px
	}
}

grass_pixel : U32
grass_pixel = I64.to_u32_wrap(Backdrop.grass_color)
