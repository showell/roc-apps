app [main!] {}

# Allocate a small list and drop it, n times. n comes from the command
# line so the compiler cannot evaluate the loop at compile time.
step : I64, I64 -> I64
step = |n, total| if n <= 0 { total } else { step(n - 1, total + U64.to_i64_wrap(List.len(List.repeat(0, 16)))) }

main! = |args| {
	n = I64.from_str(List.get(args, 0) ?? "100000") ?? 100000
	echo!(Str.concat(I64.to_str(step(n, 0)), "\n"))
	Ok({})
}
