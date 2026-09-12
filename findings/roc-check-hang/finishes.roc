app [main!] {}

loop_forever = |n| if n < 0 { 0 } else { loop_forever(n) }

main! = |args| {
	seed = List.len(args)
	echo!(I64.to_str(loop_forever(U64.to_i64_wrap(seed))))
	Ok({})
}
