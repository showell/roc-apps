app [main!] { game: "../../game.roc", lib: "../../../lib/main.roc" }

import game.Distance
import game.Speed

main! = |_arguments| {
	length = Distance.metres(2.0)
	speed = Speed.metres_a_step(1.0)
	echo!(length.plus(speed).to_metres().to_str())
	Ok({})
}
