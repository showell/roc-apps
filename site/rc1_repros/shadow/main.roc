app [main!] {}

import Distance

main! = |_args| {
	echo!(Distance.metres(2.0).to_metres().to_str())
	Ok({})
}
