app
	[main!]
	{
		game: "../../game.roc",
		lib: "../../../lib/main.roc",
	}

import game.Angle

main! = |_args| {
	north = Angle.Bearing.radians(0.0)
	quarter = Angle.Turn.radians(1.5)
	echo!(north.turn_from(quarter).to_radians().to_str())
	Ok({})
}
