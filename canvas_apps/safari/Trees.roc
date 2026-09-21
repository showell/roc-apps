# Trees -- originally emitted from Codex by rocemit; the Roc is the program now
# and this file is edited here (safari/README.md).
import Scenery

Trees :: [].{

	conifer_green : I64
	conifer_green = 1858082

	conifer_gold : I64
	conifer_gold = 13605400

	conifer_red : I64
	conifer_red = 11680298

	small_height : F64
	small_height = 4.5

	big_scale : F64
	big_scale = 1.3

	tree_spacing : F64
	tree_spacing = 30.0

	tree_road_offset : F64
	tree_road_offset = 1.5

	tree_start_inset : F64
	tree_start_inset = 6.0

	tree_end_inset : F64
	tree_end_inset = 85.0

	max_trees : I64
	max_trees = 96

	accent_color : Scenery.Scheme -> I64
	accent_color = |s| (match s {
		YellowGreen => conifer_gold
		RedGreen => conifer_red
		AllGreen => conifer_green
	})

	tree_height_for : I64, Bool -> F64
	tree_height_for = |color, even| ({
		base = (if even { (small_height * big_scale) } else { small_height })
		(if (color == conifer_red) { (base * 2.0) } else { (if (color == conifer_gold) { (base * 3.0) } else { base }) })
	})

	tree_x_for : I64 -> F64
	tree_x_for = |color| (if (color == conifer_gold) { ((Scenery.lane_width / 2.0) + (4.0 * tree_road_offset)) } else { ((Scenery.lane_width / 2.0) + tree_road_offset) })

	fill_trees : Scenery.Scheme, F64, F64, I64, I64 -> List(Scenery.Tree)
	fill_trees = |scheme, length, along, k, n| (if (along > (length - tree_end_inset)) { [] } else { (if ((n + 2) > max_trees) { [] } else { fill_trees_pair(scheme, length, along, k, n) }) })

	fill_trees_pair : Scenery.Scheme, F64, F64, I64, I64 -> List(Scenery.Tree)
	fill_trees_pair = |scheme, length, along, k, n| ({
		even = ((k - (I64.div_trunc_by(k, 2) * 2)) == 0)
		color = (if even { conifer_green } else { accent_color(scheme) })
		height = tree_height_for(color, even)
		x = tree_x_for(color)
		List.concat([{ along: along, across: (0.0 - x), color: color, height: height }, { along: along, across: x, color: color, height: height }], fill_trees(scheme, length, (along + tree_spacing), (k + 1), (n + 2)))
	})
}
