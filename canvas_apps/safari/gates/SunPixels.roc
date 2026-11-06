## SunPixels paints Safari's sun into a frame's pixels for SafariFrame (see
## SafariFrame for more context). It paints the sun's glow and then its disc, as Backdrop
## describes them, and clips both to the sky. The frame paints the sun before
## the ride's shapes, so the mountains can hide it.
import lib.Brush
import PixelGrid
import game.Backdrop
import game.Screen
import ScreenRoll
import game.Sky

SunPixels :: [].{

	## The sun, if it is in view.
	paint : List(U32), { roll : ScreenRoll, sun : Sky.SunSighting } -> List(U32)
	paint = |pixels, { roll, sun }|
		match sun {
			InView(place) => paint_glow_and_disc(pixels, { roll, sun: place })
			OutOfView => pixels
		}
}

paint_glow_and_disc : List(U32), { roll : ScreenRoll, sun : Sky.SunPlace } -> List(U32)
paint_glow_and_disc = |pixels, { roll, sun }| {
	fills = Backdrop.sun_fills(sun)
	sun_x = sun.x.to_f64()
	sun_y = sun.y.to_f64()
	screen_width = Screen.width.to_f64()
	horizon_y = Screen.horizon_y.to_f64()
	on_screen = roll.to_screen(ScreenRoll.ScenePoint.({ x: sun_x, y: sun_y }))
	rows = PixelGrid.pixels_between({
		from: on_screen.y - fills.glow_radius.to_f64(),
		to: on_screen.y + fills.glow_radius.to_f64(),
		extent: roll.height_px(),
	})
	columns = PixelGrid.pixels_between({
		from: on_screen.x - fills.glow_radius.to_f64(),
		to: on_screen.x + fills.glow_radius.to_f64(),
		extent: roll.width_px(),
	})
	var $px = pixels
	for row in rows.start.until(rows.end) {
		for column in columns.start.until(columns.end) {
			p = roll.to_scene(ScreenRoll.pixel_point({ row, column }))
			$px = if p.x >= 0.0 and p.x < screen_width and p.y >= 0.0 and p.y < horizon_y {
				at = PixelGrid.pixel_index({ row, column, width: roll.width_px() })
				lit = PixelGrid.blend($px, { at, color: Brush.shade(fills.glow, p.x, p.y) })
				distance = ((p.x - sun_x) * (p.x - sun_x) + (p.y - sun_y) * (p.y - sun_y)).sqrt()
				if distance < fills.disc_radius.to_f64() {
					PixelGrid.blend(lit, { at, color: Brush.shade(fills.disc, p.x, p.y) })
				} else {
					lit
				}
			} else {
				$px
			}
		}
	}
	$px
}
