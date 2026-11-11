app [main!] { game: "../../game.roc", lib: "../../../lib/main.roc" }

import game.Distance
import game.Pipeline
import game.Rendered
import game.Sprite

## A kind of thing beside the road, with a height and no sprite.
Rock := [Boulder].{
	scenery_height : Rock -> Distance
	scenery_height = |_| Distance.metres(1.0)
}

render_rock : Pipeline.Sighted(Rock), Sprite.LensAndLight -> Rendered
render_rock = |sighting, lens_and_light| Pipeline.rendering_of(sighting, lens_and_light)

main! = |_| Ok({})
