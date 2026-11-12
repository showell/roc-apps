app [main!, sighting_left_out] { game: "../../game.roc", lib: "../../../lib/main.roc" }

import game.Geom
import game.Pipeline
import game.RoadAhead
import game.SegmentFromRider

## A sighting whose type lists only `BelowHorizon`, though the `?` after
## `sighting_of` can pass up a `BehindCamera`.
sighting_left_out : Geom.Placed(kind),
{
	road : RoadAhead.RoadView,
	vantage : Geom.Vantage,
	from_rider : SegmentFromRider,
} -> Try(Pipeline.Sighted(kind), [BelowHorizon])
sighting_left_out = |placed, camera| {
	sighting = Pipeline.sighting_of(placed, camera)?
	Ok(sighting)
}

main! = |_| Ok({})
