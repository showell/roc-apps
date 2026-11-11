app [main!] { game: "../../game.roc", lib: "../../../lib/main.roc" }

import game.Pipeline
import game.Rendered
import game.Sprite

## A kind of thing beside the road, with one tag and no methods.
Rock := [Boulder]

render_rock : Pipeline.Sighted(Rock), Sprite.LensAndLight -> Rendered
render_rock = |sighting, lens_and_light| Pipeline.rendering_of(sighting, lens_and_light)

main! = |_| Ok({})
