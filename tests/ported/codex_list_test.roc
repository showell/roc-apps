# list-test
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/list-test.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     === ConsList Prelude Module ===
#     
#     PASS: length
#     PASS: head
#     PASS: tail length
#     PASS: map double
#     PASS: filter even
#     PASS: foldl sum
#     PASS: reverse
#     PASS: append
#     PASS: take 3
#     PASS: drop 3
#     PASS: any even
#     PASS: all even
#     PASS: sum
#     PASS: is-empty nil
#     PASS: is-empty cons
#     
#     === Array-List Operations ===
#     PASS: set-at
#     PASS: insert-at
#     PASS: empty-direct
#     PASS: empty-let
#     PASS: list-of-records

app [main!] { cdx: "./codex/main.roc" }

import cdx.List_
import cdx.Text

# ListTest -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))
Person : { name : List(U8), age : I64 }

double : I64 -> I64
double = |n| (n * 2)

is_even : I64 -> Bool
is_even = |n| ((I64.div_trunc_by(n, 2) * 2) == n)

add : I64, I64 -> I64
add = |a, b| (a + b)

show_list : List_.ConsList(I64) -> List(U8)
show_list = |xs| (match xs {
	Cons(h, t) => (if List_.cl_is_empty(t) { Text.show_int(h) } else { List.concat(List.concat(Text.show_int(h), [66, 2]), show_list(t)) })
	Nil => []
})

check : List(U8), List(U8), List(U8) -> List(U8)
check = |name, actual, expected| (if (actual == expected) { List.concat([57, 41, 45, 45, 69, 2], name) } else { List.concat(List.concat(List.concat(List.concat(List.concat(List.concat([54, 41, 43, 49, 69, 2], name), [2, 13, 36, 31, 13, 24, 14, 13, 22, 2, 88]), expected), [89, 2, 29, 16, 14, 2, 88]), actual), [89]) })

nums : List_.ConsList(I64)
nums = List_.cl_cons(1, List_.cl_cons(2, List_.cl_cons(3, List_.cl_cons(4, List_.cl_cons(5, List_.cl_nil)))))

ages_sum : List(Person), I64, I64 -> I64
ages_sum = |ps, i, acc| (if (i >= U64.to_i64_wrap(List.len(ps))) { acc } else { ages_sum(ps, (i + 1), (acc + (List.get(ps, I64.to_u64_wrap(i)) ?? crash("list-at out of range")).age)) })

# --- Entry ---

