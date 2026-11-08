app [main!] { game: "../../game.roc", lib: "../../../lib/main.roc" }

import game.Angle
import game.Distance
import game.Geom

main! = |_args| {
	ahead = { right: Distance.zero, forward: Distance.metres(5.0) }
	bend = { segment_length: Distance.metres(100.0), turn: Angle.Turn.degrees(30.0) }
	echo!(Geom.point_in_segment_before(ahead, bend).along.to_metres().to_str())
	Ok({})
}
