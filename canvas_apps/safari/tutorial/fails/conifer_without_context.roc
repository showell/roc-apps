app [main!] { game: "../../game.roc", lib: "../../../lib/main.roc" }

import game.Conifer
import game.Pipeline
import game.Pixels
import game.Rendered

tree_rendering : Pipeline.Sighted(Conifer) -> Rendered
tree_rendering = |tree| Pipeline.rendering_of(tree, { cam_focal: Pixels.of(500.0), context: {} })

main! = |_args| {
	trees : List(Pipeline.Sighted(Conifer))
	trees = []
	echo!("${trees.map(tree_rendering).len().to_str()} trees drawn")
	Ok({})
}
