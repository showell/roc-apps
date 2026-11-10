## SkyAndGrassPixels paints the sky and the grass, the first layer of a frame's
## pixels for SafariFrame (see SafariFrame for more context). The mountains
## are not part of it: they are shapes, which the game and SafariFrame both
## paint on top.
import lib.Brush
import lib.Fraction
import PixelColor
import PixelGrid
import game.Grass
import game.Screen
import game.Sky
import ScreenRoll

SkyAndGrassPixels :: [].{

	## The sky and the grass, given the sky's two colors, at the top of the
	## screen and at the horizon, and how dark the sky is, which dims the
	## grass.
	##
	## The sky holds its top colour to Sky's stop on the way down to
	## the horizon, then fades to the horizon colour; the grass is below it.
	## The fade divides by the horizon rather than shading a Linear brush,
	## whose arithmetic rounds differently.
	sky_and_grass_pixels : ScreenRoll,
	{
		sky_colors : Sky.Colors,
		darkness : Fraction,
		..,
	} -> List(U32)
	sky_and_grass_pixels = |roll, backdrop| {
		sky_colors = backdrop.sky_colors
		grass_pixel = Grass.grass_color_at(backdrop.darkness).to_i64().to_u32_wrap()
		top_color = Brush.opaque_rgba(sky_colors.top)
		horizon_color = Brush.opaque_rgba(sky_colors.horizon)
		width = roll.width_px()
		height = roll.height_px()
		var $px = List.with_capacity(width.to_u64() * height.to_u64())
		for row in PixelGrid.Coordinate.first.until(height) {
			for column in PixelGrid.Coordinate.first.until(width) {
				y = roll.to_scene(ScreenRoll.pixel_point({ row, column })).y
				pixel = if y >= Grass.grass_top_y.to_f64() {
					grass_pixel
				} else {
					t = (y / Screen.horizon_y.to_f64()).max(0.0).min(1.0)
					stop = Sky.sky_top_stop.to_f64()
					color = if t <= stop {
						top_color
					} else {
						Brush.mix({
							from: top_color,
							to: horizon_color,
							fraction: (t - stop) / (1.0 - stop),
						})
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
