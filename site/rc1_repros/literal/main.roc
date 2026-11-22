app [main!] {}

main! = |_args| {
	echo!((0.0).to_bits().to_str())
	Ok({})
}