main! = |_args| {
	line!(Text.printed([77, 77, 77, 2, 50, 16, 18, 19, 49, 17, 19, 14, 2, 57, 21, 13, 23, 25, 22, 13, 2, 52, 16, 22, 25, 23, 13, 2, 77, 77, 77]))
	line!(Text.printed([]))
	line!(Text.printed(check([23, 13, 18, 29, 14, 20], Text.show_int(List_.cl_length(nums)), [8])))
	line!(Text.printed(check([20, 13, 15, 22], Text.show_int(List_.cl_head(nums)), [4])))
	line!(Text.printed(check([14, 15, 17, 23, 2, 23, 13, 18, 29, 14, 20], Text.show_int(List_.cl_length(List_.cl_tail(nums))), [7])))
	line!(Text.printed(check([26, 15, 31, 2, 22, 16, 25, 32, 23, 13], show_list(List_.cl_map(double, nums)), [5, 66, 2, 7, 66, 2, 9, 66, 2, 11, 66, 2, 4, 3])))
	line!(Text.printed(check([28, 17, 23, 14, 13, 21, 2, 13, 33, 13, 18], show_list(List_.cl_filter(is_even, nums)), [5, 66, 2, 7])))
	line!(Text.printed(check([28, 16, 23, 22, 23, 2, 19, 25, 26], Text.show_int(List_.cl_foldl(add, 0, nums)), [4, 8])))
	line!(Text.printed(check([21, 13, 33, 13, 21, 19, 13], show_list(List_.cl_reverse(nums)), [8, 66, 2, 7, 66, 2, 6, 66, 2, 5, 66, 2, 4])))
	line!(Text.printed(check([15, 31, 31, 13, 18, 22], show_list(List_.cl_append(List_.cl_cons(1, List_.cl_cons(2, List_.cl_nil)), List_.cl_cons(3, List_.cl_cons(4, List_.cl_nil)))), [4, 66, 2, 5, 66, 2, 6, 66, 2, 7])))
	line!(Text.printed(check([14, 15, 34, 13, 2, 6], show_list(List_.cl_take(3, nums)), [4, 66, 2, 5, 66, 2, 6])))
	line!(Text.printed(check([22, 21, 16, 31, 2, 6], show_list(List_.cl_drop(3, nums)), [7, 66, 2, 8])))
	line!(Text.printed(check([15, 18, 30, 2, 13, 33, 13, 18], (if List_.cl_any(is_even, nums) { [40, 21, 25, 13] } else { [54, 15, 23, 19, 13] }), [40, 21, 25, 13])))
	line!(Text.printed(check([15, 23, 23, 2, 13, 33, 13, 18], (if List_.cl_all(is_even, nums) { [40, 21, 25, 13] } else { [54, 15, 23, 19, 13] }), [54, 15, 23, 19, 13])))
	line!(Text.printed(check([19, 25, 26], Text.show_int(List_.cl_sum(nums)), [4, 8])))
	line!(Text.printed(check([17, 19, 73, 13, 26, 31, 14, 30, 2, 18, 17, 23], (if List_.cl_is_empty(List_.cl_nil) { [40, 21, 25, 13] } else { [54, 15, 23, 19, 13] }), [40, 21, 25, 13])))
	line!(Text.printed(check([17, 19, 73, 13, 26, 31, 14, 30, 2, 24, 16, 18, 19], (if List_.cl_is_empty(nums) { [40, 21, 25, 13] } else { [54, 15, 23, 19, 13] }), [54, 15, 23, 19, 13])))
	line!(Text.printed([]))
	line!(Text.printed([77, 77, 77, 2, 41, 21, 21, 15, 30, 73, 49, 17, 19, 14, 2, 42, 31, 13, 21, 15, 14, 17, 16, 18, 19, 2, 77, 77, 77]))
	({
		xs = [10, 20, 30]
		ys = (List.set(xs, I64.to_u64_wrap(1), 99) ?? crash("list-set-at past the end"))
		({
			line!(Text.printed(check([19, 13, 14, 73, 15, 14], List.concat(List.concat(List.concat(List.concat(Text.show_int((List.get(ys, I64.to_u64_wrap(0)) ?? crash("list-at out of range"))), [81]), Text.show_int((List.get(ys, I64.to_u64_wrap(1)) ?? crash("list-at out of range")))), [81]), Text.show_int((List.get(ys, I64.to_u64_wrap(2)) ?? crash("list-at out of range")))), [4, 3, 81, 12, 12, 81, 6, 3])))
			({
				xs2 = [1, 2, 4, 5]
				ys2 = (List.insert(xs2, I64.to_u64_wrap(2), 3) ?? crash("list-insert-at past the end"))
				({
					line!(Text.printed(check([17, 18, 19, 13, 21, 14, 73, 15, 14], List.concat(List.concat(List.concat(List.concat(List.concat(List.concat(List.concat(List.concat(Text.show_int((List.get(ys2, I64.to_u64_wrap(0)) ?? crash("list-at out of range"))), [81]), Text.show_int((List.get(ys2, I64.to_u64_wrap(1)) ?? crash("list-at out of range")))), [81]), Text.show_int((List.get(ys2, I64.to_u64_wrap(2)) ?? crash("list-at out of range")))), [81]), Text.show_int((List.get(ys2, I64.to_u64_wrap(3)) ?? crash("list-at out of range")))), [81]), Text.show_int((List.get(ys2, I64.to_u64_wrap(4)) ?? crash("list-at out of range")))), [4, 81, 5, 81, 6, 81, 7, 81, 8])))
					line!(Text.printed(check([13, 26, 31, 14, 30, 73, 22, 17, 21, 13, 24, 14], Text.show_int(U64.to_i64_wrap(List.len((if True { [] } else { [1] })))), [3])))
					line!(Text.printed(check([13, 26, 31, 14, 30, 73, 23, 13, 14], Text.show_int(U64.to_i64_wrap(List.len((if True { [] } else { [1] })))), [3])))
					({
						people = [{ name: [41, 23, 17, 24, 13], age: 30 }, { name: [58, 16, 32], age: 25 }, { name: [50, 15, 21, 16, 23], age: 40 }]
						line!(Text.printed(check([23, 17, 19, 14, 73, 16, 28, 73, 21, 13, 24, 16, 21, 22, 19], Text.show_int(ages_sum(people, 0, 0)), [12, 8])))
					})
				})
			})
		})
	})
	Ok({})
}
