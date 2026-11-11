app [main!, rock_rendering] { game: "../../game.roc", lib: "../../../lib/main.roc" }

import game.Pipeline
import game.Rendered
import game.Sprite

## A kind of thing beside the road, with one tag and no methods.
Rock := [Boulder]

rock_rendering : Pipeline.Sighted(Rock), Sprite.LensAndLight -> Rendered
rock_rendering = |sighting, lens_and_light| Pipeline.rendering_of(sighting, lens_and_light)

main! = |_| Ok({})
