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

classify : I64 -> Text
classify = |n| (match n {
	0 => "zero"
	1 => "one"
	42 => "answer"
	_ => "other"
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
	line!(Text.printed(Text.concat("clamp: ", Text.show_int(clamp(0, 100, abs(max((-42), 37)))))))
	line!(Text.printed(Text.concat("absorb: ", Text.show_int(add5(7)))))
	line!(Text.printed(Text.concat(Text.concat(Text.concat(Text.concat(Text.concat("match: ", classify(42)), "/"), classify(1)), "/"), classify(99))))
	({
		large_val = 150
		({
			line!(Text.printed(Text.concat("clamping: ", Text.show_int({ p: I64.min(I64.max(large_val, 0), 100) }.p))))
			line!(Text.printed(Text.concat("even: ", (if is_even(10) { "yes" } else { "no" }))))
			line!(Text.printed(Text.concat("odd: ", (if is_odd(7) { "yes" } else { "no" }))))
			line!(Text.printed(Text.concat(Text.concat(Text.concat("comma-params: ", Text.show_int(add(10, 32))), "/"), Text.show_int(apply(add, 20, 22)))))
			line!(Text.printed(Text.concat(Text.concat(Text.concat("concat-text: ", "hello"), " "), "world")))
			line!(Text.printed(Text.concat("concat-bool: ", (if (True and False) { "True" } else { "False" }))))
			({
				xs = List.concat([1, 2], [3, 4])
				line!(Text.printed(Text.concat("concat-list: ", Text.show_int(U64.to_i64_wrap(List.len(xs))))))
			})
		})
	})
	Ok({})
}
