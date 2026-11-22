app [main!] {}

import Crate

main! = |_args| {
	echo!("${Crate.width(Crate.({ width: 3 })).to_str()} ${Crate.Lid.width(Crate.Lid.({ width: 4 })).to_str()}")
	Ok({})
}
