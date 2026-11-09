# Safari with no platform, which gates/lints.shale reads the game's types from.
# web.roc reaches the same game modules, but its platform names lib's Shape
# through a package of its own, and roc-types follows only an app's packages.
app [main!] { lib: "../lib/main.roc" }

import SafariApp

main! = |_args| {
	# The app is named so the root reaches every module it is built from.
	_app = SafariApp.canvas_app
	Ok({})
}
