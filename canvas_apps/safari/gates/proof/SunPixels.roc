## SunPixels paints Safari's sun into a frame's pixels for SafariFrame (see
## SafariFrame for more context). It paints the sun's glow and then its disc, as Sun
## describes them, onto the sky and grass that SkyAndGrassPixels painted. The
## frame paints the grass after the sun, so this paints only above the grass's top.
## The sky's rectangle reaches past every corner of a rolled screen, so above
## the grass is where the glow is. The frame paints the sun before the ride's
## shapes, so the mountains can hide it.
import lib.Brush
import lib.Point
import game.Grass
import PixelGrid
import ScreenRoll
import game.Sun

SunPixels :: [].{

	## The sun, if it is in view.
	pixels_with_sun : List(U32), { roll : ScreenRoll, sun : Sun.Sighting } -> List(U32)
	pixels_with_sun = |pixels, { roll, sun }|
		match sun {
			InView(place) => pixels_with_glow_and_disc(pixels, { roll, sun: place })
			OutOfView => pixels
		}
}

pixels_with_glow_and_disc : List(U32), { roll : ScreenRoll, sun : Sun.OnScreen } -> List(U32)
pixels_with_glow_and_disc = |pixels, { roll, sun }| {
	look = Sun.look(sun)
	glow_radius = Sun.glow_radius_on_screen(sun).to_f64()
	disc_radius = Sun.disc_radius_on_screen(sun).to_f64()
	sun_x = sun.center.x.to_f64()
	sun_y = sun.center.y.to_f64()
	grass_top_y = Grass.grass_top_y.to_f64()
	on_screen = roll.to_screen(ScreenRoll.ScenePoint.({ x: sun_x, y: sun_y }))
	rows = PixelGrid.pixels_between({
		from: on_screen.y - glow_radius,
		to: on_screen.y + glow_radius,
		extent: roll.height_px(),
	})
	columns = PixelGrid.pixels_between({
		from: on_screen.x - glow_radius,
		to: on_screen.x + glow_radius,
		extent: roll.width_px(),
	})
	var $px = pixels
	for row in rows.start.until(rows.end) {
		for column in columns.start.until(columns.end) {
			p = roll.to_scene(ScreenRoll.pixel_point({ row, column }))
			$px = if p.y < grass_top_y {
				at = PixelGrid.pixel_index({ row, column, width: roll.width_px() })
				lit = PixelGrid.blended_pixels(
					$px,
					{ at, color: Brush.shade(look.glow, Point.at(p.x, p.y)) },
				)
				distance = ((p.x - sun_x) * (p.x - sun_x) + (p.y - sun_y) * (p.y - sun_y)).sqrt()
				if distance < disc_radius {
					PixelGrid.blended_pixels(
						lit,
						{ at, color: Brush.shade(look.disc, Point.at(p.x, p.y)) },
					)
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
