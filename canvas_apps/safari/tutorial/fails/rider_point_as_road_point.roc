app [main!] { game: "../../game.roc", lib: "../../../lib/main.roc" }

import game.Angle
import game.Distance
import game.Geometry

main! = |_arguments| {
	ahead = { right: Distance.zero, forward: Distance.from_metres(5.0) }
	bend = { segment_length: Distance.from_metres(100.0), turn: Angle.Turn.degrees(30.0) }
	echo!(Geometry.point_in_segment_before(ahead, bend).along.to_metres().to_str())
	Ok({})
}
