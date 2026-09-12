app [main!] {}

loop_forever = |n| if n < 0 { 0 } else { loop_forever(n) }

main! = |_args| {
	echo!(I64.to_str(loop_forever(1)))
	Ok({})
}
