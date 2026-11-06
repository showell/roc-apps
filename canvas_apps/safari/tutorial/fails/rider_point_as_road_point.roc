app [main!] { game: "../../game.roc", lib: "../../../lib/main.roc" }

import game.Across
import game.Along
import game.Angle
import game.Distance
import game.Geom

main! = |_args| {
	ahead = { right: Distance.zero, forward: Distance.metres(5.0) }
	vantage = {
		along: Along.start,
		across: Across.middle,
		yaw: Angle.straight_ahead,
		half_width: Distance.metres(2.0),
	}
	echo!(Geom.to_rider_point(ahead, vantage).forward.to_metres().to_str())
	Ok({})
}
