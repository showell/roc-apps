app [main!] { game: "../../game.roc", lib: "../../../lib/main.roc" }

import game.Clock

main! = |_args| {
	later = Clock.start + 7
	echo!(later.to_str())
	Ok({})
}
