# arithmetic
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/arithmetic.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     clamp: 37
#     absorb: 12
#     match: answer/one/other
#     clamping: 100
#     even: yes
#     odd: yes
#     comma-params: 42/42
#     concat-text: hello world
#     concat-bool: False
#     concat-list: 4

app [main!] { cdx: "./codex/main.roc" }

import cdx.Text

# Arithmetic -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))
Pct : { p : I64 }

max : I64, I64 -> I64
max = |x, y| (if (x > y) { x } else { y })

abs : I64 -> I64
abs = |x| (if (x < 0) { (-x) } else { x })

clamp : I64, I64, I64 -> I64
clamp = |lo, hi, x| (if (x < lo) { lo } else { (if (x > hi) { hi } else { x }) })

add5 : I64 -> I64
add5 = |x| (x + 5)

classify : I64 -> List(U8)
classify = |n| (match n {
	0 => [38, 13, 21, 16]
	1 => [16, 18, 13]
	42 => [15, 18, 19, 27, 13, 21]
	_ => [16, 14, 20, 13, 21]
})

is_even : I64 -> Bool
is_even = |n| (if (n == 0) { True } else { is_odd((n - 1)) })

is_odd : I64 -> Bool
is_odd = |n| (if (n == 0) { False } else { is_even((n - 1)) })

add : I64, I64 -> I64
add = |x, y| (x + y)

apply : (I64, I64 -> I64), I64, I64 -> I64
apply = |f, a, b| f(a, b)

# --- Entry ---

main! = |_args| {
	line!(Text.printed(List.concat([24, 23, 15, 26, 31, 69, 2], Text.show_int(clamp(0, 100, abs(max((-42), 37)))))))
	line!(Text.printed(List.concat([15, 32, 19, 16, 21, 32, 69, 2], Text.show_int(add5(7)))))
	line!(Text.printed(List.concat(List.concat(List.concat(List.concat(List.concat([26, 15, 14, 24, 20, 69, 2], classify(42)), [81]), classify(1)), [81]), classify(99))))
	({
		large_val = 150
		({
			line!(Text.printed(List.concat([24, 23, 15, 26, 31, 17, 18, 29, 69, 2], Text.show_int({ p: I64.min(I64.max(large_val, 0), 100) }.p))))
			line!(Text.printed(List.concat([13, 33, 13, 18, 69, 2], (if is_even(10) { [30, 13, 19] } else { [18, 16] }))))
			line!(Text.printed(List.concat([16, 22, 22, 69, 2], (if is_odd(7) { [30, 13, 19] } else { [18, 16] }))))
			line!(Text.printed(List.concat(List.concat(List.concat([24, 16, 26, 26, 15, 73, 31, 15, 21, 15, 26, 19, 69, 2], Text.show_int(add(10, 32))), [81]), Text.show_int(apply(add, 20, 22)))))
			line!(Text.printed(List.concat(List.concat(List.concat([24, 16, 18, 24, 15, 14, 73, 14, 13, 36, 14, 69, 2], [20, 13, 23, 23, 16]), [2]), [27, 16, 21, 23, 22])))
			line!(Text.printed(List.concat([24, 16, 18, 24, 15, 14, 73, 32, 16, 16, 23, 69, 2], (if (True and False) { [40, 21, 25, 13] } else { [54, 15, 23, 19, 13] }))))
			({
				xs = List.concat([1, 2], [3, 4])
				line!(Text.printed(List.concat([24, 16, 18, 24, 15, 14, 73, 23, 17, 19, 14, 69, 2], Text.show_int(U64.to_i64_wrap(List.len(xs))))))
			})
		})
	})
	Ok({})
}
