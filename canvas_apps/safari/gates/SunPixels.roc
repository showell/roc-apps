## SunPixels paints Safari's sun into a frame's pixels for SafariFrame (see
## SafariFrame for more context). It paints the sun's glow and then its disc, as SafariShapes
## describes them, and clips both to the sky. The frame paints the sun before
## the ride's shapes, so the mountains can hide it.
import lib.Brush
import PixelGrid
import game.SafariShapes
import game.Screen
import ScreenRoll
import game.Sky

SunPixels :: [].{

	## The sun, if it is in view.
	paint : List(U32), { roll : ScreenRoll, sun : Sky.SunPos } -> List(U32)
	paint = |pixels, { roll, sun }|
		match sun {
			InView(place) => paint_glow_and_disc(pixels, { roll, sun: place })
			OutOfView => pixels
		}
}

paint_glow_and_disc : List(U32), { roll : ScreenRoll, sun : Sky.SunPlace } -> List(U32)
paint_glow_and_disc = |pixels, { roll, sun }| {
	fills = SafariShapes.sun_fills(sun)
	on_screen = roll.to_screen(ScreenRoll.ScenePoint.({ x: sun.x, y: sun.y }))
	rows = PixelGrid.pixels_between({
		from: on_screen.y - fills.glow_radius,
		to: on_screen.y + fills.glow_radius,
		count: roll.height_px(),
	})
	columns = PixelGrid.pixels_between({
		from: on_screen.x - fills.glow_radius,
		to: on_screen.x + fills.glow_radius,
		count: roll.width_px(),
	})
	var $px = pixels
	for row in rows.start.until(rows.end) {
		for column in columns.start.until(columns.end) {
			p = roll.to_scene(ScreenRoll.pixel_point({ row, column }))
			$px = if p.x >= 0.0 and p.x < Screen.width and p.y >= 0.0 and p.y < Screen.horizon_y {
				at = PixelGrid.pixel_index({
					row,
					column,
					width: roll.width_px(),
				})
				lit = PixelGrid.blend(
					$px,
					{
						at,
						color: Brush.shade(
							fills.glow,
							p.x,
							p.y,
						),
					},
				)
				distance = F64.sqrt((p.x - sun.x) * (p.x - sun.x) + (p.y - sun.y) * (p.y - sun.y))
				if distance < fills.disc_radius {
					PixelGrid.blend(
						lit,
						{
							at,
							color: Brush.shade(
								fills.disc,
								p.x,
								p.y,
							),
						},
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
