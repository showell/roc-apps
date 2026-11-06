## Detail holds the thresholds that decide how much of a thing is drawn: how
## near a tree shows its full detail, how near its crown is shaded, and how few
## pixels tall something may be and still be drawn at all.
import Pixels
Detail :: [].{

	full_detail_reach : F64
	full_detail_reach = 200.0

	crown_shade_reach : F64
	crown_shade_reach = 80.0

	min_scenery_px : Pixels
	min_scenery_px = Pixels.of(2.0)
}

expect Detail.full_detail_reach == 200.0
expect Detail.crown_shade_reach == 80.0
expect Detail.min_scenery_px.to_f64() == 2.0
