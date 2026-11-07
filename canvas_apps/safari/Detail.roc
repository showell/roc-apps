## Detail holds the thresholds that decide how much of a thing is drawn: how
## near a tree's crown is cones and how near they are shaded, how few trees
## nearer than a tree leave it a shaded trunk, and how few pixels tall something
## may be and still be drawn at all.
import Distance
import Pixels

Detail :: [].{

	## A tree nearer than this has cones for a crown.
	cone_reach : Distance
	cone_reach = Distance.metres(200.0)

	crown_shade_reach : Distance
	crown_shade_reach = Distance.metres(80.0)

	## A tree with fewer than this many trees nearer than it gets a shaded
	## trunk, which looks round.
	round_trunk_limit : U16
	round_trunk_limit = 4

	min_scenery_px : Pixels
	min_scenery_px = Pixels.of(2.0)
}

expect Detail.cone_reach.to_metres() == 200.0
expect Detail.crown_shade_reach.to_metres() == 80.0
expect Detail.round_trunk_limit == 4
expect Detail.min_scenery_px.to_f64() == 2.0
