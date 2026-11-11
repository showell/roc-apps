app [main!] { game: "../../game.roc", lib: "../../../lib/main.roc" }

import game.Distance
import game.Pipeline
import game.Sky
import game.Clock
import game.Lens

## A kind of thing beside the road, with a height and no sprite.
Rock := [Boulder].{
	scenery_height : Rock -> Distance
	scenery_height = |_rock| Distance.metres(1.0)
}

render_rock : Pipeline.Sighted(Rock) -> {}
render_rock = |sighting| {
	_rendered = Pipeline.rendering_of(
		sighting,
		{ focal_length: Lens.resting_focal_length, darkness: Sky.darkness_at(Clock.start) },
	)
	{}
}

main! = |_args| Ok({})
