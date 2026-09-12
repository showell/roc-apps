import Basic

main! = |args| {
	seed = U64.plus_wrap(1, List.len(args))
	echo!(Basic.run("10 READ A(1)\n20 DATA 9\n30 PRINT A(1)\n40 END\n", [], seed))
	Ok({})
}
